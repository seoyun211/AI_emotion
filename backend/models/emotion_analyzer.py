## backend/models/emotion_analyzer.py

from __future__ import annotations
from typing import Any, Dict, List, Optional

from .ensemble_model import EnsembleEmotionModel
from .clients.face_client import predict_face_probs_from_frames
from .clients.voice_client import predict_voice_probs
from .clients.text_client import predict_text_probs

class EmotionAnalysisEngine:
    """
    [저작권 보호 대상: 다중 생체 신호 기반 감정 인식 융합 엔진]
    본 클래스는 시각(안면), 언어(텍스트), 청각(음성) 데이터를 상호 보완적으로 
    결합하여 사용자의 감정 상태를 분석하는 핵심 알고리즘을 구현함.
    """

    def __init__(self, w_img: float = 0.6, w_text: float = 0.2, w_audio: float = 0.2):
        # 앙상블 모델 초기화 및 가중치(Weights) 정책 설정
        self.ensemble_model = EnsembleEmotionModel(
            w_img=w_img,
            w_text=w_text,
            w_audio=w_audio,
        )
        # 데이터 부재 또는 오류 발생 시 적용할 기본 확률값 (Uniform Distribution)
        self.fallback_probs = [0.25, 0.25, 0.25, 0.25]

    def _execute_modal_analysis(self, func, data, label: str) -> list[float]:
        """개별 데이터 모달리티 분석 수행 및 예외 처리 로직"""
        if data is None or (isinstance(data, str) and not data.strip()):
            return self.fallback_probs
        
        try:
            return func(data)
        except Exception as e:
            # 실시간 오류 로깅 및 시스템 가용성 보장을 위한 Fallback 메커니즘
            print(f"[ENGINE_ERROR] {label} 분석 실패: {e}")
            return self.fallback_probs

    def run_inference(self, 
                      image_frames: Optional[List[bytes]], 
                      text: Optional[str], 
                      wav_path: Optional[str]) -> Dict[str, Any]:
        """
        멀티모달 데이터 통합 분석 프로세스 (Main Pipeline)
        1. 모달리티별 특징 추출
        2. 독립 분석 결과 산출
        3. 가중치 기반 확률 융합
        """
        
        # 단계 1: 개별 모달리티 분석 (Image, Text, Audio)
        p_img = self._execute_modal_analysis(predict_face_probs_from_frames, image_frames, "Image")
        p_text = self._execute_modal_analysis(predict_text_probs, text, "Text")
        p_audio = self._execute_modal_analysis(predict_voice_probs, wav_path, "Audio")

        # 실시간 모니터링을 위한 디버그 출력
        print(f"[DEBUG] Raw Probabilities -> Img: {p_img}, Text: {p_text}, Audio: {p_audio}")

        # 단계 2: 앙상블(Ensemble) 알고리즘을 통한 결과 융합
        result = self.ensemble_model.predict(
            image_probs=p_img,
            text_probs=p_text,
            audio_probs=p_audio,
        )

        print(f"[DEBUG] Final Integrated Result: {result['final']['probabilities']}")
        
        return result

# --- 외부 인터페이스 유지 ---
# 기존 코드와의 하위 호환성을 위해 싱글톤 인스턴스 및 래퍼 함수 제공
_engine = EmotionAnalysisEngine()

def analyze_multimodal_emotion(
    image_frames: Optional[List[bytes]],
    text: Optional[str],
    wav_path: Optional[str],
) -> Dict[str, Any]:
    return _engine.run_inference(image_frames, text, wav_path)
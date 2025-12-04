# backend/models/emotion_analyzer.py

from __future__ import annotations
from typing import Any, Dict, List, Optional

from .ensemble_model import EnsembleEmotionModel
from .clients.face_client import predict_face_probs_from_frames
from .clients.voice_client import predict_voice_probs
from .clients.text_client import predict_text_probs


# 기본 가중치: 이미지 0.6, 텍스트 0.2, 음성 0.2
ensemble_model = EnsembleEmotionModel(
    w_img=0.6,
    w_text=0.2,
    w_audio=0.2,
)


def _default_probs() -> list[float]:
    return [0.25, 0.25, 0.25, 0.25]


def analyze_multimodal_emotion(
    image_frames: Optional[List[bytes]],
    text: Optional[str],
    wav_path: Optional[str],
) -> Dict[str, Any]:
    """
    - image_frames: 프레임 bytes 리스트 (0~N장)
    - text       : STT 결과 또는 사용자가 입력한 텍스트
    - wav_path   : 임시 저장된 wav 파일 경로 (없으면 None)

    각각 모달리티가 None/빈값이면 → 균일분포 사용.
    """

    # 1) 이미지
    if image_frames:
        try:
            p_img = predict_face_probs_from_frames(image_frames)
        except Exception as e:
            print(f"[EMOTION_ANALYZER] 이미지 모델 오류: {e}")
            p_img = _default_probs()
    else:
        p_img = _default_probs()

    # 2) 텍스트
    if text and text.strip():
        try:
            p_text = predict_text_probs(text)
        except Exception as e:
            print(f"[EMOTION_ANALYZER] 텍스트 모델 오류: {e}")
            p_text = _default_probs()
    else:
        p_text = _default_probs()

    # 3) 음성
    if wav_path:
        try:
            p_audio = predict_voice_probs(wav_path)
        except Exception as e:
            print(f"[EMOTION_ANALYZER] 음성 모델 오류: {e}")
            p_audio = _default_probs()
    else:
        p_audio = _default_probs()

    # 4) 앙상블 결합
    result = ensemble_model.predict(
        image_probs=p_img,
        text_probs=p_text,
        audio_probs=p_audio,
    )
    return result

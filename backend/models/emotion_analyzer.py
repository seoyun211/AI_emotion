# backend/models/emotion_analyzer.py
from __future__ import annotations

from typing import Any, Dict, Optional, List

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
    """입력 모달이 없거나 오류가 날 때 사용할 균일 분포 확률"""
    return [0.25, 0.25, 0.25, 0.25]


def analyze_multimodal_emotion(
    image_frames: Optional[List[bytes]],
    text: Optional[str],
    wav_path: Optional[str],
) -> Dict[str, Any]:
    """
    이미지(프레임 여러 장) / 텍스트 / 음성 입력을 받아
    세 단일 모델의 확률을 계산하고,
    앙상블 결과를 반환한다.

    - image_frames: 프레임 bytes 리스트 (보통 5장)
    - text       : STT 결과 텍스트
    - wav_path   : 로컬 wav 파일 경로

    각 입력이 None이거나 오류가 나면 → 균일 분포 확률 사용.
    """

    # ---------------------------
    # 1) 이미지 확률 (프레임 여러 개)
    # ---------------------------
    if image_frames and len(image_frames) > 0:
        try:
            # 프레임이 너무 많으면 앞에서 몇 개만 사용 (face_client 안에서 5장으로 잘라줘도 됨)
            p_img = predict_face_probs_from_frames(image_frames)
        except Exception:
            p_img = _default_probs()
    else:
        p_img = _default_probs()

    # ---------------------------
    # 2) 텍스트 확률
    # ---------------------------
    if text is not None and text.strip() != "":
        try:
            p_text = predict_text_probs(text)
        except Exception:
            p_text = _default_probs()
    else:
        p_text = _default_probs()

    # ---------------------------
    # 3) 음성 확률
    # ---------------------------
    if wav_path:
        try:
            p_audio = predict_voice_probs(wav_path)
        except Exception:
            p_audio = _default_probs()
    else:
        p_audio = _default_probs()

    # ---------------------------
    # 4) 앙상블 결합
    # ---------------------------
    result = ensemble_model.predict(
        image_probs=p_img,
        text_probs=p_text,
        audio_probs=p_audio,
    )

    return result

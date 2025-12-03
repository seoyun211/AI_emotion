# backend/models/emotion_analyzer.py
from __future__ import annotations
from typing import Any, Dict

from .ensemble_model import EnsembleEmotionModel
from .clients.face_client import predict_face_probs
from .clients.text_client import predict_text_probs
from .clients.voice_client import predict_voice_probs

# 기본 가중치: 이미지 0.6, 텍스트 0.2, 음성 0.2
ensemble_model = EnsembleEmotionModel(
    w_img=0.6,
    w_text=0.2,
    w_audio=0.2,
)


def analyze_multimodal_emotion(
    image_path: str,
    text: str,
    wav_path: str,
) -> Dict[str, Any]:
    """
    이미지/텍스트/음성 경로(또는 텍스트)를 받아
    단일 모델 3개를 돌리고, 앙상블 결과를 반환한다.
    """
    p_img = predict_face_probs(image_path)   # [4]
    p_text = predict_text_probs(text)        # [4]
    p_audio = predict_voice_probs(wav_path)  # [4]

    result = ensemble_model.predict(
        image_probs=p_img,
        text_probs=p_text,
        audio_probs=p_audio,
    )
    return result

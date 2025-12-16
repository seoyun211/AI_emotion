# routers/web_analyze.py
from fastapi import APIRouter, UploadFile, File, Form, HTTPException
from typing import List
import numpy as np

from models.clients.face_client import predict_face_probs_from_frames
from models.clients.text_client import predict_text_probs

router = APIRouter(prefix="/api/v1/web", tags=["web-analyze"])

EMOTION_LABELS = ["기쁨", "분노", "불안", "슬픔"]

def probs_to_top(probs: List[float]) -> str:
    idx = int(np.argmax(probs))
    return EMOTION_LABELS[idx]

def emotion_to_risk(emotion: str) -> float:
    return {
        "기쁨": 0.1,
        "분노": 0.7,
        "불안": 0.8,
        "슬픔": 0.85,
    }.get(emotion, 0.5)

@router.post("/analyze")
async def analyze_web(
    user_id: int = Form(...),
    text: str = Form(""),
    frames: List[UploadFile] = File(default=[]),
):
    """
    웹용: 프레임(JPEG/PNG) 여러 장 + 텍스트만으로 감정 분석
    - 음성 없음
    - 가중치: 이미지 0.6, 텍스트 0.4 (웹 1단계용)
    """
    try:
        # 1) frames bytes
        frame_bytes_list: List[bytes] = []
        for f in frames:
            b = await f.read()
            if b:
                frame_bytes_list.append(b)

        # 2) 각 모달 확률
        p_img = predict_face_probs_from_frames(frame_bytes_list)  # [4]
        p_txt = predict_text_probs(text) if text else [0.25, 0.25, 0.25, 0.25]

        # 3) 앙상블 (웹 1단계: 이미지+텍스트만)
        w_img, w_txt = 0.6, 0.4
        p_final = (np.array(p_img) * w_img + np.array(p_txt) * w_txt).tolist()

        final_emotion = probs_to_top(p_final)
        risk_score = emotion_to_risk(final_emotion)

        return {
            "user_id": user_id,
            "text": text,
            "frames_count": len(frame_bytes_list),
            "p_img": p_img,
            "p_text": p_txt,
            "p_final": dict(zip(EMOTION_LABELS, p_final)),
            "final_emotion": final_emotion,
            "risk_score": risk_score,
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"web analyze 실패: {e}")

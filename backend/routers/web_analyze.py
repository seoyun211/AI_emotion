# routers/web_analyze.py
from fastapi import APIRouter, UploadFile, File, Form, HTTPException
from typing import List
import numpy as np
import base64

from models.clients.face_client import predict_face_probs_from_frames
from models.clients.text_client import predict_text_probs

from services.llm_service import get_llm_response
from services.tts_service import tts_synthesize_to_bytes


router = APIRouter(prefix="/web", tags=["web-analyze"])

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
    웹용 통합 분석:
    - 이미지 + 텍스트 감정분석
    - LLM 답변 생성
    - TTS 음성 생성
    """
    try:
        # --------------------------------------------------
        # 1) 프레임 bytes
        # --------------------------------------------------
        frame_bytes_list: List[bytes] = []
        for f in frames:
            b = await f.read()
            if b:
                frame_bytes_list.append(b)

        # --------------------------------------------------
        # 2) 감정 확률
        # --------------------------------------------------
        p_img = predict_face_probs_from_frames(frame_bytes_list) if frame_bytes_list else [0.25]*4
        p_txt = predict_text_probs(text) if text else [0.25]*4

        # --------------------------------------------------
        # 3) 앙상블 (웹: 이미지 0.6, 텍스트 0.4)
        # --------------------------------------------------
        w_img, w_txt = 0.6, 0.4
        p_final = (np.array(p_img) * w_img + np.array(p_txt) * w_txt).tolist()

        final_emotion = probs_to_top(p_final)
        risk_score = emotion_to_risk(final_emotion)
        confidence = float(max(p_final))

        # --------------------------------------------------
        # 4) ✅ LLM 답변 생성
        # --------------------------------------------------
        llm_reply = get_llm_response(
            user_text=text,
            emotion=final_emotion,
            confidence=confidence,
            risk_score=risk_score,
            ensemble_detail={
                "p_img": p_img,
                "p_text": p_txt,
                "p_final": p_final,
            },
        )

        # --------------------------------------------------
        # 5) ✅ TTS 생성 → base64
        # --------------------------------------------------
        tts_audio_base64 = ""
        tts_bytes = await tts_synthesize_to_bytes(llm_reply)
        if tts_bytes:
            tts_audio_base64 = base64.b64encode(tts_bytes).decode("utf-8")

        # --------------------------------------------------
        # 6) 응답
        # --------------------------------------------------
        return {
            "user_id": user_id,
            "text": text,
            "frames_count": len(frame_bytes_list),

            "p_img": p_img,
            "p_text": p_txt,
            "p_final": dict(zip(EMOTION_LABELS, p_final)),

            "final_emotion": final_emotion,
            "confidence": confidence,
            "risk_score": risk_score,

            # ✅ 핵심
            "llm_reply": llm_reply,
            "tts_audio_base64": tts_audio_base64,
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"web analyze 실패: {e}")
    
print("[WEB_ANALYZE] final_emotion=", final_emotion, "risk=", risk_score, "conf=", confidence)
print("[WEB_ANALYZE] calling LLM...")
llm_reply = get_llm_response(
    user_text=text,
    emotion=final_emotion,
    confidence=confidence,
    risk_score=risk_score,
    ensemble_detail={"p_img": p_img, "p_text": p_txt, "p_final": p_final},
)
print("[WEB_ANALYZE] LLM reply=", llm_reply)


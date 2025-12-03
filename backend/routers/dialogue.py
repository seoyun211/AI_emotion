# backend/routers/dialogue.py

from typing import List, Optional
from io import BytesIO
import base64

from fastapi import APIRouter, UploadFile, File, HTTPException
from fastapi.responses import JSONResponse

from openai import OpenAI
from services.emotion_service import process_emotion_analysis
from services.LLM_service import get_llm_response
from services.TTS_service import tts_synthesize_to_bytes

router = APIRouter(prefix="/dialogue", tags=["Dialogue"])
openai_client = OpenAI()   # 환경변수 OPENAI_API_KEY 필요


@router.post("/speak")
async def handle_user_speech(
    audio_file: UploadFile = File(...),        # 🎙 사용자 음성
    frames: List[UploadFile] = File([]),       # 🎥 영상 프레임 (0~5장)
    user_id: Optional[int] = None,
):
    """
    1) Whisper STT → 텍스트
    2) 앙상블 감정 분석 (이미지+텍스트+음성)
    3) 감정 기반 LLM 응답 생성
    4) TTS 음성 생성 (MP3)
    """

    # ============================
    # 1. 음성 읽기 (raw bytes)
    # ============================
    try:
        wav_bytes = await audio_file.read()
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"오디오 읽기 실패: {e}")

    # ============================
    # 2. Whisper-1 STT 실행
    # ============================
    try:
        transcription = openai_client.audio.transcriptions.create(
            model="whisper-1",
            file=("audio.wav", wav_bytes)   # 업로드 형식
        )
        user_text = transcription.text.strip()
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Whisper STT 실패: {e}")

    if not user_text:
        user_text = "..."  # 최소 fallback 문장

    # ============================
    # 3. 프레임 이미지 bytes 리스트 생성
    # ============================
    frame_bytes_list = None
    if frames:
        frame_bytes_list = []
        for f in frames:
            frame_bytes_list.append(await f.read())

    # ============================
    # 4. 감정 분석 (앙상블)
    # ============================
    analysis_result = await process_emotion_analysis(
        text=user_text,
        user_id=user_id,
        image_frames=frame_bytes_list,
        audio_bytes=wav_bytes,
    )

    emotion = analysis_result["emotion"]
    confidence = float(analysis_result["confidence"])
    risk_score = float(analysis_result["risk_score"])

    # ============================
    # 5. LLM 답변 생성
    # ============================
    llm_reply = get_llm_response(
        user_text=user_text,
        emotion=emotion,
        confidence=confidence,
        risk_score=risk_score,
        ensemble_detail=analysis_result.get("ensemble_detail"),
    )

    # ============================
    # 6. TTS 음성 생성
    # ============================
    try:
        tts_audio_bytes = await tts_synthesize_to_bytes(llm_reply)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"TTS 합성 실패: {e}")

    tts_audio_b64 = base64.b64encode(tts_audio_bytes).decode("utf-8")

    # ============================
    # 7. 최종 응답 반환
    # ============================
    return JSONResponse(
        content={
            "user_id": user_id,
            "user_text": user_text,               # STT 결과
            "emotion": emotion,
            "confidence": confidence,
            "risk_score": risk_score,
            "llm_reply": llm_reply,
            "tts_audio_base64": tts_audio_b64,    # Flutter에서 재생 가능
            "ensemble_detail": analysis_result.get("ensemble_detail"),
            "analysis_id": analysis_result.get("analysis_id"),
            "timestamp": str(analysis_result.get("timestamp")),
        }
    )

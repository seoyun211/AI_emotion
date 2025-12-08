# backend/routers/dialogue.py

from __future__ import annotations
from typing import List, Optional
from io import BytesIO
import base64

from fastapi import APIRouter, UploadFile, File, HTTPException
from fastapi.responses import JSONResponse

import speech_recognition as sr
from pydub import AudioSegment

from services.emotion_service import process_emotion_analysis
from services.llm_service import get_llm_response
from services.tts_service import tts_synthesize_to_bytes

router = APIRouter(prefix="/dialogue", tags=["Dialogue"])

from pydantic import BaseModel
class ChatRequest(BaseModel):
    text: str


@router.post("/speak")
async def handle_user_speech(
    audio_file: UploadFile = File(...),
    frames: List[UploadFile] = File([]),
    user_id: Optional[int] = None,
):
    """
    Flutter 영상통화 화면에서:
      - audio_file: 사용자 음성
      - frames: 0~N개의 얼굴 프레임 이미지 (jpg/png)
    """

    # 1) 오디오를 wav bytes로 변환
    try:
        original_bytes = await audio_file.read()
        audio_segment = AudioSegment.from_file(BytesIO(original_bytes))
        wav_buffer = BytesIO()
        audio_segment.export(wav_buffer, format="wav")
        wav_bytes = wav_buffer.getvalue()
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"오디오 변환 실패: {e}")

    # 2) STT (Google SpeechRecognition)
    recognizer = sr.Recognizer()
    try:
        with sr.AudioFile(BytesIO(wav_bytes)) as source:
            audio_data = recognizer.record(source)

        try:
            user_text = recognizer.recognize_google(audio_data, language="ko-KR")
        except sr.UnknownValueError:
            user_text = ""
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"STT 처리 실패: {e}")

    if not user_text.strip():
        user_text = "..."  # 최소 기본값

    # 3) 프레임 bytes 리스트 생성
    frame_bytes_list: Optional[List[bytes]] = None
    if frames:
        frame_bytes_list = []
        for f in frames:
            frame_bytes_list.append(await f.read())

    # 4) 감정 분석 + DB 저장
    analysis_result = await process_emotion_analysis(
        text=user_text,
        user_id=user_id,
        image_frames=frame_bytes_list,
        audio_bytes=wav_bytes,
    )

    emotion = analysis_result["emotion"]
    confidence = float(analysis_result["confidence"])
    risk_score = float(analysis_result["risk_score"])
    ensemble_detail = analysis_result.get("ensemble_detail")

    # 5) LLM 답변 생성
    llm_reply = get_llm_response(
        user_text=user_text,
        emotion=emotion,
        confidence=confidence,
        risk_score=risk_score,
        ensemble_detail=ensemble_detail,
    )

    # 6) TTS 합성
    tts_audio_bytes = await tts_synthesize_to_bytes(llm_reply)
    if tts_audio_bytes is None:
        raise HTTPException(status_code=500, detail="TTS 합성 실패")

    print(f"[TTS] length = {len(tts_audio_bytes)} bytes")  # ← 이 줄 추가

    tts_b64 = base64.b64encode(tts_audio_bytes).decode("utf-8")
    print(f"[TTS] base64 length = {len(tts_b64)}")         # ← 이 줄 추가


    # 7) Flutter로 응답
    return JSONResponse(
        content={
            "user_id": user_id,
            "user_text": user_text,
            "emotion": emotion,
            "confidence": confidence,
            "risk_score": risk_score,
            "llm_reply": llm_reply,
            "tts_audio_base64": tts_b64,
            "ensemble_detail": ensemble_detail,
            "analysis_id": analysis_result.get("analysis_id"),
            "timestamp": str(analysis_result.get("timestamp")),
        }
    )

@router.post("/chat") # 최종 경로: /dialogue/chat
async def chat_with_maldong(request: ChatRequest, user_id: Optional[int] = None):
    try:
        constrained_text = f"{request.text} (대답은 반드시 2줄 이내로 짧게 해줘)"
        
        # 기존 dialogue.py에서 사용하는 LLM 서비스 연결
        # 감정 데이터가 없으므로 일단 기본값(Normal)으로 전달
        llm_reply = get_llm_response(
            user_text=constrained_text,
            emotion="Normal", 
            confidence=1.0,
            risk_score=0.0
        )
        
        return {"answer": llm_reply}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

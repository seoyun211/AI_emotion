# backend/routers/dialogue.py
from __future__ import annotations

from typing import List, Optional
from io import BytesIO
import base64
from datetime import datetime

from fastapi import APIRouter, UploadFile, File, HTTPException, Form
from fastapi.responses import JSONResponse
from pydantic import BaseModel

import speech_recognition as sr
from pydub import AudioSegment

from services.emotion_service import process_emotion_analysis
from services.llm_service import get_llm_response
from services.tts_service import tts_synthesize_to_bytes

from database.crud import SessionCRUD  # ✅ 너가 올린 crud.py의 SessionCRUD 사용

router = APIRouter(prefix="/dialogue", tags=["Dialogue"])


# =========================================================
# ✅ 1) 모바일/에뮬 실시간: 오디오 + 프레임
# =========================================================
@router.post("/speak")
async def handle_user_speech(
    audio_file: UploadFile = File(...),
    frames: List[UploadFile] = File([]),
    user_id: Optional[int] = Form(None),
):
    print("[/dialogue/speak] ✅ 요청 들어옴")
    print(f"  - user_id: {user_id}, frames: {len(frames)}")

    # 1) 오디오 bytes 읽기
    try:
        original_bytes = await audio_file.read()
        print(f"  - audio_file bytes: {len(original_bytes)}")

        audio_segment = AudioSegment.from_file(BytesIO(original_bytes))
        wav_buffer = BytesIO()
        audio_segment.export(wav_buffer, format="wav")
        wav_bytes = wav_buffer.getvalue()
        print(f"  - wav bytes: {len(wav_bytes)}")
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"오디오 변환 실패: {e}")

    # 2) STT
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
        user_text = "..."

    # 3) 프레임 bytes 리스트
    frame_bytes_list: Optional[List[bytes]] = None
    if frames:
        frame_bytes_list = [await f.read() for f in frames]

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

    # 5) LLM 답변
    llm_reply = get_llm_response(
        user_text=user_text,
        emotion=emotion,
        confidence=confidence,
        risk_score=risk_score,
        ensemble_detail=ensemble_detail,
    )

    # 6) TTS
    tts_audio_bytes = await tts_synthesize_to_bytes(llm_reply)
    if tts_audio_bytes is None:
        raise HTTPException(status_code=500, detail="TTS 합성 실패")

    tts_b64 = base64.b64encode(tts_audio_bytes).decode("utf-8")

    # 7) 응답
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


# =========================================================
# ✅ 2) 웹(Flutter Web): 텍스트 + 프레임(5장)
# =========================================================
@router.post("/web")
async def handle_web_input(
    text: str = Form("..."),
    frames: List[UploadFile] = File([]),
    user_id: Optional[int] = Form(None),
):
    print("[/dialogue/web] ✅ 요청 들어옴")
    print(f"  - user_id: {user_id}, frames: {len(frames)}, text_len: {len(text)}")

    frame_bytes_list: Optional[List[bytes]] = None
    if frames:
        frame_bytes_list = [await f.read() for f in frames]

    analysis_result = await process_emotion_analysis(
        text=text if text.strip() else "...",
        user_id=user_id,
        image_frames=frame_bytes_list,
        audio_bytes=None,
    )

    emotion = analysis_result["emotion"]
    confidence = float(analysis_result["confidence"])
    risk_score = float(analysis_result["risk_score"])
    ensemble_detail = analysis_result.get("ensemble_detail")

    llm_reply = get_llm_response(
        user_text=text if text.strip() else "...",
        emotion=emotion,
        confidence=confidence,
        risk_score=risk_score,
        ensemble_detail=ensemble_detail,
    )

    tts_audio_bytes = await tts_synthesize_to_bytes(llm_reply)
    tts_b64 = base64.b64encode(tts_audio_bytes).decode("utf-8") if tts_audio_bytes else ""

    return JSONResponse(
        content={
            "user_id": user_id,
            "user_text": text,
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


# =========================================================
# ✅ 3) 통화 세션 저장 (start/end) + 통화목록 조회
#    - Flutter CallHistoryScreen과 경로 맞춤
# =========================================================
class EndSessionBody(BaseModel):
    session_id: int
    user_id: int
    full_transcript: str


@router.post("/session/start")
def start_session(user_id: int):
    now = datetime.now()
    now_str = now.strftime("%Y-%m-%d %H:%M:%S")

    session_id = SessionCRUD.create_session(
        user_id=user_id,
        start_time=now_str,
        end_time=None,
        duration_seconds=None,
        full_transcript=None,
    )
    if session_id is None:
        raise HTTPException(status_code=500, detail="통화 세션 시작 기록 생성 실패")

    return {
        "session_id": session_id,
        "user_id": user_id,
        "start_time": now,
        "end_time": None,
        "duration_seconds": None,
        "full_transcript": None,
    }


@router.post("/session/end")
def end_session(body: EndSessionBody):
    now = datetime.now()
    now_str = now.strftime("%Y-%m-%d %H:%M:%S")

    ok = SessionCRUD.update_session(
        session_id=body.session_id,
        end_time=now_str,
        full_transcript=body.full_transcript,
    )
    if not ok:
        raise HTTPException(status_code=404, detail="세션 업데이트 실패")

    updated = SessionCRUD.get_session_by_id(body.session_id)
    if updated is None:
        raise HTTPException(status_code=500, detail="세션 종료 후 데이터 조회 실패")

    return updated


# ✅ CallHistoryScreen이 GET /api/v1/calls/user/{id} 호출하니까 맞춰줌
@router.get("/calls/user/{user_id}")
def get_calls_by_user(user_id: int):
    calls = SessionCRUD.get_sessions_by_user_id(user_id)
    return {"calls": calls}

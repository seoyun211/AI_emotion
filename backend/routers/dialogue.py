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

from database.session import get_db_connection
from database.crud import SessionCRUD  # ✅ 너가 준 CRUD 그대로 사용

from services.emotion_service import process_emotion_analysis
from services.llm_service import get_llm_response
from services.tts_service import tts_synthesize_to_bytes

router = APIRouter(prefix="/dialogue", tags=["Dialogue"])


# =========================================================
# ✅ analysischunk 저장 (테이블명 소문자/대문자 혼동 방지)
#    - 너 요구대로 AnalysisChunk 대신 analysischunk 사용
#    - "통화 1번 = 감정 1개" 정책이라 /session/end에서만 호출
# =========================================================
def insert_analysischunk(
    session_id: int,
    user_id: int,
    text_result: Optional[str],
    audio_result: Optional[str],
    face_result: Optional[str],
    risk_score: Optional[float],
    final_result: str,
) -> int:
    conn = get_db_connection()
    try:
        now = datetime.now()
        with conn.cursor() as cur:
            sql = """
            INSERT INTO analysischunk
              (session_id, user_id, analysis_id, analysis_time,
               text_result, audio_result, face_result,
               risk_score, final_result)
            VALUES (%s, %s, UUID(), %s, %s, %s, %s, %s, %s)
            """
            cur.execute(
                sql,
                (
                    session_id,
                    user_id,
                    now,
                    text_result,
                    audio_result,
                    face_result,
                    risk_score,
                    final_result,
                ),
            )
            conn.commit()
            return cur.lastrowid
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=f"analysischunk 저장 실패: {e}")
    finally:
        conn.close()


# =========================================================
# ✅ 세션 시작/종료 모델
# =========================================================
class SessionStartResponse(BaseModel):
    session_id: int
    user_id: int
    start_time: str


class SessionEndRequest(BaseModel):
    session_id: int
    user_id: int
    full_transcript: str

    # ✅ 통화 종료 시 "최종 1개" 감정만 저장하기 위한 필드들
    final_emotion: str
    risk_score: float = 0.0
    text_result: Optional[str] = None
    audio_result: Optional[str] = None
    face_result: Optional[str] = None


# =========================================================
# ✅ 0) 통화 시작: Session 생성 → session_id 반환
#    - 이걸 호출해야 session_id undefined 문제가 절대 안 남
# =========================================================
@router.post("/session/start", response_model=SessionStartResponse)
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
        raise HTTPException(status_code=500, detail="통화 세션 생성 실패")

    return {
        "session_id": session_id,
        "user_id": user_id,
        "start_time": now_str,
    }


# =========================================================
# ✅ 0-2) 통화 종료:
#    1) Session 종료 업데이트
#    2) analysischunk에 감정 1개만 저장  (⭐ 정책 강제)
# =========================================================
@router.post("/session/end")
def end_session(payload: SessionEndRequest):
    now = datetime.now()
    now_str = now.strftime("%Y-%m-%d %H:%M:%S")

    # 1) 세션 종료 업데이트
    ok = SessionCRUD.update_session(
        session_id=payload.session_id,
        end_time=now_str,
        full_transcript=payload.full_transcript,
    )
    if not ok:
        raise HTTPException(status_code=404, detail="세션 종료 업데이트 실패")

    # 2) ⭐ 통화 1번 = 감정 1개만 저장
    chunk_id = insert_analysischunk(
        session_id=payload.session_id,
        user_id=payload.user_id,
        text_result=payload.text_result,
        audio_result=payload.audio_result,
        face_result=payload.face_result,
        risk_score=float(payload.risk_score),
        final_result=payload.final_emotion,
    )

    return {
        "message": "세션 종료 + 최종 감정 1개 저장 완료",
        "session_id": payload.session_id,
        "chunk_id": chunk_id,
    }


# =========================================================
# ✅ 1) 모바일/에뮬: 오디오 + 프레임 → 분석 + LLM + TTS
#    ⚠️ 여기서는 analysischunk 저장 안 함 (통화 끝에서만 저장)
# =========================================================
@router.post("/speak")
async def handle_user_speech(
    audio_file: UploadFile = File(...),
    frames: List[UploadFile] = File([]),
    user_id: Optional[int] = Form(None),
    session_id: Optional[int] = Form(None),  # ✅ 프론트가 보내면 로그/추적만 가능
):
    print("[/dialogue/speak] ✅ 요청")
    print(f"  - user_id={user_id}, session_id={session_id}, frames={len(frames)}")

    # 1) 오디오 -> wav 변환
    try:
        original_bytes = await audio_file.read()
        audio_segment = AudioSegment.from_file(BytesIO(original_bytes))
        wav_buffer = BytesIO()
        audio_segment.export(wav_buffer, format="wav")
        wav_bytes = wav_buffer.getvalue()
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

    # 3) 프레임 bytes
    frame_bytes_list = [await f.read() for f in frames] if frames else None

    # 4) 감정 분석 (DB 저장은 여기서 하지 않음!)
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

    # 5) LLM
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

    return JSONResponse(
        content={
            "user_id": user_id,
            "session_id": session_id,
            "user_text": user_text,
            "emotion": emotion,
            "confidence": confidence,
            "risk_score": risk_score,
            "llm_reply": llm_reply,
            "tts_audio_base64": tts_b64,
            "ensemble_detail": ensemble_detail,
            # ✅ 저장은 /session/end에서 하므로 여기서는 안내용만
            "timestamp": datetime.now().isoformat(),
        }
    )


# =========================================================
# ✅ 2) 웹(Flutter Web): 텍스트 + 프레임 → 분석 + LLM + TTS
#    ⚠️ 여기서도 analysischunk 저장 안 함 (통화 끝에서만 저장)
# =========================================================
@router.post("/web")
async def handle_web_input(
    text: str = Form("..."),
    frames: List[UploadFile] = File([]),
    user_id: Optional[int] = Form(None),
    session_id: Optional[int] = Form(None),
):
    print("[/dialogue/web] ✅ 요청")
    print(f"  - user_id={user_id}, session_id={session_id}, frames={len(frames)}, text_len={len(text)}")

    frame_bytes_list = [await f.read() for f in frames] if frames else None

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
            "session_id": session_id,
            "user_text": text,
            "emotion": emotion,
            "confidence": confidence,
            "risk_score": risk_score,
            "llm_reply": llm_reply,
            "tts_audio_base64": tts_b64,
            "ensemble_detail": ensemble_detail,
            "timestamp": datetime.now().isoformat(),
        }
    )

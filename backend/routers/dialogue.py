# backend/routers/dialogue.py

from __future__ import annotations
from typing import List, Optional
from io import BytesIO
import base64

from fastapi import APIRouter, UploadFile, File, HTTPException, Form
from fastapi.responses import JSONResponse

import speech_recognition as sr
from pydub import AudioSegment

from services.emotion_service import process_emotion_analysis
from services.llm_service import get_llm_response
from services.tts_service import tts_synthesize_to_bytes

router = APIRouter(prefix="/dialogue", tags=["Dialogue"])


# =========================================================
# ✅ 1) 모바일/에뮬 실시간: 오디오 + 프레임
#    (네가 준 코드 그대로 유지)
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

        # m4a 등 -> wav 변환
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
# ✅ 2) 웹(Flutter Web) 1단계: 텍스트 + 프레임(5장)만
#    - 오디오/ STT 없음
#    - 프레임은 5fps로 캡처해서 frames로 보내면 됨
# =========================================================
@router.post("/web")
async def handle_web_input(
    text: str = Form("..."),
    frames: List[UploadFile] = File([]),
    user_id: Optional[int] = Form(None),
):
    print("[/dialogue/web] ✅ 요청 들어옴")
    print(f"  - user_id: {user_id}, frames: {len(frames)}, text_len: {len(text)}")

    # 1) 프레임 bytes 리스트
    frame_bytes_list: Optional[List[bytes]] = None
    if frames:
        frame_bytes_list = [await f.read() for f in frames]

    # 2) 감정 분석 (✅ 오디오 없음)
    analysis_result = await process_emotion_analysis(
        text=text if text.strip() else "...",
        user_id=user_id,
        image_frames=frame_bytes_list,
        audio_bytes=None,   # ✅ 웹 1단계는 오디오 없음
    )

    emotion = analysis_result["emotion"]
    confidence = float(analysis_result["confidence"])
    risk_score = float(analysis_result["risk_score"])
    ensemble_detail = analysis_result.get("ensemble_detail")

    # 3) LLM 답변
    llm_reply = get_llm_response(
        user_text=text if text.strip() else "...",
        emotion=emotion,
        confidence=confidence,
        risk_score=risk_score,
        ensemble_detail=ensemble_detail,
    )

    # 4) TTS (선택)
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

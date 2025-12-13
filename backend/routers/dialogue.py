# backend/routers/dialogue.py

from __future__ import annotations
from typing import List, Optional
from io import BytesIO
import base64
from datetime import datetime

from fastapi import APIRouter, UploadFile, File, HTTPException
from fastapi.responses import JSONResponse
from models.schemas import SessionCreate, SessionResponse
from database.crud import SessionCRUD

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
    

@router.post("/session/start", response_model=SessionResponse)
def start_session(user_id: int):
    """
    통화 시작 시, Session 레코드를 생성하고 session_id를 반환합니다.
    """
    now = datetime.now()
    now_str = now.strftime('%Y-%m-%d %H:%M:%S') # DB에 문자열로 전달

    session_id = SessionCRUD.create_session(
        user_id=user_id,
        start_time=now_str,
        end_time=None,
        duration_seconds=None,
        full_transcript=None
    )
    
    if session_id is None:
        raise HTTPException(status_code=500, detail="통화 세션 시작 기록 생성 실패")
    # 응답은 SessionResponse Pydantic 모델이 처리하므로 datetime 객체를 그대로 반환해도 되지만
    # # 명확성을 위해 문자열 포맷을 맞춥니다.
    
    return {
        "session_id": session_id,
        "user_id": user_id,
        "start_time": now, # Pydantic이 ISO 포맷으로 변환 처리
        "end_time": None,
        "duration_seconds": None,
        "full_transcript": None
    }


@router.post("/session/end", response_model=SessionResponse)
def end_session(session_id: int, user_id: int, full_transcript: str):
    """
    통화 종료 시, Session 레코드를 업데이트하고 최종 녹취록을 저장합니다.
    """
    now = datetime.now()
    now_str = now.strftime('%Y-%m-%d %H:%M:%S')

    # 1. 세션 업데이트 (종료 시간, 녹취록, 지속 시간 계산)
    success = SessionCRUD.update_session(
        session_id=session_id,
        end_time=now_str,
        full_transcript=full_transcript
    )
    
    if not success:
        # 업데이트 실패 시, 404 또는 500 오류 반환
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, 
                            detail=f"세션 ID {session_id}를 찾을 수 없거나 업데이트에 실패했습니다.")
    
    # 2. 업데이트된 레코드 전체 조회 (새로 추가된 get_session_by_id 사용)
    updated_session_data = SessionCRUD.get_session_by_id(session_id=session_id)

    if updated_session_data is None:
        # 업데이트는 성공했지만 조회가 안 되는 경우 (매우 드뭄, 서버 오류)
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, 
                            detail=f"세션 ID {session_id} 종료 후 최종 데이터 조회 실패")

    # ✅ CRUD에서 반환된 최종 딕셔너리 데이터를 Pydantic 스키마에 맞게 바로 반환
    return updated_session_data
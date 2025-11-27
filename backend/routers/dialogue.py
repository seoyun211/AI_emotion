# backend/routers/dialogue.py

from fastapi import APIRouter, UploadFile, File, HTTPException
from fastapi.responses import Response
from services.LLM_service import get_llm_response
from services.TTS_service import tts_synthesize_to_bytes
from services.emotion_service import process_emotion_analysis

import speech_recognition as sr
from io import BytesIO
from pydub import AudioSegment

router = APIRouter(prefix="/dialogue", tags=["Dialogue"])


@router.post("/speak")
async def handle_user_speech(audio_file: UploadFile = File(...)):
    """Flutter 앱에서 받은 오디오를 처리하고, 감정 분석 + LLM + TTS 후 응답 오디오 반환"""
    
    # --- 1. 오디오 파일 읽기 및 WAV 변환 ---
    original_audio_bytes = await audio_file.read()

    try:
        # Pydub으로 어떤 포맷이든 WAV로 변환 (STT + 감정 모델용)
        audio_segment = AudioSegment.from_file(BytesIO(original_audio_bytes))
        wav_buffer = BytesIO()
        audio_segment.export(wav_buffer, format="wav")
        wav_buffer.seek(0)
        wav_bytes_for_emotion = wav_buffer.getvalue()
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"오디오 파일 처리 오류: {e}")

    # --- 2. STT (Speech-to-Text) ---
    r = sr.Recognizer()
    wav_buffer.seek(0)
    with sr.AudioFile(wav_buffer) as source:
        audio = r.record(source)
    try:
        user_text = r.recognize_google(audio, language="ko-KR")
        print(f"사용자 텍스트: {user_text}")
    except sr.UnknownValueError:
        # 인식 실패 시: 감정 분석은 생략하고 안내 멘트만 반환 (기존 동작 유지)
        return {"response_text": "다시 말씀해 주시겠어요?", "emotion": "중립"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"STT 오류: {e}")

    # --- 3. 감정 분석 + DB 저장 (Fusion 모델: text + audio) ---
    try:
        analysis_result = await process_emotion_analysis(
            text=user_text,
            user_id=None,               # 나중에 실제 user_id 넘기면 됨
            image_bytes=None,           # 지금은 이미지 없음
            audio_bytes=wav_bytes_for_emotion,
        )
        print(f"[Emotion] {analysis_result['emotion']} (risk={analysis_result['risk_score']})")
    except HTTPException as e:
        raise e
    except Exception as e:
        print(f"❌ 감정 분석 중 오류: {e}")
        # 여기서 바로 막지 않고, LLM/TTS는 계속 진행할지 여부는 선택 사항
        # 지금은 계속 진행하도록 둠

    # --- 4. LLM 응답 생성 ---
    llm_response_text = get_llm_response(user_text)

    # --- 5. TTS (Text-to-Speech) ---
    tts_audio_bytes = tts_synthesize_to_bytes(llm_response_text)
    if not tts_audio_bytes:
        raise HTTPException(status_code=500, detail="TTS 오디오 생성 실패")
        
    # --- 6. 응답 반환 ---
    return Response(content=tts_audio_bytes, media_type="audio/mp3")

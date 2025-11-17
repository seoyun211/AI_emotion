# backend/routers/dialogue.py
from fastapi import APIRouter, UploadFile, File, HTTPException
from fastapi.responses import Response
from services.LLM_service import get_llm_response
from services.TTS_service import tts_synthesize_to_bytes
import speech_recognition as sr
from io import BytesIO
from pydub import AudioSegment

router = APIRouter(prefix="/dialogue", tags=["Dialogue"])

@router.post("/speak")
async def handle_user_speech(audio_file: UploadFile = File(...)):
    """Flutter 앱에서 받은 오디오를 처리하고 응답 오디오를 반환합니다."""
    
    # --- 1. 오디오 파일 읽기 및 WAV 변환 ---
    audio_bytes = await audio_file.read()
    try:
        # Pydub을 사용하여 받은 오디오(예: webm, m4a 등)를 WAV로 변환
        audio_segment = AudioSegment.from_file(BytesIO(audio_bytes))
        wav_buffer = BytesIO()
        audio_segment.export(wav_buffer, format="wav")
        wav_buffer.seek(0)
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"오디오 파일 처리 오류: {e}")

    # --- 2. STT (Speech-to-Text) ---
    r = sr.Recognizer()
    with sr.AudioFile(wav_buffer) as source:
        audio = r.record(source)
    try:
        user_text = r.recognize_google(audio, language="ko-KR")
        print(f"사용자 텍스트: {user_text}")
    except sr.UnknownValueError:
        return {"response_text": "다시 말씀해 주시겠어요?", "emotion": "중립"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"STT 오류: {e}")

    # --- 3. 감정 분석 및 DB 저장 (main.py의 로직을 서비스로 분리하여 통합해야 함) ---
    # *TODO: 여기서 user_text를 main.py의 /predict 로직(emotion_service)을 호출하여 감정 분석 수행 및 DB 저장*
    emotion = "기쁨" # 임시 감정

    # --- 4. LLM 응답 생성 ---
    llm_response_text = get_llm_response(user_text)

    # --- 5. TTS (Text-to-Speech) ---
    tts_audio_bytes = tts_synthesize_to_bytes(llm_response_text)
    if not tts_audio_bytes:
        raise HTTPException(status_code=500, detail="TTS 오디오 생성 실패")
        
    # --- 6. 응답 반환 ---
    return Response(content=tts_audio_bytes, media_type="audio/mp3")

# 참고: 오디오 파일 없이 텍스트만 처리하고 싶다면, 별도의 POST /text 엔드포인트를 만들어야 합니다.
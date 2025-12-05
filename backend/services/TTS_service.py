# backend/services/tts_service.py
from google.cloud import texttospeech
import os

# Google Cloud 인증 정보가 환경 변수로 설정되어 있어야 합니다.

def tts_synthesize_to_bytes(text: str) -> bytes | None:
    """텍스트를 받아 MP3 오디오 바이트를 반환합니다."""
    try:
        client = texttospeech.TextToSpeechClient()
        synthesis_input = texttospeech.SynthesisInput(text=text)
        voice = texttospeech.VoiceSelectionParams(
            language_code="ko-KR", ssml_gender=texttospeech.SsmlVoiceGender.FEMALE
        )
        audio_config = texttospeech.AudioConfig(
            audio_encoding=texttospeech.AudioEncoding.MP3
        )
        response = client.synthesize_speech(
            input=synthesis_input, voice=voice, audio_config=audio_config
        )
        return response.audio_content
    except Exception as e:
        print(f"TTS 오류: {e}")
        return None
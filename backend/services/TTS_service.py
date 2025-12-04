# backend/services/tts_service.py
import asyncio
from google.cloud import texttospeech


async def tts_synthesize_to_bytes(text: str) -> bytes:
    """
    Google TTS를 비동기 방식처럼 사용할 수 있도록
    별도 스레드에서 실행하도록 감싸줌.
    """

    return await asyncio.to_thread(_tts_blocking, text)


def _tts_blocking(text: str) -> bytes | None:
    """
    실제 TTS 작업 (blocking)
    """
    try:
        client = texttospeech.TextToSpeechClient()

        synthesis_input = texttospeech.SynthesisInput(text=text)
        voice = texttospeech.VoiceSelectionParams(
            language_code="ko-KR",
            ssml_gender=texttospeech.SsmlVoiceGender.FEMALE
        )
        audio_config = texttospeech.AudioConfig(
            audio_encoding=texttospeech.AudioEncoding.MP3
        )

        response = client.synthesize_speech(
            input=synthesis_input,
            voice=voice,
            audio_config=audio_config,
        )
        return response.audio_content

    except Exception as e:
        print(f"[TTS 오류] {e}")
        return None

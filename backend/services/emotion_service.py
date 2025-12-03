# backend/services/emotion_service.py

import uuid
import asyncio
from datetime import datetime
from typing import Any, Dict, Optional, List
from pathlib import Path

from fastapi import HTTPException

from models.emotion_analyzer import analyze_multimodal_emotion
from database.session import get_db_connection

TEMP_DIR = Path("temp_uploads")
TEMP_DIR.mkdir(exist_ok=True, parents=True)


class EmotionService:

    @staticmethod
    async def analyze_multimodal_emotion(
        text: Optional[str],
        image_frames: Optional[List[bytes]],   # 🔥 프레임 리스트로 변경
        audio_bytes: Optional[bytes],
        user_id: Optional[int] = None,
    ) -> Dict[str, Any]:
        """
        이미지 프레임 리스트와 음성 bytes를 받아
        1) 음성만 임시 wav 파일로 저장하고
        2) 앙상블 파이프라인(analyze_multimodal_emotion)을 호출한다.
        """

        audio_path = None

        # 1) 오디오 임시 저장
        try:
            if audio_bytes:
                audio_path = TEMP_DIR / f"{uuid.uuid4()}_audio.wav"
                with audio_path.open("wb") as f:
                    f.write(audio_bytes)

        except Exception as e:
            raise HTTPException(status_code=500, detail=f"파일 저장 실패: {e}")

        # 2) 앙상블 모델 호출
        try:
            result = analyze_multimodal_emotion(
                image_frames=image_frames,
                text=text,
                wav_path=str(audio_path) if audio_path else None,
            )
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"감정 분석 실패: {e}")
        finally:
            # 3) 임시 오디오 파일 정리
            if audio_path and audio_path.exists():
                audio_path.unlink()

        return result


emotion_service = EmotionService()


# ------------------------------
# 💾 DB 저장 함수
# ------------------------------
def save_analysis_chunk(
    text: str,
    emotion: str,
    confidence: float,
    risk_score: float,
    analysis_id: str,
    user_id: Optional[int] = None,
) -> str:

    conn = get_db_connection()
    if not conn:
        return " (DB 연결 실패)"

    try:
        with conn.cursor() as cursor:
            sql = """
            INSERT INTO AnalysisChunk
            (session_id, user_id, analysis_id, analysis_time,
             text_result, audio_result, face_result,
             confidence, risk_score, final_result)
            VALUES (%s, %s, %s, NOW(),
                    %s, NULL, NULL,
                    %s, %s, %s)
            """

            cursor.execute(sql, (
                user_id or 1,
                user_id or 1,
                analysis_id,
                text,
                confidence,
                risk_score,
                emotion
            ))

        conn.commit()
        return " (DB 저장 완료)"

    except Exception as e:
        conn.rollback()
        return f"(DB 저장 실패: {e})"


# ------------------------------
# 🚀 최종 실행 함수 (라우터에서 호출)
# ------------------------------
async def process_emotion_analysis(
    text: str,
    user_id: Optional[int] = None,
    image_frames: Optional[List[bytes]] = None,  # 🔥 프레임 리스트
    audio_bytes: Optional[bytes] = None,
) -> Dict[str, Any]:

    # 1) 앙상블 분석 실행
    analysis_result = await emotion_service.analyze_multimodal_emotion(
        text=text,
        image_frames=image_frames,    # 🔥 여기서 image_frames 넘김
        audio_bytes=audio_bytes,
        user_id=user_id,
    )

    # analysis_result 예:
    # {
    #   "final": {...},
    #   "per_modality": {...}
    # }
    final = analysis_result["final"]
    emotion_label = final["label"]
    confidence = float(final["probabilities"][emotion_label])
    risk_score = confidence * (1.3 if final["id"] in (2, 3) else 1.0)

    analysis_id = str(uuid.uuid4())
    now = datetime.now()

    # 2) DB 저장
    db_msg = await asyncio.to_thread(
        save_analysis_chunk,
        text=text,
        emotion=emotion_label,
        confidence=confidence,
        risk_score=risk_score,
        analysis_id=analysis_id,
        user_id=user_id,
    )

    # 3) 클라이언트 응답
    return {
        "emotion": emotion_label,
        "confidence": confidence,
        "risk_score": risk_score,
        "user_id": user_id,
        "analysis_id": analysis_id,
        "timestamp": now,
        "ensemble_detail": analysis_result,
        "message": "감정 분석 완료" + db_msg,
    }

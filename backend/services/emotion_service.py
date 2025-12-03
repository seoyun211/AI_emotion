# backend/services/emotion_service.py

from __future__ import annotations

import uuid
import asyncio
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, Optional, List

from fastapi import HTTPException

from models.emotion_analyzer import analyze_multimodal_emotion
from database.session import get_db_connection


TEMP_DIR = Path("temp_uploads")
TEMP_DIR.mkdir(exist_ok=True, parents=True)


class EmotionService:
    @staticmethod
    async def analyze_multimodal_emotion(
        text: Optional[str],
        image_frames: Optional[List[bytes]],
        audio_bytes: Optional[bytes],
        user_id: Optional[int] = None,
    ) -> Dict[str, Any]:
        """
        - image_frames: 프레임 bytes 리스트
        - audio_bytes: 녹음된 음성 (bytes, wav or other)
        """

        # 1) 오디오 임시 wav 파일로 저장
        audio_path = None
        try:
            if audio_bytes:
                audio_path = TEMP_DIR / f"{uuid.uuid4()}_audio.wav"
                with audio_path.open("wb") as f:
                    f.write(audio_bytes)
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"오디오 파일 저장 실패: {e}")

        # 2) 감정 분석 호출
        try:
            result = analyze_multimodal_emotion(
                image_frames=image_frames,
                text=text,
                wav_path=str(audio_path) if audio_path else None,
            )
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"감정 분석 실패: {e}")

        # 3) 임시파일 정리
        if audio_path and audio_path.exists():
            try:
                audio_path.unlink()
            except Exception:
                pass

        return result


emotion_service = EmotionService()


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
            cursor.execute(
                sql,
                (
                    user_id or 1,
                    user_id or 1,
                    analysis_id,
                    text,
                    confidence,
                    risk_score,
                    emotion,
                ),
            )
        conn.commit()
        return " (DB 저장 완료)"
    except Exception as e:
        conn.rollback()
        return f"(DB 저장 실패: {e})"


async def process_emotion_analysis(
    text: str,
    user_id: Optional[int] = None,
    image_frames: Optional[List[bytes]] = None,
    audio_bytes: Optional[bytes] = None,
) -> Dict[str, Any]:
    """
    Dialogue 라우터에서 호출:
    - text: STT 결과
    - image_frames: 프레임 bytes 리스트
    - audio_bytes: wav bytes
    """

    analysis_result = await emotion_service.analyze_multimodal_emotion(
        text=text,
        image_frames=image_frames,
        audio_bytes=audio_bytes,
        user_id=user_id,
    )

    final = analysis_result["final"]
    emotion_label = final["label"]
    probabilities = final["probabilities"]
    confidence = float(probabilities[emotion_label])

    # 🔥 불안(2), 슬픔(3)일 때 risk_score 가중치 ↑
    if final["id"] in (2, 3):
        risk_score = confidence * 1.3
    else:
        risk_score = confidence * 1.0

    analysis_id = str(uuid.uuid4())
    now = datetime.now()

    db_msg = await asyncio.to_thread(
        save_analysis_chunk,
        text=text,
        emotion=emotion_label,
        confidence=confidence,
        risk_score=risk_score,
        analysis_id=analysis_id,
        user_id=user_id,
    )

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

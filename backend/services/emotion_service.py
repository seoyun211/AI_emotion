# backend/services/emotion_service.py

from models.emotion_analyzer import analyze_emotion   # 텍스트-only 기본 모델 (선택사항)
from models.ensemble_model import ensemble_model      # 🔥 새 앙상블 모델 불러오기
from database.session import get_db_connection

import asyncio
from typing import Dict, Any, Optional
import uuid
from datetime import datetime
from fastapi import HTTPException


class EmotionService:

    # @staticmethod
    #async def analyze_text_emotion(text: str, user_id: Optional[str] = None) -> Dict:
        #"""
        #텍스트-only 모델을 계속 쓰고 싶으면 사용.
        #앙상블에 텍스트까지 포함하면 이 함수는 안 써도 됨.
        #"""
        #return analyze_emotion(text)

    @staticmethod
    async def analyze_multimodal_emotion(
        text: Optional[str],
        image_bytes: Optional[bytes],
        audio_bytes: Optional[bytes],
        user_id: Optional[str] = None,
    ) -> Dict:
        """
        🔥 앙상블 모델을 직접 호출해서 결과 그대로 반환
        """
        result = ensemble_model.predict(
            text=text,
            image_bytes=image_bytes,
            audio_bytes=audio_bytes,
        )
        return result


emotion_service = EmotionService()


# ------------------------------
# 💾 DB 저장 함수
# ------------------------------

def save_analysis_chunk(
    text: str,
    emotion: str,
    risk_score: float,
    analysis_id: str,
    user_id: Optional[str] = None,
) -> str:
    conn = get_db_connection()
    if not conn:
        return " (DB 연결 실패로 저장 불가)"

    try:
        with conn.cursor() as cursor:
            sql = """
            INSERT INTO AnalysisChunk
            (session_id, user_id, analysis_id, analysis_time, 
             text_result, audio_result, face_result, risk_score, final_result) 
            VALUES (%s, %s, %s, NOW(),
                    %s, NULL, NULL, %s, %s)
            """
            cursor.execute(sql, (
                1,
                1,
                analysis_id,
                text,
                risk_score,
                emotion
            ))
        conn.commit()
        return " 및 DB 저장 완료"

    except Exception as db_e:
        conn.rollback()
        print(f"❌❌ DB INSERT 오류: {db_e}")
        return f"DB 저장 실패: {db_e}"


# ------------------------------
# 🚀 최종 통합 실행 함수
# ------------------------------

async def process_emotion_analysis(
    text: str,
    user_id: Optional[str] = None,
    image_bytes: Optional[bytes] = None,
    audio_bytes: Optional[bytes] = None,
) -> Dict[str, Any]:

    # 1. 감정 분석 실행
    if audio_bytes is not None or image_bytes is not None:
        # 🔥 앙상블 모델 사용
        analysis_result = await emotion_service.analyze_multimodal_emotion(
            text=text,
            image_bytes=image_bytes,
            audio_bytes=audio_bytes,
            user_id=user_id,
        )
    else:
        # 텍스트-only (원하면 ensemble_model.predict 로 통일 가능)
        analysis_result = await emotion_service.analyze_text_emotion(text, user_id)

    analysis_id = str(uuid.uuid4())
    current_time = datetime.now()

    # 2. DB 저장
    db_message = await asyncio.to_thread(
        save_analysis_chunk,
        text=text,
        emotion=analysis_result["emotion"],
        risk_score=analysis_result["risk_score"],
        analysis_id=analysis_id,
        user_id=user_id,
    )

    if db_message.startswith("DB 저장 실패:"):
        raise HTTPException(status_code=500, detail=f"감정 분석 저장 중 에러 발생")

    # 3. 응답 반환
    return {
        **analysis_result,
        "analysis_id": analysis_id,
        "user_id": user_id,
        "timestamp": current_time,
        "message": "감정 분석 완료" + db_message,
    }

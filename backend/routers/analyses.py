# routers/analyses.py
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List, Tuple
from datetime import datetime
import uuid

from database.session import get_db_connection
from models.schemas import EmotionStatsResponse  # 감정 통계 응답 스키마

router = APIRouter(prefix="/api/v1/analyses", tags=["분석 기록"])

# ---------------------------------------------------------
# 1. 기존 분석 저장 모델
# ---------------------------------------------------------
class AnalysisCreate(BaseModel):
    session_id: int
    text_result: str
    final_result: str


class AnalysisResponse(BaseModel):
    session_id: int
    analysis_time: datetime
    text_result: str
    final_result: str


# ---------------------------------------------------------
# 2. 분석 저장 (기존 코드 그대로)
# ---------------------------------------------------------
@router.post("/", response_model=AnalysisResponse)
def create_analysis(data: AnalysisCreate):
    """
    analysischunk 테이블에 분석 결과 저장 (구버전용)
    """
    conn = get_db_connection()
    try:
        now = datetime.now()
        with conn.cursor() as cur:
            sql = """
            INSERT INTO analysischunk
              (session_id, analysis_time, text_result, final_result)
            VALUES (%s, %s, %s, %s)
            """
            cur.execute(sql, (data.session_id, now, data.text_result, data.final_result))
            conn.commit()

        return AnalysisResponse(
            session_id=data.session_id,
            analysis_time=now,
            text_result=data.text_result,
            final_result=data.final_result,
        )

    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=f"분석 기록 저장 실패: {e}")
    finally:
        conn.close()


# ---------------------------------------------------------
# 3. 특정 세션 분석 기록 조회 (기존 코드 그대로)
# ---------------------------------------------------------
@router.get("/session/{session_id}", response_model=List[AnalysisResponse])
def get_analyses_by_session(session_id: int):
    """
    특정 세션(session_id)에 대한 분석 기록 목록 조회 (구버전용)
    """
    conn = get_db_connection()
    try:
        with conn.cursor() as cur:
            sql = """
            SELECT
              session_id,
              analysis_time,
              text_result,
              final_result
            FROM analysischunk
            WHERE session_id = %s
            ORDER BY analysis_time DESC
            """
            cur.execute(sql, (session_id,))
            rows = cur.fetchall() or []

        return [AnalysisResponse(**row) for row in rows]

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"분석 기록 조회 실패: {e}")
    finally:
        conn.close()


# =========================================================
# 4. 월별 감정 통계 API (AnalysisChunk 기반)
# =========================================================
def _get_month_range(year: int, month: int) -> Tuple[datetime, datetime]:
    start = datetime(year, month, 1)
    if month == 12:
        end = datetime(year + 1, 1, 1)
    else:
        end = datetime(year, month + 1, 1)
    return start, end


def save_analysis(session_id: int, user_id: int, result: dict) -> int:
    """
    감정 분석 결과를 AnalysisChunk 테이블에 저장하고 chunk_id 반환
    ✅ 영상 업로드용이 아니라 /dialogue/speak 같은 "실시간 분석" 저장용으로 유지
    """
    conn = get_db_connection()
    try:
        now = datetime.now()
        with conn.cursor() as cur:
            sql = """
            INSERT INTO AnalysisChunk
              (session_id, user_id, analysis_id, analysis_time,
               text_result, audio_result, face_result,
               risk_score, final_result)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
            """
            cur.execute(
                sql,
                (
                    session_id,
                    user_id,
                    str(uuid.uuid4()),
                    now,
                    result.get("text_top"),
                    result.get("audio_top"),
                    result.get("image_top"),
                    result.get("risk_score"),
                    result.get("final_emotion"),
                ),
            )
            conn.commit()
            return cur.lastrowid
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=f"분석 저장 실패: {e}")
    finally:
        conn.close()


@router.get("/stats/monthly/{user_id}", response_model=EmotionStatsResponse)
def get_monthly_emotion_stats(user_id: int, year: int, month: int):
    """
    특정 유저의 월별 감정 통계 (AnalysisChunk.final_result 기준)
    """
    start, end = _get_month_range(year, month)
    conn = get_db_connection()

    try:
        with conn.cursor() as cur:
            sql = """
            SELECT a.final_result
            FROM AnalysisChunk a
            JOIN Session s ON a.session_id = s.session_id
            WHERE s.user_id = %s
              AND a.analysis_time >= %s
              AND a.analysis_time < %s
            """
            cur.execute(sql, (user_id, start, end))
            rows = cur.fetchall() or []

        joy = anger = anxiety = sadness = 0
        for row in rows:
            emotion_label = row["final_result"]
            if emotion_label == "기쁨":
                joy += 1
            elif emotion_label == "분노":
                anger += 1
            elif emotion_label == "불안":
                anxiety += 1
            elif emotion_label == "슬픔":
                sadness += 1

        return EmotionStatsResponse(joy=joy, anger=anger, anxiety=anxiety, sadness=sadness)

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"월별 감정 통계 조회 실패: {e}")
    finally:
        conn.close()

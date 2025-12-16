# routers/analyses.py
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List, Tuple
from datetime import datetime
import uuid

from database.session import get_db_connection
from models.schemas import EmotionStatsResponse  # joy/anger/anxiety/sadness

router = APIRouter(prefix="/analyses", tags=["분석 기록"])

# ---------------------------------------------------------
# 1) 구버전용 저장/조회
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

@router.post("/", response_model=AnalysisResponse)
def create_analysis(data: AnalysisCreate):
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
        try:
            conn.rollback()
        except Exception:
            pass
        raise HTTPException(status_code=500, detail=f"분석 기록 저장 실패: {e}")
    finally:
        try:
            conn.close()
        except Exception:
            pass

@router.get("/session/{session_id}", response_model=List[AnalysisResponse])
def get_analyses_by_session(session_id: int):
    conn = get_db_connection()
    try:
        with conn.cursor() as cur:
            sql = """
            SELECT session_id, analysis_time, text_result, final_result
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
        try:
            conn.close()
        except Exception:
            pass

# ---------------------------------------------------------
# 2) dialogue에서 호출 가능한 저장 함수 (원하면 사용)
# ---------------------------------------------------------
def save_analysis(session_id: int, user_id: int, result: dict) -> int:
    conn = get_db_connection()
    try:
        now = datetime.now()
        with conn.cursor() as cur:
            sql = """
            INSERT INTO analysischunk
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
        try:
            conn.rollback()
        except Exception:
            pass
        raise HTTPException(status_code=500, detail=f"분석 저장 실패: {e}")
    finally:
        try:
            conn.close()
        except Exception:
            pass

# ---------------------------------------------------------
# 3) 월별 통계
# GET /api/v1/analyses/stats/monthly/{user_id}?year=2025&month=12
# ---------------------------------------------------------
def _get_month_range(year: int, month: int) -> Tuple[datetime, datetime]:
    start = datetime(year, month, 1)
    if month == 12:
        end = datetime(year + 1, 1, 1)
    else:
        end = datetime(year, month + 1, 1)
    return start, end

@router.get("/stats/monthly/{user_id}", response_model=EmotionStatsResponse)
def get_monthly_emotion_stats(user_id: int, year: int, month: int):
    start, end = _get_month_range(year, month)
    conn = get_db_connection()
    try:
        with conn.cursor() as cur:
            sql = """
            SELECT final_result
            FROM analysischunk
            WHERE user_id = %s
              AND analysis_time >= %s
              AND analysis_time < %s
            """
            cur.execute(sql, (user_id, start, end))
            rows = cur.fetchall() or []

        joy = anger = anxiety = sadness = 0
        for row in rows:
            e = row.get("final_result")
            if e == "기쁨":
                joy += 1
            elif e == "분노":
                anger += 1
            elif e == "불안":
                anxiety += 1
            elif e == "슬픔":
                sadness += 1

        return EmotionStatsResponse(joy=joy, anger=anger, anxiety=anxiety, sadness=sadness)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"월별 감정 통계 조회 실패: {e}")
    finally:
        try:
            conn.close()
        except Exception:
            pass

# ---------------------------------------------------------
# 4) 오늘 최다 감정
# GET /api/v1/analyses/stats/today-top/{user_id}
# ---------------------------------------------------------
@router.get("/stats/today-top/{user_id}")
def get_today_top_emotion(user_id: int):
    conn = get_db_connection()
    try:
        with conn.cursor() as cur:
            sql = """
            SELECT final_result, COUNT(*) as cnt
            FROM analysischunk
            WHERE user_id = %s
              AND DATE(analysis_time) = CURDATE()
            GROUP BY final_result
            ORDER BY cnt DESC
            LIMIT 1
            """
            cur.execute(sql, (user_id,))
            row = cur.fetchone()

        if not row:
            return {"emotion": None, "count": 0}

        return {"emotion": row["final_result"], "count": int(row["cnt"])}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"오늘 최다 감정 조회 실패: {e}")
    finally:
        try:
            conn.close()
        except Exception:
            pass

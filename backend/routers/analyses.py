# routers/analyses.py
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime

from database.session import get_db_connection

router = APIRouter(prefix="/api/v1/analyses", tags=["분석 기록"])


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
    """
    analysischunk 테이블에 분석 결과 저장
    (모델에서 분석 완료된 결과를 받아서 저장)
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
            cur.execute(
                sql,
                (
                    data.session_id,
                    now,
                    data.text_result,
                    data.final_result,
                ),
            )
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


@router.get("/session/{session_id}", response_model=List[AnalysisResponse])
def get_analyses_by_session(session_id: int):
    """
    특정 세션(session_id)에 대한 분석 기록 목록 조회
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

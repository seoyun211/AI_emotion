# routers/calls.py
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional
from datetime import datetime

from database.session import get_db_connection

router = APIRouter(prefix="/api/v1/calls", tags=["통화 기록"])


class CallStartRequest(BaseModel):
    user_id: int  # 통화 주체 회원 ID


class CallResponse(BaseModel):
    session_id: int
    user_id: int
    start_time: datetime
    end_time: Optional[datetime] = None
    duration_seconds: Optional[int] = None


@router.post("/start", response_model=CallResponse)
def start_call(data: CallStartRequest):
    """
    통화 시작 기록 (session 테이블)
    """
    conn = get_db_connection()
    try:
        now = datetime.now()
        with conn.cursor() as cur:
            sql = """
            INSERT INTO `session` (user_id, start_time)
            VALUES (%s, %s)
            """
            cur.execute(sql, (data.user_id, now))
            conn.commit()
            session_id = cur.lastrowid

        return CallResponse(
            session_id=session_id,
            user_id=data.user_id,
            start_time=now,
            end_time=None,
            duration_seconds=None,
        )

    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=f"통화 시작 기록 실패: {e}")
    finally:
        conn.close()


@router.post("/{session_id}/end", response_model=CallResponse)
def end_call(session_id: int):
    """
    통화 종료 기록 + 통화지속시간 계산
    """
    conn = get_db_connection()
    try:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT user_id, start_time, end_time
                FROM `session`
                WHERE session_id = %s
                """,
                (session_id,),
            )
            row = cur.fetchone()

            if not row:
                raise HTTPException(status_code=404, detail="통화 기록을 찾을 수 없습니다.")

            if row["end_time"] is not None:
                raise HTTPException(status_code=400, detail="이미 종료된 통화입니다.")

            start_time = row["start_time"]
            end_time = datetime.now()
            duration = int((end_time - start_time).total_seconds())

            update_sql = """
            UPDATE `session`
            SET end_time = %s, duration_seconds = %s
            WHERE session_id = %s
            """
            cur.execute(update_sql, (end_time, duration, session_id))
            conn.commit()

        return CallResponse(
            session_id=session_id,
            user_id=row["user_id"],
            start_time=start_time,
            end_time=end_time,
            duration_seconds=duration,
        )

    except HTTPException:
        raise
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=f"통화 종료 기록 실패: {e}")
    finally:
        conn.close()

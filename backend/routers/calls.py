# routers/calls.py
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
from services.emotion_service import process_emotion_analysis
#from services.alert_service import create_alert
from routers.analyses import save_analysis
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


class CallListResponse(BaseModel):
    calls: List[CallResponse]


@router.post("/start", response_model=CallResponse)
def start_call(data: CallStartRequest):
    """
    통화 시작 기록 (Session 테이블)
    """
    conn = get_db_connection()
    try:
        now = datetime.now()
        with conn.cursor() as cur:
            sql = """
            INSERT INTO `Session` (user_id, start_time)
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
    conn = get_db_connection()
    try:
        with conn.cursor() as cur:
            cur.execute("SELECT user_id, start_time, end_time FROM `Session` WHERE session_id = %s", (session_id,))
            row = cur.fetchone()
            if not row: raise HTTPException(status_code=404, detail="기록 없음")
            if row["end_time"]: raise HTTPException(status_code=400, detail="이미 종료됨")

            start_time = row["start_time"]
            end_time = datetime.now()
            duration = int((end_time - start_time).total_seconds())

            cur.execute("UPDATE `Session` SET end_time=%s, duration_seconds=%s WHERE session_id=%s", (end_time, duration, session_id))
            conn.commit()

            return CallResponse(
                session_id=session_id, user_id=row["user_id"],
                start_time=start_time, end_time=end_time, duration_seconds=duration
            )
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        conn.close()
        
@router.get("/user/{user_id}", response_model=CallListResponse)
def get_call_history_by_user(user_id: int):
    """
    특정 유저의 통화 기록 전체 조회 (최근 순)
    Flutter 통화기록 화면에서 사용하는 API
    """
    conn = get_db_connection()
    try:
        with conn.cursor() as cur:
            sql = """
            SELECT session_id, user_id, start_time, end_time, duration_seconds
            FROM `Session`
            WHERE user_id = %s
            ORDER BY start_time DESC
            """
            cur.execute(sql, (user_id,))
            rows = cur.fetchall()

        calls: List[CallResponse] = []
        for row in rows:
            calls.append(
                CallResponse(
                    session_id=row["session_id"],
                    user_id=row["user_id"],
                    start_time=row["start_time"],
                    end_time=row["end_time"],
                    duration_seconds=row["duration_seconds"],
                )
            )

        return CallListResponse(calls=calls)

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"통화 기록 조회 실패: {e}")
    finally:
        conn.close()

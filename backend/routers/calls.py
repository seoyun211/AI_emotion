# routers/calls.py
<<<<<<< HEAD
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
=======
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import datetime

from database.session import get_db
from database.models import CallLog, User
from models.schemas import CallStartRequest, CallResponse

router = APIRouter(prefix="/api/v1/calls", tags=["통화 기록"])

@router.post("/start", response_model=CallResponse)
def start_call(req: CallStartRequest, db: Session = Depends(get_db)):
    """
    통화 시작 기록
    - Flutter에서 영상통화 시작 버튼 눌렀을 때 호출하면 됨
    """
    user = db.query(User).get(req.user_id)
    if not user:
        raise HTTPException(status_code=404, detail="해당 회원이 없습니다.")

    call = CallLog(
        user_id=req.user_id,
        start_time=datetime.utcnow(),
    )
    db.add(call)
    db.commit()
    db.refresh(call)
    return call

@router.post("/{call_id}/end", response_model=CallResponse)
def end_call(call_id: int, db: Session = Depends(get_db)):
    """
    통화 종료 기록
    - Flutter에서 영상통화 종료 버튼 눌렀을 때 호출
    """
    call = db.query(CallLog).get(call_id)
    if not call:
        raise HTTPException(status_code=404, detail="통화 기록을 찾을 수 없습니다.")

    if call.end_time is not None:
        raise HTTPException(status_code=400, detail="이미 종료된 통화입니다.")

    end_time = datetime.utcnow()
    duration = int((end_time - call.start_time).total_seconds())

    call.end_time = end_time
    call.duration_seconds = duration

    db.commit()
    db.refresh(call)
    return call
>>>>>>> cba8aa7fb5c69d0cf5121029e34b01655c3c4040

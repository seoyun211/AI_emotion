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

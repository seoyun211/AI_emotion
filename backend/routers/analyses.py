# routers/analyses.py
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from database.session import get_db
from database.models import AnalysisLog, CallLog
from models.schemas import AnalysisCreate, AnalysisResponse, PredictRequest

router = APIRouter(prefix="/api/v1/analyses", tags=["분석 기록"])

@router.post("/", response_model=AnalysisResponse)
def create_analysis(data: AnalysisCreate, db: Session = Depends(get_db)):
    """
    (모델이 계산한) 분석 결과를 저장하는 API
    """
    call = db.query(CallLog).get(data.call_id)
    if not call:
        raise HTTPException(status_code=404, detail="통화 기록을 찾을 수 없습니다.")

    analysis = AnalysisLog(
        call_id=data.call_id,
        text_result=data.text_result,
        voice_result=data.voice_result,
        facial_result=data.facial_result,
        final_result=data.final_result,
    )
    db.add(analysis)
    db.commit()
    db.refresh(analysis)
    return analysis

@router.get("/call/{call_id}", response_model=list[AnalysisResponse])
def get_analyses_by_call(call_id: int, db: Session = Depends(get_db)):
    """
    특정 통화에 대한 분석 기록 조회
    """
    q = db.query(AnalysisLog).filter(
        AnalysisLog.call_id == call_id
    ).order_by(AnalysisLog.analyzed_at.desc())
    return q.all()

# 🔮 (선택) 나중에 "모델 호출"을 이 API에서 할 수 있음
@router.post("/predict")
def predict(req: PredictRequest):
    """
    ⚠️ 여기서는 '모델 호출 자리'만 잡고, 실제 분석은 안 함.
    나중에:
      - 코랩/모델 서버에 req.text, req.call_id 보내고
      - 결과 받아서 /analyses/ 에 저장 / 응답으로 반환
    """
    return {
        "message": "여기에 나중에 모델 연동 로직 추가 예정",
        "call_id": req.call_id,
        "text": req.text,
    }

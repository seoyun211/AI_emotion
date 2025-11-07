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
    분석 결과 저장
    - 나중에 모델(코랩)에서 최종 결과를 계산한 뒤,
      이 API로 분석기록만 저장하게 만들 수 있음.
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
    특정 통화에 대한 분석 기록 목록 조회
    """
    q = db.query(AnalysisLog).filter(AnalysisLog.call_id == call_id).order_by(AnalysisLog.analyzed_at.desc())
    analyses = q.all()
    return analyses

# 🔮 나중에 모델 직접 호출하고 싶으면 여기에 로직 추가하면 됨
@router.post("/predict")
def predict(req: PredictRequest):
    """
    TODO: 여기에 코랩/모델 서버 호출 → 결과 받고,
    /api/v1/analyses/ 에 저장하거나 바로 반환하는 로직 추가
    """
    return {
        "message": "여기에 나중에 모델 연동 로직 추가 예정",
        "call_id": req.call_id,
        "text": req.text,
    }

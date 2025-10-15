# 😊 감정 분석 API
from fastapi import APIRouter, HTTPException
from models.schemas import InputData, EmotionResponse
from services.emotion_service import emotion_service
from datetime import datetime
import uuid

router = APIRouter(prefix="/api/v1", tags=["감정 분석"])

@router.post("/predict", response_model=EmotionResponse)
async def predict(data: InputData):
    """
    텍스트 기반 감정 분석
    """
    try:
        # 감정 분석 수행
        result = await emotion_service.analyze_text_emotion(data.text, data.user_id)
        
        return EmotionResponse(
            emotion=result["emotion"],
            confidence=result["confidence"],
            risk_score=result["risk_score"],
            needs_alert=result["needs_alert"],
            analysis_id=str(uuid.uuid4()),
            user_id=data.user_id,
            timestamp=datetime.now()
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"감정 분석 중 오류: {str(e)}")
# 😊 감정 분석 API
from fastapi import APIRouter, HTTPException
from models.schemas import InputData, EmotionResponse
# from services.emotion_service import emotion_service
from services.emotion_service import process_emotion_analysis
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
        result = await process_emotion_analysis(data.text, data.user_id)
        
        return EmotionResponse(
            emotion=result["emotion"],
            confidence=result["confidence"],
            risk_score=result["risk_score"], 
            needs_alert=result["needs_alert"],
            analysis_id=result["analysis_id"],
            user_id=result["user_id"], 
            timestamp=result["timestamp"],
            message=result["message"]
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"감정 분석 중 오류: {str(e)}")
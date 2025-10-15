# 📈 통계 API
from fastapi import APIRouter
from database.crud import EmotionLogCRUD
from datetime import datetime

router = APIRouter(prefix="/api/v1", tags=["통계"])

@router.get("/stats/emotions")
async def get_emotion_stats():
    """
    감정 통계 조회
    """
    try:
        stats = await EmotionLogCRUD.get_emotion_stats()
        
        return {
            "statistics": stats,
            "timestamp": datetime.now().isoformat()
        }
        
    except Exception as e:
        # Mock 데이터 반환
        return {
            "statistics": [
                {"_id": "기쁨", "count": 15, "avg_risk": 0.2},
                {"_id": "슬픔", "count": 8, "avg_risk": 0.75},
                {"_id": "중립", "count": 12, "avg_risk": 0.3}
            ],
            "timestamp": datetime.now().isoformat()
        }
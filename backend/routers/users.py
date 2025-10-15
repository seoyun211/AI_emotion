# 👤 사용자 관리 API
from fastapi import APIRouter, HTTPException
from models.schemas import UserCreate, UserResponse
from database.crud import UserCRUD
from datetime import datetime
import uuid

router = APIRouter(prefix="/api/v1", tags=["사용자 관리"])

@router.post("/users/register", response_model=UserResponse)
async def register_user(user_data: UserCreate):
    """
    사용자 등록
    """
    try:
        user_id = str(uuid.uuid4())
        
        user_doc = {
            "_id": user_id,
            "name": user_data.name,
            "phone": user_data.phone,
            "age": user_data.age,
            "emergency_contact": user_data.emergency_contact,
            "created_at": datetime.now()
        }
        
        await UserCRUD.create_user(user_doc)
        
        return UserResponse(
            user_id=user_id,
            name=user_data.name,
            message="사용자 등록 성공",
            timestamp=datetime.now()
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"사용자 등록 실패: {str(e)}")

@router.get("/users/{user_id}/emotions")
async def get_emotion_history(user_id: str, limit: int = 10):
    """
    사용자 감정 기록 조회
    """
    try:
        from database.crud import EmotionLogCRUD
        history = await EmotionLogCRUD.get_user_emotion_history(user_id, limit)
        
        return {
            "user_id": user_id,
            "history": history,
            "total_count": len(history),
            "timestamp": datetime.now().isoformat()
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"기록 조회 실패: {str(e)}")
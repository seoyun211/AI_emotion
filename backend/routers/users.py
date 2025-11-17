# 👤 사용자 관리 API
from fastapi import APIRouter, HTTPException
from models.schemas import UserCreate, UserResponse
from database.crud import UserCRUD
from datetime import datetime
import uuid

router = APIRouter(prefix="/api/v1", tags=["사용자 관리"])

# 사용자 등록
@router.post("/users/register", response_model=UserResponse)
def register_user(user_data: UserCreate):
    try:
        user_info = {
            "username": user_data.username,
            "gender": user_data.gender,
            "birth_date": user_data.birth_date, 
            "address": user_data.address,
            "guardian_name": user_data.guardian_name,
            "guardian_phone": user_data.guardian_phone,
            
        }

        new_user_id = UserCRUD.create_user(user_info)
        
        return UserResponse(
            user_id=new_user_id,
            username=user_data.username,
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
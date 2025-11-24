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
    user_role = 'guardian' if user_data.is_guardian else 'ward'
    user_info = {
        "username": user_data.username,
        "password": user_data.password,
        "role": user_role,
        "gender": user_data.gender,
        "birth_date": user_data.birth_date, 
        "address": user_data.address
        }
    try:
        # 3. CRUD 함수 호출: 
        # UserCRUD.create_user 내부에서 비밀번호 해싱과 DB INSERT가 이루어져야 함
        new_user_id = UserCRUD.create_user(user_info)
        
        return UserResponse(
            user_id=new_user_id,
            username=user_data.username,
            message="사용자 등록 성공 (role: " + user_role + ")",
            timestamp=datetime.now()
        )
        
    except Exception as e:
        # DB 연결 실패, 쿼리 오류 등 발생 시
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
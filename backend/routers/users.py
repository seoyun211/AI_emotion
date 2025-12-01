# 👤 사용자 관리 API
from fastapi import APIRouter, HTTPException, status
from models.schemas import UserCreate, UserResponse
from database.crud import UserCRUD
from datetime import datetime
import uuid

router = APIRouter(prefix="/api/v1", tags=["사용자 관리"])

@router.get("/users/{user_id}", response_model=UserResponse)
def get_user_profile(user_id: int):
    """
    특정 user_id를 가진 사용자의 프로필 정보를 조회합니다. (회원 수정 시 사용)
    """
    try:
        # 1. user_id로 DB에서 사용자 정보를 조회하는 CRUD 함수 호출
        user = UserCRUD.get_user_by_id(user_id) # 👈 이 함수가 필요함
        
        if user is None:
            # 2. 사용자가 없을 경우 404 반환
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
        
        # 3. UserResponse 스키마에 맞게 딕셔너리 데이터를 반환합니다.
        #    (user_id가 딕셔너리에 있다고 가정)
        return user
        
    except HTTPException:
        # HTTPException은 다시 발생시킵니다.
        raise
    except Exception as e:
        # DB 연결 오류 등 기타 오류 처리
        raise HTTPException(status_code=500, detail=f"사용자 정보 조회 실패: {str(e)}")

@router.get("/users/{user_id}/emotions")
async def get_emotion_history(user_id: str, limit: int = 10):
    """
    사용자 감정 기록 조회
    """
    try:
        from database.crud import AnalysisChunkCRUD
        history = await AnalysisChunkCRUD.get_user_emotion_history(user_id, limit)
        
        return {
            "user_id": user_id,
            "history": history,
            "total_count": len(history),
            "timestamp": datetime.now().isoformat()
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"기록 조회 실패: {str(e)}")
# 👨‍👩‍👧‍👦 보호자 API
from fastapi import APIRouter, Depends, HTTPException
from auth.dependencies import get_current_guardian
from database.crud import GuardianCRUD, EmotionLogCRUD
from models.schemas import GuardianResponse
from bson import ObjectId

router = APIRouter(prefix="/api/v1/guardians", tags=["보호자"])

@router.get("/me", response_model=GuardianResponse)
async def get_my_info(current_guardian: dict = Depends(get_current_guardian)):
    """내 정보 조회"""
    return GuardianResponse(
        id=str(current_guardian["_id"]),
        name=current_guardian["name"],
        phone=current_guardian["phone"],
        email=current_guardian.get("email")
    )

@router.get("/my-elders")
async def get_my_elders(current_guardian: dict = Depends(get_current_guardian)):
    """내가 관리하는 노인 목록"""
    guardian_id = str(current_guardian["_id"])
    elders = await GuardianCRUD.get_guardian_elders(guardian_id)
    
    # 각 노인의 최근 감정 상태 포함
    elder_status = []
    for elder in elders:
        recent_logs = await EmotionLogCRUD.get_user_emotion_history(elder["_id"], 1)
        current_emotion = recent_logs[0] if recent_logs else None
        
        elder_status.append({
            "id": elder["_id"],
            "name": elder["name"],
            "age": elder["age"],
            "phone": elder["phone"],
            "current_emotion": current_emotion,
            "last_updated": current_emotion["created_at"] if current_emotion else None
        })
    
    return {"elders": elder_status}
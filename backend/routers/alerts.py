# 🚨 알림 API
from fastapi import APIRouter, Depends, HTTPException
from auth.dependencies import get_current_guardian
from database.crud import AlertCRUD
from models.schemas import AlertResponse
from typing import List

router = APIRouter(prefix="/api/v1/alerts", tags=["알림"])

@router.get("/", response_model=List[AlertResponse])
async def get_my_alerts(current_guardian: dict = Depends(get_current_guardian)):
    """내 알림 목록 조회"""
    guardian_id = str(current_guardian["_id"])
    alerts = await AlertCRUD.get_guardian_alerts(guardian_id)
    return alerts

@router.post("/{alert_id}/read")
async def mark_alert_read(alert_id: str, current_guardian: dict = Depends(get_current_guardian)):
    """알림 읽음 표시"""
    guardian_id = str(current_guardian["_id"])
    success = await AlertCRUD.mark_alert_read(alert_id, guardian_id)
    
    if not success:
        raise HTTPException(status_code=404, detail="알림을 찾을 수 없습니다")
    
    return {"message": "알림이 읽음 처리되었습니다"}
# C:\Users\user\Desktop\AI_emotion\backend\routers\alerts.py

from fastapi import APIRouter, Depends, HTTPException, status
from typing import List
from datetime import datetime

# 데이터베이스와 서비스에서 필요한 모듈을 임포트합니다.
# (이 경로와 스키마는 사용자의 프로젝트 구조에 맞게 조정해야 합니다.)
from database.crud import AlertCRUD 
from models.schemas import AlertResponse, AlertCreate, EmotionCreate # 스키마는 가상의 이름입니다.
from services.alert_service import alert_service 

# 사용자 인증 종속성 (가정)
# from routers.users import get_current_user 

# 라우터 객체 생성
router = APIRouter(
    prefix="/alerts",
    tags=["Alerts"]
    # 인증이 필요하다면 여기에 dependencies를 추가할 수 있습니다:
    # dependencies=[Depends(get_current_user)] 
)

# ==============================================================================

@router.get(
    "/",
    # response_model=List[AlertResponse] # 실제 Alert 스키마에 맞춰 조정
)
async def get_all_alerts_for_guardian(
    # current_user: dict = Depends(get_current_user)
):
    """
    📜 인증된 보호자에게 연결된 모든 알림 목록을 조회합니다.
    """
    # **NOTE:** 실제 구현 시, current_user에서 'guardian_id'를 가져와야 합니다.
    guardian_id = "temp_guardian_id_123" 
    
    try:
        # AlertCRUD를 사용하여 데이터베이스에서 알림을 가져옵니다.
        alerts = await AlertCRUD.get_alerts_by_guardian_id(guardian_id)
        
        # 알림이 없더라도 빈 리스트를 반환하여 클라이언트 처리를 쉽게 합니다.
        return alerts if alerts is not None else []
        
    except Exception as e:
        # DB 에러 처리
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to retrieve alerts: {e}"
        )

# ==============================================================================

@router.patch("/{alert_id}/read")
async def mark_alert_as_read(
    alert_id: str,
    # current_user: dict = Depends(get_current_user)
):
    """
    ✅ 특정 알림을 '읽음' 상태로 업데이트합니다 (read_at 필드 업데이트).
    """
    # **NOTE:** 실제 구현 시, 해당 알림이 current_user의 소유인지 확인하는 로직이 필요합니다.
    
    try:
        updated_alert = await AlertCRUD.mark_as_read(alert_id, read_at=datetime.utcnow())
    except Exception as e:
         raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update alert status: {e}"
        )
        
    if not updated_alert:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Alert with ID {alert_id} not found."
        )

    return {"message": f"Alert {alert_id} marked as read successfully.", "alert": updated_alert}

# ==============================================================================

# **선택적 엔드포인트**
# 이 엔드포인트는 외부에서 감정 데이터를 받아 알림 생성 로직을 트리거하는 데 사용됩니다.
# 대부분은 내부 서비스(예: 감정 분석 서비스)에서 직접 호출되지만,
# 테스트 또는 특정 시스템 통합을 위해 API로 노출할 수 있습니다.
@router.post(
    "/trigger-emotion-alert",
    status_code=status.HTTP_202_ACCEPTED
)
async def trigger_emotion_alert_manually(
    emotion_data_request: EmotionCreate # 요청 본문 스키마
):
    """
    🚀 (테스트 또는 시스템 연동용) 감정 데이터를 받아 알림 생성 로직을 트리거합니다.
    """
    try:
        result = await alert_service.send_emotion_alert(
            guardian_id=emotion_data_request.guardian_id,
            elder_name=emotion_data_request.elder_name,
            emotion_data={
                "emotion": emotion_data_request.emotion,
                "risk_score": emotion_data_request.risk_score
            }
        )
        return {"message": "Alert processing initiated.", "details": result}
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Alert generation failed: {e}"
        )
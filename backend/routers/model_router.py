 # 🤖 모델 관리 API
from fastapi import APIRouter
from models.clients import client_manager

router = APIRouter(prefix="/api/v1/models", tags=["모델 관리"])

@router.get("/health")
async def get_model_health():
    """
    모든 모델 서버 상태 확인
    """
    health_status = await client_manager.health_check_all()
    return {
        "models": health_status,
        "timestamp": datetime.now().isoformat()
    }

@router.get("/enabled")
async def get_enabled_models():
    """
    활성화된 모델 목록
    """
    enabled_clients = client_manager.get_enabled_clients()
    return {
        "enabled_models": [client.model_name for client in enabled_clients],
        "count": len(enabled_clients)
    }
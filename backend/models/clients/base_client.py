import httpx
import asyncio
from typing import Dict, Any, Optional

class BaseModelClient:
    def __init__(self, model_name: str, config: Dict):
        self.model_name = model_name
        self.url = config["url"]
        self.timeout = config["timeout"]
        self.enabled = config["enabled"]
    
    async def predict(self, data: Any) -> Dict[str, Any]:
        """모델 예측 기본 메서드"""
        if not self.enabled:
            return {"error": f"{self.model_name} 모델 비활성화"}
        
        try:
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                response = await client.post(self.url, json=data)
                response.raise_for_status()
                return response.json()
        except Exception as e:
            return {"error": f"{self.model_name} 모델 호출 실패: {str(e)}"}
    
    async def health_check(self) -> bool:
        """모델 서버 상태 확인"""
        try:
            async with httpx.AsyncClient(timeout=10) as client:
                response = await client.get(f"{self.url}/health")
                return response.status_code == 200
        except:
            return False
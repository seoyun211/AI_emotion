from .text_client import text_client
from .voice_client import voice_client
from .face_client import face_client

# 모든 클라이언트 리스트
all_clients = [text_client, voice_client, face_client]

# 클라이언트 매니저
class ModelClientManager:
    @staticmethod
    async def health_check_all():
        """모든 모델 서버 상태 확인"""
        results = {}
        for client in all_clients:
            results[client.model_name] = await client.health_check()
        return results
    
    @staticmethod
    def get_enabled_clients():
        """활성화된 클라이언트만 반환"""
        return [client for client in all_clients if client.enabled]

# 전역 매니저 인스턴스
client_manager = ModelClientManager()
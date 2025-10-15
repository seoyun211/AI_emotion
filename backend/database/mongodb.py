from motor.motor_asyncio import AsyncIOMotorClient
from config import MONGODB_URL

try:
    # 비동기 클라이언트 생성
    client = AsyncIOMotorClient(MONGODB_URL)
    database = client.get_database()
    
    # 컬렉션 참조
    users_collection = database.users
    emotion_logs_collection = database.emotion_logs
    guardians_collection = database.guardians
    alerts_collection = database.alerts
    
    # 연결 테스트 함수
    async def test_connection():
        try:
            await database.command("ping")
            return True
        except Exception:
            return False
            
except Exception as e:
    print(f"❌ MongoDB 연결 실패: {e}")
    # 에러 시 None으로 설정
    users_collection = None
    emotion_logs_collection = None
    guardians_collection = None
    alerts_collection = None
    
    async def test_connection():
        return False
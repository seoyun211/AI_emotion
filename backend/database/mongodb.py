from motor.motor_asyncio import AsyncIOMotorClient
import os

# MongoDB Atlas 연결 URL (본인 정보로 수정해야 함)
MONGODB_URL = "mongodb+srv://tina030917_db_user:uSUEMMcX7mN966WK@cluster0.evfuuit.mongodb.net/"

# 비동기 클라이언트 생성
client = AsyncIOMotorClient(MONGODB_URL)
database = client.AI_EMOTION

# 컬렉션 참조
users_collection = database.users
emotion_logs_collection = database.emotion_logs
guardians_collection = database.guardians
alerts_collection = database.alerts

# 연결 테스트 함수
async def test_connection():
    try:
        await database.command("ping")
        print("✅ MongoDB 연결 성공!")
        return True
    except Exception as e:
        print(f"❌ MongoDB 연결 실패: {e}")
        return False
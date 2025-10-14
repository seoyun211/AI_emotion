from motor.motor_asyncio import AsyncIOMotorClient
from pymongo import MongoClient
import os

# MongoDB 연결 URL
# 로컬: "mongodb://localhost:27017"
# Atlas: "mongodb+srv://username:password@cluster.mongodb.net/"
MONGODB_URL = "mongodb://localhost:27017"

# 클라이언트 생성
client = AsyncIOMotorClient(MONGODB_URL)
database = client.elder_care_db

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
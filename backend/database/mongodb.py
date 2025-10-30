# database/mongodb.py
from motor.motor_asyncio import AsyncIOMotorClient
from config import MONGODB_URL

client = None
database = None

users_collection = None
emotion_logs_collection = None
guardians_collection = None
alerts_collection = None

async def connect_to_mongo():
    """
    서버 시작 시 MongoDB 연결
    """
    global client, database, users_collection, emotion_logs_collection, guardians_collection, alerts_collection

    try:
        client = AsyncIOMotorClient(MONGODB_URL, serverSelectionTimeoutMS=5000)
        # URI에 /ai_emotion 같은 DB 이름이 있다면 그걸 가져오고,
        # 없다면 기본값 'ai_emotion'으로 접속
        database = client.get_default_database() or client["ai_emotion"]
        await database.command("ping")

        users_collection = database["users"]
        emotion_logs_collection = database["emotion_logs"]
        guardians_collection = database["guardians"]
        alerts_collection = database["alerts"]

        print(f"✅ MongoDB Atlas 연결 성공 (DB: {database.name})")

    except Exception as e:
        print(f"❌ MongoDB Atlas 연결 실패: {e}")

async def close_mongo_connection():
    """
    서버 종료 시 MongoDB 연결 닫기
    """
    global client
    if client:
        client.close()
        print("🛑 MongoDB 연결 종료")

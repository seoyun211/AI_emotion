import os
from pymongo import MongoClient
from dotenv import load_dotenv

# .env 파일 로드
load_dotenv()

# MongoDB 연결 정보
MONGODB_URI = os.getenv('MONGODB_URI')
DB_NAME = os.getenv('DB_NAME')

# 전역 변수로 MongoDB 클라이언트 관리
client = None
db = None

async def connect_to_mongo():
    """MongoDB에 연결"""
    global client, db
    try:
        client = MongoClient(MONGODB_URI)
        # 연결 테스트
        client.admin.command('ping')
        db = client[DB_NAME]
        print("✅ MongoDB 연결 성공!")
        return True
    except Exception as e:
        print(f"❌ MongoDB 연결 실패: {e}")
        return False

async def close_mongo_connection():
    """MongoDB 연결 종료"""
    global client
    if client:
        client.close()
        print("✅ MongoDB 연결 종료")

async def test_connection():
    """MongoDB 연결 상태 테스트"""
    global client
    try:
        if client:
            client.admin.command('ping')
            return True
        return False
    except Exception:
        return False

def get_database():
    """데이터베이스 인스턴스 반환"""
    global db
    return db

def get_collection(collection_name):
    """컬렉션 인스턴스 반환"""
    global db
    if db is None:
        raise Exception("Database not connected")
    return db[collection_name]
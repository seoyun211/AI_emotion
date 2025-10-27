import asyncio
import sys
import os

# database 모듈 import를 위해 경로 추가
sys.path.append(os.path.dirname(os.path.dirname(__file__)))

from database.mongodb import test_connection, users_collection

async def main():
    print("🔗 MongoDB 연결 테스트 시작...")
    
    # 연결 테스트
    if await test_connection():
        print("🔄 기존 사용자 데이터 조회 중...")
        
        # 기존 데이터 조회
        users = await users_collection.find().to_list(10)
        print(f"📊 현재 사용자 수: {len(users)}")
        
        for user in users:
            print(f"👤 {user['name']} ({user['phone']})")
        
        print("✅ MongoDB 연동 준비 완료!")
    else:
        print("❌ MongoDB 연결에 문제가 있습니다.")

if __name__ == "__main__":
    asyncio.run(main())
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from datetime import datetime
import asyncio
# DB 및 라우터 임포트 (모든 기능 활성화)
from database.session import get_db_connection
from routers.dialogue import router as dialogue_router
from routers.alerts import router as alerts_router
from routers.emotions import router as emotions_router
from routers.users import router as users_router
from routers.auth import router as auth_router

# -------------------------
## 🚀 FastAPI 앱 및 미들웨어 설정
# -------------------------
app = FastAPI(title="말동이 감정 분석 API", version="1.0.0")

# ✅ CORS 설정
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://127.0.0.1:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ✅ 라우터 포함
app.include_router(dialogue_router)
app.include_router(alerts_router)
app.include_router(emotions_router)
app.include_router(users_router)    
app.include_router(auth_router)


# ✅ 루트 경로
@app.get("/")
def read_root():
    return {"message": "말동이 백엔드 서버 정상 작동!", "port": 8000}

# ✅ 상태 확인용
@app.get("/health")
async def health_check(): 
    conn = await asyncio.to_thread(get_db_connection)
    db_status = "connected" if conn else "disconnected"
    return {"status": "healthy", "db_status": db_status, "timestamp": datetime.now().isoformat()}

# ✅ 서버 실행
if __name__ == "__main__":
    import uvicorn
    # 서버 시작 시점에 DB 연결을 시도합니다.
    get_db_connection() 
    print("🚀 말동이 백엔드 서버 시작합니다...")
    # 포트를 8000으로 가정합니다.
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
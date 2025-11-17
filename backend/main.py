# main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from datetime import datetime

from database.session import get_db_connection
from routers.dialogue import router as dialogue_router
from routers.alerts import router as alerts_router
from routers.emotions import router as emotions_router

# -------------------------
## 🚀 FastAPI 앱 및 미들웨어 설정
# -------------------------
app = FastAPI(title="말동이 감정 분석 API", version="1.0.0")


# ✅ CORS 설정
# CORS 미들웨어 추가 
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://127.0.0.1:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
# 라우터 포함
app.include_router(dialogue_router)
app.include_router(alerts_router)
app.include_router(emotions_router)
# app.include_router(auth_router)

# ✅ 루트 경로
# -------------------------
## 🌐 API 엔드포인트 정의
# -------------------------

@app.get("/")
def read_root():
    return {"message": "말동이 백엔드 서버 정상 작동!", "port": 8080}

# ✅ 상태 확인용
@app.get("/health")
def health_check():
    conn = get_db_connection()
    db_status = "connected" if conn else "disconnected"
    return {"status": "healthy", "db_status": db_status, "timestamp": datetime.now().isoformat()}

# ✅ 서버 실행
# -------------------------
## 🔥 서버 실행 블록 (항상 파일의 가장 아래에 위치)
# -------------------------
if __name__ == "__main__":
    import uvicorn
    # 서버 시작 시점에 DB 연결을 시도하여 로그를 남깁니다.
    get_db_connection() 
    print("🚀 말동이 백엔드 서버 시작합니다...")
    uvicorn.run("main:app", host="0.0.0.0", port=8080, reload=True)


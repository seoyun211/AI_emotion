from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from datetime import datetime

from database.session import get_db_connection

# HEAD (로컬)의 라우터들을 개별적으로 import
from routers.dialogue import router as dialogue_router
from routers.alerts import router as alerts_router
from routers.emotions import router as emotions_router

# 원격 (f3f8096de58...)의 라우터들을 모듈로 import
from routers import users, calls, analyses 

app = FastAPI(title="말동이 감정 분석 API", version="1.0.0")

# ✅ CORS 설정 (개발 단계라 일단 전부 허용)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 나중에 웹/앱 도메인 정해지면 여기서 제한
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 라우터 포함 (HEAD와 원격의 라우터를 모두 포함)
# HEAD에서 가져온 라우터
app.include_router(dialogue_router)
app.include_router(alerts_router)
app.include_router(emotions_router)

# 원격에서 가져온 라우터
app.include_router(users.router)      # /api/v1/users/...
app.include_router(calls.router)      # /api/v1/calls/...
app.include_router(analyses.router)   # /api/v1/analyses/...

# auth 라우터는 주석 처리되어 있었으므로 그대로 둡니다.
# app.include_router(auth_router)


# ✅ 루트 경로
@app.get("/")
def read_root():
    return {"message": "말동이 백엔드 서버 정상 작동!", "port": 8080}


# ✅ 상태 확인용 (간단 버전)
@app.get("/health")
def health_check():
    # HEAD의 DB 연결 체크 로직을 포함하여 더 상세하게 만듭니다.
    conn = get_db_connection() 
    db_status = "connected" if conn else "disconnected"
    
    return {
        "status": "healthy", 
        "db_status": db_status, 
        "timestamp": datetime.now().isoformat()
    }

# ✅ 서버 실행
# -------------------------
## 🔥 서버 실행 블록 (항상 파일의 가장 아래에 위치)
# -------------------------
if __name__ == "__main__":
    import uvicorn

    print("🚀 말동이 백엔드 서버 시작합니다...")
    uvicorn.run("main:app", host="0.0.0.0", port=8080, reload=True)
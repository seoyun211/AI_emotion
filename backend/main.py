from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from datetime import datetime
<<<<<<< HEAD
=======
#from routers.auth import router as auth_router
from database.session import get_db_connection
>>>>>>> 679b4b754f95c1f623f2147650cfa9d5abaf8eb4

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
#app.include_router(auth_router)

# ✅ 라우터 연결
app.include_router(users.router)      # /api/v1/users/...
app.include_router(calls.router)      # /api/v1/calls/...
app.include_router(analyses.router)   # /api/v1/analyses/...


# ✅ 루트 경로
@app.get("/")
def read_root():
    return {"message": "말동이 백엔드 서버 정상 작동!", "port": 8080}


# ✅ 상태 확인용 (간단 버전)
@app.get("/health")
def health_check():
    return {
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
    }


if __name__ == "__main__":
    import uvicorn

    print("🚀 말동이 백엔드 서버 시작합니다...")
    uvicorn.run("main:app", host="0.0.0.0", port=8080, reload=True)

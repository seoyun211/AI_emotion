# main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from datetime import datetime

# 👉 여기서 DB를 직접 쓰지 않고, 라우터들만 불러온다
from routers import users, calls, analyses

app = FastAPI(title="말동이 감정 분석 API", version="1.0.0")

# CORS (개발 단계: 다 허용)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 라우터 연결
app.include_router(users.router)      # /api/v1/users/...
app.include_router(calls.router)      # /api/v1/calls/...
app.include_router(analyses.router)   # /api/v1/analyses/...

# 루트
@app.get("/")
def read_root():
    return {"message": "말동이 백엔드 서버 정상 작동!", "port": 8080}

# 헬스체크 (여기서는 그냥 서버 상태만)
@app.get("/health")
def health_check():
    return {
        "status": "healthy",
        "timestamp": datetime.now().isoformat()
    }

if __name__ == "__main__":
    import uvicorn
    print("🚀 말동이 백엔드 서버 시작합니다...")
    uvicorn.run("main:app", host="0.0.0.0", port=8080, reload=True)

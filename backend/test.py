from fastapi import FastAPI
import uvicorn
# 💡 라우터를 임포트합니다. (backend를 패키지 루트로 하는 절대 경로 사용)
from backend.routers import users as users 

app = FastAPI()

# 🧩 사용자 라우터 연결 (이 부분이 중요합니다)
app.include_router(users.router) 

@app.get("/")
def read_root():
    return {"message": "테스트 서버 작동! 라우터 연결됨."}

@app.get("/health")
def health_check():
    return {"status": "ok"}

# ⚠️ Uvicorn 실행 코드는 제거합니다. (py -m uvicorn 명령어로 실행하기 위함)
# if __name__ == "__main__":
#     uvicorn.run(app, host="0.0.0.0", port=8080)
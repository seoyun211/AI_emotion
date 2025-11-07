# main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from datetime import datetime

app = FastAPI(title="말동이 감정 분석 API", version="1.0.0")

# ✅ CORS 설정 (Flutter, 웹 다 허용하고 싶으면 "*"로 해도 됨)
app.add_middleware(
    CORSMiddleware,
    # 개발 단계에서는 일단 다 허용해도 괜찮음
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ✅ 루트 경로
@app.get("/")
def read_root():
    return {"message": "말동이 백엔드 서버 정상 작동!", "port": 8080}

# ✅ 상태 확인용
@app.get("/health")
def health_check():
    return {"status": "healthy", "timestamp": datetime.now().isoformat()}


# 🔮 (선택) 나중에 감정 분석용 엔드포인트 자리는 이렇게만 잡아두고,
# 실제 모델 호출 로직은 나중에 팀원이 MySQL/모델 붙이면서 채워도 됨.
# from models.schemas import PredictRequest
# @app.post("/predict")
# def predict(req: PredictRequest):
#     # TODO: 여기서 코랩/모델 서버 호출해서 결과 받아오기
#     return {"message": "나중에 모델 연동 예정", "text": req.text}


# ✅ 서버 실행
if __name__ == "__main__":
    import uvicorn
    print("🚀 말동이 백엔드 서버 시작합니다...")
    uvicorn.run("main:app", host="0.0.0.0", port=8080, reload=True)

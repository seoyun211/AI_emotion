# main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional
import uuid
from datetime import datetime

# ✅ MongoDB 연결 함수 임포트
from database.mongodb import connect_to_mongo, close_mongo_connection

app = FastAPI(title="말동이 감정 분석 API", version="1.0.0")

# ✅ 서버 시작 시 MongoDB 연결
@app.on_event("startup")
async def startup_event():
    await connect_to_mongo()

# ✅ 서버 종료 시 MongoDB 닫기
@app.on_event("shutdown")
async def shutdown_event():
    await close_mongo_connection()

# ✅ CORS 설정
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://127.0.0.1:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ✅ 모델 정의
class InputData(BaseModel):
    text: str
    user_id: Optional[str] = None

# ✅ 루트 경로
@app.get("/")
def read_root():
    return {"message": "말동이 백엔드 서버 정상 작동!", "port": 8080}

# ✅ 상태 확인용
@app.get("/health")
def health_check():
    return {"status": "healthy", "timestamp": datetime.now().isoformat()}

# ✅ 간단 감정 분석
@app.post("/predict")
def predict(data: InputData):
    try:
        text = data.text.lower()

        if any(word in text for word in ["기뻐", "좋아", "행복", "즐거워"]):
            emotion, confidence, risk_score = "기쁨", 0.85, 0.2
        elif any(word in text for word in ["슬퍼", "우울", "힘들어", "외로워"]):
            emotion, confidence, risk_score = "슬픔", 0.78, 0.8
        elif any(word in text for word in ["화나", "분노", "짜증"]):
            emotion, confidence, risk_score = "분노", 0.82, 0.7
        else:
            emotion, confidence, risk_score = "중립", 0.65, 0.3

        needs_alert = risk_score > 0.7

        return {
            "emotion": emotion,
            "confidence": confidence,
            "risk_score": risk_score,
            "needs_alert": needs_alert,
            "analysis_id": str(uuid.uuid4()),
            "user_id": data.user_id,
            "message": "감정 분석 완료",
        }

    except Exception as e:
        return {"error": str(e)}

# ✅ MongoDB 연결 상태 확인용 엔드포인트
@app.get("/health/mongo")
async def mongo_health():
    from database.mongodb import test_connection
    connected = await test_connection()
    return {"mongodb_connected": connected}

# ✅ 서버 실행
if __name__ == "__main__":
    import uvicorn
    print("🚀 말동이 백엔드 서버 시작합니다...")
    uvicorn.run("main:app", host="0.0.0.0", port=8080, reload=True)

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional
import uuid
from datetime import datetime

app = FastAPI(title="말동이 감정 분석 API", version="1.0.0")

# CORS 미들웨어 추가 - 프론트엔드 접근 허용
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://127.0.0.1:3000"],  # 프론트엔드 주소
    allow_credentials=True,
    allow_methods=["*"],  # 모든 HTTP 메서드 허용
    allow_headers=["*"],  # 모든 헤더 허용
)

# 기존 API 코드...
class InputData(BaseModel):
    text: str
    user_id: Optional[str] = None

@app.get("/")
def read_root():
    return {"message": "말동이 백엔드 서버 정상 작동!", "port": 8080}

@app.get("/health")
def health_check():
    return {"status": "healthy", "timestamp": datetime.now().isoformat()}

@app.post("/predict")
def predict(data: InputData):
    try:
        # 간단한 Mock 감정 분석
        text = data.text.lower()
        
        if any(word in text for word in ["기뻐", "좋아", "행복", "즐거워"]):
            emotion = "기쁨"
            confidence = 0.85
            risk_score = 0.2
        elif any(word in text for word in ["슬퍼", "우울", "힘들어", "외로워"]):
            emotion = "슬픔"
            confidence = 0.78
            risk_score = 0.8
        elif any(word in text for word in ["화나", "분노", "짜증"]):
            emotion = "분노"
            confidence = 0.82
            risk_score = 0.7
        else:
            emotion = "중립"
            confidence = 0.65
            risk_score = 0.3
        
        needs_alert = risk_score > 0.7
        
        return {
            "emotion": emotion,
            "confidence": confidence,
            "risk_score": risk_score,
            "needs_alert": needs_alert,
            "analysis_id": str(uuid.uuid4()),
            "user_id": data.user_id,
            "message": "감정 분석 완료"
        }
        
    except Exception as e:
        return {"error": str(e)}
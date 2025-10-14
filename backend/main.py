from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import Dict, List, Optional
import uuid
from datetime import datetime

app = FastAPI(
    title="말동이 감정 분석 API",
    description="노인 대상 감정 분석 및 보호자 알림 시스템",
    version="1.0.0"
)

# 감정 레이블 정의
EMOTION_LABELS = {
    0: "기쁨",
    1: "슬픔", 
    2: "분노",
    3: "불안",
    4: "중립"
}

# 요청 데이터 정의
class InputData(BaseModel):
    text: str
    user_id: Optional[str] = None

@app.get("/")
def read_root():
    return {"message": "말동이 서버가 8080 포트에서 정상 작동중!", "port": 8080}

@app.get("/health")
def health_check():
    return {
        "status": "healthy",
        "port": 8080,
        "timestamp": datetime.now().isoformat()
    }

@app.post("/predict")
def predict(data: InputData):
    # 간단한 Mock 감정 분석
    text = data.text.lower()
    
    if "기뻐" in text or "좋아" in text or "행복" in text:
        emotion = "기쁨"
        confidence = 0.85
    elif "슬퍼" in text or "우울" in text or "힘들" in text:
        emotion = "슬픔" 
        confidence = 0.78
    elif "화나" in text or "분노" in text or "짜증" in text:
        emotion = "분노"
        confidence = 0.82
    else:
        emotion = "중립"
        confidence = 0.65
    
    return {
        "emotion": emotion,
        "confidence": confidence,
        "text": data.text,
        "analysis_id": str(uuid.uuid4())
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8080)
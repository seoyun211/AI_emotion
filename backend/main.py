# main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional
import uuid
from datetime import datetime
from routers.auth import router as auth_router
from database.session import get_db_connection

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
app.include_router(auth_router)

# ✅ 모델 정의
# Pydantic 모델 (입력 데이터 정의)
class InputData(BaseModel):
    text: str
    user_id: Optional[str] = None

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

# ✅ 간단 감정 분석
@app.post("/predict")
def predict(data: InputData):
    db_message = ""
    # --- 1. 감정 분석 로직 ---
    text = data.text.lower()
    
    # Mock 감정 분석 결과 계산 (기존 로직 유지)
    if any(word in text for word in ["기뻐", "좋아", "행복", "즐거워"]):
        emotion, confidence, risk_score = "기쁨", 0.85, 0.2
    elif any(word in text for word in ["슬퍼", "우울", "힘들어", "외로워"]):
        emotion, confidence, risk_score = "슬픔", 0.78, 0.8
    elif any(word in text for word in ["화나", "분노", "짜증"]):
        emotion, confidence, risk_score = "분노", 0.82, 0.7
    else:
        emotion, confidence, risk_score = "중립", 0.65, 0.3
    
    needs_alert = risk_score > 0.7
    message = "감정 분석 완료"
    # --- 감정 분석 로직 끝 ---

    # ----- 2. MySQL DB INSERT 로직 시작 -----
    conn = get_db_connection()
    if conn:
        try:
            with conn.cursor() as cursor:
                # AnalysisChunk 테이블에 INSERT 쿼리 실행
                sql = """
                INSERT INTO AnalysisChunk
                (session_id, analysis_time, text_result, final_result)
                VALUES (%s, NOW(), %s, %s)
                """
                cursor.execute(sql, (
                    1,             # 🚨 임시 session_id 
                    data.text,     # 입력 텍스트
                    emotion        # 분석된 감정
                ))
            conn.commit()
            db_message = " 및 DB 저장 완료"

        except Exception as db_e:
            db_message = f" (DB 저장 오류: {db_e})"
            conn.rollback()
    else:
        db_message = " (DB 연결 실패로 저장 불가)"
    # ----- DB INSERT 로직 끝 -----

    return {
        "emotion": emotion,
        "confidence": confidence,
        "risk_score": risk_score,
        "needs_alert": needs_alert,
        "analysis_id": str(uuid.uuid4()),
        "user_id": data.user_id,
        "message": message + db_message # 메시지에 DB 저장 결과 추가
    }

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


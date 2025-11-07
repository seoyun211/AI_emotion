# main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional
import uuid
from datetime import datetime

# ✅ MongoDB 연결 함수 임포트
from database.mongodb import connect_to_mongo, close_mongo_connection

import pymysql.cursors
# config.py 파일에서 DB 설정 정보를 불러옵니다.
from config import DATABASE_CONFIG 

# -------------------------
## 💾 DB 연결 관리 함수
# -------------------------
db_connection = None

def get_db_connection():
    """DB 연결을 생성하고 반환합니다."""
    global db_connection
    # 연결이 없거나 닫혀있으면 새로 연결 시도
    if db_connection is None or not db_connection.open:
        try:
            db_connection = pymysql.connect(
                host=DATABASE_CONFIG['host'],
                user=DATABASE_CONFIG['user'],
                password=DATABASE_CONFIG['password'],
                database=DATABASE_CONFIG['database'],
                cursorclass=pymysql.cursors.DictCursor
            )
            # 서버 시작 시 또는 첫 요청 시 연결 성공 로그 출력
            print("✅ MySQL DB 연결 성공!")
        except Exception as e:
            print(f"❌ MySQL DB 연결 실패: {e}")
            db_connection = None
    return db_connection

# -------------------------
## 🚀 FastAPI 앱 및 미들웨어 설정
# -------------------------
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
# CORS 미들웨어 추가 
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://127.0.0.1:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

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
    
    # --- 1. Mock 감정 분석 로직 ---
    text = data.text.lower()
    
    # Mock 감정 분석 결과 계산
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
    message = "감정 분석 완료"
    # --- Mock 감정 분석 로직 끝 ---

    # ----- 2. DB INSERT 로직 시작 -----
    conn = get_db_connection()
    if conn:
        try:
            with conn.cursor() as cursor:
                # AnalysisChunk 테이블에 INSERT 쿼리 실행
                # text_result에 입력 텍스트(원본 데이터)를, final_result에 감정 레이블을 저장
                sql = """
                INSERT INTO AnalysisChunk
                (session_id, analysis_time, text_result, final_result)
                VALUES (%s, NOW(), %s, %s)
                """
                cursor.execute(sql, (
                    1,             # 🚨 임시 session_id (실제 앱에서는 세션 생성 후 ID를 받아와야 함)
                    data.text,     # 입력 텍스트
                    emotion        # 분석된 감정
                ))
            conn.commit()
            message = "감정 분석 및 DB 저장 완료"

        except Exception as db_e:
            message = f"DB 저장 오류: {db_e}"
            conn.rollback()
    else:
        message = "DB 연결 실패로 저장 불가"
    # ----- DB INSERT 로직 끝 -----

    return {
        "emotion": emotion,
        "confidence": confidence,
        "risk_score": risk_score,
        "needs_alert": needs_alert,
        "analysis_id": str(uuid.uuid4()),
        "user_id": data.user_id,
        "message": message
    }

# ✅ MongoDB 연결 상태 확인용 엔드포인트
@app.get("/health/mongo")
async def mongo_health():
    from database.mongodb import test_connection
    connected = await test_connection()
    return {"mongodb_connected": connected}

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


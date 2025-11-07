# main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
<<<<<<< HEAD
from pydantic import BaseModel
from typing import Optional
=======
>>>>>>> cba8aa7fb5c69d0cf5121029e34b01655c3c4040
from datetime import datetime
import uuid

<<<<<<< HEAD
# ✅ DB 연결 함수 (다른 사람이 만든 MySQL 세션 함수)
from database.session import get_db_connection

# ✅ 라우터들 (우리가 만든 사용자/통화/분석 기록용)
from routers import users, calls, analyses

app = FastAPI(title="말동이 감정 분석 API", version="1.0.0")

# ✅ CORS 설정 (개발 단계라 일단 전부 허용)
app.add_middleware(
    CORSMiddleware,
=======
app = FastAPI(title="말동이 감정 분석 API", version="1.0.0")

# ✅ CORS 설정 (Flutter, 웹 다 허용하고 싶으면 "*"로 해도 됨)
app.add_middleware(
    CORSMiddleware,
    # 개발 단계에서는 일단 다 허용해도 괜찮음
>>>>>>> cba8aa7fb5c69d0cf5121029e34b01655c3c4040
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

<<<<<<< HEAD
# ✅ 라우터 연결
app.include_router(users.router)      # /api/v1/users/...
app.include_router(calls.router)      # /api/v1/calls/...
app.include_router(analyses.router)   # /api/v1/analyses/...

# ---------- 공용 Pydantic 모델 ----------

class InputData(BaseModel):
    text: str
    user_id: Optional[str] = None

# ---------- 엔드포인트들 ----------

=======
# ✅ 루트 경로
>>>>>>> cba8aa7fb5c69d0cf5121029e34b01655c3c4040
@app.get("/")
def read_root():
    return {"message": "말동이 백엔드 서버 정상 작동!", "port": 8080}


@app.get("/health")
def health_check():
    """
    서버 + DB 상태 확인
    """
    conn = None
    try:
        conn = get_db_connection()
        db_status = "connected" if conn else "disconnected"
    except Exception:
        db_status = "disconnected"
    finally:
        if conn:
            conn.close()

    return {
        "status": "healthy",
        "db_status": db_status,
        "timestamp": datetime.now().isoformat(),
    }


<<<<<<< HEAD
@app.post("/predict")
def predict(data: InputData):
    """
    👉 기존에 다른 사람이 만들어 둔
       - 간단 감정 분석
       - MySQL의 AnalysisChunk 테이블에 저장
    로직을 그대로 살린 엔드포인트
    """
    db_message = ""

    # --- 1. 감정 분석 (Mock) ---
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
    message = "감정 분석 완료"
    # --- 감정 분석 로직 끝 ---

    # --- 2. MySQL DB INSERT (AnalysisChunk) ---
    conn = None
    try:
        conn = get_db_connection()
        if conn:
            with conn.cursor() as cursor:
                sql = """
                INSERT INTO AnalysisChunk
                (session_id, analysis_time, text_result, final_result)
                VALUES (%s, NOW(), %s, %s)
                """
                cursor.execute(
                    sql,
                    (
                        1,          # TODO: 실제 세션 ID로 대체
                        data.text,  # 원본 텍스트
                        emotion,    # 분석된 감정
                    ),
                )
            conn.commit()
            db_message = " 및 DB 저장 완료"
        else:
            db_message = " (DB 연결 실패로 저장 불가)"
    except Exception as db_e:
        if conn:
            conn.rollback()
        db_message = f" (DB 저장 오류: {db_e})"
    finally:
        if conn:
            conn.close()
    # --- DB INSERT 끝 ---

    return {
        "emotion": emotion,
        "confidence": confidence,
        "risk_score": risk_score,
        "needs_alert": needs_alert,
        "analysis_id": str(uuid.uuid4()),
        "user_id": data.user_id,
        "message": message + db_message,
    }


=======

# 🔮 (선택) 나중에 감정 분석용 엔드포인트 자리는 이렇게만 잡아두고,
# 실제 모델 호출 로직은 나중에 팀원이 MySQL/모델 붙이면서 채워도 됨.
# from models.schemas import PredictRequest
# @app.post("/predict")
# def predict(req: PredictRequest):
#     # TODO: 여기서 코랩/모델 서버 호출해서 결과 받아오기
#     return {"message": "나중에 모델 연동 예정", "text": req.text}


# ✅ 서버 실행
>>>>>>> cba8aa7fb5c69d0cf5121029e34b01655c3c4040
if __name__ == "__main__":
    import uvicorn
    print("🚀 말동이 백엔드 서버 시작합니다...")
    uvicorn.run("main:app", host="0.0.0.0", port=8080, reload=True)

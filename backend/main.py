# main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional
from datetime import datetime
import uuid

# ✅ MySQL 연결 함수: database/session.py 에서 가져오기
# (여기서 get_db_connection은 connection 객체를 리턴한다고 가정)
from database.session import get_db_connection

# -------------------------
# 🚀 FastAPI 앱 및 미들웨어 설정
# -------------------------
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


# ✅ Pydantic 모델 (입력 데이터 정의)
class InputData(BaseModel):
    text: str
    user_id: Optional[str] = None


# -------------------------
# 🌐 API 엔드포인트 정의
# -------------------------

# ✅ 루트 경로
@app.get("/")
def read_root():
    return {"message": "말동이 백엔드 서버 정상 작동!", "port": 8080}


# ✅ 상태 확인용 (MySQL 상태 포함)
@app.get("/health")
def health_check():
    conn = get_db_connection()
    db_status = "connected" if conn else "disconnected"
    return {
        "status": "healthy",
        "db_status": db_status,
        "timestamp": datetime.now().isoformat(),
    }


# ✅ 감정 분석 + MySQL 저장 Mock 엔드포인트
@app.post("/analyze")
def analyze_text(data: InputData):
    """
    텍스트 기반 Mock 감정 분석 + MySQL 저장 예시 엔드포인트
    """

    # --- 1. Mock 감정 분석 로직 ---
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
                cursor.execute(
                    sql,
                    (
                        1,          # 🚨 임시 session_id (실제 앱에서는 세션 생성 후 ID를 받아와야 함)
                        data.text,  # 입력 텍스트
                        emotion,    # 분석된 감정
                    ),
                )
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
        "message": message,
    }


# ✅ 서버 실행
# -------------------------
# 🔥 서버 실행 블록 (항상 파일의 가장 아래에 위치)
# -------------------------
if __name__ == "__main__":
    import uvicorn

    # 서버 시작 시점에 DB 연결을 시도하여 로그를 남기고 싶다면 (옵션)
    conn = get_db_connection()
    if conn:
        print("✅ MySQL DB 연결 확인 완료!")
    else:
        print("⚠️ MySQL DB 연결 실패 (health 엔드포인트로도 확인 가능)")

    print("🚀 말동이 백엔드 서버 시작합니다...")
    uvicorn.run("main:app", host="0.0.0.0", port=8080, reload=True)

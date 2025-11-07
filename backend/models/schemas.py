<<<<<<< HEAD
# main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from datetime import datetime

# 라우터들 가져오기 (곧 만들 거야)
from routers import users, calls, analyses

app = FastAPI(title="말동이 감정 분석 API", version="1.0.0")

# ✅ CORS 설정 (개발 단계라 일단 전부 허용)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 나중에 웹/앱 도메인 정해지면 여기서 제한
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ✅ 라우터 연결
app.include_router(users.router)      # /api/v1/users/...
app.include_router(calls.router)      # /api/v1/calls/...
app.include_router(analyses.router)   # /api/v1/analyses/...

# ✅ 루트 경로
@app.get("/")
def read_root():
    return {"message": "말동이 백엔드 서버 정상 작동!", "port": 8080}

# ✅ 상태 확인용 (DB 체크는 나중에 넣고 싶으면 여기서 해도 됨)
@app.get("/health")
def health_check():
    return {
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
    }


if __name__ == "__main__":
    import uvicorn

    print("🚀 말동이 백엔드 서버 시작합니다...")
    uvicorn.run("main:app", host="0.0.0.0", port=8080, reload=True)
=======
# models/schemas.py
from pydantic import BaseModel
from datetime import datetime, date
from typing import Optional, List

# 1) 사용자(회원)
class UserCreate(BaseModel):
  name: str              # 회원명
  gender: str            # "M" / "F" 또는 "남" / "여"
  birth_date: date       # 생년월일
  address: str           # 주소
  guardian_name: str     # 보호자명
  guardian_phone: str    # 보호자 연락처

class UserResponse(BaseModel):
  user_id: str
  name: str
  gender: str
  birth_date: date
  address: str
  guardian_name: str
  guardian_phone: str
  created_at: datetime

# 2) 통화 기록
class CallStartRequest(BaseModel):
  user_id: str  # 어떤 회원이 통화 시작했는지

class CallEndRequest(BaseModel):
  # 필요하다면 여기에 추가 정보 (예: 통화 중 이벤트) 넣을 수 있음
  pass

class CallResponse(BaseModel):
  call_id: str
  user_id: str
  start_time: datetime
  end_time: Optional[datetime] = None
  duration_seconds: Optional[int] = None

# 3) 분석 기록 + 감정 분석 요청
class PredictRequest(BaseModel):
  text: str
  user_id: Optional[str] = None
  call_id: Optional[str] = None  # 어떤 통화에 대한 분석인지

class PredictResponse(BaseModel):
  analysis_id: str
  emotion: str
  confidence: float
  risk_score: float
  needs_alert: bool
  user_id: Optional[str]
  call_id: Optional[str]
  message: str

class AnalysisRecord(BaseModel):
  analysis_id: str
  call_id: str
  analyzed_at: datetime
  text_result: str
  voice_result: Optional[str] = None
  facial_result: Optional[str] = None
  final_result: str
>>>>>>> cba8aa7fb5c69d0cf5121029e34b01655c3c4040

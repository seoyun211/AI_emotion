# models/schemas.py
from pydantic import BaseModel
from datetime import datetime, date
from typing import Optional, List

# -------------------------------------------------
# 1) 사용자(회원) - user 테이블과 매핑
# -------------------------------------------------

class UserCreate(BaseModel):
    """
    회원 등록 요청 바디
    DB: user
      - username, gender, birth_date, address,
        guardian_name, guardian_phone
    """
    username: str
    gender: str              # 예: "M" / "F" 혹은 "남" / "여"
    birth_date: date         # "YYYY-MM-DD"
    address: str
    guardian_name: str
    guardian_phone: str


class UserResponse(BaseModel):
    """
    회원 정보 응답
    DB: user
      - user_id (PK)
    """
    user_id: int
    username: str
    gender: str
    birth_date: date
    address: str
    guardian_name: str
    guardian_phone: str
    created_at: datetime

    class Config:
        orm_mode = True


# -------------------------------------------------
# 2) 통화 기록 - session 테이블과 매핑
# -------------------------------------------------

class CallStartRequest(BaseModel):
    """
    통화 시작 요청
    """
    user_id: int  # 어떤 회원이 통화 시작했는지


class CallResponse(BaseModel):
    """
    통화 기록 정보
    DB: session
      - session_id (PK), user_id, start_time, end_time, duration_seconds
    """
    session_id: int
    user_id: int
    start_time: datetime
    end_time: Optional[datetime] = None
    duration_seconds: Optional[int] = None

    class Config:
        orm_mode = True


# -------------------------------------------------
# 3) 감정 분석 요청/응답 (모델 연동용, 선택)
#    => 지금은 실제 엔드포인트에서 안 쓰고,
#       나중에 /predict 같은 곳에서 사용할 용도
# -------------------------------------------------

class PredictRequest(BaseModel):
    text: str
    user_id: Optional[int] = None
    session_id: Optional[int] = None  # 어떤 통화(session)에 대한 분석인지


class PredictResponse(BaseModel):
    analysis_id: int
    emotion: str
    confidence: float
    risk_score: float
    needs_alert: bool
    user_id: Optional[int]
    session_id: Optional[int]
    message: str


# -------------------------------------------------
# 4) 분석 기록 - analysischunk (또는 분석기록 테이블) 매핑
# -------------------------------------------------

class AnalysisCreate(BaseModel):
    """
    분석 결과 저장 요청
    지금 DB 컬럼:
      - session_id, analysis_time, text_result, final_result
    (voice_result, facial_result는 나중에 컬럼 추가하면 같이 쓰면 됨)
    """
    session_id: int
    text_result: str
    voice_result: Optional[str] = None
    facial_result: Optional[str] = None
    final_result: str


class AnalysisResponse(BaseModel):
    """
    분석 기록 응답
    PK 컬럼명은 DB 설계에 따라 id / analysis_id 등일 수 있는데,
    여기서는 analysis_id(int) 기준으로 둠.
    """
    analysis_id: int
    session_id: int
    analysis_time: datetime
    text_result: str
    voice_result: Optional[str] = None
    facial_result: Optional[str] = None
    final_result: str

    class Config:
        orm_mode = True


# (옵션) 분석 기록 히스토리를 리스트로 줄 때 쓸 수 있는 타입
class AnalysisRecord(BaseModel):
    analysis_id: int
    session_id: int
    analysis_time: datetime
    text_result: str
    voice_result: Optional[str] = None
    facial_result: Optional[str] = None
    final_result: str

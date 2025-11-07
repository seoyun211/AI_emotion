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

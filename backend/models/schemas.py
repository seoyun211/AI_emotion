from pydantic import BaseModel
from datetime import date, datetime
from typing import Optional

# 기본 입력 스키마 (Emotions, Dialogue 등에서 사용)
class InputData(BaseModel):
    """텍스트 입력과 선택적 사용자 ID를 위한 기본 스키마"""
    text: str
    user_id: Optional[str] = None

# 1. 사용자 스키마 (User 테이블 CREATE/Response)
class UserCreate(BaseModel):
    """MySQL User 테이블의 칼럼에 맞춘 사용자 생성 요청 스키마"""
    username: str
    password : str 
    gender: str
    birth_date: date
    user_phone: str
    address: Optional[str] = None
    role: str
    guardian_name: Optional[str] = None
    guardian_phone: Optional[str] = None

class UserResponse(BaseModel):
    """회원가입 성공 및 사용자 조회 시 반환할 응답 형식"""
    user_id: int
    username: str
    gender: str 
    user_phone: str
    birth_date: date
    address: Optional[str] = None
    guardian_name: Optional[str] = None
    guardian_phone: Optional[str] = None
    message: str
    timestamp: datetime

# 2. 감정 분석 스키마 (Emotions)
class EmotionCreate(BaseModel):
    """[내부 요청용] 알림 트리거/분석 기록 생성을 위한 데이터 스키마"""
    guardian_id: str
    elder_name: str
    emotion: str
    risk_score: float

class EmotionResponse(BaseModel):
    """감정 분석 결과와 DB 저장 정보를 반환하는 응답 형식 (POST /predict 응답)"""
    emotion: str
    confidence: float
    risk_score: float
    needs_alert: bool
    analysis_id: str
    user_id: Optional[str] = None
    timestamp: datetime
    message: Optional[str] = None

# 3. 알림 스키마 (Alerts)
class AlertCreate(BaseModel):
    """새로운 위험 알림 생성을 위한 요청 스키마"""
    user_id: int
    alert_type: str 
    risk_score: float
    chunk_id: Optional[int] = None 

class AlertResponse(BaseModel):
    """위험 알림 조회 시 반환하는 응답 형식"""
    alert_id: int
    user_id: int
    alert_type: str
    risk_score: float
    triggered_at: datetime
    status: str
    chunk_id: Optional[int] = None
    message: str

# 4. 인증 스키마
class LoginRequest(BaseModel):
    """전화번호 기반 로그인 요청 스키마"""
    user_phone: str # 로그인 ID로 사용
    password: str

class TokenResponse(BaseModel):
    """JWT 토큰 응답 스키마"""
    access_token: str
    token_type: str = "bearer"
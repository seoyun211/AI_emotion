# backend/models/schemas.py
from pydantic import BaseModel
from datetime import date, datetime
from typing import Optional, List

# -------------------------
# A. 기본 입력 스키마 (Emotions, Dialogue 등에서 사용)
# -------------------------
class InputData(BaseModel):
    """텍스트 입력과 선택적 사용자 ID를 위한 기본 스키마"""
    text: str
    user_id: Optional[str] = None


# -------------------------
# 1. User 관련 스키마
# -------------------------
class UserCreate(BaseModel):
    """회원가입 요청 시 사용"""
    username: str
    password: str
    gender: str
    birth_date: date
    address: Optional[str] = None
    guardian_name: Optional[str] = None
    guardian_phone: Optional[str] = None


class UserResponse(BaseModel):
    """사용자 조회/회원가입 응답"""
    user_id: int
    username: str
    gender: str
    address: Optional[str] = None
    guardian_name: Optional[str] = None
    guardian_phone: Optional[str] = None


class User(BaseModel):
    """DB 조회용 내부 유저 모델"""
    user_id: int
    username: str
    password: str
    gender: str
    birth_date: date
    address: Optional[str]
    guardian_name: Optional[str]
    guardian_phone: Optional[str]


# -------------------------
# 2. Auth / 로그인 관련 스키마
# -------------------------
class LoginRequest(BaseModel):
    user_phone: str
    password: str


class SignUpRequest(BaseModel):
    username: str
    password: str
    gender: str
    role: str
    birth_date: date
    address: Optional[str] = None
    guardian_name: Optional[str] = None
    guardian_phone: Optional[str] = None
    user_phone: str
    


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user_id: int
    username: str
    role: str


# -------------------------
# 3. 감정 기록 저장용 스키마
# -------------------------
class EmotionCreate(BaseModel):
    user_id: int
    emotion: str
    confidence: float
    risk_score: float
    created_at: Optional[datetime] = None


class EmotionResponse(BaseModel):
    emotion_id: int
    user_id: int
    emotion: str
    confidence: float
    risk_score: float
    created_at: datetime


class EmotionListResponse(BaseModel):
    emotions: List[EmotionResponse]


# -------------------------
# 4. Alerts (보호자 알림)
# -------------------------
class AlertCreate(BaseModel):
    user_id: int
    emotion: str
    risk_score: float
    created_at: Optional[datetime] = None


class AlertResponse(BaseModel):
    alert_id: int
    user_id: int
    emotion: str
    risk_score: float
    created_at: datetime


# -------------------------
# 5. 멀티모달 요청/응답 스키마
# -------------------------
class MultiModalEmotionRequest(BaseModel):
    user_id: Optional[int] = None
    text: Optional[str] = None
    audio_base64: Optional[str] = None
    image_base64: Optional[str] = None


class MultiModalEmotionResponse(BaseModel):
    emotion: str
    confidence: float
    risk_score: float
    needs_alert: bool
    message: Optional[str] = None

from pydantic import BaseModel, EmailStr
from typing import Optional, List
from datetime import datetime

# ── 공통 입력 ─────────────────────────────────────────────
class InputData(BaseModel):
    text: str
    user_id: Optional[str] = None

# ── 보호자 서브도큐먼트 (회원가입 시 함께 제출) ─────────────
class GuardianIn(BaseModel):
    name: str
    phone: str
    relation: Optional[str] = None
    email: Optional[EmailStr] = None
    # 알림 채널 확장 대비
    channels: dict = {"sms": True, "push": False}

# ── 노인(사용자) 회원가입 ─────────────────────────────────
# 기존 UserCreate 대신 사용: 보호자 배열 포함
class ElderRegister(BaseModel):
    name: str
    phone: str
    password: str
    # 선택: 나이/이메일/긴급연락처 등
    age: Optional[int] = None
    email: Optional[EmailStr] = None
    emergency_contact: Optional[str] = None
    guardians: List[GuardianIn] = []  # 최소 1명 권장(서버에서 검증 가능)

# ── 노인(사용자) 로그인 ───────────────────────────────────
class ElderLogin(BaseModel):
    phone: str
    password: str

# ── 감정 분석 응답 ────────────────────────────────────────
class EmotionResponse(BaseModel):
    emotion: str
    confidence: float
    risk_score: float
    needs_alert: bool
    analysis_id: str
    user_id: Optional[str] = None
    timestamp: datetime

# ── 사용자 응답 ───────────────────────────────────────────
class UserResponse(BaseModel):
    user_id: str
    name: str
    message: str
    timestamp: datetime

# ── 토큰 ─────────────────────────────────────────────────
class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"

class TokenData(BaseModel):
    phone: Optional[str] = None
    elder_id: Optional[str] = None  # ← guardian_id 대신 elder_id

# ── 보호자 조회용(필요 시만 사용) ─────────────────────────
class GuardianResponse(BaseModel):
    id: str
    name: str
    phone: str
    email: Optional[str] = None

# ── 알림 로그/피드 ───────────────────────────────────────
class AlertResponse(BaseModel):
    id: str
    guardian_id: str
    elder_name: str
    message: str
    alert_level: str  # e.g., "high" | "medium" | "low"
    is_read: bool
    created_at: datetime  # ← str 대신 datetime 권장

# ── 헬스체크 ─────────────────────────────────────────────
class HealthResponse(BaseModel):
    status: str
    timestamp: datetime
    mongodb: str
    version: str

from pydantic import BaseModel, EmailStr
from typing import Optional, List
from datetime import datetime

# 요청 스키마
class InputData(BaseModel):
    text: str
    user_id: Optional[str] = None

class UserCreate(BaseModel):
    name: str
    phone: str
    age: int
    emergency_contact: str

class GuardianCreate(BaseModel):
    name: str
    phone: str
    password: str
    email: Optional[EmailStr] = None

class GuardianLogin(BaseModel):
    phone: str
    password: str

# 응답 스키마
class EmotionResponse(BaseModel):
    emotion: str
    confidence: float
    risk_score: float
    needs_alert: bool
    analysis_id: str
    user_id: Optional[str] = None
    timestamp: datetime

class UserResponse(BaseModel):
    user_id: str
    name: str
    message: str
    timestamp: datetime

class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    phone: Optional[str] = None
    guardian_id: Optional[str] = None

class GuardianResponse(BaseModel):
    id: str
    name: str
    phone: str
    email: Optional[str] = None

class AlertResponse(BaseModel):
    id: str
    guardian_id: str
    elder_name: str
    message: str
    alert_level: str
    is_read: bool
    created_at: str

class HealthResponse(BaseModel):
    status: str
    timestamp: datetime
    mongodb: str
    version: str
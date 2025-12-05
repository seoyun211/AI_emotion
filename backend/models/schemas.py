# backend/models/schemas.py
from pydantic import BaseModel
from datetime import date, datetime
from typing import Optional, List, Dict

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
    user_id: int
    username: str
    user_phone: str          
    gender: str
    role: str
    birth_date: date        
    address: Optional[str] = None
    guardian_name: Optional[str] = None
    guardian_phone: Optional[str] = None


class User(BaseModel):
    user_id: int
    username: str
    password: str
    user_phone: str          
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
    linked_phone_input: Optional[str] = None
    ward_phone: Optional[str] = None


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


# ----- 6. 앙상블 상세 구조 (추가) ----- #
class ModalityDetail(BaseModel):
    """각 모달리티별(이미지/텍스트/음성) 감정 결과 상세"""
    label: str               # "기쁨", "분노", "불안", "슬픔"
    id: int                  # 0,1,2,3
    probabilities: Dict[str, float]  # {"기쁨":0.7, "분노":0.1, ...}


class EnsembleDetail(BaseModel):
    """앙상블 최종 결과 + 모달리티별 결과"""
    final: ModalityDetail
    per_modality: Dict[str, ModalityDetail]  # {"image": {...}, "text": {...}, "audio": {...}}


class MultiModalEmotionResponse(BaseModel):
    emotion: str          # 최종 감정 라벨 (예: "기쁨")
    confidence: float     # 최종 감정 확률 (예: 0.83)
    risk_score: float
    needs_alert: bool
    message: Optional[str] = None

    ensemble_detail: Optional[EnsembleDetail] = None


class DailyEmotionResponse(BaseModel):
    date: str
    emotion: str  # "0", "2", "3", "5"
    emotion_name: str  # "기쁨", "분노", "불안", "슬픔"
    severity: str
    avg_risk_score: float


# ------------------------------------------------
# ⭐⭐⭐ 수정된 부분: 감정 4종 그대로 반환하는 구조
# ------------------------------------------------
class EmotionStatsResponse(BaseModel):
    joy: int      # 기쁨
    anger: int    # 분노
    anxiety: int  # 불안
    sadness: int  # 슬픔


class WardInfoResponse(BaseModel):
    user_id: int
    username: str
    user_phone: str


# -------------------------
# 7. 통화기록(Session) 스키마
# -------------------------
class SessionBase(BaseModel):
    user_id: int
    start_time: datetime
    end_time: Optional[datetime] = None
    duration_seconds: Optional[int] = None


class SessionCreate(SessionBase):
    """통화 종료 시 기록 저장할 때 사용"""
    pass


class SessionResponse(SessionBase):
    """통화기록 조회용"""
    session_id: int


class SessionListResponse(BaseModel):
    sessions: List[SessionResponse]

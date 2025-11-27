from pydantic import BaseModel
from datetime import date, datetime
from typing import Optional
from typing import List

# -------------------------
# A. 기본 입력 스키마 (Emotions, Dialogue 등에서 사용)
# -------------------------
class InputData(BaseModel):
    """텍스트 입력과 선택적 사용자 ID를 위한 기본 스키마"""
    text: str
    user_id: Optional[str] = None

# -------------------------
# 1. 요청 스키마 (User 테이블 CREATE에 사용)
# -------------------------
class UserCreate(BaseModel):
    """MySQL User 테이블의 칼럼에 맞춘 Pydantic 모델"""
    username: str
    password : str 
    gender: str
    birth_date: date
    address: Optional[str] = None
    guardian_name: Optional[str] = None
    guardian_phone: Optional[str] = None 

# -------------------------
# 2. 응답 스키마 (User 등록 성공/조회 응답)
# -------------------------
class UserResponse(BaseModel):
    """회원가입 성공 및 사용자 조회 시 반환할 응답 형식"""
    user_id: int
    username: str
    gender: str 
    birth_date: date
    address: Optional[str] = None
    guardian_name: Optional[str] = None
    guardian_phone: Optional[str] = None
    message: str
    timestamp: datetime

# -------------------------
# 3. 알림 스키마 (Alerts)
# -------------------------
class AlertResponse(BaseModel):
    """위험 알림을 반환하는 응답 형식"""
    alert_id: int
    user_id: int
    session_id: Optional[int] = None
    emotion_detected: str
    risk_score: float
    triggered_at: datetime
    status: str # 'pending', 'resolved', 'ignored'
    message: str # 알림 메시지

# -------------------------
# 4. 감정 분석 응답 스키마 (Emotions)
# -------------------------
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

class MultiModalEmotionRequest(BaseModel):
    """멀티모달 분석용 요청 스키마"""
    text: str
    image_path: str   # 서버 기준 이미지 파일 경로
    audio_path: str   # 서버 기준 wav 파일 경로
    user_id: Optional[str] = None

class MultiModalEmotionResponse(BaseModel):
    """멀티모달 감정 + 말동이 답변"""
    emotion_id: int
    emotion: str
    probs: List[float]
    llm_reply: str
    user_id: Optional[str] = None
    timestamp: datetime
# C:\Users\user\Desktop\AI_emotion\backend\database\schemas.py 파일 내용

from pydantic import BaseModel
from typing import Optional, Dict
from datetime import datetime

# 1. Alert 생성/업데이트를 위한 기본 스키마 (alerts.py에서 AlertBase로 사용됨)
class AlertBase(BaseModel):
    guardian_id: str
    elder_name: str
    message: str
    alert_level: str
    emotion: str
    risk_score: float

# 2. API 응답용 스키마 (alerts.py에서 AlertResponse로 사용됨)
class AlertResponse(AlertBase):
    id: str # DB에서 생성된 ID
    created_at: datetime
    read_at: Optional[datetime] = None

    class Config:
        from_attributes = True

# 3. 알림 트리거 요청 데이터 스키마 (alerts.py에서 EmotionDataRequest로 사용됨)
class EmotionDataRequest(BaseModel):
    guardian_id: str
    elder_name: str
    emotion: str
    risk_score: float
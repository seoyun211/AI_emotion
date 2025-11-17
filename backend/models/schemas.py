from pydantic import BaseModel
from datetime import date, datetime
from typing import Optional

# -------------------------
# 1. 요청 스키마 (User 테이블 CREATE에 사용)
# -------------------------
class UserCreate(BaseModel):
    """MySQL User 테이블의 칼럼에 맞춘 Pydantic 모델"""
    username: str
    gender: str
    birth_date: date  # 'YYYY-MM-DD' 형식의 날짜 객체
    address: Optional[str] = None
    guardian_name: Optional[str] = None
    guardian_phone: Optional[str] = None 

# -------------------------
# 2. 응답 스키마 (User 등록 성공 응답)
# -------------------------
class UserResponse(BaseModel):
    """회원가입 성공 시 반환할 응답 형식"""
    user_id: int  # MySQL의 AUTO_INCREMENT ID
    username: str
    message: str
    timestamp: datetime
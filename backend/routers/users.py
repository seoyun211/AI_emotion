# routers/users.py
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from database.session import get_db
from database.models import User
from models.schemas import UserCreate, UserResponse

router = APIRouter(prefix="/api/v1/users", tags=["사용자"])

@router.post("/", response_model=UserResponse)
def create_user(user_data: UserCreate, db: Session = Depends(get_db)):
    """
    사용자(회원) 등록
    """
    user = User(
        name=user_data.name,
        gender=user_data.gender,
        birth_date=user_data.birth_date,
        address=user_data.address,
        guardian_name=user_data.guardian_name,
        guardian_phone=user_data.guardian_phone,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user

@router.get("/{user_id}", response_model=UserResponse)
def get_user(user_id: int, db: Session = Depends(get_db)):
    """
    특정 회원 상세 조회
    """
    user = db.query(User).get(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="사용자를 찾을 수 없습니다.")
    return user

# 🔑 인증 API
from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import OAuth2PasswordRequestForm
from database.crud import GuardianCRUD
from auth.security import verify_password, get_password_hash
from auth.auth import create_access_token
from models.schemas import GuardianCreate, Token, GuardianResponse
from datetime import timedelta
from config import JWT_CONFIG

router = APIRouter(prefix="/api/v1/auth", tags=["인증"])

@router.post("/register")
async def register_guardian(guardian_data: GuardianCreate):
    """보호자 회원가입"""
    # 기존 사용자 확인
    existing = await GuardianCRUD.get_guardian_by_phone(guardian_data.phone)
    if existing:
        raise HTTPException(status_code=400, detail="이미 등록된 전화번호입니다")
    
    # 비밀번호 해시
    hashed_password = get_password_hash(guardian_data.password)
    
    # 보호자 생성
    guardian_id = await GuardianCRUD.create_guardian({
        "name": guardian_data.name,
        "phone": guardian_data.phone,
        "email": guardian_data.email,
        "hashed_password": hashed_password
    })
    
    return {"message": "회원가입 성공", "guardian_id": guardian_id}

@router.post("/login", response_model=Token)
async def login(form_data: OAuth2PasswordRequestForm = Depends()):
    """보호자 로그인"""
    guardian = await GuardianCRUD.get_guardian_by_phone(form_data.username)
    if not guardian or not verify_password(form_data.password, guardian["hashed_password"]):
        raise HTTPException(status_code=400, detail="전화번호 또는 비밀번호가 틀렸습니다")
    
    access_token = create_access_token(
        data={"sub": guardian["phone"], "guardian_id": str(guardian["_id"])},
        expires_delta=timedelta(minutes=JWT_CONFIG["access_token_expire_minutes"])
    )
    
    return {"access_token": access_token, "token_type": "bearer"}
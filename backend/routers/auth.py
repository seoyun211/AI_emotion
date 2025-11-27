from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from models.schemas import LoginRequest, TokenResponse 
from auth.auth import authenticate_user, create_access_token
from datetime import timedelta

router = APIRouter(prefix="/api/v1/auth", tags=["인증"])

@router.post("/login", response_model=TokenResponse)
def login_for_access_token(form_data: LoginRequest):
    
    # 1. 사용자 인증 (user_phone과 password 사용)  
    user = authenticate_user(form_data.user_phone, form_data.password)
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect phone number or password"
        )
    
    # 2. JWT 토큰 생성
    access_token_expires = timedelta(minutes=60) 
    
    # 토큰 페이로드에 user_phone (sub)과 user_id를 포함시켜야 함
    access_token = create_access_token(
        data={"sub": user['user_phone'], "user_id": user['user_id']},
        expires_delta=access_token_expires
    )
    
    # 3. 토큰 반환
    return {"access_token": access_token, "token_type": "bearer"}
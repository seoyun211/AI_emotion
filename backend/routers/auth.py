from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from models.schemas import LoginRequest, TokenResponse, SignUpRequest, UserResponse
from auth.auth import authenticate_user, create_access_token, create_new_user
from datetime import timedelta, datetime

router = APIRouter(prefix="/api/v1/auth", tags=["인증"])

@router.post("/signup", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
def signup_new_user(user_data: SignUpRequest):
    """
    새로운 사용자(어르신 또는 보호자)를 등록합니다.
    """
    try:
        # 2. 새로운 사용자 생성 및 DB에 저장
        # create_new_user 함수는 성공적으로 저장된 사용자 객체를 반환해야 합니다.
        new_user_id = create_new_user(user_data)
        
        # 3. 성공 응답 (HTTP 201 Created)
        return UserResponse(
            user_id=new_user_id, # DB에서 받은 ID 사용
            username=user_data.username,
            user_phone=user_data.user_phone,
            # UserResponse에 필요한 나머지 필드들을 여기에 채워 넣어야 합니다.
            gender=user_data.gender,
            birth_date=user_data.birth_date,
            address=user_data.address,
            message=f"사용자 등록 성공 (ID: {new_user_id})",
            timestamp=datetime.now()
        )
    
    except ValueError as e:
        # 예: 전화번호 형식 오류, DB 저장 실패 등 구체적인 오류 처리
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="User registration failed unexpectedly"
        )

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
    return {
        "access_token": access_token, 
        "token_type": "bearer",
        "user_id": user['user_id'],  
        "username": user['username']
        }
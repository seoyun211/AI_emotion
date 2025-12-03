# backend/routers/auth.py

from fastapi import APIRouter, HTTPException, status
from models.schemas import LoginRequest, TokenResponse, SignUpRequest, UserResponse
from auth.auth import authenticate_user, create_access_token, create_new_user
from datetime import timedelta, datetime

# ✅ 라우터 객체 생성 (이 줄이 꼭 필요합니다!)
router = APIRouter(prefix="/api/v1/auth", tags=["인증"])


@router.post("/signup", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
def signup_new_user(user_data: SignUpRequest):
    """
    새로운 사용자(어르신 또는 보호자)를 등록하고, 관계 정보를 등록합니다.
    """
    try:
        # 새로운 사용자 생성 및 DB에 저장 + 관계 설정
        result = create_new_user(user_data) 
        
        # 성공 응답 (HTTP 201 Created)
        return UserResponse(
            user_id=result['user_id'],
            username=user_data.username,
            user_phone=user_data.user_phone,
            role=result['role'],
            gender=user_data.gender,
            birth_date=user_data.birth_date,
            address=user_data.address,
            guardian_name=None,  # SignUpRequest에 이 필드가 없으면 None
            guardian_phone=None,  # SignUpRequest에 이 필드가 없으면 None
            message=f"사용자 등록 및 관계 설정 성공 (ID: {result['user_id']})",
            timestamp=datetime.now()
        )
    
    except ValueError as e:
        # DB 제약 조건 위반 (전화번호 중복) 또는 관계 설정 실패
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        # 그 외 예기치 않은 오류
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"회원가입 중 오류가 발생했습니다: {str(e)}"
        )


@router.post("/login", response_model=TokenResponse)
def login_for_access_token(form_data: LoginRequest):
    """
    사용자 로그인 (전화번호와 비밀번호 사용)
    """
    # 1. 사용자 인증
    user = authenticate_user(form_data.user_phone, form_data.password)
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="전화번호 또는 비밀번호가 올바르지 않습니다",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # 2. JWT 토큰 생성
    access_token_expires = timedelta(minutes=60) 
    
    access_token = create_access_token(
        data={"sub": user['user_phone'], "user_id": user['user_id']},
        expires_delta=access_token_expires
    )
    
    # 3. 토큰 반환
    return TokenResponse(
        access_token=access_token, 
        token_type="bearer",
        user_id=user['user_id'],
        username=user['username'],
        role=user['role']
    )
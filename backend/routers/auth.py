from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from models.schemas import LoginRequest, TokenResponse, SignUpRequest, UserResponse
from auth.auth import authenticate_user, create_access_token, create_new_user
from datetime import timedelta, datetime

router = APIRouter(prefix="/api/v1/auth", tags=["인증"])

@router.post("/signup", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
def signup_new_user(user_data: SignUpRequest):
    """
    새로운 사용자(어르신 또는 보호자)를 등록하고, 관계 정보를 등록합니다.
    """
    try:
        # 2. 새로운 사용자 생성 및 DB에 저장 + 관계 설정
        # create_new_user 함수는 성공 시 { "user_id": int, "role": str } 형태의 딕셔너리를 반환합니다.
        result = create_new_user(user_data) 
        
        # 3. 성공 응답 (HTTP 201 Created)
        return UserResponse(
            user_id=result['user_id'],          # ✅ create_new_user 결과에서 ID 사용
            username=user_data.username,
            user_phone=user_data.user_phone,
            
            # 🌟 UserResponse에 role 필드를 채워 넣습니다.
            role=result['role'],                # ✅ create_new_user 결과에서 Role 사용
            
            # UserResponse에 필요한 나머지 필드들을 여기에 채워 넣습니다.
            gender=user_data.gender,
            birth_date=user_data.birth_date,
            address=user_data.address,
            guardian_name=user_data.guardian_name,      # SignUpRequest에서 직접 가져옴
            guardian_phone=user_data.guardian_phone,    # SignUpRequest에서 직접 가져옴
            
            message=f"사용자 등록 및 관계 설정 성공 (ID: {result['user_id']})",
            timestamp=datetime.now()
        )
    
    except ValueError as e:
        # DB 제약 조건 위반 (전화번호 중복) 또는 관계 설정 실패 등의 구체적인 오류 처리
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        # 그 외 예기치 않은 오류
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"User registration failed unexpectedly: {e}"
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
        "username": user['username'],
        "role": user['role']
        }
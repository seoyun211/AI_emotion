from datetime import datetime, timedelta
from jose import JWTError, jwt
from fastapi import HTTPException, status
from config import JWT_CONFIG
from typing import Dict, Optional
from database.crud import UserCRUD 
from database.crud import verify_password

def create_access_token(data: dict, expires_delta: timedelta = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=JWT_CONFIG["access_token_expire_minutes"])
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, JWT_CONFIG["secret_key"], algorithm=JWT_CONFIG["algorithm"])
    return encoded_jwt

async def verify_token(token: str):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, JWT_CONFIG["secret_key"], algorithms=[JWT_CONFIG["algorithm"]])
        return payload
    except JWTError:
        raise credentials_exception
    
def get_user_by_phone(user_phone: str) -> Optional[Dict]:
    """
    DB에서 전화번호로 사용자 정보를 조회합니다.
    """
    return UserCRUD.get_user_by_phone(user_phone)


def authenticate_user(user_phone: str, password: str) -> Optional[Dict]:
    """
    전화번호와 비밀번호로 사용자를 인증합니다.
    """
    # 1. 전화번호로 사용자 정보 조회
    user = get_user_by_phone(user_phone) 
    
    if not user:
        return None  
    if not verify_password(password, user['password_hash']):
        return None  # 비밀번호 불일치

    # 인증 성공 시 해시값 제외한 사용자 정보 반환
    user_data = user.copy()
    user_data.pop('password_hash', None)
    return user_data


def get_current_user(token: str) -> Dict:
    """
    JWT 토큰에서 정보를 추출하고, DB에서 해당 사용자를 조회합니다.
    (주로 Dependencies.py에서 사용될 함수입니다.)
    """
    payload = verify_token(token)
    
    # JWT 토큰의 sub(subject) 필드에 user_phone을 저장했다고 가정합니다.
    user_phone: str = payload.get("sub")
    
    if user_phone is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication token payload"
        )
    
    # user_phone으로 DB에서 사용자 정보 다시 조회
    user = get_user_by_phone(user_phone)
    
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found"
        )
        
    return user
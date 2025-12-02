from datetime import datetime, timedelta
from jose import JWTError, jwt
from fastapi import HTTPException, status
from config import JWT_CONFIG
from typing import Dict, Optional
# UserCRUD, GuardianCRUD, delete_user_by_id 함수 import
from database.crud import UserCRUD, verify_password, hash_password, GuardianCRUD
from models.schemas import SignUpRequest, User
import bcrypt
import logging 

logger = logging.getLogger(__name__)

# =========================================================================
# 1. 사용자 생성 및 인증
# =========================================================================

def hash_password(password: str) -> str:
    """비밀번호를 해싱하고 문자열로 반환합니다."""
    hashed = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt())
    return hashed.decode('utf-8')

def create_new_user(user_data: SignUpRequest) -> Dict:
    """
    회원가입 데이터를 받아 비밀번호를 해시하고 DB에 새 사용자를 저장하며,
    필요 시 보호자-피보호자 관계를 설정합니다.
    """
    # 1. 비밀번호 해싱
    hashed_password = hash_password(user_data.password) 
    
    db_data = user_data.model_dump()

    # 2. DB 저장용 데이터 준비
    db_data.pop('password', None)
    db_data['password_hash'] = hashed_password

    ward_phone = db_data.pop('ward_phone', None)

    if db_data['role'] == 'guardian' and not ward_phone:
        raise ValueError("보호자 계정은 연결할 피보호자의 전화번호를 반드시 입력해야 합니다.")
    
    logger.debug(f"최종 DB 데이터 키 확인: {db_data.keys()}")

    # 3. User 테이블에 사용자 생성 (commit 발생)
    # 이 시점에서 사용자는 이미 DB에 저장됩니다.
    try:
        new_user_id = UserCRUD.create_user(db_data)
    except Exception as e:
        # DB 제약 조건 위반(예: 전화번호 중복) 오류 처리
        raise ValueError(f"회원가입 처리 실패: {str(e)}")
    
    # 4. 보호자-피보호자 관계 설정 및 실패 시 보상(삭제) 로직 
    if ward_phone:
        try:
            GuardianCRUD.create_relationship_with_validation(
                new_user_id=new_user_id,
                new_user_role=db_data['role'], 
                linked_phone_input=ward_phone # ward_phone을 linked_phone_input 인자로 전달
            )
            logger.info(f"관계 생성 성공: User ID {new_user_id} 연결됨")
            
        except ValueError as e:
            # 🚨 관계 설정 실패 시, 보상 로직: 방금 생성된 사용자 삭제(롤백) 🚨
            try:
                UserCRUD.delete_user_by_id(new_user_id) 
                logger.warning(f"관계 설정 실패로 인해 User ID {new_user_id} 삭제(롤백) 완료.")
            except Exception as delete_e:
                logger.error(f"보상 롤백 실패: User ID {new_user_id} 삭제 중 오류: {delete_e}")
                # 이 경우 DB에 남은 데이터를 수동으로 정리해야 합니다.

            # 클라이언트에게 실패 메시지 전달
            raise ValueError(f"관계 설정 실패로 회원가입 취소됨 어르신 번호를 확인해주세요.: {str(e)}")

    # 5. 응답 형태로 사용자 ID와 역할 반환
    return {
        "user_id": new_user_id,
        "role": db_data['role']
    }


def get_user_by_phone(user_phone: str) -> Optional[Dict]:
    """DB에서 전화번호로 사용자 정보를 조회합니다."""
    return UserCRUD.get_user_by_phone(user_phone)


def authenticate_user(user_phone: str, password: str) -> Optional[Dict]:
    """전화번호와 비밀번호로 사용자를 인증합니다."""
    user = get_user_by_phone(user_phone) 
    
    if not user:
        return None 
    if not verify_password(password, user['password_hash']):
        return None 

    user_data = user.copy()
    user_data.pop('password_hash', None)
    return user_data

# =========================================================================
# 2. JWT 및 토큰 관리
# =========================================================================

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
    
def get_current_user(token: str) -> Dict:
    """JWT 토큰에서 정보를 추출하고, DB에서 해당 사용자를 조회합니다."""
    payload = verify_token(token)
    
    user_phone: str = payload.get("sub")
    
    if user_phone is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication token payload"
        )
    
    user = get_user_by_phone(user_phone)
    
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found"
        )
        
    return user
# 의존성 주입
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from .auth import get_current_user 
from database.crud import GuardianCRUD 

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login")

async def get_current_guardian(token: str = Depends(oauth2_scheme)):
    
    user = get_current_user(token)
    
    if user['role'] != 'guardian':
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="접근 권한이 없습니다. (Guardian 역할만 접근 가능)"
        )

    return user
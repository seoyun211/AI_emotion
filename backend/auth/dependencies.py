# 의존성 주입
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from .auth import verify_token
from database.crud import GuardianCRUD

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login")

async def get_current_guardian(token: str = Depends(oauth2_scheme)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    
    payload = await verify_token(token)
    phone: str = payload.get("sub")
    guardian_id: str = payload.get("guardian_id")
    
    if phone is None or guardian_id is None:
        raise credentials_exception
    
    guardian = await GuardianCRUD.get_guardian_by_id(guardian_id)
    if guardian is None:
        raise credentials_exception
    
    return guardian
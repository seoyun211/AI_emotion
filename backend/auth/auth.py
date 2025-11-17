# JWT 인증
from datetime import datetime, timedelta
from jose import JWTError, jwt
from fastapi import HTTPException, status
from config import JWT_CONFIG

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
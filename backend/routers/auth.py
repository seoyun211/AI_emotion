#DB연동전 라우터 확인용
from fastapi import APIRouter, HTTPException
from datetime import datetime
from bson import ObjectId
from models.schemas import ElderRegister, ElderLogin, Token
import os

router = APIRouter(prefix="/api/v1/auth", tags=["인증"])

ACCESS_MIN = int(os.getenv("ACCESS_TOKEN_MIN", "60"))

# 🧩 임시 해시 함수 (보기용)
def hash_password(password: str) -> str:
    return password

# 🧩 회원가입 (테스트용)
@router.post("/register")
async def register_user(payload: ElderRegister):
    """사용자 회원가입"""
    guardians = []
    for g in payload.guardians:
        gd = g.dict()
        gd["_id"] = ObjectId()
        guardians.append(gd)

    return {
        "message": "회원가입 성공 (테스트용)",
        "user_id": "fake_user_id_12345",
        "guardian_ids": [str(g["_id"]) for g in guardians],
        "hashed_password": hash_password(payload.password)
    }


# 🔑 로그인 (테스트용)
@router.post("/login", response_model=Token)
async def login(payload: ElderLogin):
    """사용자 로그인"""
    # 실제 DB 없이 테스트용 계정 하나만 통과시키기
    if payload.phone != "010-1234-5678" or payload.password != "test1234":
        raise HTTPException(status_code=400, detail="전화번호 또는 비밀번호가 틀렸습니다 (테스트용)")

    # JWT 없이 임시 토큰 반환
    fake_token = f"fake-token-{datetime.utcnow().timestamp()}"

    return {
        "access_token": fake_token,
        "token_type": "bearer"
    }


#원래 코드
'''from fastapi import APIRouter, HTTPException
from datetime import datetime
from bson import ObjectId
from database.mongodb import users_collection
from models.schemas import ElderRegister, ElderLogin, Token
from utils.password import hash_password, verify_password
from auth.jwt import create_access_token
import os

router = APIRouter(prefix="/api/v1/auth", tags=["인증"])

ACCESS_MIN = int(os.getenv("ACCESS_TOKEN_MIN", "60"))


# 🧩 회원가입 (사용자)
@router.post("/register")
async def register_user(payload: ElderRegister):
    """사용자 회원가입"""
    # 1️⃣ 중복 전화번호 검사
    if await users_collection.find_one({"phone": payload.phone}):
        raise HTTPException(status_code=400, detail="이미 등록된 전화번호입니다")

    # 2️⃣ 비밀번호 해시
    hashed_pw = hash_password(payload.password)

    # 3️⃣ 보호자 리스트 정제
    guardians = []
    for g in payload.guardians:
        gd = g.dict()
        gd["_id"] = ObjectId()
        guardians.append(gd)

    # 4️⃣ DB 저장
    doc = {
        "name": payload.name,
        "phone": payload.phone,
        "email": payload.email,
        "age": payload.age,
        "emergency_contact": payload.emergency_contact,
        "hashed_password": hashed_pw,
        "guardians": guardians,
        "createdAt": datetime.utcnow(),
        "updatedAt": datetime.utcnow(),
    }

    result = await users_collection.insert_one(doc)

    return {
        "message": "회원가입 성공",
        "user_id": str(result.inserted_id),
        "guardian_ids": [str(g["_id"]) for g in guardians],
    }


# 🔑 로그인 (JSON 방식)
@router.post("/login", response_model=Token)
async def login(payload: ElderLogin):
    """사용자 로그인"""
    user = await users_collection.find_one({"phone": payload.phone})
    if not user or not verify_password(payload.password, user.get("hashed_password", "")):
        raise HTTPException(status_code=400, detail="전화번호 또는 비밀번호가 틀렸습니다")

    # JWT 토큰 생성
    token = create_access_token(
        data={"sub": user["phone"], "user_id": str(user["_id"])},
        minutes=ACCESS_MIN
    )

    return {"access_token": token, "token_type": "bearer"}'''

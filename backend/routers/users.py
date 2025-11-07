# routers/users.py
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from datetime import date, datetime

from database.session import get_db_connection

router = APIRouter(prefix="/api/v1/users", tags=["사용자"])


class UserCreate(BaseModel):
    username: str
    gender: str
    birth_date: date
    address: str
    guardian_name: str
    guardian_phone: str


class UserResponse(BaseModel):
    user_id: int
    username: str
    gender: str
    birth_date: date
    address: str
    guardian_name: str
    guardian_phone: str
    created_at: datetime


@router.post("/", response_model=UserResponse)
def create_user(user: UserCreate):
    """
    user 테이블에 회원 등록
    """
    conn = get_db_connection()
    try:
        with conn.cursor() as cur:
            sql = """
            INSERT INTO `user`
              (username, gender, birth_date, address, guardian_name, guardian_phone, created_at)
            VALUES (%s, %s, %s, %s, %s, %s, NOW())
            """
            cur.execute(
                sql,
                (
                    user.username,
                    user.gender,
                    user.birth_date,
                    user.address,
                    user.guardian_name,
                    user.guardian_phone,
                ),
            )
            conn.commit()
            user_id = cur.lastrowid

        return UserResponse(
            user_id=user_id,
            username=user.username,
            gender=user.gender,
            birth_date=user.birth_date,
            address=user.address,
            guardian_name=user.guardian_name,
            guardian_phone=user.guardian_phone,
            created_at=datetime.now(),  # DB NOW()와 거의 동일
        )

    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=f"사용자 등록 실패: {e}")
    finally:
        conn.close()


@router.get("/{user_id}", response_model=UserResponse)
def get_user(user_id: int):
    """
    특정 회원 조회
    """
    conn = get_db_connection()
    try:
        with conn.cursor() as cur:
            sql = """
            SELECT
              user_id,
              username,
              gender,
              birth_date,
              address,
              guardian_name,
              guardian_phone,
              created_at
            FROM `user`
            WHERE user_id = %s
            """
            cur.execute(sql, (user_id,))
            row = cur.fetchone()

        if not row:
            raise HTTPException(status_code=404, detail="사용자를 찾을 수 없습니다.")

        return UserResponse(**row)

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"사용자 조회 실패: {e}")
    finally:
        conn.close()

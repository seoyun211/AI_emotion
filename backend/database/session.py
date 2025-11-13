# backend/database/session.py 내용

from backend.config import DATABASE_CONFIG
import pymysql.cursors


# -------------------------
## 💾 DB 연결 관리
# -------------------------
db_connection = None

def get_db_connection():
    """DB 연결을 생성하고 반환합니다."""
    global db_connection
    # 연결이 없거나 닫혀있으면 새로 연결 시도
    if db_connection is None or not db_connection.open:
        try:
            db_connection = pymysql.connect(
                host=DATABASE_CONFIG['host'],
                user=DATABASE_CONFIG['user'],
                password=DATABASE_CONFIG['password'],
                database=DATABASE_CONFIG['database'],
                cursorclass=pymysql.cursors.DictCursor
            )
            print("✅ MySQL DB 연결 성공!")
        except Exception as e:
            print(f"❌ MySQL DB 연결 실패: {e}")
            db_connection = None
    return db_connection
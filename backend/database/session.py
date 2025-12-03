# C:\Users\jiheo\AI_emotion\backend\database\session.py

from config import DATABASE_CONFIG
import pymysql.cursors
import time

# -------------------------
## 💾 DB 연결 관리
# -------------------------
db_connection = None

def get_db_connection():
    """
    DB 연결을 생성하고 반환합니다.
    
    Returns:
        pymysql.connections.Connection: PyMySQL 연결 객체
    """
    global db_connection
    
    # 🚨 DB 연결 시도 타임아웃 설정 (5초) 
    CONNECT_TIMEOUT = 5 
    
    # 연결이 없거나 닫혀있으면 새로 연결 시도
    if db_connection is None or not db_connection.open:
        try:
            print(f"[{time.strftime('%H:%M:%S')}] ⏳ MySQL DB 연결 시도 중...")
            
            db_connection = pymysql.connect(
                host=DATABASE_CONFIG['host'],
                user=DATABASE_CONFIG['user'],
                password=DATABASE_CONFIG['password'],
                database=DATABASE_CONFIG['database'],
                # ✅ DictCursor 사용 (auth.py와 호환)
                cursorclass=pymysql.cursors.DictCursor,
                connect_timeout=CONNECT_TIMEOUT,
                charset='utf8mb4',
                autocommit=False  # 트랜잭션 제어
            )
            print("✅ MySQL DB 연결 성공!")
            
        except pymysql.err.OperationalError as e:
            print(f"❌ MySQL DB 연결 실패 (OperationalError): {e}")
            db_connection = None
            raise  # 에러를 다시 발생시켜 호출자가 처리하도록
            
        except Exception as e:
            print(f"❌ MySQL DB 연결 실패 (기타 오류): {e}")
            db_connection = None
            raise
            
    return db_connection


def close_db_connection():
    """DB 연결을 명시적으로 종료합니다."""
    global db_connection
    if db_connection and db_connection.open:
        db_connection.close()
        print("🔌 MySQL DB 연결 종료")
        db_connection = None
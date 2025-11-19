# C:\Users\user\Desktop\AI_emotion\backend\database\session.py 파일 수정

from config import DATABASE_CONFIG
import pymysql.cursors
import time  # time 모듈 임포트 (디버깅용)


# -------------------------
## 💾 DB 연결 관리
# -------------------------
db_connection = None

def get_db_connection():
    """DB 연결을 생성하고 반환합니다."""
    global db_connection
    
    # 🚨 DB 연결 시도 타임아웃 설정 (5초) 
    CONNECT_TIMEOUT = 5 
    
    # 연결이 없거나 닫혀있으면 새로 연결 시도
    if db_connection is None or not db_connection.open:
        try:
            # 💡 1. DB 연결 전에 현재 시간을 출력하여 얼마나 걸리는지 확인
            print(f"[{time.strftime('%H:%M:%S')}] ⏳ MySQL DB 연결 시도 중...")
            
            db_connection = pymysql.connect(
                host=DATABASE_CONFIG['host'],
                user=DATABASE_CONFIG['user'],
                password=DATABASE_CONFIG['password'],
                database=DATABASE_CONFIG['database'],
                cursorclass=pymysql.cursors.DictCursor,
                # ⭐️ 핵심 수정: 타임아웃을 5초로 설정합니다.
                connect_timeout=CONNECT_TIMEOUT 
            )
            print("✅ MySQL DB 연결 성공!")
        except pymysql.err.OperationalError as e:
            # 타임아웃이나 접근 오류 등 연결 관련 오류를 구체적으로 잡습니다.
            print(f"❌ MySQL DB 연결 실패 (OperationalError): {e}")
            db_connection = None
        except Exception as e:
            # 그 외의 일반 오류
            print(f"❌ MySQL DB 연결 실패 (기타 오류): {e}")
            db_connection = None
            
    return db_connection
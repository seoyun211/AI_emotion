# database/session.py
import os
import pymysql
from dotenv import load_dotenv
from pymysql.cursors import DictCursor

load_dotenv()


def get_db_connection():
    conn = pymysql.connect(
        host=os.getenv("DB_HOST", "127.0.0.1"),
        user=os.getenv("DB_USER", "root"),
        password=os.getenv("DB_PASSWORD", ""),
        database=os.getenv("DB_NAME", "emotion_analysis_app"),
        port=int(os.getenv("DB_PORT", "3306")),
        charset="utf8mb4",
        cursorclass=DictCursor,
        autocommit=False,
        connect_timeout=10,
        read_timeout=30,
        write_timeout=30,
    )
    # 끊겼으면 자동 재연결
    try:
        conn.ping(reconnect=True)
    except Exception:
        pass
    return conn

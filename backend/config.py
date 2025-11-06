# config.py
import os
from pathlib import Path
from dotenv import load_dotenv, find_dotenv

# ① 가장 안전: 이 파일이 있는 폴더의 .env를 지정
ENV_PATH = Path(__file__).resolve().parent / ".env"
if ENV_PATH.exists():
    load_dotenv(dotenv_path=ENV_PATH)
else:
    # ② 그래도 못 찾으면 상위 경로로 탐색
    load_dotenv(find_dotenv())

# --- 이하 그대로 ---
APP_CONFIG = { ... }

JWT_CONFIG = {
    "secret_key": os.getenv("JWT_SECRET_KEY", "your-secret-key-change-in-production"),
    "algorithm": "HS256",
    "access_token_expire_minutes": 60 * 24,
}

MONGODB_URL = os.getenv("MONGODB_URL")
if not MONGODB_URL:
    raise RuntimeError("MONGODB_URL is not set. Put your Atlas SRV URI in .env")

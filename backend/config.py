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

# 모델 서버 설정
MODEL_SERVERS = {
    "text_model": {
        "url": "https://your-text-model.com/predict",
        "timeout": 30,
        "enabled": True
    },
    "voice_model": {
        "url": "https://your-voice-model.com/analyze",
        "timeout": 60,
        "enabled": True
    },
    "face_model": {
        "url": "https://your-face-model.com/detect",
        "timeout": 60,
        "enabled": True
    }
}

# 모델 가중치
MODEL_WEIGHTS = {
    "text": 0.4,
    "voice": 0.3,
    "face": 0.3
}

# 감정 분석 설정
EMOTION_CONFIG = {
    "risk_threshold": 0.7,
    "high_risk_emotions": ["슬픔", "분노", "불안"]
}

# 데이터베이스 설정(MySQL)
DATABASE_CONFIG = {
    "host": os.getenv("DB_HOST", "127.0.0.1"),
    "port": int(os.getenv("DB_PORT", 3306)),
    "user": os.getenv("DB_USER", "root"),
    "password": os.getenv("DB_PASSWORD", "root"),
    "database": os.getenv("DB_NAME", "emotion_analysis_app"),
    "dialect": "mysql",
    "driver": "pymysql"
}

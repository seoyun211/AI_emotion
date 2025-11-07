import os
from dotenv import load_dotenv

load_dotenv()

# 앱 설정
APP_CONFIG = {
    "title": "말동이 감정 분석 API",
    "description": "노인 감정 분석 및 보호자 알림 시스템",
    "version": "2.0.0",
    "host": "0.0.0.0",
    "port": 8080
}

# CORS 설정
CORS_CONFIG = {
    "allow_origins": [
        "http://localhost:3000",
        "http://127.0.0.1:3000",
        "http://localhost:3001", 
        "http://127.0.0.1:3001"
    ],
    "allow_credentials": True,
    "allow_methods": ["*"],
    "allow_headers": ["*"]
}

# JWT 설정
JWT_CONFIG = {
    "secret_key": os.getenv("JWT_SECRET_KEY", "your-secret-key-change-in-production"),
    "algorithm": "HS256",
    "access_token_expire_minutes": 60 * 24  # 24시간
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
    "password": os.getenv("DB_PASSWORD", "your_mysql_root_password"), # 기본값은 보안에 취약하므로 실제 비밀번호를 .env에 설정하세요.
    "database": os.getenv("DB_NAME", "emotion_analysis_app"),
    "dialect": "mysql",
    "driver": "pymysql" # Python MySQL 드라이버 (프로젝트에서 어떤 라이브러리를 쓰는지에 따라 변경될 수 있음)
}
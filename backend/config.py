# backend/config.py

# 모델 서버 주소 (나중에 코랩 모델 배포하면 여기만 변경)
MODEL_SERVERS = {
    "text_analysis": "https://future-text-model.com/predict",  # 임시 주소
    "voice_analysis": "https://future-voice-model.com/analyze", 
    "face_analysis": "https://future-face-model.com/analyze"
}

# 서버 설정
SERVER_CONFIG = {
    "host": "0.0.0.0",
    "port": 8080
}

# 감정 설정(추가 부탁)
EMOTION_LABELS = {
    0: "기쁨",
    1: "슬픔", 
    2: "분노",
    3: "불안",
    4: "중립"
}
# 🧠 기본 감정 분석
def analyze_emotion(text: str) -> dict:
    """텍스트 기반 감정 분석"""
    text_lower = text.lower()
    
    # 감정 키워드 분석
    positive_keywords = ["기뻐", "좋아", "행복", "즐거워", "감사", "사랑", "기쁘", "신나"]
    negative_keywords = ["슬퍼", "우울", "화나", "분노", "불안", "힘들어", "외로워", "짜증", "속상"]
    anxiety_keywords = ["불안", "걱정", "무서워", "두려워", "긴장"]
    anger_keywords = ["화나", "분노", "짜증", "열받", "화남"]
    
    positive_count = sum(1 for keyword in positive_keywords if keyword in text_lower)
    negative_count = sum(1 for keyword in negative_keywords if keyword in text_lower)
    anxiety_count = sum(1 for keyword in anxiety_keywords if keyword in text_lower)
    anger_count = sum(1 for keyword in anger_keywords if keyword in text_lower)
    
    # 감정 판별
    if anger_count > 0:
        emotion = "분노"
        confidence = min(0.7 + (anger_count * 0.1), 0.95)
        risk_score = min(0.8 + (anger_count * 0.05), 0.95)
    elif anxiety_count > 0:
        emotion = "불안"
        confidence = min(0.65 + (anxiety_count * 0.1), 0.9)
        risk_score = min(0.7 + (anxiety_count * 0.05), 0.9)
    elif negative_count > positive_count:
        emotion = "슬픔"
        confidence = min(0.6 + (negative_count * 0.08), 0.85)
        risk_score = min(0.75 + (negative_count * 0.03), 0.9)
    elif positive_count > negative_count:
        emotion = "기쁨"
        confidence = min(0.7 + (positive_count * 0.08), 0.9)
        risk_score = max(0.1 - (positive_count * 0.02), 0.05)
    else:
        emotion = "중립"
        confidence = 0.5
        risk_score = 0.3
    
    needs_alert = risk_score > 0.7
    
    return {
        "emotion": emotion,
        "confidence": round(confidence, 3),
        "risk_score": round(risk_score, 3),
        "needs_alert": needs_alert
    }
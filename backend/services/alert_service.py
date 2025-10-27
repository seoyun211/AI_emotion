# 🚨 알림 서비스
from database.crud import AlertCRUD
from typing import Dict

class AlertService:
    @staticmethod
    async def send_emotion_alert(guardian_id: str, elder_name: str, emotion_data: Dict):
        """감정 기반 알림 전송"""
        emotion = emotion_data["emotion"]
        risk_score = emotion_data["risk_score"]
        
        if risk_score > 0.7:
            alert_level = "high"
            message = f"🚨 {elder_name}님에게 위험 감정({emotion})이 감지되었습니다. 즉시 확인이 필요합니다."
        elif risk_score > 0.4:
            alert_level = "medium"
            message = f"⚠️ {elder_name}님에게 관심이 필요한 감정({emotion})이 감지되었습니다."
        else:
            alert_level = "low"
            message = f"ℹ️ {elder_name}님의 감정 상태: {emotion}"
        
        alert_data = {
            "guardian_id": guardian_id,
            "elder_name": elder_name,
            "message": message,
            "alert_level": alert_level,
            "emotion": emotion,
            "risk_score": risk_score
        }
        
        await AlertCRUD.create_alert(alert_data)
        return {"sent": True, "level": alert_level}

# 전역 서비스 인스턴스
alert_service = AlertService()
from typing import Dict, Optional
import asyncio
# 전부 임시
class VoiceClient:
    """음성 감정 분석 모델의 최소 인터페이스"""
    # 현재는 모델이 없으므로 비활성화 (리소스 절약)
    enabled = False 

    def __init__(self):
        print("💡 VoiceClient 모델 인터페이스 로드 완료.")
        # 여기에 실제 모델 로드 코드를 나중에 추가합니다.

    async def analyze_emotion(self, audio_data: bytes, user_id: Optional[str] = None) -> Dict:
        """[임시 로직] 실제 모델이 구현될 때까지 Mock 결과를 반환합니다."""
        if not self.enabled:
            return {"success": False, "model": "voice_mock", "emotion": "N/A", "confidence": 0.0, "risk_score": 0.0}

        await asyncio.sleep(0.01) 
        
        # 임시 Mock 결과
        return {
            "success": True,
            "model": "voice_mock",
            "emotion": "슬픔",
            "confidence": 0.6,
            "risk_score": 0.5,
            "needs_alert": False
        }

# 🚨 emotion_service에서 임포트하기 위한 인스턴스 정의
voice_client = VoiceClient()
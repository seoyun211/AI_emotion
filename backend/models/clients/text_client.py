# backend/models/clients/text_client.py

from typing import Dict, Optional
import asyncio
# 전부 임시
class TextClient:
    """텍스트 감정 분석 모델의 최소 인터페이스 (모델 추론은 나중에 추가)"""
    
    # emotion_service에서 enabled를 체크하므로, True로 설정
    enabled = True 

    def __init__(self):
        print("💡 TextClient 모델 인터페이스 로드 완료.")
        # 여기에 실제 모델(BERT 등)을 로드하는 코드를 나중에 추가합니다.
        
    async def analyze_emotion(self, text: str, user_id: Optional[str] = None) -> Dict:
        """
        [임시 로직] 실제 모델이 구현될 때까지 Mock 결과를 반환합니다.
        emotion_service가 await로 호출하므로 async 함수로 유지해야 합니다.
        """
        # 비동기 환경을 막지 않도록 잠시 대기
        await asyncio.sleep(0.01) 
        
        # 임시 Mock 결과 (나중에 삭제하고 모델 추론 결과로 대체)
        return {
            "success": True,
            "model": "text_mock",
            "emotion": "중립",
            "confidence": 0.5,
            "risk_score": 0.3,
            "needs_alert": False
        }

# 🚨 임포트 오류를 해결하기 위한 핵심: 인스턴스 생성 🚨
text_client = TextClient()
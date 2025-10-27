# 😊 감정 분석 서비스
from models.clients import text_client, voice_client, face_client, client_manager
from models.emotion_analyzer import analyze_emotion
from config import MODEL_WEIGHTS
import asyncio
from typing import Dict, List

class EmotionService:
    @staticmethod
    async def analyze_text_emotion(text: str, user_id: str = None) -> Dict:
        """텍스트 감정 분석 (멀티모델)"""
        tasks = []
        
        # 기본 감정 분석
        basic_result = analyze_emotion(text)
        tasks.append(asyncio.create_task(asyncio.sleep(0).__await__().__iter__().__next__()))
        
        # 외부 모델 호출 (활성화된 경우)
        if text_client.enabled:
            tasks.append(asyncio.create_task(text_client.analyze_emotion(text, user_id)))
        
        # 기본 결과를 첫 번째 결과로 설정
        results = [basic_result]
        
        # 외부 모델 결과 수집
        external_results = await asyncio.gather(*tasks[1:], return_exceptions=True)
        results.extend([r for r in external_results if not isinstance(r, Exception)])
        
        # 결과 통합
        return await EmotionService._integrate_results(results, "text")
    
    @staticmethod
    async def _integrate_results(results: List, analysis_type: str) -> Dict:
        """여러 모델 결과 통합"""
        valid_results = []
        
        for result in results:
            if isinstance(result, Exception):
                continue
            if result.get("success", True):  # 성공한 결과만
                valid_results.append(result)
        
        if not valid_results:
            # 모든 모델 실패 시 기본값 반환
            return {
                "emotion": "중립",
                "confidence": 0.0,
                "risk_score": 0.3,
                "needs_alert": False,
                "models_used": [],
                "integrated": False
            }
        
        # 가중치 기반 통합
        final_emotion = await EmotionService._weighted_integration(valid_results)
        
        return {
            **final_emotion,
            "models_used": [r.get("model", "basic") for r in valid_results],
            "integrated": len(valid_results) > 1
        }
    
    @staticmethod
    async def _weighted_integration(results: List[Dict]) -> Dict:
        """가중치 기반 감정 통합"""
        emotion_scores = {}
        confidence_sum = 0
        
        for result in results:
            emotion = result["emotion"]
            confidence = result["confidence"]
            model_type = result.get("model", "basic")
            
            # 모델별 가중치 적용
            weight = MODEL_WEIGHTS.get(model_type, 0.5)
            weighted_confidence = confidence * weight
            
            if emotion not in emotion_scores:
                emotion_scores[emotion] = 0
            
            emotion_scores[emotion] += weighted_confidence
            confidence_sum += weighted_confidence
        
        # 가장 높은 점수의 감정 선택
        if emotion_scores:
            final_emotion = max(emotion_scores.items(), key=lambda x: x[1])
            final_confidence = final_emotion[1] / confidence_sum if confidence_sum > 0 else 0
            
            # 위험도 계산 (가중 평균)
            risk_scores = [r["risk_score"] * MODEL_WEIGHTS.get(r.get("model", "basic"), 0.5) 
                          for r in results]
            total_weight = sum(MODEL_WEIGHTS.get(r.get("model", "basic"), 0.5) for r in results)
            final_risk = sum(risk_scores) / total_weight if total_weight > 0 else 0.3
            
            return {
                "emotion": final_emotion[0],
                "confidence": round(final_confidence, 3),
                "risk_score": round(final_risk, 3),
                "needs_alert": final_risk > 0.7
            }
        
        return {
            "emotion": "중립",
            "confidence": 0.0,
            "risk_score": 0.3,
            "needs_alert": False
        }

# 전역 서비스 인스턴스
emotion_service = EmotionService()
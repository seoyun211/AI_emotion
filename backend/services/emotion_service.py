# backend/services/emotion_service.py

from models.clients.multimodal_client import multimodal_client
from models.emotion_analyzer import analyze_emotion  # 텍스트 기본 감정 분석 모델
from config import MODEL_WEIGHTS
from database.session import get_db_connection

import asyncio
from typing import Dict, List, Any, Optional
import uuid
from datetime import datetime
from fastapi import HTTPException


class EmotionService:
    @staticmethod
    async def analyze_text_emotion(text: str, user_id: Optional[str] = None) -> Dict:
        """
        텍스트-only 감정 분석.
        지금은 내부 BERT 기반 analyze_emotion(text) 결과만 사용.
        """
        basic_result = analyze_emotion(text)  # 동기 함수라고 가정
        # basic_result 형식 예:
        # {"emotion": "...", "confidence": 0.8, "risk_score": 0.2, "model": "text"}

        # 통합 로직 재사용 (실제로는 모델 1개지만, 구조 통일을 위해 사용)
        return await EmotionService._integrate_results([basic_result], "text")
    
    @staticmethod
    async def analyze_multimodal_emotion(
        text: Optional[str],
        image_bytes: Optional[bytes],
        audio_bytes: Optional[bytes],
        user_id: Optional[str] = None,
    ) -> Dict:
        """
        ✅ 통합 퓨전 모델(이미지+텍스트+음성)을 사용하는 감정 분석
        - multimodal_client(= EmotionAnalyzer 래퍼)를 한 번만 호출
        """
        fusion_result = await multimodal_client.analyze_emotion(
            text=text,
            image_bytes=image_bytes,
            audio_bytes=audio_bytes,
            user_id=user_id,
        )

        # 기존 통합 로직(_integrate_results)을 재사용
        integrated = await EmotionService._integrate_results(
            [fusion_result],
            analysis_type="multimodal",
        )
        return integrated

    @staticmethod
    async def _integrate_results(results: List[Dict], analysis_type: str) -> Dict:
        """여러 모델 결과 통합"""
        valid_results: List[Dict] = []
        
        for result in results:
            if isinstance(result, Exception):
                continue
            if result.get("success", True):  # success 키 없으면 True로 간주
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
        emotion_scores: Dict[str, float] = {}
        confidence_sum = 0.0
        
        for result in results:
            emotion = result["emotion"]
            confidence = result["confidence"]
            model_type = result.get("model", "basic")
            
            # 모델별 가중치 적용
            weight = MODEL_WEIGHTS.get(model_type, 0.5)
            weighted_confidence = confidence * weight
            
            if emotion not in emotion_scores:
                emotion_scores[emotion] = 0.0
            
            emotion_scores[emotion] += weighted_confidence
            confidence_sum += weighted_confidence
        
        # 가장 높은 점수의 감정 선택
        if emotion_scores:
            final_emotion = max(emotion_scores.items(), key=lambda x: x[1])
            final_confidence = final_emotion[1] / confidence_sum if confidence_sum > 0 else 0.0
            
            # 위험도 계산 (가중 평균)
            risk_scores = [
                r["risk_score"] * MODEL_WEIGHTS.get(r.get("model", "basic"), 0.5)
                for r in results
            ]
            total_weight = sum(
                MODEL_WEIGHTS.get(r.get("model", "basic"), 0.5)
                for r in results
            )
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


# ------------------------------
# 💾 DB 저장 함수
# ------------------------------

def save_analysis_chunk(
    text: str,
    emotion: str,
    risk_score: float,
    analysis_id: str,
    user_id: Optional[str] = None,
) -> str:
    """분석 결과를 DB의 AnalysisChunk 테이블에 저장합니다."""
    conn = get_db_connection()
    if not conn:
        return " (DB 연결 실패로 저장 불가)"

    try:
        with conn.cursor() as cursor:
            sql = """
            INSERT INTO AnalysisChunk
            (session_id, user_id, analysis_id, analysis_time, 
             text_result, audio_result, face_result, risk_score, final_result) 
            VALUES (%s, %s, %s, NOW(), 
                    %s, NULL, NULL, %s, %s)
            """
            cursor.execute(sql, (
                1,                      # 1. session_id (int)
                1,                      # 2. user_id (int)  (나중에 실제 user_id로 교체 가능)
                analysis_id,            # 3. analysis_id (str/UUID)
                # 4. analysis_time은 NOW()
                text,                   # 5. text_result
                risk_score,             # 6. risk_score
                emotion                 # 7. final_result
            ))
        conn.commit()
        return " 및 DB 저장 완료"

    except Exception as db_e:
        conn.rollback()
        print(f"❌❌ 최종 DB INSERT 실패 오류 (로그용): {db_e}") 
        return f"DB 저장 실패: {db_e}"
    


# ------------------------------
# 🚀 최종 통합 실행 함수 (라우터에서 호출)
# ------------------------------

async def process_emotion_analysis(
    text: str,
    user_id: Optional[str] = None,
    image_bytes: Optional[bytes] = None,
    audio_bytes: Optional[bytes] = None,
) -> Dict[str, Any]:
    """
    감정 분석을 실행하고 DB에 저장 후 결과를 반환하는 통합 함수
    - audio_bytes / image_bytes 가 있으면 👉 멀티모달(퓨전 모델)
    - 없으면 👉 텍스트-only 분석
    """
    # 1. 감정 분석 실행
    if audio_bytes is not None or image_bytes is not None:
        # 🔥 멀티모달(퓨전) 사용
        analysis_result = await emotion_service.analyze_multimodal_emotion(
            text=text,
            image_bytes=image_bytes,
            audio_bytes=audio_bytes,
            user_id=user_id,
        )
    else:
        # 텍스트-only
        analysis_result = await emotion_service.analyze_text_emotion(text, user_id)
    
    analysis_id = str(uuid.uuid4())
    current_time = datetime.now()
    
    # 2. 분석 결과 DB 저장
    db_message = await asyncio.to_thread(
        save_analysis_chunk, 
        text=text, 
        emotion=analysis_result["emotion"], 
        risk_score=analysis_result["risk_score"],
        analysis_id=analysis_id,
        user_id=user_id,
    )
    if db_message.startswith("DB 저장 실패:"):
        raise HTTPException(status_code=500, detail=f"감정 분석 중 오류: {db_message}")
    
    # 3. 최종 결과 반환
    return {
        **analysis_result,
        "analysis_id": analysis_id,
        "user_id": user_id,
        "timestamp": current_time,
        "message": "감정 분석 완료" + db_message
    }

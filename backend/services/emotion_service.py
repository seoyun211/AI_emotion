# backend/services/emotion_service.py

# --- 임포트 ---
from models.clients.text_client import text_client
from models.clients.voice_client import voice_client
from models.clients.face_client import face_client
from models.clients.multimodal_client import client_manager

from models.emotion_analyzer import analyze_emotion # 실제 감정 분석 모델 함수
from config import MODEL_WEIGHTS
from database.session import get_db_connection

import asyncio
from typing import Dict, List, Any, Optional
import uuid
from datetime import datetime
from fastapi import HTTPException

# -----------------------------------------------------
# EmotionService 클래스 (분석/통합 로직만 담당)
# -----------------------------------------------------

class EmotionService:
    @staticmethod
    async def analyze_text_emotion(text: str, user_id: Optional[str] = None) -> Dict:
        """텍스트 감정 분석 (멀티모델)"""
        tasks = []
        
        # 🚨 1. 기본 감정 분석 (동기 함수이므로 바로 실행)
        basic_result = analyze_emotion(text) 
        
        # 🚨 2. 외부 모델 호출 (비동기이므로 tasks에 추가)
        if text_client.enabled:
            # tasks.append(asyncio.create_task(asyncio.sleep(0).__await__().__iter__().__next__())) 
            # ☝️ 이 불필요한 줄을 제거하고
            tasks.append(asyncio.create_task(text_client.analyze_emotion(text, user_id)))
        
        # 기본 결과를 첫 번째 결과로 설정 (tasks가 비어있을 수 있으므로 주의)
        results = [basic_result]
        
        # 3. 외부 모델 결과 수집 (비동기 결과만 gather)
        if tasks:
             external_results = await asyncio.gather(*tasks, return_exceptions=True)
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
    

# -----------------------------------------------------
# 🚨 전역 서비스 인스턴스 (클래스 정의 직후)
# -----------------------------------------------------
emotion_service = EmotionService()


# -----------------------------------------------------
# 💾 DB 저장 함수 (클래스 외부에 정의)
# -----------------------------------------------------

def save_analysis_chunk(text: str, emotion: str, risk_score: float, analysis_id: str, user_id: Optional[str] = None) -> str:
    """분석 결과를 DB의 AnalysisChunk 테이블에 저장합니다."""
    conn = get_db_connection()
    if not conn:
        return " (DB 연결 실패로 저장 불가)"

    try:
        with conn.cursor() as cursor:
            # 🚨 쿼리가 7개의 컬럼과 7개의 %s를 가지도록 수정 (risk_score가 포함되어야 함)
            sql = """
            INSERT INTO AnalysisChunk
            (session_id, user_id, analysis_id, analysis_time, 
             text_result, audio_result, face_result, risk_score, final_result) 
            VALUES (%s, %s, %s, NOW(), 
                    %s, NULL, NULL, %s, %s)
            """
            cursor.execute(sql, (
                1,                      # 1. session_id (int)
                1,                      # 2. user_id (int) 
                analysis_id,            # 3. analysis_id (str/UUID)
                # 4. analysis_time은 NOW()로 처리
                text,                   # 5. text_result (str, 입력 텍스트)
                risk_score,             # 6. risk_score (float)
                emotion                 # 7. final_result (str, 분석된 감정)
            ))
        conn.commit()
        return " 및 DB 저장 완료"

    except Exception as db_e:
        conn.rollback()
        # 🚨🚨 터미널에 출력 (로그용)
        print(f"❌❌ 최종 DB INSERT 실패 오류 (로그용): {db_e}") 
        # 🚨🚨 오류 메시지를 문자열로 반환 (핵심 변경)
        return f"DB 저장 실패: {db_e}"
    


# -----------------------------------------------------
# 🚀 최종 통합 실행 함수 (라우터에서 호출됨)
# -----------------------------------------------------

async def process_emotion_analysis(text: str, user_id: Optional[str] = None) -> Dict[str, Any]:
    """감정 분석을 실행하고 DB에 저장 후 결과를 반환하는 통합 함수"""
    
    # 1. 멀티모델 감정 분석 실행 (EmotionService 인스턴스를 통해 메서드 호출)
    analysis_result = await emotion_service.analyze_text_emotion(text, user_id)
    
    analysis_id = str(uuid.uuid4())
    current_time = datetime.now()
    
    # 2. 분석 결과 DB 저장 (클래스 외부 함수 호출)
    db_message = await asyncio.to_thread(
        save_analysis_chunk, 
        text=text, 
        emotion=analysis_result['emotion'], 
        risk_score=analysis_result['risk_score'],
        analysis_id=analysis_id,
        user_id=user_id
    )
    if db_message.startswith("DB 저장 실패:"):
        # FastAPI 라우터가 이 예외를 catch하여 500 응답으로 변환합니다.
        raise HTTPException(status_code=500, detail=f"감정 분석 중 오류: {db_message}")
    
    # 3. 최종 결과 반환
    return {
        **analysis_result,
        "analysis_id": analysis_id,
        "user_id": user_id,
        "timestamp": current_time,
        "message": "감정 분석 완료" + db_message
    }   
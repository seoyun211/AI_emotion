 # 🔧 도우미 함수
import uuid
from datetime import datetime
from typing import Any, Dict

def generate_id() -> str:
    """고유 ID 생성"""
    return str(uuid.uuid4())

def get_current_time() -> str:
    """현재 시간 문자열 반환"""
    return datetime.now().isoformat()

def safe_get(data: Dict, key: str, default: Any = None) -> Any:
    """안전한 딕셔너리 값 접근"""
    return data.get(key, default)

def format_emotion_result(result: Dict) -> Dict:
    """감정 결과 포맷팅"""
    return {
        "emotion": result.get("emotion", "중립"),
        "confidence": round(result.get("confidence", 0), 3),
        "risk_score": round(result.get("risk_score", 0.3), 3),
        "timestamp": get_current_time()
    }
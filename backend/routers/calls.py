from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel
from typing import Optional, List, Dict, Any
from datetime import datetime

from database.crud import SessionCRUD

# NOTE: SessionCRUD 내부에서 get_db_connection을 사용하므로 라우터에서 직접 임포트 불필요

router = APIRouter(prefix="/calls", tags=["통화 기록"])


# =========================================================================
# 1. 스키마 정의
# =========================================================================    
class CallResponse(BaseModel):
    session_id: int
    user_id: int
    start_time: datetime
    end_time: Optional[datetime] = None
    duration_seconds: Optional[int] = None
    full_transcript: Optional[str] = None 


class CallListResponse(BaseModel):
    calls: List[CallResponse]

# =========================================================================
# 2. API 엔드포인트 구현 (CRUD 직접 적용)
# =========================================================================

@router.get("/user/{user_id}", response_model=CallListResponse)
def get_call_history_by_user(user_id: int):
    """
    특정 유저(피보호자) 본인의 통화 기록 전체 조회 (최근 순)
    - Flutter 앱의 통화기록 화면에서 사용
    """
    try:
        # 💡 SessionCRUD.get_sessions_by_user_id 호출 (CRUD 함수 사용)
        session_data_list = SessionCRUD.get_sessions_by_user_id(
            user_id=user_id
        )

        calls: List[CallResponse] = []
        # DB에서 가져온 딕셔너리 리스트를 Pydantic 모델 리스트로 변환
        for row in session_data_list:
            calls.append(
                CallResponse(
                    session_id=row["session_id"],
                    user_id=row["user_id"],
                    # PyMySQL이 반환하는 datetime 객체나 포맷을 Pydantic이 처리합니다.
                    start_time=row["start_time"],
                    end_time=row["end_time"],
                    duration_seconds=row["duration_seconds"],
                    full_transcript=row["full_transcript"],
                )
            )

        return CallListResponse(calls=calls)

    except Exception as e:
        # SessionCRUD 내부에서 DB 연결 실패/롤백 등을 처리했으므로, 
        # 여기서는 최종적으로 500 오류를 반환합니다.
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, 
            detail=f"통화 기록 조회 실패: {e}"
        )
# routers/dialogue.py
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional
from datetime import datetime
import uuid

from database.session import get_db_connection

router = APIRouter(prefix="/dialogue", tags=["Dialogue"])

# -------------------------
# 요청 스키마
# -------------------------
class SessionStartResponse(BaseModel):
    session_id: int
    start_time: str

class SessionEndRequest(BaseModel):
    session_id: int
    user_id: int
    full_transcript: Optional[str] = None
    final_emotion: Optional[str] = None   # ✅ 없어도 되게
    risk_score: Optional[float] = None

# -------------------------
# 1) 세션 시작
# POST /api/v1/dialogue/session/start?user_id=1
# -------------------------
@router.post("/session/start", response_model=SessionStartResponse)
def start_session(user_id: int):
    conn = get_db_connection()
    try:
        now = datetime.now()
        with conn.cursor() as cur:
            sql = """
            INSERT INTO Session (user_id, start_time, end_time, duration_seconds, full_transcript)
            VALUES (%s, %s, NULL, NULL, NULL)
            """
            cur.execute(sql, (user_id, now))
        conn.commit()
        return SessionStartResponse(session_id=int(cur.lastrowid), start_time=now.isoformat())
    except Exception as e:
        try:
            conn.rollback()
        except Exception:
            pass
        raise HTTPException(status_code=500, detail=f"세션 시작 실패: {e}")
    finally:
        try:
            conn.close()
        except Exception:
            pass

# -------------------------
# 2) 세션 종료 + ✅ 통화 1번 = analysischunk 1개 저장
# POST /api/v1/dialogue/session/end
# -------------------------
@router.post("/session/end")
def end_session(payload: SessionEndRequest):
    conn = get_db_connection()
    try:
        end_time = datetime.now()

        # ✅ final_emotion 없으면 기본값(422 방지)
        final_emotion = (payload.final_emotion or "").strip() or "기쁨"
        risk_score = float(payload.risk_score) if payload.risk_score is not None else 0.0
        transcript = payload.full_transcript

        with conn.cursor() as cur:
            # 1) Session 업데이트
            sql_update = """
            UPDATE Session
            SET end_time = %s,
                full_transcript = %s,
                duration_seconds = TIMESTAMPDIFF(SECOND, start_time, %s)
            WHERE session_id = %s AND user_id = %s
            """
            cur.execute(
                sql_update,
                (end_time, transcript, end_time, payload.session_id, payload.user_id),
            )

            # 2) ✅ analysischunk에 1건만 저장
            sql_insert = """
            INSERT INTO analysischunk
              (session_id, user_id, analysis_id, analysis_time, risk_score, final_result)
            VALUES (%s, %s, %s, %s, %s, %s)
            """
            cur.execute(
                sql_insert,
                (
                    payload.session_id,
                    payload.user_id,
                    str(uuid.uuid4()),
                    end_time,
                    risk_score,
                    final_emotion,
                ),
            )

        conn.commit()
        return {
            "ok": True,
            "session_id": payload.session_id,
            "saved_emotion": final_emotion,
            "saved_at": end_time.isoformat(),
        }

    except Exception as e:
        try:
            conn.rollback()
        except Exception:
            pass
        raise HTTPException(status_code=500, detail=f"세션 종료 실패: {e}")
    finally:
        try:
            conn.close()
        except Exception:
            pass

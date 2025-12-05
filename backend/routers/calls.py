# routers/calls.py
from fastapi import APIRouter, HTTPException, UploadFile, File, status, Response
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime

from database.session import get_db_connection

from services.stt_service import convert_audio_to_text
from services.llm_service import get_llm_response
from services.tts_service import tts_synthesize_to_bytes

# (임시) 감정 분석 함수 정의 (실제로는 별도 서비스 파일에 분리되어야 함)
def analyze_emotion(text: str):
    # 실제 감정 분석 모델 호출 로직이 들어갈 자리입니다.
    # 일단은 텍스트 길이로 대충 처리
    emotion = "기쁨" if len(text) > 10 else "안정"
    return {
        "emotion": emotion,
        "confidence": 0.95,
        "risk_score": 0.10
    }

router = APIRouter(prefix="/api/v1/calls", tags=["통화 기록"])


class CallStartRequest(BaseModel):
    user_id: int # 통화 주체 회원 ID


class CallResponse(BaseModel):
    session_id: int
    user_id: int
    start_time: datetime
    end_time: Optional[datetime] = None
    duration_seconds: Optional[int] = None


class CallListResponse(BaseModel):
    calls: List[CallResponse]

class DialogueResponse(BaseModel):
    user_text: str
    maldong_response: str # maldongi -> maldong 변경
    emotion: str
    risk_score: float
    session_id: int


@router.post("/start", response_model=CallResponse)
def start_call(data: CallStartRequest):
    """
    통화 시작 기록 (Session 테이블)
    """
    conn = get_db_connection()
    try:
        now = datetime.now()
        with conn.cursor() as cur:
            sql = """
            INSERT INTO `Session` (user_id, start_time)
            VALUES (%s, %s)
            """
            cur.execute(sql, (data.user_id, now))
            conn.commit()
            session_id = cur.lastrowid

        return CallResponse(
            session_id=session_id,
            user_id=data.user_id,
            start_time=now,
            end_time=None,
            duration_seconds=None,
        )

    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=f"통화 시작 기록 실패: {e}")
    finally:
        conn.close()


@router.post("/{session_id}/end", response_model=CallResponse)
def end_call(session_id: int):
    """
    통화 종료 기록 + 통화지속시간 계산
    """
    conn = get_db_connection()
    try:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT user_id, start_time, end_time
                FROM `Session`
                WHERE session_id = %s
                """, # ✅ Session_id → session_id (컬럼명 소문자)
                (session_id,),
            )
            row = cur.fetchone()

            if not row:
                raise HTTPException(status_code=404, detail="통화 기록을 찾을 수 없습니다.")

            if row["end_time"] is not None:
                raise HTTPException(status_code=400, detail="이미 종료된 통화입니다.")

            start_time = row["start_time"]
            end_time = datetime.now()
            duration = int((end_time - start_time).total_seconds())

            update_sql = """
            UPDATE `Session`
            SET end_time = %s, duration_seconds = %s
            WHERE session_id = %s
            """
            cur.execute(update_sql, (end_time, duration, session_id))
            conn.commit()

        return CallResponse(
            session_id=session_id,
            user_id=row["user_id"],
            start_time=start_time,
            end_time=end_time,
            duration_seconds=duration,
        )

    except HTTPException:
        # 위에서 이미 적절한 상태코드로 던진 것들은 그대로 다시 raise
        raise
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=f"통화 종료 기록 실패: {e}")
    finally:
        conn.close()


@router.get("/user/{user_id}", response_model=CallListResponse)
def get_call_history_by_user(user_id: int):
    """
    특정 유저의 통화 기록 전체 조회 (최근 순)
    Flutter 통화기록 화면에서 사용하는 API
    """
    conn = get_db_connection()
    try:
        with conn.cursor() as cur:
            sql = """
            SELECT session_id, user_id, start_time, end_time, duration_seconds
            FROM `Session`
            WHERE user_id = %s
            ORDER BY start_time DESC
            """
            cur.execute(sql, (user_id,))
            rows = cur.fetchall()

        calls: List[CallResponse] = []
        for row in rows:
            calls.append(
                CallResponse(
                    session_id=row["session_id"],
                    user_id=row["user_id"],
                    start_time=row["start_time"],
                    end_time=row["end_time"],
                    duration_seconds=row["duration_seconds"],
                )
            )

        return CallListResponse(calls=calls)

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"통화 기록 조회 실패: {e}")
    finally:
        conn.close()

@router.post("/dialogue/{session_id}")
async def process_dialogue_turn(
    session_id: int, # 현재 진행 중인 통화(세션) ID
    audio_file: UploadFile = File(..., description="사용자 음성 파일")
):
    """
    STT, 감정 분석, LLM 응답 생성을 한 번에 처리하는 단일 대화 턴 엔드포인트.
    """
    conn = get_db_connection() # DB 연결을 통해 session_id 유효성 검사 및 로그 저장 가능
    try:
        # 1. 오디오 파일 데이터 읽기
        audio_data = await audio_file.read()
        
        if not audio_data:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="오디오 파일 데이터가 비어있습니다."
            )

        # 2. STT (Speech-to-Text) 수행
        user_text = convert_audio_to_text(audio_data)
        
        if "STT 처리 중 오류 발생" in user_text or user_text == "음성 인식 결과가 없습니다.":
            # 오류 발생 시, TTS를 거치지 않고 JSON 형태로 오류 메시지를 반환하는 것이 클라이언트 처리에는 더 안전합니다.
            return Response(
                content=f'{{"error": "STT 처리 오류 또는 결과 없음: {user_text}"}}',
                media_type="application/json",
                status_code=500
            )
        
        # 3. 감정 분석 및 위험도 판단
        analysis_result = analyze_emotion(user_text)

        # 4. LLM 서비스 호출 (말동이 응답 생성)
        # maldongi_response_text -> maldong_response_text 변수명 변경
        maldong_response_text = get_llm_response( 
            user_text=user_text,
            emotion=analysis_result["emotion"],
            confidence=analysis_result["confidence"],
            risk_score=analysis_result["risk_score"]
        )
        
        # 5. DB에 대화 로그 저장 (Dialogue 테이블에 session_id와 함께 저장)
        now = datetime.now()
        
        insert_dialogue_sql = """
        INSERT INTO `Dialogue` 
            (session_id, user_text, maldong_response, emotion, risk_score, timestamp) # DB 컬럼명 maldong_response로 가정
        VALUES 
            (%s, %s, %s, %s, %s, %s)
        """
        with conn.cursor() as cur:
            cur.execute(
                insert_dialogue_sql, 
                (
                    session_id, 
                    user_text, 
                    maldong_response_text, # 변수명 변경 반영
                    analysis_result["emotion"], 
                    analysis_result["risk_score"], 
                    now
                )
            )
            conn.commit()

        # 6. TTS (Text-to-Speech) 수행 및 음성 바이트 생성
        audio_content = await tts_synthesize_to_bytes(maldong_response_text) # 변수명 변경 반영
        if audio_content is None:
            # TTS 생성 실패 시
             return Response(
                content='{"error": "TTS 음성 파일 생성에 실패했습니다."}',
                media_type="application/json",
                status_code=500
            )


        # 7. 결과 반환: MP3 파일 스트림을 직접 반환
        return Response(
            content=audio_content,
            media_type="audio/mp3",
            headers={
                "X-Maldong-Text": maldong_response_text,
                 "X-User-STT-Text": user_text, # 헤더명 및 변수명 변경 반영
                }
        )
        
    except HTTPException:
        conn.rollback() 
        raise
    except Exception as e:
        conn.rollback()
        # 기타 오류 처리 시 JSON으로 응답
        return Response(
            content=f'{{"error": "대화 처리 중 서버 오류 발생: {e}"}}',
            media_type="application/json",
            status_code=500
        )
    finally:
        conn.close()
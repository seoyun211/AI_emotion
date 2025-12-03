# backend/routers/guardian.py

from fastapi import APIRouter, HTTPException
from datetime import datetime, timedelta

# ❗ 무조건 session.py의 get_db_connection만 사용
from database.session import get_db_connection

router = APIRouter(prefix="/api/v1/guardian", tags=["보호자"])


# ---------------- 공통 유틸 ----------------

def map_emotion_label(emotion: str) -> str:
    if not emotion:
        return "3"

    emotion_lower = str(emotion).lower()

    if emotion_lower in ["positive", "happy", "joy", "pleased", "excited"]:
        return "0"
    elif emotion_lower in ["anger", "angry", "annoyed", "irritated", "mad"]:
        return "2"
    elif emotion_lower in ["anxiety", "anxious", "fear", "worried", "nervous", "stress"]:
        return "3"
    elif emotion_lower in ["sad", "sadness", "depressed", "unhappy", "negative", "critical"]:
        return "5"
    else:
        return "3"


def get_emotion_korean_name(emotion_label: str) -> str:
    mapping = {
        "0": "기쁨",
        "2": "분노",
        "3": "불안",
        "5": "슬픔",
    }
    return mapping.get(emotion_label, "불안")


def calculate_severity(emotion_label: str, risk_score: float) -> str:
    if emotion_label == "0":
        return "긍정"
    elif emotion_label == "3" and risk_score < 0.4:
        return "보통"
    elif emotion_label in ["2", "3"] and 0.4 <= risk_score < 0.7:
        return "부정"
    elif emotion_label == "5" or risk_score >= 0.7:
        return "심각"
    else:
        return "보통"


def _get_ward_user_id(conn, guardian_user_id: int) -> int:
    """
    GuardianRelationship 에서 ward_user_id 하나 가져오기 (없으면 404)
    DictCursor 기준: row는 dict 이다.
    """
    cursor = conn.cursor()
    cursor.execute(
        """
        SELECT ward_user_id
        FROM GuardianRelationship
        WHERE guardian_user_id = %s
          AND status = 'active'
        LIMIT 1
        """,
        (guardian_user_id,),
    )
    row = cursor.fetchone()
    print("🔎 GuardianRelationship row:", row)

    if not row:
        raise HTTPException(status_code=404, detail="연동된 어르신을 찾을 수 없습니다")

    # row: {"ward_user_id": 3}
    return row["ward_user_id"]


# ---------------- 1) 어르신 기본 정보 ----------------

@router.get("/ward-info/{guardian_user_id}")
def get_ward_info(guardian_user_id: int):
    conn = get_db_connection()
    if not conn:
        raise HTTPException(status_code=500, detail="DB 연결 실패")

    try:
        print("✅ ward-info guardian_user_id =", guardian_user_id)
        ward_user_id = _get_ward_user_id(conn, guardian_user_id)
        print("✅ 찾은 ward_user_id =", ward_user_id)

        cursor = conn.cursor()
        cursor.execute(
            """
            SELECT user_id, username, user_phone
            FROM User
            WHERE user_id = %s
            """,
            (ward_user_id,),
        )
        row = cursor.fetchone()
        cursor.close()
        print("✅ User row:", row)

        if not row:
            raise HTTPException(status_code=404, detail="연동된 어르신을 찾을 수 없습니다")

        # row: {"user_id": ..., "username": ..., "user_phone": ...}
        return {
            "user_id": row["user_id"],
            "username": row["username"],
            "user_phone": row["user_phone"],
        }

    except HTTPException:
        raise
    except Exception as e:
        import traceback
        traceback.print_exc()  # 🔥 터미널에 전체 스택 출력
        print("❌ ward-info 내부 에러 type:", type(e), "args:", getattr(e, "args", None))
        raise HTTPException(status_code=500, detail=f"정보 조회 실패: {repr(e)}")
    finally:
        conn.close()


# ---------------- 2) 최근 N일 감정 리스트 ----------------

@router.get("/ward-emotions/{guardian_user_id}")
def get_ward_emotions(guardian_user_id: int, days: int = 30):
    conn = get_db_connection()
    if not conn:
        raise HTTPException(status_code=500, detail="DB 연결 실패")

    try:
        ward_user_id = _get_ward_user_id(conn, guardian_user_id)
        cursor = conn.cursor()

        start_date = datetime.now() - timedelta(days=days)
        cursor.execute(
            """
            SELECT 
                DATE(analysis_time) AS date,
                final_result        AS emotion,
                AVG(risk_score)     AS avg_risk_score
            FROM AnalysisChunk
            WHERE user_id = %s
              AND analysis_time >= %s
            GROUP BY DATE(analysis_time), final_result
            ORDER BY DATE(analysis_time) DESC
            """,
            (ward_user_id, start_date),
        )
        rows = cursor.fetchall()
        cursor.close()
        print("✅ ward-emotions rows:", rows)

        result = []
        for row in rows:
            # row: {"date": ..., "emotion": ..., "avg_risk_score": ...}
            date_value = row["date"]
            emotion_raw = row["emotion"]
            avg_risk = float(row["avg_risk_score"] or 0.0)

            label = map_emotion_label(emotion_raw)
            name = get_emotion_korean_name(label)
            severity = calculate_severity(label, avg_risk)

            # pymysql DictCursor 에서 date는 datetime.date / datetime 둘 중 하나
            if hasattr(date_value, "strftime"):
                date_str = date_value.strftime("%Y-%m-%d")
            else:
                date_str = str(date_value)

            result.append(
                {
                    "date": date_str,
                    "emotion": label,
                    "emotion_name": name,
                    "severity": severity,
                    "avg_risk_score": round(avg_risk, 2),
                }
            )

        return result

    except HTTPException:
        raise
    except Exception as e:
        import traceback
        traceback.print_exc()
        print("❌ ward-emotions 내부 에러 type:", type(e), "args:", getattr(e, "args", None))
        raise HTTPException(status_code=500, detail=f"데이터 조회 실패: {repr(e)}")
    finally:
        conn.close()


# ---------------- 3) N일간 감정 통계 ----------------

@router.get("/emotion-stats/{guardian_user_id}")
def get_emotion_stats(guardian_user_id: int, days: int = 30):
    conn = get_db_connection()
    if not conn:
        raise HTTPException(status_code=500, detail="DB 연결 실패")

    try:
        ward_user_id = _get_ward_user_id(conn, guardian_user_id)
        cursor = conn.cursor()

        start_date = datetime.now() - timedelta(days=days)
        cursor.execute(
            """
            SELECT 
                final_result    AS emotion,
                AVG(risk_score) AS avg_risk_score
            FROM AnalysisChunk
            WHERE user_id = %s
              AND analysis_time >= %s
            GROUP BY DATE(analysis_time), final_result
            """,
            (ward_user_id, start_date),
        )
        rows = cursor.fetchall()
        cursor.close()
        print("✅ emotion-stats rows:", rows)

        stats = {
            "positive": 0,
            "normal": 0,
            "negative": 0,
            "serious": 0,
        }

        for row in rows:
            # row: {"emotion": ..., "avg_risk_score": ...}
            emotion_raw = row["emotion"]
            avg_risk = float(row["avg_risk_score"] or 0.0)

            label = map_emotion_label(emotion_raw)
            severity = calculate_severity(label, avg_risk)

            if severity == "긍정":
                stats["positive"] += 1
            elif severity == "보통":
                stats["normal"] += 1
            elif severity == "부정":
                stats["negative"] += 1
            elif severity == "심각":
                stats["serious"] += 1

        return stats

    except HTTPException:
        raise
    except Exception as e:
        import traceback
        traceback.print_exc()
        print("❌ emotion-stats 내부 에러 type:", type(e), "args:", getattr(e, "args", None))
        raise HTTPException(status_code=500, detail=f"통계 조회 실패: {repr(e)}")
    finally:
        conn.close()

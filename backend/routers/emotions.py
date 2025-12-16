# backend/routers/emotions.py
from fastapi import APIRouter, HTTPException
from database.session import get_db_connection

router = APIRouter(prefix="/emotions", tags=["Emotions"])

@router.get("/{user_id}/today-top")
def today_top_emotion(user_id: int):
    conn = get_db_connection()
    if not conn:
        raise HTTPException(status_code=500, detail="DB 연결 실패")

    # ✅ 오늘 날짜(CURDATE()) 기준으로 감정 COUNT 후 가장 큰 것 1개
    sql = """
        SELECT emotion, COUNT(*) AS cnt
        FROM AnalysisChunk
        WHERE user_id = %s
          AND DATE(analyzed_at) = CURDATE()
        GROUP BY emotion
        ORDER BY cnt DESC
        LIMIT 1
    """

    try:
        with conn.cursor() as cur:
            cur.execute(sql, (user_id,))
            row = cur.fetchone()

        if not row:
            return {"emotion": None, "count": 0}

        return {"emotion": row["emotion"], "count": int(row["cnt"] or 0)}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    
@router.get("/{user_id}/latest")
def latest_emotion(user_id: int):
    conn = get_db_connection()
    if not conn:
        raise HTTPException(status_code=500, detail="DB 연결 실패")

    sql = """
        SELECT emotion, analyzed_at
        FROM AnalysisChunk
        WHERE user_id = %s
        ORDER BY analyzed_at DESC
        LIMIT 1
    """

    try:
        with conn.cursor() as cur:
            cur.execute(sql, (user_id,))
            row = cur.fetchone()
        if not row:
            return {"emotion": None, "timestamp": None}

        return {
            "emotion": row["emotion"],
            "timestamp": row["analyzed_at"].isoformat() if row["analyzed_at"] else None,
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/{user_id}/monthly-stats")
def monthly_stats(user_id: int, year: int, month: int):
    conn = get_db_connection()
    if not conn:
        raise HTTPException(status_code=500, detail="DB 연결 실패")

    sql = """
        SELECT emotion, COUNT(*) AS cnt
        FROM AnalysisChunk
        WHERE user_id = %s
          AND YEAR(analyzed_at) = %s
          AND MONTH(analyzed_at) = %s
        GROUP BY emotion
    """

    # HomeScreen이 기대하는 키: joy/anger/anxiety/sadness
    out = {"joy": 0, "anger": 0, "anxiety": 0, "sadness": 0}

    try:
        with conn.cursor() as cur:
            cur.execute(sql, (user_id, year, month))
            rows = cur.fetchall()

        for r in rows:
            emo = r["emotion"]
            cnt = int(r["cnt"] or 0)
            if emo == "기쁨":
                out["joy"] += cnt
            elif emo == "분노":
                out["anger"] += cnt
            elif emo == "불안":
                out["anxiety"] += cnt
            elif emo == "슬픔":
                out["sadness"] += cnt

        return out
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

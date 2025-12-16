from fastapi import APIRouter
from database.session import get_db_connection

router = APIRouter(prefix="/api/v1/alerts", tags=["Alerts"])

@router.post("/check")
def check_and_create_alert(user_id: int, chunk_id: int):
    db = get_db_connection()
    with db.cursor() as cursor:
        # 1. 해당 chunk의 risk_score 조회
        cursor.execute(
            "SELECT risk_score, final_result FROM AnalysisChunk WHERE chunk_id=%s AND user_id=%s",
            (chunk_id, user_id)
        )
        row = cursor.fetchone()

        if not row:
            return {"message": "❌ 해당 분석 기록 없음"}

        risk_score = row["risk_score"]
        emotion = row["final_result"]

        # 2. 위험 점수 기준 확인
        if risk_score >= 0.8:
            cursor.execute(
                "INSERT INTO Alert (user_id, chunk_id, alert_type, status) VALUES (%s, %s, %s, %s)",
                (user_id, chunk_id, f"High_{emotion}", "pending")
            )
            db.commit()
            return {
                "message": "✅ Alert created",
                "user_id": user_id,
                "chunk_id": chunk_id,
                "risk_score": risk_score
            }
        else:
            return {"message": "ℹ️ 위험 점수 낮음, 알람 생성 안 함", "risk_score": risk_score}
        
# ✅ 알람 상태 업데이트 (pending → resolved)
@router.patch("/{alert_id}")
def resolve_alert(alert_id: int):
    db = get_db_connection()
    with db.cursor() as cursor:
        # 해당 알람 조회
        cursor.execute("SELECT alert_id FROM Alert WHERE alert_id=%s", (alert_id,))
        row = cursor.fetchone()
        if not row:
            return {"message": "❌ Alert not found"}

        # 상태 업데이트
        cursor.execute("UPDATE Alert SET status=%s WHERE alert_id=%s", ("resolved", alert_id))
        db.commit()

        return {"message": "✅ Alert resolved", "alert_id": alert_id}
    
# 📌 보호자 조회 API 추가
@router.get("/guardian/{guardian_id}")
def get_guardian_alerts(guardian_id: int):
    db = get_db_connection()
    with db.cursor() as cursor:
        cursor.execute("""
            SELECT a.alert_id,
                   a.alert_type,
                   a.status,
                   a.triggered_at,
                   u.username AS ward_name
            FROM Alert a
            JOIN GuardianRelationship gr
              ON a.user_id = gr.ward_user_id
            JOIN User u
              ON gr.ward_user_id = u.user_id
            WHERE gr.guardian_user_id = %s
            ORDER BY a.triggered_at DESC
        """, (guardian_id,))
        return cursor.fetchall()

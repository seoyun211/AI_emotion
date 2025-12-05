# backend/services/alert_service.py

from sqlalchemy.orm import Session
from backend.models import Alert, GuardianRelationship, User
from backend.utils.sms import send_sms  # 알림 전송 함수

def create_alert(db: Session, user_id: int, chunk_id: int, alert_type: str, status: str = "pending"):
    alert = Alert(
        user_id=user_id,
        chunk_id=chunk_id,
        alert_type=alert_type,
        status=status
    )
    db.add(alert)
    db.commit()
    db.refresh(alert)

    guardians = db.query(GuardianRelationship).filter_by(ward_user_id=user_id, status="active").all()
    for rel in guardians:
        guardian = db.query(User).filter_by(user_id=rel.guardian_user_id).first()
        send_sms(guardian.user_phone, f"[경고] {user_id}님에게 위험 감정이 감지되었습니다.")

    return alert
# backend/services/alert_service.py
'''
from sqlalchemy.orm import Session
from models import Alert, GuardianRelationship, User
from utils.notifications import send_push_notification

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
        send_push_notification(
            user_id=guardian.user_id,
            title="위험 감정 감지",
            message=f"{user_id}님에게 위험 감정이 감지되었습니다.",
            alert_type="High_RiskScore"
        )

    return alert
    '''
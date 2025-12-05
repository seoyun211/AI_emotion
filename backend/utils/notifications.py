# backend/utils/notifications.py

def send_push_notification(user_id: int, title: str, message: str, alert_type: str):
    """
    앱 내부 푸시 알림 또는 인앱 알림을 트리거하는 함수
    실제 구현은 FCM, Expo, OneSignal 등과 연동 필요
    """
    print(f"[알림] 사용자 {user_id} → {title}: {message} ({alert_type})")
    # TODO: 실제 푸시 알림 API 연동
    
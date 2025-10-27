from .mongodb import users_collection, emotion_logs_collection, guardians_collection, alerts_collection
from datetime import datetime
from bson import ObjectId
from typing import List, Optional

class UserCRUD:
    @staticmethod
    async def create_user(user_data: dict):
        if not users_collection:
            return {"message": "MongoDB 미연동"}
        
        result = await users_collection.insert_one(user_data)
        return str(result.inserted_id)

    @staticmethod
    async def get_user(user_id: str):
        if not users_collection:
            return None
        return await users_collection.find_one({"_id": user_id})

class EmotionLogCRUD:
    @staticmethod
    async def create_emotion_log(log_data: dict):
        if not emotion_logs_collection:
            return {"message": "MongoDB 미연동"}
        
        log_data["created_at"] = datetime.now()
        result = await emotion_logs_collection.insert_one(log_data)
        return {"log_id": str(result.inserted_id)}

    @staticmethod
    async def get_user_emotion_history(user_id: str, limit: int = 10):
        if not emotion_logs_collection:
            return []
        
        cursor = emotion_logs_collection.find(
            {"user_id": user_id}
        ).sort("created_at", -1).limit(limit)
        
        logs = await cursor.to_list(length=limit)
        for log in logs:
            log["_id"] = str(log["_id"])
            log["created_at"] = log["created_at"].isoformat()
        
        return logs

class GuardianCRUD:
    @staticmethod
    async def create_guardian(guardian_data: dict):
        if not guardians_collection:
            return {"message": "MongoDB 미연동"}
        
        result = await guardians_collection.insert_one(guardian_data)
        return str(result.inserted_id)

    @staticmethod
    async def get_guardian_by_phone(phone: str):
        if not guardians_collection:
            return None
        return await guardians_collection.find_one({"phone": phone})

    @staticmethod
    async def get_guardian_by_id(guardian_id: str):
        if not guardians_collection:
            return None
        return await guardians_collection.find_one({"_id": ObjectId(guardian_id)})

    @staticmethod
    async def get_guardian_elders(guardian_id: str):
        if not users_collection:
            return []
        
        # 간단한 구현 - 실제로는 관계 테이블 필요
        cursor = users_collection.find().limit(10)
        return await cursor.to_list(length=10)

class AlertCRUD:
    @staticmethod
    async def create_alert(alert_data: dict):
        if not alerts_collection:
            return {"message": "MongoDB 미연동"}
        
        alert_data["created_at"] = datetime.now()
        alert_data["is_read"] = False
        result = await alerts_collection.insert_one(alert_data)
        return str(result.inserted_id)

    @staticmethod
    async def get_guardian_alerts(guardian_id: str, limit: int = 20):
        if not alerts_collection:
            return []
        
        cursor = alerts_collection.find(
            {"guardian_id": guardian_id}
        ).sort("created_at", -1).limit(limit)
        
        alerts = await cursor.to_list(length=limit)
        for alert in alerts:
            alert["_id"] = str(alert["_id"])
            alert["created_at"] = alert["created_at"].isoformat()
        
        return alerts

    @staticmethod
    async def mark_alert_read(alert_id: str, guardian_id: str):
        if not alerts_collection:
            return False
        
        result = await alerts_collection.update_one(
            {"_id": ObjectId(alert_id), "guardian_id": guardian_id},
            {"$set": {"is_read": True}}
        )
        return result.modified_count > 0
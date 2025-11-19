from typing import Dict
from datetime import datetime
from database.session import get_db_connection
import asyncio

class UserCRUD:
    @staticmethod
    def create_user(user_data: Dict): # Dict는 UserCreate 스키마의 내용 (username, gender 등)
        connection = get_db_connection()
        if not connection:
            raise Exception("DB 연결 실패")
        
        
        sql = """
            INSERT INTO User (username, gender, birth_date, address, guardian_name, guardian_phone)
            VALUES (%s, %s, %s, %s, %s, %s)
        """
        
        params = (
            user_data['username'],
            user_data['gender'],
            user_data['birth_date'], # FastAPI Pydantic이 Date 객체로 변환해준다고 가정
            user_data.get('address'),
            user_data.get('guardian_name'),
            user_data.get('guardian_phone'),
        )
        
        try:
            with connection.cursor() as cursor:
                cursor.execute(sql, params)
            connection.commit()
            # AUTO_INCREMENT로 생성된 user_id를 반환
            return cursor.lastrowid
        except Exception as e:
            connection.rollback()
            print(f"User 생성 중 오류: {e}")
            raise e

    @staticmethod
    def get_user(user_id: int):
        connection = get_db_connection()
        if not connection:
            return None
            
        sql = "SELECT * FROM User WHERE user_id = %s"
        
        try:
            with connection.cursor() as cursor:
                cursor.execute(sql, (user_id,))
                return cursor.fetchone()
        except Exception:
            return None

class AnalysisChunkCRUD:
    # EmotionLogCRUD 대신 AnalysisChunk 테이블을 사용하도록 이름 변경 및 구현
    @staticmethod
    def create_analysis_chunk(chunk_data: Dict):
        connection = get_db_connection()
        if not connection:
            raise Exception("DB 연결 실패")
        
        # SQL: AnalysisChunk 테이블의 칼럼명과 순서를 정확히 일치시킵니다.
        sql = """
            INSERT INTO AnalysisChunk (session_id, analysis_time, text_result, audio_result, face_result, final_result)
            VALUES (%s, %s, %s, %s, %s, %s)
        """
        
        params = (
            chunk_data['session_id'],
            datetime.now(), # analysis_time은 현재 시간으로 설정
            chunk_data.get('text_result'),
            chunk_data.get('audio_result'),
            chunk_data.get('face_result'),
            chunk_data['final_result'],
        )
        
        try:
            with connection.cursor() as cursor:
                cursor.execute(sql, params)
            connection.commit()
            return cursor.lastrowid
        except Exception as e:
            connection.rollback()
            print(f"Chunk 생성 중 오류: {e}")
            raise e
        
class GuardianCRUD:
    """보호자(Guardian) 관련 데이터베이스 작업을 위한 최소한의 CRUD 클래스"""
    @staticmethod
    def get_guardian_by_phone(phone_number: str):
        # 보호자 전화번호로 정보를 조회하는 로직 (나중에 구현)
        # 현재는 임포트 오류 해결을 위해 정의만 해둡니다.
        return None
        
    # 필요한 다른 Guardian 관련 메서드 (예: create, update)도 여기에 추가됩니다.
    pass

class AlertCRUD:
    # 🚨 이 메서드를 AlertCRUD 클래스 내부에 추가해야 합니다.
    @staticmethod
    async def get_alerts_by_guardian_id(guardian_id: str):
        """특정 보호자의 알림 목록을 DB에서 조회합니다."""
        
        # 동기적인 DB 조회 작업을 비동기 스레드 풀에서 실행합니다.
        def fetch_alerts():
            conn = get_db_connection()
            if not conn:
                print("❌ DB 연결 실패: 알림 조회 불가")
                return []
            
            try:
                with conn.cursor() as cursor:
                    # 💡 실제 알림 테이블 이름과 컬럼에 맞게 쿼리를 수정하세요.
                    sql = "SELECT * FROM Alerts WHERE guardian_id = %s ORDER BY created_at DESC"
                    cursor.execute(sql, (guardian_id,))
                    return cursor.fetchall()
            except Exception as e:
                print(f"❌ 알림 조회 중 DB 쿼리 오류: {e}")
                return []
                
        # 비동기적으로 동기 함수를 호출하고 결과를 기다립니다.
        alerts_data = await asyncio.to_thread(fetch_alerts)
        
        return alerts_data
        
    # 필요한 다른 Alert 관련 메서드 (예: update_status)도 여기에 추가됩니다.
    pass
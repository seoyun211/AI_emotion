from typing import Dict
from datetime import datetime
from database.session import get_db_connection
import asyncio
import bcrypt

def hash_password(password: str) -> str:
    """비밀번호를 해싱하고 문자열로 반환합니다."""
    # 비밀번호를 바이트로 인코딩하고, salt를 생성하여 해싱합니다.
    hashed = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt())
    return hashed.decode('utf-8')

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """평문 비밀번호와 해시된 비밀번호를 비교합니다."""
    try:
        return bcrypt.checkpw(
            plain_password.encode('utf-8'), 
            hashed_password.encode('utf-8')
        )
    except ValueError:
        # 해시 형식이 잘못된 경우 (예: DB에 빈 문자열 저장)
        return False

class UserCRUD:
    @staticmethod
    def create_user(user_data: Dict):
        connection = get_db_connection()
        if not connection:
            raise Exception("DB 연결 실패")
        
        plain_password = user_data.get('password')
        if not plain_password:
            raise ValueError("비밀번호 정보가 누락되었습니다.")
            
        password_hash = hash_password(plain_password)
        
        sql = """
            INSERT INTO User (username, password_hash, role, gender, birth_date, address, user_phone)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
        """
        
        params = (
            user_data['username'],
            password_hash,
            user_data['role'],
            user_data['gender'],
            user_data['birth_date'],
            user_data.get('address'),
            user_data['user_phone']
        )
        
        try:
            with connection.cursor() as cursor:
                cursor.execute(sql, params)
            connection.commit()
            return cursor.lastrowid
        except Exception as e:
            connection.rollback()
            print(f"User 생성 중 오류: {e}")
            raise e

    @staticmethod
    def get_user_by_phone(user_phone: str) -> Dict | None:
        """전화번호(user_phone)로 사용자 정보(비밀번호 해시 포함)를 조회합니다."""
        connection = get_db_connection()
        if not connection:
            return None
            
        sql = "SELECT user_id, username, password_hash, role, user_phone FROM User WHERE user_phone = %s"
        
        try:
            with connection.cursor() as cursor:
                cursor.execute(sql, (user_phone,))
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
            INSERT INTO AnalysisChunk (session_id, user_id, analysis_id, analysis_time, text_result, audio_result, face_result, final_result)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        """
        
        params = (
            chunk_data['session_id'],
            chunk_data['user_id'],   
            chunk_data['analysis_id'],  
            datetime.now(), 
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
    """보호자-피보호자 관계(GuardianRelationship) 관리 클래스"""
    
    @staticmethod
    def create_relationship(guardian_id: int, ward_id: int):
        """보호자와 피보호자 사이에 관리 관계를 생성합니다."""
        connection = get_db_connection()
        if not connection:
            raise Exception("DB 연결 실패")
            
        sql = """
            INSERT INTO GuardianRelationship (guardian_user_id, ward_user_id)
            VALUES (%s, %s)
        """
        params = (guardian_id, ward_id)
        
        try:
            with connection.cursor() as cursor:
                cursor.execute(sql, params)
            connection.commit()
            return cursor.lastrowid
        except Exception as e:
            connection.rollback()
            print(f"관계 생성 중 오류: {e}")
            raise e

    @staticmethod
    def get_wards_by_guardian_id(guardian_id: int) -> list[Dict]:
        """특정 보호자가 관리하는 모든 피보호자의 user_id와 username을 조회합니다."""
        connection = get_db_connection()
        if not connection:
            return []
            
        sql = """
            SELECT 
                U.user_id, 
                U.username, 
                GR.relationship_id
            FROM GuardianRelationship AS GR
            JOIN User AS U ON GR.ward_user_id = U.user_id
            WHERE GR.guardian_user_id = %s
        """
        
        try:
            with connection.cursor() as cursor:
                cursor.execute(sql, (guardian_id,))
                return cursor.fetchall()
            
        except Exception:
            return []
        
class AlertCRUD:
    @staticmethod
    async def get_alerts_by_guardian_id(guardian_id: int):
        """특정 보호자가 관리하는 모든 피보호자의 알림 목록을 DB에서 조회합니다."""
        
        # 동기적인 DB 조회 작업을 비동기 스레드 풀에서 실행합니다.
        def fetch_alerts():
            conn = get_db_connection()
            if not conn:
                print("❌ DB 연결 실패: 알림 조회 불가")
                return []
            
            try:
                with conn.cursor() as cursor:
                    sql = """
                        SELECT 
                            A.*, 
                            U.username AS ward_username 
                        FROM Alert AS A
                        JOIN GuardianRelationship AS GR ON A.user_id = GR.ward_user_id
                        JOIN User AS U ON A.user_id = U.user_id
                        WHERE GR.guardian_user_id = %s 
                        ORDER BY A.triggered_at DESC
                    """
                    
                    cursor.execute(sql, (guardian_id,))
                    return cursor.fetchall()
            except Exception as e:
                print(f"❌ 알림 조회 중 DB 쿼리 오류: {e}")
                return []
                
        # 비동기적으로 동기 함수를 호출하고 결과를 기다립니다.
        alerts_data = await asyncio.to_thread(fetch_alerts)
        
        return alerts_data

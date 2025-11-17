
from typing import Dict
from datetime import datetime
from database.session import get_db_connection
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
        
# Session 테이블에 대한 CRUD도 유사한 방식으로 구현해야 합니다.
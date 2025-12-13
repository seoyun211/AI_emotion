from typing import Dict, List, Optional
from datetime import datetime
from database.session import get_db_connection
import asyncio
import bcrypt

# =========================================================================
# 1. 인증/비밀번호 관련 함수 (bcrypt 구현 완료)
# =========================================================================

def hash_password(password: str) -> str:
    """비밀번호를 해시합니다. (bcrypt 실제 구현)"""
    if not password:
        raise ValueError("비밀번호는 비워둘 수 없습니다.")
    # 실제 bcrypt 해싱 로직
    # salt를 생성하고, password를 인코딩한 후 해시합니다.
    hashed_bytes = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt())
    return hashed_bytes.decode('utf-8')

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """평문 비밀번호와 해시된 비밀번호를 비교합니다."""
    try:
        # DB에 저장된 해시된 비밀번호는 문자열이므로, 비교를 위해 바이트로 인코딩해야 합니다.
        return bcrypt.checkpw(
            plain_password.encode('utf-8'),
            hashed_password.encode('utf-8')
        )
    except ValueError:
        # 해시된 비밀번호가 잘못된 형식일 경우 (예: DUMMY_HASHED_PASSWORD)
        return False

# =========================================================================
# 2. 사용자 관리 (UserCRUD)
# =========================================================================

class UserCRUD:
    @staticmethod
    def create_user(user_data: Dict):
        """새로운 사용자를 DB에 생성합니다."""
        print("--- [DEBUG] create_user 함수 시작 ---", flush=True)

        connection = get_db_connection()
        if not connection:
            raise Exception("DB 연결 실패")

        password_hash_value = user_data.get('password_hash')
        if not password_hash_value:
            raise ValueError("해시된 비밀번호 정보가 누락되었습니다.")

        sql = """
            INSERT INTO User (username, password_hash, role, gender, birth_date, address, user_phone, 
                              guardian_name, guardian_phone)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
        """

        params = (
            user_data['username'],
            password_hash_value,
            user_data['role'],
            user_data['gender'],
            user_data['birth_date'],
            user_data.get('address'),
            user_data['user_phone'],
            user_data.get('guardian_name'),
            user_data.get('guardian_phone')
        )

        try:
            with connection.cursor() as cursor:
                cursor.execute(sql, params)
            connection.commit()
            return cursor.lastrowid  # 새로 생성된 user_id 반환
        except Exception as e:
            connection.rollback()
            print(f"--- [ERROR] User 생성 중 오류: {e} ---", flush=True)
            raise e

    @staticmethod
    def get_user_by_phone(user_phone: str) -> Dict | None:
        """전화번호(user_phone)로 사용자 정보(비밀번호 해시 포함)를 조회합니다."""
        connection = get_db_connection()
        if not connection:
            return None

        sql = """
            SELECT 
                user_id, 
                username, 
                password_hash, 
                role, 
                user_phone 
            FROM User 
            WHERE user_phone = %s
        """

        try:
            with connection.cursor() as cursor:
                cursor.execute(sql, (user_phone,))
                # cursor.fetchone()은 딕셔너리를 반환한다고 가정합니다.
                return cursor.fetchone()
        except Exception:
            return None

    @staticmethod
    def get_user_by_id(user_id: int) -> dict | None:
        """user_id를 사용하여 DB에서 사용자 정보를 조회합니다."""
        connection = get_db_connection()
        if not connection:
            return None

        sql = """
            SELECT 
                user_id,
                username,
                user_phone,
                gender,
                role,
                birth_date,
                address,
                guardian_name,
                guardian_phone
            FROM User
            WHERE user_id = %s
        """

        try:
            with connection.cursor() as cursor:
                cursor.execute(sql, (user_id,))
                return cursor.fetchone()
        except Exception:
            return None

    @staticmethod
    def delete_user_by_id(user_id: int):
        """특정 user_id를 가진 사용자를 DB에서 삭제합니다 (롤백용)."""
        connection = get_db_connection()
        if not connection:
            raise Exception("DB 연결 실패")

        sql_disable_fk = "SET FOREIGN_KEY_CHECKS = 0;"
        sql_enable_fk = "SET FOREIGN_KEY_CHECKS = 1;"

        # 주의: 이 SQL 쿼리들은 User 테이블의 user_id가 Alert, Session, AnalysisChunk 등의 user_id 필드와 WardRelationship의 두 필드 모두에 외래 키로 연결되어 있다고 가정합니다.
        sql_delete_relationship = "DELETE FROM GuardianRelationship WHERE guardian_user_id = %s OR ward_user_id = %s"
        sql_delete_alerts = "DELETE FROM Alert WHERE user_id = %s"
        sql_delete_chunks = "DELETE FROM AnalysisChunk WHERE user_id = %s"
        sql_delete_sessions = "DELETE FROM Session WHERE user_id = %s"

        sql_delete_user = "DELETE FROM User WHERE user_id = %s"

        try:
            with connection.cursor() as cursor:
                # 1. 외래 키 검사 잠시 비활성화 (보험)
                cursor.execute(sql_disable_fk)

                # 2. 자식 레코드 먼저 삭제
                cursor.execute(sql_delete_relationship, (user_id, user_id))
                cursor.execute(sql_delete_alerts, (user_id,))
                cursor.execute(sql_delete_chunks, (user_id,))
                cursor.execute(sql_delete_sessions, (user_id,))

                # 3. 부모 레코드 (User) 삭제
                cursor.execute(sql_delete_user, (user_id,))

                # 4. 외래 키 검사 활성화
                cursor.execute(sql_enable_fk)

            connection.commit()

        except Exception as e:
            connection.rollback()
            # 롤백 후에도 외래 키 검사를 다시 켜야 합니다.
            try:
                with connection.cursor() as cursor:
                    cursor.execute(sql_enable_fk)
            except:
                pass
            raise e

# =========================================================================
# 4. 보호자 관계 관리 (GuardianCRUD)
# =========================================================================

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
    def create_relationship_with_validation(
        new_user_id: int,
        new_user_role: str,
        linked_phone_input: Optional[str]
    ):
        """
        사용자의 역할에 따라 상대방을 조회하고 관계를 생성하며 유효성 검사를 수행합니다.
        회원가입 시 linked_phone_input이 없는 경우 (None) 관계 생성 로직을 건너뜁니다.
        """
        if not linked_phone_input:
            print("--- [DEBUG] 연결할 전화번호가 없어 관계 생성을 건너뜁니다. ---")
            return None  # 관계 생성 로직 건너뛰기

        # A. 상대방 정보 조회 (user_id, role 포함)
        linked_user_data = UserCRUD.get_user_by_phone(linked_phone_input)

        if linked_user_data is None:
            raise ValueError("연결하려는 상대방의 전화번호가 등록되어 있지 않습니다.")

        linked_user_id = linked_user_data['user_id']
        linked_user_role = linked_user_data['role']

        # B. 역할 유효성 검사
        if new_user_role == 'guardian' and linked_user_role != 'ward':
            raise ValueError("보호자는 피보호자(ward)하고만 연결할 수 있습니다.")
        if new_user_role == 'ward' and linked_user_role != 'guardian':
            raise ValueError("피보호자는 보호자(guardian)하고만 연결할 수 있습니다.")

        # C. GuardianRelationship에 삽입할 ID 결정
        if new_user_role == 'guardian':
            guardian_id = new_user_id
            ward_id = linked_user_id
        else:  # new_user_role == 'ward'
            guardian_id = linked_user_id
            ward_id = new_user_id

        # D. 관계 생성
        try:
            return GuardianCRUD.create_relationship(guardian_id, ward_id)
        except Exception as e:
            # DB의 UNIQUE KEY 제약 조건 위반(중복 관계) 등의 오류를 사용자 친화적으로 처리
            if "Duplicate entry" in str(e):
                raise ValueError("이미 등록된 보호자-피보호자 관계입니다.")
            raise ValueError(f"관계 생성 실패: {str(e)}")

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

# =========================================================================
# 5. 알림 관리 (AlertCRUD)
# =========================================================================

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
    
# =========================================================================
# 6. 통화 기록 관리 (SessionCRUD)
# =========================================================================

class SessionCRUD:
    """통화 기록(Session) 관리 클래스"""

    @staticmethod
    def create_session(user_id: int, start_time: str, end_time: str | None, duration_seconds: int | None, full_transcript: str | None) -> int | None:
        """
        새로운 통화 기록(Session)을 데이터베이스에 저장합니다.
        """
        connection = None
        session_id = None

        try:
            connection = get_db_connection()
            
            # SQL 쿼리: full_transcript 필드에 값을 저장하도록 수정
            sql = """
                INSERT INTO Session 
                    (user_id, start_time, end_time, duration_seconds, full_transcript) 
                VALUES 
                    (%s, %s, %s, %s, %s)
            """
            
            # SQL에 전달할 데이터 (순서가 SQL 필드와 일치해야 함)
            data = (
                user_id, 
                start_time, 
                end_time, 
                duration_seconds, 
                full_transcript  # STT 텍스트 데이터
            )

            with connection.cursor() as cursor:
                cursor.execute(sql, data)
                
                # 새로 생성된 ID를 가져옵니다.
                session_id = cursor.lastrowid
                
                connection.commit()
                
                print(f"✅ Session 생성 성공. Session ID: {session_id}")
                return session_id

        except Exception as e:
            if connection:
                connection.rollback() # 오류 발생 시 롤백
            print(f"❌ Session 생성 실패 (DB Error in crud.py): {e}")
            return None
            
        finally:
            # Note: DB 연결 관리는 get_db_connection()에서 처리한다고 가정하고 여기서는 pass
            pass
            

    @staticmethod
    def update_session(session_id: int, end_time: str, full_transcript: str):
        """특정 session_id의 통화 기록을 종료 시간과 최종 녹취록으로 업데이트합니다."""
        connection = get_db_connection()
        if not connection:
            return None
        
        # duration_seconds는 MySQL의 TIMESTAMPDIFF(SECOND, start_time, end_time)을 사용하여 계산
        sql = """
            UPDATE Session
            SET 
                end_time = %s,
                full_transcript = %s,
                duration_seconds = TIMESTAMPDIFF(SECOND, start_time, %s) 
            WHERE 
                session_id = %s
        """
        
        params = (
            end_time,
            full_transcript,
            end_time, # TIMESTAMPDIFF의 두 번째 인수로 사용
            session_id
        )

        try:
            with connection.cursor() as cursor:
                cursor.execute(sql, params)
            connection.commit()
            return True # 성공 여부만 반환하도록 단순화
        except Exception as e:
            connection.rollback()
            print(f"❌ Session 업데이트 실패: {e}")
            return None

    @staticmethod
    def get_session_by_id(session_id: int) -> Dict | None:
        """
        특정 session_id에 해당하는 통화 기록(Session)을 조회합니다.
        """
        connection = get_db_connection()
        if not connection:
            # ... (오류 처리)
            return None

        sql = """
            SELECT 
                session_id, 
                user_id, 
                start_time, 
                end_time, 
                duration_seconds, 
                full_transcript
            FROM Session
            WHERE session_id = %s
        """

        try:
            with connection.cursor() as cursor:
                cursor.execute(sql, (session_id,))
                return cursor.fetchone()
        except Exception as e:
            # ... (오류 처리)
            return None

    @staticmethod
    def get_session_by_id(session_id: int) -> Dict | None:
        """
        특정 session_id에 해당하는 통화 기록(Session)을 조회합니다.
        """
        connection = get_db_connection()
        if not connection:
            # ... (오류 처리)
            return None

        sql = """
            SELECT 
                session_id, 
                user_id, 
                start_time, 
                end_time, 
                duration_seconds, 
                full_transcript
            FROM Session
            WHERE session_id = %s
        """

        try:
            with connection.cursor() as cursor:
                cursor.execute(sql, (session_id,))
                return cursor.fetchone()
        except Exception as e:
            # ... (오류 처리)
            return None        

    @staticmethod
    def get_sessions_by_user_id(user_id: int) -> list[Dict]:
        """
        특정 피보호자(user_id)의 통화 기록 전체를 조회합니다. (피보호자 본인 앱용)
        """
        connection = get_db_connection()
        if not connection:
            return []

        sql = """
            SELECT 
                session_id, 
                user_id, 
                start_time, 
                end_time, 
                duration_seconds, 
                full_transcript
            FROM Session
            WHERE user_id = %s
            ORDER BY start_time DESC
        """

        try:
            with connection.cursor() as cursor:
                cursor.execute(sql, (user_id,))
                return cursor.fetchall()

        except Exception as e:
            print(f"❌ UserID로 통화 기록 조회 중 DB 쿼리 오류: {e}")
            return []
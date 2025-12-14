# backend/models/alert_model.py
from sqlalchemy import Column, BigInteger, String, DateTime, ForeignKey
from datetime import datetime
from .base import Base

class Alert(Base):
    __tablename__ = "Alert"

    alert_id = Column(BigInteger, primary_key=True, autoincrement=True)
    user_id = Column(BigInteger, ForeignKey("User.user_id", ondelete="CASCADE"), nullable=False)
    chunk_id = Column(BigInteger, ForeignKey("AnalysisChunk.chunk_id", ondelete="SET NULL"))
    status = Column(String(20), default="pending", nullable=False)
    alert_type = Column(String(50), nullable=False)
    triggered_at = Column(DateTime, default=datetime.now, nullable=False)
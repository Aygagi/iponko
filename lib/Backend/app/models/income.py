from sqlalchemy import Column, Integer, Float, String, DateTime, ForeignKey
from datetime import datetime
from app.core.database import Base


class Income(Base):
    __tablename__ = "income"

    id = Column(Integer, primary_key=True)
    amount = Column(Float, nullable=False)
    source = Column(String)
    user_id = Column(Integer, ForeignKey("users.id"))
    created_at = Column(DateTime, default=datetime.utcnow)
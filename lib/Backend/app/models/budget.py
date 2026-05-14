from sqlalchemy import Column, Integer, Float, String, ForeignKey
from app.core.database import Base


class Budget(Base):
    __tablename__ = "budgets"

    id = Column(Integer, primary_key=True)
    limit_amount = Column(Float, nullable=False)
    month = Column(String)
    user_id = Column(Integer, ForeignKey("users.id"))
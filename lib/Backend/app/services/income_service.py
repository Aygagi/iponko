from sqlalchemy.orm import Session
from app.models.income import Income


def create_income(db: Session, data, user_id: int):
    income = Income(
        amount=data.amount,
        source=data.source,
        user_id=user_id
    )

    db.add(income)
    db.commit()
    db.refresh(income)

    return income
from sqlalchemy.orm import Session
from app.models.budget import Budget


def create_budget(db: Session, data, user_id: int):
    budget = Budget(
        limit_amount=data.limit_amount,
        month=data.month,
        user_id=user_id
    )

    db.add(budget)
    db.commit()
    db.refresh(budget)

    return budget
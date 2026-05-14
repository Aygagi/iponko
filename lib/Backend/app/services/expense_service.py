from sqlalchemy.orm import Session
from app.models.expense import Expense


def create_expense(db: Session, data, user_id: int):
    expense = Expense(
        amount=data.amount,
        description=data.description,
        category_id=data.category_id,
        user_id=user_id
    )

    db.add(expense)
    db.commit()
    db.refresh(expense)

    return expense


def get_expenses(db: Session, user_id: int):
    return db.query(Expense).filter(
        Expense.user_id == user_id
    ).all()
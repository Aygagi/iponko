from sqlalchemy.orm import Session
from sqlalchemy import func
from app.models.expense import Expense
from app.models.income import Income


def get_summary(db: Session, user_id: int):
    total_expenses = db.query(
        func.sum(Expense.amount)
    ).filter(
        Expense.user_id == user_id
    ).scalar() or 0

    total_income = db.query(
        func.sum(Income.amount)
    ).filter(
        Income.user_id == user_id
    ).scalar() or 0

    return {
        "income": total_income,
        "expenses": total_expenses,
        "balance": total_income - total_expenses
    }
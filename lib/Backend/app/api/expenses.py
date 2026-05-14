from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.middleware.auth import get_current_user
from app.schemas.expense import ExpenseCreate
from app.services.expense_service import (
    create_expense,
    get_expenses
)

router = APIRouter(prefix="/expenses", tags=["Expenses"])


@router.post("/")
def add_expense(
        data: ExpenseCreate,
        db: Session = Depends(get_db),
        user_id: int = Depends(get_current_user)
):
    return create_expense(db, data, user_id)


@router.get("/")
def fetch_expenses(
        db: Session = Depends(get_db),
        user_id: int = Depends(get_current_user)
):
    return get_expenses(db, user_id)
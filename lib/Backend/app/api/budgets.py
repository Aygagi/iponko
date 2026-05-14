from fastapi import APIRouter

router = APIRouter(prefix="/budgets", tags=["Budgets"])


@router.get("/")
def get_budgets():
    return {"message": "Budgets endpoint"}
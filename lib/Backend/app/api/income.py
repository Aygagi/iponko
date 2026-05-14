from fastapi import APIRouter

router = APIRouter(prefix="/income", tags=["Income"])


@router.get("/")
def get_income():
    return {"message": "Income endpoint"}
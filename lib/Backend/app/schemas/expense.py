from pydantic import BaseModel


class ExpenseCreate(BaseModel):
    amount: float
    description: str
    category_id: int
from pydantic import BaseModel


class BudgetCreate(BaseModel):
    limit_amount: float
    month: str
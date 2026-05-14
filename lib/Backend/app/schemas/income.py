from pydantic import BaseModel


class IncomeCreate(BaseModel):
    amount: float
    source: str
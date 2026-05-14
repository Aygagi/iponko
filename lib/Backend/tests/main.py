from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.database import Base, engine

from app.api.auth import router as auth_router
from app.api.users import router as users_router
from app.api.expenses import router as expenses_router
from app.api.income import router as income_router
from app.api.budgets import router as budgets_router
from app.api.categories import router as categories_router
from app.api.transactions import router as transactions_router
from app.api.analytics import router as analytics_router

Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Finance Tracker API",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router)
app.include_router(users_router)
app.include_router(expenses_router)
app.include_router(income_router)
app.include_router(budgets_router)
app.include_router(categories_router)
app.include_router(transactions_router)
app.include_router(analytics_router)


@app.get("/")
def root():
    return {
        "success": True,
        "message": "Finance Tracker Backend Running"
    }
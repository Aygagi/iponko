from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.middleware.auth import get_current_user
from app.services.analytics_service import get_summary

router = APIRouter(prefix="/analytics", tags=["Analytics"])


@router.get("/summary")
def analytics_summary(
        db: Session = Depends(get_db),
        user_id: int = Depends(get_current_user)
):
    return get_summary(db, user_id)
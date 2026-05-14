from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.schemas.auth import RegisterSchema, LoginSchema
from app.services.auth_service import register_user, login_user

router = APIRouter(prefix="/auth", tags=["Auth"])


@router.post("/register")
def register(data: RegisterSchema, db: Session = Depends(get_db)):
    user = register_user(db, data)

    if not user:
        raise HTTPException(400, "Email already exists")

    return {
        "success": True,
        "message": "User registered"
    }


@router.post("/login")
def login(data: LoginSchema, db: Session = Depends(get_db)):
    token = login_user(db, data)

    if not token:
        raise HTTPException(401, "Invalid credentials")

    return {
        "access_token": token,
        "token_type": "bearer"
    }
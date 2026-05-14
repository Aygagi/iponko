from sqlalchemy.orm import Session
from app.models.user import User
from app.schemas.auth import RegisterSchema, LoginSchema
from app.core.security import (
    hash_password,
    verify_password,
    create_access_token
)


def register_user(db: Session, data: RegisterSchema):
    existing_user = db.query(User).filter(
        User.email == data.email
    ).first()

    if existing_user:
        return None

    user = User(
        username=data.username,
        email=data.email,
        password_hash=hash_password(data.password)
    )

    db.add(user)
    db.commit()
    db.refresh(user)

    return user


def login_user(db: Session, data: LoginSchema):
    user = db.query(User).filter(
        User.email == data.email
    ).first()

    if not user:
        return None

    if not verify_password(data.password, user.password_hash):
        return None

    token = create_access_token({"sub": str(user.id)})

    return token
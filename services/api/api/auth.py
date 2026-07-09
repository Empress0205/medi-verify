"""
Admin auth — POST /auth/login issues a JWT; require_admin() guards admin-only
endpoints (reports list/get/patch/delete, analytics).

A default admin is seeded on startup (config.ADMIN_*) if none exists, so the
dashboard can log in on a fresh DB. Change the credentials in production.
"""
from datetime import datetime, timedelta

import bcrypt
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from config import get_settings
from infra.db import get_db, AsyncSessionLocal
from infra.orm import AdminUser
from domain.schemas import LoginRequest, TokenResponse

settings = get_settings()
router = APIRouter(prefix="/auth", tags=["Auth"])

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/login")


def hash_password(raw: str) -> str:
    # bcrypt hard-caps the secret at 72 bytes; truncate to stay within it.
    return bcrypt.hashpw(raw.encode("utf-8")[:72], bcrypt.gensalt()).decode("utf-8")


def verify_password(raw: str, hashed: str) -> bool:
    try:
        return bcrypt.checkpw(raw.encode("utf-8")[:72], hashed.encode("utf-8"))
    except (ValueError, TypeError):
        return False


def create_access_token(subject: str) -> str:
    expire = datetime.utcnow() + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    payload = {"sub": subject, "exp": expire}
    return jwt.encode(payload, settings.SECRET_KEY, algorithm=settings.ALGORITHM)


@router.post("/login", response_model=TokenResponse)
async def login(body: LoginRequest, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(AdminUser).where(AdminUser.username == body.username))
    user = result.scalar_one_or_none()
    if not user or not verify_password(body.password, user.hashed_password):
        raise HTTPException(status_code=401, detail="Invalid username or password")
    return TokenResponse(access_token=create_access_token(user.username))


async def require_admin(token: str = Depends(oauth2_scheme)) -> str:
    """Dependency: decode the Bearer JWT and return the admin username, or 401."""
    credentials_exc = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        username = payload.get("sub")
        if username is None:
            raise credentials_exc
    except JWTError:
        raise credentials_exc
    return username


async def seed_default_admin() -> None:
    """Create the default admin if the table is empty. Called on startup."""
    async with AsyncSessionLocal() as db:
        existing = await db.execute(select(AdminUser).limit(1))
        if existing.scalar_one_or_none() is None:
            db.add(AdminUser(
                username=settings.ADMIN_USERNAME,
                email=settings.ADMIN_EMAIL,
                hashed_password=hash_password(settings.ADMIN_PASSWORD),
            ))
            await db.commit()

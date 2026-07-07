from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    # App
    APP_NAME: str = "MediGuard API"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = True

    # Database — SQLite for dev, swap to PostgreSQL URL in prod
    DATABASE_URL: str = "sqlite+aiosqlite:///./mediguard.db"

    # JWT — change SECRET_KEY in production!
    SECRET_KEY: str = "CHANGE_THIS_IN_PRODUCTION_USE_LONG_RANDOM_STRING"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24  # 24 hours

    # CORS — add your React dashboard origin and Flutter app
    CORS_ORIGINS: list[str] = [
        "http://localhost:3000",   # React dev server
        "http://localhost:5173",   # Vite dev server
        "http://127.0.0.1:3000",
        "*",                       # Remove in production, list exact origins
    ]

    # Image verification — set to True to use a real AI model endpoint
    USE_REAL_AI: bool = False
    AI_ENDPOINT: str = ""
    AI_API_KEY: str = ""

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


@lru_cache
def get_settings() -> Settings:
    return Settings()
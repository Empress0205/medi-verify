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

    # ── Verification engine ─────────────────────────────────────────────────
    # Which engine reads the packaging photo:
    #   "mock"   -> deterministic fake (default; no key needed)
    #   "gemini" -> Google Gemini vision (free tier)
    #   "groq"   -> Groq vision (free tier, fallback)
    ENGINE: str = "mock"
    GEMINI_API_KEY: str = ""
    GEMINI_MODEL: str = "gemini-flash-latest"   # confirm exact id when wiring the adapter
    GROQ_API_KEY: str = ""
    GROQ_MODEL: str = ""

    # Default admin — seeded on startup if no admin exists (change in prod!)
    ADMIN_USERNAME: str = "admin"
    ADMIN_EMAIL: str = "admin@mediguard.local"
    ADMIN_PASSWORD: str = "admin123"

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        extra = "ignore"   # tolerate unrelated env vars without crashing


@lru_cache
def get_settings() -> Settings:
    return Settings()
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from config import get_settings
from infra.db import init_db
from api.verify import router as verify_router
from api.reports import router as reports_router
from api.analytics import router as analytics_router
from api.scans import router as scans_router
from api.auth import router as auth_router, seed_default_admin
settings = get_settings()


@asynccontextmanager
async def lifespan(app: FastAPI):
    await init_db()
    await seed_default_admin()
    yield


app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router)
app.include_router(verify_router)
app.include_router(reports_router)
app.include_router(analytics_router)
app.include_router(scans_router)


@app.get("/", tags=["Health"])
async def root():
    return {"app": settings.APP_NAME, "version": settings.APP_VERSION, "status": "running"}


@app.get("/health", tags=["Health"])
async def health():
    return {"status": "ok"}
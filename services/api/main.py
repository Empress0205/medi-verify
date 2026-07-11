import asyncio
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import func, select

from config import get_settings
from infra.db import init_db, AsyncSessionLocal
from infra.orm import Medicine
from infra.tmda_sync import sync_register
from api.verify import router as verify_router
from api.reports import router as reports_router
from api.analytics import router as analytics_router
from api.scans import router as scans_router
from api.auth import router as auth_router, seed_default_admin
settings = get_settings()


async def _register_worker():
    """Seed the TMDA register on first boot (if empty), then refresh periodically.

    Runs as a background task so it never blocks startup / health checks.
    """
    try:
        async with AsyncSessionLocal() as db:
            count = (await db.execute(select(func.count()).select_from(Medicine))).scalar() or 0
        if count == 0:
            print("[startup] medicines table empty — syncing TMDA register…")
            await sync_register(verbose=True)
    except Exception as e:
        print(f"[startup] register seed skipped: {e}")

    hours = settings.REGISTER_SYNC_HOURS
    while hours and hours > 0:
        await asyncio.sleep(hours * 3600)
        try:
            await sync_register(verbose=True)
        except Exception as e:
            print(f"[sync] periodic refresh failed: {e}")


@asynccontextmanager
async def lifespan(app: FastAPI):
    await init_db()
    await seed_default_admin()
    task = asyncio.create_task(_register_worker())
    yield
    task.cancel()


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
    # Auth is via Bearer tokens (Authorization header), not cookies, so we don't
    # need credentialed CORS — which lets "*" origins stay valid (the "*" +
    # allow_credentials=True combination is rejected by browsers).
    allow_credentials=False,
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
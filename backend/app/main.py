"""
Mynix Control Backend
FastAPI application entry point.

Registers all module routers, runs seed on startup, connects to DB.
"""

from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.database import init_db, auto_migrate_tenant_schemas, async_session_factory


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Application lifecycle:
      - Startup: create tables, run seed data
      - Shutdown: cleanup
    """
    # ── Startup ──────────────────────────────────────────────────
    print(f"Starting {settings.app_name}...")

    # Create all tables (dev convenience; use Alembic in production)
    await init_db()
    await auto_migrate_tenant_schemas()
    print("  Database tables ready")

    # Run seed data
    try:
        async with async_session_factory() as session:
            from app.users.seed import seed_database
            from app.inventory.seed import seed_inventory

            await seed_database(session)
            await seed_inventory(session)
    except Exception as e:
        print(f"  Seed note: {e}")

    print(f"{settings.app_name} is running!")
    print(f"Docs: http://localhost:8000/docs")

    yield

    # ── Shutdown ─────────────────────────────────────────────────
    print("Shutting down...")


# ── Create FastAPI App ───────────────────────────────────────────

try:
    import sentry_sdk

    sentry_sdk.init(
        dsn="https://ee579c86969f6643e4786fef0ebd98a6@o4511875643015168.ingest.de.sentry.io/4511875720544336",
        send_default_pii=True,
        traces_sample_rate=1.0,
        profiles_sample_rate=1.0,
    )
except ImportError:
    pass

app = FastAPI(
    title=settings.app_name,
    description=(
        "REST Omni-System for hybrid café with street booth. "
        "Multi-tenant modular monolith with PBAC access control."
    ),
    version="0.1.0",
    lifespan=lifespan,
)

# ── Exception Handlers ───────────────────────────────────────────
from fastapi.responses import JSONResponse
from app.exceptions import AppException

@app.exception_handler(AppException)
async def app_exception_handler(request, exc: AppException):
    return JSONResponse(
        status_code=exc.status_code,
        content={"detail": exc.detail, "extra": exc.extra},
    )

@app.exception_handler(ValueError)
async def value_error_handler(request, exc: ValueError):
    return JSONResponse(
        status_code=400,
        content={"detail": str(exc)},
    )

@app.exception_handler(Exception)
async def generic_exception_handler(request, exc: Exception):
    import traceback
    traceback.print_exc()
    return JSONResponse(
        status_code=500,
        content={"detail": f"Internal Server Error: {str(exc)}"},
    )

# ── CORS (allow Flutter apps from any origin in development) ─────
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Register Module Routers ─────────────────────────────────────

from app.users.router import router as users_router
from app.pos.router import router as pos_router
from app.pos.ws import router as ws_router
from app.inventory.router import router as inventory_router
from app.kitchen.router import router as kitchen_router
from app.analytics.router import router as analytics_router
from app.crm.router import router as crm_router
from app.system.router import router as system_router
from app.system.integrations import router as integrations_router

app.include_router(users_router, prefix="/api/v1")
app.include_router(pos_router, prefix="/api/v1")
app.include_router(inventory_router, prefix="/api/v1")
app.include_router(kitchen_router, prefix="/api/v1")
app.include_router(analytics_router, prefix="/api/v1", tags=["Analytics"])
app.include_router(crm_router, prefix="/api/v1")
app.include_router(system_router, prefix="/api/v1/system")
app.include_router(system_router, prefix="/system")
app.include_router(integrations_router, prefix="/api/v1")
app.include_router(ws_router)  # WebSocket at root /ws/kitchen/{tenant_id}


# ── Health Check ─────────────────────────────────────────────────

@app.get("/health", tags=["System"])
async def health_check():
    return {"status": "ok", "service": settings.app_name}


@app.get("/", tags=["System"])
async def root():
    return {
        "service": settings.app_name,
        "version": "0.1.0",
        "docs": "/docs",
        "health": "/health",
    }

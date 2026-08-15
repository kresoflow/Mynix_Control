from fastapi import APIRouter

from app.analytics.routers import analytics_router, dashboard_router

router = APIRouter()

router.include_router(analytics_router.router, prefix="/analytics")
router.include_router(dashboard_router.router)

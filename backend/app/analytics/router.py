from fastapi import APIRouter

from app.analytics.routers import analytics_router

router = APIRouter()

router.include_router(analytics_router.router, prefix="/analytics")

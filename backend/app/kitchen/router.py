from fastapi import APIRouter

from app.kitchen.routers.kds_router import router as kds_router

router = APIRouter()

router.include_router(kds_router)

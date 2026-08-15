from fastapi import APIRouter
from app.system.routers.tenant_router import router as tenant_router
from app.system.routers.database_router import router as database_router

router = APIRouter()
router.include_router(tenant_router)
router.include_router(database_router)

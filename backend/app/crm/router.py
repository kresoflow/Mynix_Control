from fastapi import APIRouter
from app.crm.routers.crm_router import router as crm_subrouter

router = APIRouter(prefix="/crm")
router.include_router(crm_subrouter)

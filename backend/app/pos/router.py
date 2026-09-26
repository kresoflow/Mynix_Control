"""
POS module — API endpoints.
Main router that includes sub-routers for checkout, shifts, and menu.
"""

from fastapi import APIRouter

from app.pos.routers.shift_router import router as shift_router
from app.pos.routers.checkout_router import router as checkout_router
from app.pos.routers.cash_operation_router import router as cash_operation_router

router = APIRouter()

router.include_router(shift_router)
router.include_router(checkout_router)
router.include_router(cash_operation_router)

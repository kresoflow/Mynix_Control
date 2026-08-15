from fastapi import APIRouter
from app.users.routers.auth_router import router as auth_router
from app.users.routers.users_router import router as users_router
from app.users.routers.roles_router import router as roles_router

router = APIRouter()
router.include_router(auth_router)
router.include_router(users_router)
router.include_router(roles_router)

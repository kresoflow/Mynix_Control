from fastapi import APIRouter

from app.inventory.routers.category_router import router as category_router
from app.inventory.routers.ingredient_router import router as ingredient_router
from app.inventory.routers.menu_router import router as menu_router
from app.inventory.routers.recipe_router import router as recipe_router
from app.inventory.routers.stock_router import router as stock_router
from app.inventory.routers.document_router import router as document_router
from app.inventory.routers.supplier_router import router as supplier_router

router = APIRouter()

router.include_router(category_router)
router.include_router(ingredient_router)
router.include_router(menu_router)
router.include_router(recipe_router)
router.include_router(stock_router)
router.include_router(document_router)
router.include_router(supplier_router)

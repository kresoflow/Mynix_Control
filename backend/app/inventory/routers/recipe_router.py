# ==============================================================================
# РОУТЕР: Технологические карты и калькуляция себестоимости (Recipes)
# ДОМЕН: backend/app/inventory/routers/recipe_router.py
# ==============================================================================
#
# [БЕЗОПАСНОСТЬ] [PBAC] Все эндпоинты защищены каноническими правами Perm:
# Perm.MENU_VIEW, Perm.MENU_MANAGE, Perm.ANALYTICS_VIEW.
#
# ==============================================================================

from fastapi import APIRouter, Depends
from app.dependencies import require_permission, TenantSession
from app.inventory.models import RecipeCreate, BulkRecipeCreate
from app.inventory.services import recipe_service as svc
from app.users.permissions import Perm

router = APIRouter(tags=["Recipes"])


# ─── 1. Чтение рецептур и сводки себестоимости ────────────────────────────────

@router.get("/recipes/summary", dependencies=[Depends(require_permission(Perm.MENU_VIEW))])
async def get_recipes_summary(session: TenantSession):
    """Возвращает агрегированную сводку себестоимости и наличия техкарт по меню."""
    return await svc.get_all_recipes_summary(session)


@router.get("/menu/{menu_item_id}/recipe", dependencies=[Depends(require_permission(Perm.MENU_VIEW))])
async def get_recipe(menu_item_id: int, session: TenantSession):
    """Возвращает подробную спецификацию сырья для указанного блюда."""
    return await svc.get_recipe(session, menu_item_id)


@router.get("/menu/{menu_item_id}/food-cost", dependencies=[Depends(require_permission(Perm.ANALYTICS_VIEW))])
async def food_cost(menu_item_id: int, session: TenantSession):
    """Калькулирует фудкост для блюда в реальном времени."""
    cost = await svc.calc_food_cost(session, menu_item_id)
    return {"menu_item_id": menu_item_id, "food_cost_rub": cost}


# ─── 2. Управление ингредиентами техкарты ──────────────────────────────────────

@router.post("/menu/{menu_item_id}/recipe", dependencies=[Depends(require_permission(Perm.MENU_MANAGE))])
async def add_ingredient_to_recipe(menu_item_id: int, data: RecipeCreate, session: TenantSession):
    """Добавляет или обновляет норму расхода сырья в техкарте."""
    await svc.add_ingredient_to_recipe(session, menu_item_id, data.model_dump())
    return {"status": "ok"}


@router.put("/menu/{menu_item_id}/recipe", dependencies=[Depends(require_permission(Perm.MENU_MANAGE))])
async def bulk_update_recipe(menu_item_id: int, data: BulkRecipeCreate, session: TenantSession):
    """Пакетное обновление всей рецептуры блюда."""
    await svc.bulk_update_recipe(session, menu_item_id, [item.model_dump() for item in data.recipes])
    return {"status": "ok"}


@router.delete("/menu/{menu_item_id}/recipe/{ingredient_id}", dependencies=[Depends(require_permission(Perm.MENU_MANAGE))])
async def remove_ingredient_from_recipe(menu_item_id: int, ingredient_id: int, session: TenantSession):
    """Удаляет ингредиент из технологической карты."""
    await svc.remove_ingredient_from_recipe(session, menu_item_id, ingredient_id)
    return {"status": "ok"}

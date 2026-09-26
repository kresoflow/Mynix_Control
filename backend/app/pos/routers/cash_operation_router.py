# ==============================================================================
#  Kreso Flow — POS: Cash Operations Router
#  [БЕЗОПАСНОСТЬ] PBAC защита эндпоинтов кассовых операций (внесение/инкассация).
# ==============================================================================

from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status

from app.dependencies import require_any_permission, CurrentUser, TenantSession
from app.pos.models import (
    CashOperationCreate, CashOperationRead, CashOperationsSummary
)
from app.pos.services.cash_operation_service import (
    create_cash_operation, list_cash_operations, get_cash_operations_summary
)

router = APIRouter(prefix="/cash/operations", tags=["POS — Cash Operations"])


# ──────────────────────────────────────────────────────────────────────────────
#  1. Проведение кассовой операции (Внесение / Расход / Инкассация)
# ──────────────────────────────────────────────────────────────────────────────

@router.post(
    "",
    response_model=dict,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(require_any_permission("pos:cash_operations", "cashbox:operate", "cashbox:expense"))],
)
async def api_create_cash_operation(
    data: CashOperationCreate,
    current_user: CurrentUser,
    session: TenantSession,
):
    """
    [БЕЗОПАСНОСТЬ] Проведение служебного внесения или расхода/инкассации.
    Требует права: pos:cash_operations или cashbox:operate.
    """
    try:
        operation, new_balance = await create_cash_operation(
            session=session,
            user_id=current_user.id,
            data=data,
        )
        return {
            "status": "ok",
            "operation": CashOperationRead(
                id=operation.id,
                client_uuid=operation.client_uuid,
                shift_id=operation.shift_id,
                user_id=operation.user_id,
                user_name=current_user.full_name or f"@{current_user.username}",
                type=operation.type,
                amount=operation.amount,
                category=operation.category,
                comment=operation.comment,
                created_at=operation.created_at,
            ),
            "current_expected_cash": new_balance,
            "message": (
                f"Внесение на сумму {operation.amount:.2f} ₽ успешно проведено"
                if operation.type.value == "deposit"
                else f"Выдача/инкассация на сумму {operation.amount:.2f} ₽ успешно проведена"
            ),
        }
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Ошибка проведения кассовой операции: {str(e)}",
        )


# ──────────────────────────────────────────────────────────────────────────────
#  2. Список кассовых операций (Журнал)
# ──────────────────────────────────────────────────────────────────────────────

@router.get(
    "",
    response_model=List[CashOperationRead],
    dependencies=[Depends(require_any_permission("pos:cash_operations", "cashbox:view", "shifts:view"))],
)
async def api_list_cash_operations(
    session: TenantSession,
    current_user: CurrentUser,
    shift_id: Optional[int] = None,
    limit: int = 50,
    offset: int = 0,
):
    """
    [БЕЗОПАСНОСТЬ] Получение истории кассовых операций по смене.
    Требует права: pos:cash_operations, cashbox:view или shifts:view.
    """
    try:
        return await list_cash_operations(
            session=session,
            shift_id=shift_id,
            limit=limit,
            offset=offset,
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Ошибка получения списка кассовых операций: {str(e)}",
        )


# ──────────────────────────────────────────────────────────────────────────────
#  3. Сводная статистика по кассовым операциям за смену
# ──────────────────────────────────────────────────────────────────────────────

@router.get(
    "/summary",
    response_model=CashOperationsSummary,
    dependencies=[Depends(require_any_permission("pos:cash_operations", "cashbox:view", "shifts:view"))],
)
async def api_cash_operations_summary(
    session: TenantSession,
    current_user: CurrentUser,
    shift_id: Optional[int] = None,
):
    """
    [БЕЗОПАСНОСТЬ] Получение агрегированной сводки кассовых операций по смене.
    """
    try:
        return await get_cash_operations_summary(session=session, shift_id=shift_id)
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Ошибка формирования сводки: {str(e)}",
        )

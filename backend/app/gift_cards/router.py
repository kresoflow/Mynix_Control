# ==============================================================================
# МОДУЛЬ: Подарочные карты (Gift Cards)
# ДОМЕН: app.gift_cards.router
# ==============================================================================
"""
HTTP-роутер API подарочных карт.

[БЕЗОПАСНОСТЬ] Все эндпоинты защищены PBAC (Perm.GIFTCARDS_MANAGE / GIFTCARDS_VIEW).
[ИНВАРИАНТ]   Сессия get_tenant_session изолирует данные в схеме тенанта.
"""

from typing import Annotated, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.dependencies import CurrentUser, get_tenant_session, require_permission
from app.gift_cards import services as gift_card_svc
from app.gift_cards.models import (
    GiftCardCreate,
    GiftCardListResponse,
    GiftCardRead,
    GiftCardRedeem,
    GiftCardTopUp,
    GiftCardUpdateStatus,
)
from app.users.permissions import Perm

router = APIRouter(prefix="/gift-cards", tags=["Gift Cards"])


# ─── 1. Эмиссия и создание карты ──────────────────────────────────────────────

@router.post(
    "",
    response_model=GiftCardRead,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(require_permission(Perm.GIFTCARDS_MANAGE))],
    summary="Выпустить новую подарочную карту",
)
async def create_gift_card(
    card_in: GiftCardCreate,
    current_user: CurrentUser,
    session: Annotated[AsyncSession, Depends(get_tenant_session)],
) -> GiftCardRead:
    """
    Выпускает новую карту с указанным номиналом и сохраняет операцию в журнал.
    
    [БЕЗОПАСНОСТЬ] Требуется право `giftcards:manage`.
    [ТРАНЗАКЦИЯ]   Атомарная генерация карты и начальной транзакции.
    """
    card = await gift_card_svc.issue_gift_card(
        session=session,
        card_in=card_in,
        user_id=current_user.id,
    )
    return card


# ─── 2. Получение и поиск карт ────────────────────────────────────────────────

@router.get(
    "",
    response_model=GiftCardListResponse,
    dependencies=[Depends(require_permission(Perm.GIFTCARDS_VIEW))],
    summary="Список подарочных карт с фильтрацией",
)
async def get_gift_cards(
    session: Annotated[AsyncSession, Depends(get_tenant_session)],
    search: Optional[str] = Query(default=None, description="Поиск по коду или примечанию"),
    is_active: Optional[bool] = Query(default=None, description="Фильтр активности"),
    customer_id: Optional[int] = Query(default=None, description="Фильтр по гостю"),
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
) -> GiftCardListResponse:
    """
    Возвращает список карт заведения с поддержкой пагинации и поиска.
    """
    cards, total = await gift_card_svc.list_gift_cards(
        session=session,
        search=search,
        is_active=is_active,
        customer_id=customer_id,
        limit=limit,
        offset=offset,
    )
    return GiftCardListResponse(items=cards, total=total)


@router.get(
    "/lookup",
    response_model=GiftCardRead,
    dependencies=[Depends(require_permission(Perm.GIFTCARDS_VIEW))],
    summary="Поиск карты по коду / штрихкоду",
)
async def lookup_gift_card(
    code: str,
    session: Annotated[AsyncSession, Depends(get_tenant_session)],
) -> GiftCardRead:
    """
    Находит карту по ее уникальному коду (для проверки баланса на кассе).
    """
    card = await gift_card_svc.get_gift_card_by_code(session=session, code=code)
    if not card:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Подарочная карта с кодом '{code}' не найдена",
        )
    return card


@router.get(
    "/{card_id}",
    response_model=GiftCardRead,
    dependencies=[Depends(require_permission(Perm.GIFTCARDS_VIEW))],
    summary="Детальная информация о подарочной карте",
)
async def get_gift_card(
    card_id: int,
    session: Annotated[AsyncSession, Depends(get_tenant_session)],
) -> GiftCardRead:
    """
    Возвращает карту и полную историю ее транзакций по ID.
    """
    card = await gift_card_svc.get_gift_card_by_id(session=session, card_id=card_id)
    if not card:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Подарочная карта не найдена",
        )
    return card


# ─── 3. Списание и пополнение баланса ─────────────────────────────────────────

@router.post(
    "/{card_id}/redeem",
    response_model=GiftCardRead,
    dependencies=[Depends(require_permission(Perm.GIFTCARDS_MANAGE))],
    summary="Списать средства с подарочной карты",
)
async def redeem_gift_card_endpoint(
    card_id: int,
    redeem_in: GiftCardRedeem,
    current_user: CurrentUser,
    session: Annotated[AsyncSession, Depends(get_tenant_session)],
) -> GiftCardRead:
    """
    Списывает указанную сумму с карты при оплате чека.
    
    [ИНВАРИАНТ] Списание не может превышать текущий баланс карты.
    """
    return await gift_card_svc.redeem_gift_card(
        session=session,
        card_id=card_id,
        redeem_in=redeem_in,
        user_id=current_user.id,
    )


@router.post(
    "/{card_id}/topup",
    response_model=GiftCardRead,
    dependencies=[Depends(require_permission(Perm.GIFTCARDS_MANAGE))],
    summary="Пополнить баланс подарочной карты",
)
async def top_up_gift_card_endpoint(
    card_id: int,
    topup_in: GiftCardTopUp,
    current_user: CurrentUser,
    session: Annotated[AsyncSession, Depends(get_tenant_session)],
) -> GiftCardRead:
    """
    Пополняет текущий баланс карты.
    """
    return await gift_card_svc.top_up_gift_card(
        session=session,
        card_id=card_id,
        topup_in=topup_in,
        user_id=current_user.id,
    )


@router.patch(
    "/{card_id}/status",
    response_model=GiftCardRead,
    dependencies=[Depends(require_permission(Perm.GIFTCARDS_MANAGE))],
    summary="Изменить статус или активность карты",
)
async def update_status_endpoint(
    card_id: int,
    status_in: GiftCardUpdateStatus,
    current_user: CurrentUser,
    session: Annotated[AsyncSession, Depends(get_tenant_session)],
) -> GiftCardRead:
    """
    Блокирует/разблокирует карту или меняет статус.
    """
    return await gift_card_svc.update_gift_card_status(
        session=session,
        card_id=card_id,
        status_in=status_in,
        user_id=current_user.id,
    )

# ==============================================================================
# МОДУЛЬ: Подарочные карты (Gift Cards)
# ДОМЕН: app.gift_cards.services
# ==============================================================================
"""
Сервисный слой бизнес-логики подарочных карт.

[ИНВАРИАНТ]   Запрещено проводить списание суммы, превышающей текущий остаток.
[ТРАНЗАКЦИЯ] Любое изменение баланса карты фиксируется в GiftCardTransaction.
[ФИНАНСЫ]     Все денежные суммы округляются до 2 знаков после запятой.
"""

import random
import string
from datetime import date, datetime, timezone
from typing import List, Optional, Tuple
from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import col, func, select

from app.gift_cards.models import (
    GiftCard,
    GiftCardCreate,
    GiftCardRedeem,
    GiftCardStatus,
    GiftCardTopUp,
    GiftCardTransaction,
    GiftCardTransactionType,
    GiftCardUpdateStatus,
)

# ─── 1. Вспомогательные генераторы ────────────────────────────────────────────

async def generate_unique_card_code(session: AsyncSession) -> str:
    """Генерирует уникальный код карты формата GC-XXXX-XXXX."""
    chars = string.ascii_uppercase + string.digits
    for _ in range(10):
        code = f"GC-{''.join(random.choices(chars, k=4))}-{''.join(random.choices(chars, k=4))}"
        res = await session.execute(select(GiftCard).where(GiftCard.code == code))
        if res.scalars().first() is None:
            return code
    return f"GC-{int(datetime.now(timezone.utc).timestamp())}"

# ─── 2. Эмиссия и выпуск карты ────────────────────────────────────────────────

async def issue_gift_card(
    session: AsyncSession,
    card_in: GiftCardCreate,
    user_id: Optional[int] = None,
) -> GiftCard:
    """Выпускает новую подарочную карту и фиксирует операцию эмиссии."""
    if card_in.initial_balance <= 0:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Номинал карты должен быть > 0")

    code = (card_in.code or "").strip().upper()
    if not code:
        code = await generate_unique_card_code(session)
    else:
        existing = await session.execute(select(GiftCard).where(GiftCard.code == code))
        if existing.scalars().first() is not None:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"Подарочная карта с кодом '{code}' уже зарегистрирована",
            )

    nominal = round(float(card_in.initial_balance), 2)
    card = GiftCard(
        code=code,
        initial_balance=nominal,
        current_balance=nominal,
        status=GiftCardStatus.ACTIVE,
        is_active=True,
        expiry_date=card_in.expiry_date,
        customer_id=card_in.customer_id,
        notes=card_in.notes,
        created_by=user_id,
    )
    session.add(card)
    await session.flush()

    session.add(GiftCardTransaction(
        gift_card_id=card.id,
        type=GiftCardTransactionType.ISSUE,
        amount=nominal,
        balance_before=0.0,
        balance_after=nominal,
        comment=card_in.notes or "Первичный выпуск карты",
        created_by=user_id,
    ))
    await session.flush()
    await session.refresh(card)
    return card

# ─── 3. Списание средств и оплата ─────────────────────────────────────────────

async def redeem_gift_card(
    session: AsyncSession,
    card_id: int,
    redeem_in: GiftCardRedeem,
    user_id: Optional[int] = None,
) -> GiftCard:
    """Списывает средства с баланса подарочной карты при оплате чека."""
    card = await session.get(GiftCard, card_id, with_for_update=True, populate_existing=True)
    if not card:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Подарочная карта не найдена")

    # [ИНВАРИАНТ] Идемпотентность: повторная отправка с тем же client_uuid возвращает результат без изменения баланса
    if redeem_in.client_uuid:
        existing_stmt = select(GiftCardTransaction).where(
            GiftCardTransaction.gift_card_id == card.id,
            GiftCardTransaction.client_uuid == redeem_in.client_uuid,
        )
        existing_txn = (await session.execute(existing_stmt)).scalars().first()
        if existing_txn:
            return card

    if not card.is_active or card.status == GiftCardStatus.BLOCKED:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Карта заблокирована или неактивна")

    if card.expiry_date and card.expiry_date < date.today():
        card.status = GiftCardStatus.EXPIRED
        session.add(card)
        await session.flush()
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Срок действия карты истёк")

    amount = round(float(redeem_in.amount), 2)
    if amount <= 0:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Сумма списания должна быть > 0")
    if amount > card.current_balance:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Недостаточно средств. Доступно: {card.current_balance:.2f} сом, запрошено: {amount:.2f} сом",
        )

    b_before, b_after = card.current_balance, round(card.current_balance - amount, 2)
    card.current_balance = b_after
    if b_after <= 0.001:
        card.status = GiftCardStatus.EXHAUSTED

    session.add(card)
    session.add(GiftCardTransaction(
        gift_card_id=card.id,
        order_id=redeem_in.order_id,
        client_uuid=redeem_in.client_uuid,
        type=GiftCardTransactionType.REDEEM,
        amount=amount,
        balance_before=b_before,
        balance_after=b_after,
        comment=redeem_in.notes or "Оплата заказа",
        created_by=user_id,
    ))
    await session.flush()
    await session.refresh(card)
    return card

# ─── 4. Пополнение баланса ────────────────────────────────────────────────────

async def top_up_gift_card(
    session: AsyncSession,
    card_id: int,
    topup_in: GiftCardTopUp,
    user_id: Optional[int] = None,
) -> GiftCard:
    """Пополняет баланс существующей подарочной карты."""
    card = await session.get(GiftCard, card_id, with_for_update=True, populate_existing=True)
    if not card:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Подарочная карта не найдена")

    # [ИНВАРИАНТ] Идемпотентность: повторная отправка с тем же client_uuid возвращает результат без изменения баланса
    if topup_in.client_uuid:
        existing_stmt = select(GiftCardTransaction).where(
            GiftCardTransaction.gift_card_id == card.id,
            GiftCardTransaction.client_uuid == topup_in.client_uuid,
        )
        existing_txn = (await session.execute(existing_stmt)).scalars().first()
        if existing_txn:
            return card

    if not card.is_active or card.status == GiftCardStatus.BLOCKED:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Нельзя пополнить заблокированную карту")

    amount = round(float(topup_in.amount), 2)
    if amount <= 0:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Сумма пополнения должна быть > 0")

    b_before, b_after = card.current_balance, round(card.current_balance + amount, 2)
    card.current_balance = b_after
    card.status = GiftCardStatus.ACTIVE

    session.add(card)
    session.add(GiftCardTransaction(
        gift_card_id=card.id,
        client_uuid=topup_in.client_uuid,
        type=GiftCardTransactionType.TOPUP,
        amount=amount,
        balance_before=b_before,
        balance_after=b_after,
        comment=topup_in.notes or "Пополнение баланса",
        created_by=user_id,
    ))
    await session.flush()
    await session.refresh(card)
    return card

# ─── 5. Поиск и фильтрация ───────────────────────────────────────────────────

async def get_gift_card_by_id(session: AsyncSession, card_id: int) -> Optional[GiftCard]:
    return await session.get(GiftCard, card_id)

async def get_gift_card_by_code(session: AsyncSession, code: str) -> Optional[GiftCard]:
    res = await session.execute(select(GiftCard).where(GiftCard.code == code.strip().upper()))
    return res.scalars().first()

async def list_gift_cards(
    session: AsyncSession,
    search: Optional[str] = None,
    is_active: Optional[bool] = None,
    customer_id: Optional[int] = None,
    limit: int = 50,
    offset: int = 0,
) -> Tuple[List[GiftCard], int]:
    stmt = select(GiftCard)
    if search:
        s = f"%{search.strip()}%"
        stmt = stmt.where(col(GiftCard.code).ilike(s) | col(GiftCard.notes).ilike(s))
    if is_active is not None:
        stmt = stmt.where(GiftCard.is_active == is_active)
    if customer_id is not None:
        stmt = stmt.where(GiftCard.customer_id == customer_id)

    count_res = await session.execute(select(func.count()).select_from(stmt.subquery()))
    total_count = count_res.scalar_one()

    stmt = stmt.order_by(col(GiftCard.id).desc()).limit(limit).offset(offset)
    res = await session.execute(stmt)
    return list(res.scalars().all()), total_count

async def update_gift_card_status(
    session: AsyncSession,
    card_id: int,
    status_in: GiftCardUpdateStatus,
    user_id: Optional[int] = None,
) -> GiftCard:
    card = await session.get(GiftCard, card_id)
    if not card:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Подарочная карта не найдена")
    if status_in.is_active is not None:
        card.is_active = status_in.is_active
    if status_in.status is not None:
        card.status = status_in.status
    if status_in.notes is not None:
        card.notes = status_in.notes

    session.add(card)
    await session.flush()
    await session.refresh(card)
    return card

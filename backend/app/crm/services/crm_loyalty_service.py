from typing import List, Optional, Dict
from datetime import datetime, timezone
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select, func
from fastapi import HTTPException, status

from app.crm.models import (
    Customer, BonusTransaction, BonusTransactionType,
    CreateBonusTransactionRequest, BonusTransactionRead
)

TIER_CASHBACK_RATES = {
    "standard": 0.03,  # 3%
    "silver": 0.05,    # 5%
    "gold": 0.10,      # 10%
}

async def get_customer_bonus_transactions(
    session: AsyncSession,
    customer_id: int,
) -> List[BonusTransactionRead]:
    stmt = (
        select(BonusTransaction)
        .where(BonusTransaction.customer_id == customer_id)
        .order_by(BonusTransaction.date.desc(), BonusTransaction.id.desc())
    )
    result = await session.execute(stmt)
    txns = result.scalars().all()

    return [
        BonusTransactionRead(
            id=t.id,
            customer_id=t.customer_id,
            order_id=t.order_id,
            type=t.type,
            amount=t.amount,
            comment=t.comment,
            date=t.date,
            created_by=t.created_by,
        )
        for t in txns
    ]

async def create_bonus_transaction(
    session: AsyncSession,
    customer_id: int,
    data: CreateBonusTransactionRequest,
    user_id: Optional[int] = None,
) -> BonusTransactionRead:
    customer = await session.get(Customer, customer_id)
    if not customer or not customer.is_active:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Клиент не найден")

    if data.amount <= 0:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Сумма бонусов должна быть больше нуля")

    is_deduction = data.type in [
        BonusTransactionType.REDEEM,
        BonusTransactionType.MANUAL_DEDUCTION,
        BonusTransactionType.EXPIRED,
    ]

    if is_deduction:
        if (customer.bonus_balance or 0.0) < data.amount:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Недостаточно бонусов. Доступно: {customer.bonus_balance:.2f} с"
            )
        customer.bonus_balance = round(customer.bonus_balance - data.amount, 2)
    else:
        customer.bonus_balance = round((customer.bonus_balance or 0.0) + data.amount, 2)

    txn = BonusTransaction(
        customer_id=customer.id,
        type=data.type,
        amount=data.amount,
        comment=data.comment or ("Начисление бонусов" if not is_deduction else "Списание бонусов"),
        date=datetime.now(timezone.utc).replace(tzinfo=None),
        created_by=user_id,
    )
    session.add(txn)
    session.add(customer)
    await session.flush()

    return BonusTransactionRead(
        id=txn.id,
        customer_id=txn.customer_id,
        order_id=txn.order_id,
        type=txn.type,
        amount=txn.amount,
        comment=txn.comment,
        date=txn.date,
        created_by=txn.created_by,
    )

async def update_customer_ltv_and_loyalty(
    session: AsyncSession,
    customer: Customer,
    order_total: float,
    order_id: Optional[int] = None,
    bonus_spent: float = 0.0,
    user_id: Optional[int] = None,
) -> None:
    """
    Called upon POS order completion:
    - Increments LTV (total_spent) and orders_count
    - Updates average check & last visit timestamp
    - Recalculates tier level
    - Deducts redeemed bonus_spent (if any)
    - Accrues cashback bonuses based on tier rate
    """
    now = datetime.now(timezone.utc).replace(tzinfo=None)

    # 1. Update LTV metrics
    customer.orders_count = (customer.orders_count or 0) + 1
    customer.total_spent = round((customer.total_spent or 0.0) + order_total, 2)
    customer.average_check = round(customer.total_spent / customer.orders_count, 2)
    customer.last_visit_at = now

    # 2. Tier level progression
    if customer.total_spent >= 30000.0:
        customer.tier_level = "gold"
    elif customer.total_spent >= 10000.0:
        customer.tier_level = "silver"
    else:
        customer.tier_level = "standard"

    cashback_rate = TIER_CASHBACK_RATES.get(customer.tier_level, 0.03)

    # 3. Process redeemed bonuses
    if bonus_spent > 0:
        if (customer.bonus_balance or 0.0) < bonus_spent:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Недостаточно бонусов на счете клиента ({customer.bonus_balance:.2f} с)"
            )
        customer.bonus_balance = round(customer.bonus_balance - bonus_spent, 2)
        redeem_txn = BonusTransaction(
            customer_id=customer.id,
            order_id=order_id,
            type=BonusTransactionType.REDEEM,
            amount=bonus_spent,
            comment=f"Оплата бонусами чека #{order_id or ''}".strip(),
            date=now,
            created_by=user_id,
        )
        session.add(redeem_txn)

    # 4. Accrue cashback bonus on money paid (excluding redeemed bonuses)
    cash_paid = max(0.0, order_total - bonus_spent)
    if cash_paid > 0:
        cashback_earned = round(cash_paid * cashback_rate, 2)
        if cashback_earned > 0:
            customer.bonus_balance = round((customer.bonus_balance or 0.0) + cashback_earned, 2)
            cashback_txn = BonusTransaction(
                customer_id=customer.id,
                order_id=order_id,
                type=BonusTransactionType.CASHBACK,
                amount=cashback_earned,
                comment=f"Кешбэк {int(cashback_rate * 100)}% по чеку #{order_id or ''}".strip(),
                date=now,
                created_by=user_id,
            )
            session.add(cashback_txn)

    session.add(customer)
    await session.flush()

"""
Helper functions for checkout financial processing: customer balance, debt/deposit, and cashbox transactions.
"""

from typing import Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select

from app.pos.models import (
    Order, Shift, CashTransaction, PaymentMethod, CashTransactionType, CreateOrderRequest
)


async def process_customer_checkout(
    session: AsyncSession,
    data: CreateOrderRequest,
    total: float,
    order: Order,
    user_id: int,
) -> None:
    """[PILOT LEAN MVP] Обработка CRM/лояльности и долгов клиентов отключена для пилота."""
    return


async def process_cash_income(
    session: AsyncSession,
    shift: Shift,
    user_id: int,
    order_number: int,
    total: float,
    data: CreateOrderRequest,
) -> None:
    """Record cash income in cashbox shift if paid by CASH or MIXED."""
    if data.payment_method in (PaymentMethod.CASH, PaymentMethod.MIXED):
        cash_paid = max(0.0, total - (data.bonus_spent or 0.0))
        cash_amount = cash_paid if data.payment_method == PaymentMethod.CASH else cash_paid / 2
        if cash_amount > 0:
            txn = CashTransaction(
                shift_id=shift.id,
                user_id=user_id,
                type=CashTransactionType.INCOME,
                amount=round(cash_amount, 2),
                description=f"Order #{order_number} payment",
            )
            session.add(txn)

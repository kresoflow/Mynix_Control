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
    """Process customer debt, deposit, loyalty tier, and bonus redemption."""
    if not data.customer_id:
        return

    from app.crm.models import Customer, CustomerTransaction, CustomerTransactionType
    from app.crm.services.crm_loyalty_service import update_customer_ltv_and_loyalty

    # Lock customer row with FOR UPDATE to prevent race conditions during debt/deposit/loyalty updates
    cust_stmt = select(Customer).where(Customer.id == data.customer_id).with_for_update()
    cust_res = await session.execute(cust_stmt)
    customer = cust_res.scalar_one_or_none()
    if not customer or not customer.is_active:
        raise ValueError(f"Клиент #{data.customer_id} не найден или деактивирован")

    # Handle Debt/Deposit payments
    if data.payment_method == PaymentMethod.DEBT:
        net_debt = max(0.0, total - (data.bonus_spent or 0.0))
        if customer.credit_limit > 0 and (customer.balance - net_debt) < -customer.credit_limit:
            raise ValueError(
                f"Превышен кредитный лимит гостя ({customer.credit_limit} с). Текущий баланс: {customer.balance} с."
            )
        customer.balance = round(customer.balance - net_debt, 2)
        c_txn = CustomerTransaction(
            customer_id=customer.id,
            order_id=order.id,
            type=CustomerTransactionType.ORDER_DEBT,
            amount=round(net_debt, 2),
            payment_method="debt",
            comment=f"Заказ #{order.order_number} (В долг)",
            created_by=user_id,
        )
        session.add(customer)
        session.add(c_txn)

    elif data.payment_method == PaymentMethod.DEPOSIT:
        net_deposit = max(0.0, total - (data.bonus_spent or 0.0))
        if customer.balance < net_deposit:
            raise ValueError(
                f"Недостаточно средств на депозите ({customer.balance} с). Сумма к списанию: {net_deposit} с."
            )
        customer.balance = round(customer.balance - net_deposit, 2)
        c_txn = CustomerTransaction(
            customer_id=customer.id,
            order_id=order.id,
            type=CustomerTransactionType.ORDER_DEPOSIT,
            amount=round(net_deposit, 2),
            payment_method="deposit",
            comment=f"Заказ #{order.order_number} (С депозита)",
            created_by=user_id,
        )
        session.add(customer)
        session.add(c_txn)

    # Update LTV, Tier progression, cashback accrual, and bonus redemption
    await update_customer_ltv_and_loyalty(
        session=session,
        customer=customer,
        order_total=total,
        order_id=order.id,
        bonus_spent=data.bonus_spent or 0.0,
        user_id=user_id,
    )


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

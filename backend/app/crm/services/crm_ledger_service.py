"""
CRM Ledger and Transaction Services.
Handles customer account balances, debt/deposit transactions, and order history.
"""

from typing import List, Optional
from datetime import datetime, timezone
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select
from fastapi import HTTPException, status

from app.crm.models import (
    Customer, CustomerTransaction, CustomerTransactionType,
    CustomerTransactionCreate, CustomerTransactionRead
)
from app.pos.models import Shift, CashTransaction, CashTransactionType


async def get_customer_transactions(
    session: AsyncSession,
    customer_id: int,
) -> List[CustomerTransactionRead]:
    """Retrieve all financial ledger entries for a customer."""
    customer = await session.get(Customer, customer_id)
    if not customer or not customer.is_active:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Клиент не найден")

    stmt = (
        select(CustomerTransaction)
        .where(CustomerTransaction.customer_id == customer_id)
        .order_by(CustomerTransaction.date.desc(), CustomerTransaction.id.desc())
    )
    result = await session.execute(stmt)
    txns = result.scalars().all()

    return [
        CustomerTransactionRead(
            id=t.id,
            customer_id=t.customer_id,
            order_id=t.order_id,
            type=t.type,
            amount=t.amount,
            payment_method=t.payment_method,
            comment=t.comment,
            date=t.date,
            created_by=t.created_by,
        )
        for t in txns
    ]


async def create_customer_transaction(
    session: AsyncSession,
    customer_id: int,
    txn_in: CustomerTransactionCreate,
    user_id: Optional[int] = None,
) -> CustomerTransactionRead:
    """Post a debt payment or deposit to a customer balance with row-level lock."""
    # Row-level lock on Customer to avoid balance race conditions
    stmt = select(Customer).where(Customer.id == customer_id).with_for_update()
    res = await session.execute(stmt)
    customer = res.scalar_one_or_none()
    if not customer or not customer.is_active:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Клиент не найден")

    if txn_in.amount <= 0:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Сумма должна быть больше нуля")

    txn = CustomerTransaction(
        customer_id=customer.id,
        type=txn_in.type,
        amount=txn_in.amount,
        payment_method=txn_in.payment_method,
        comment=txn_in.comment,
        date=txn_in.date or datetime.now(timezone.utc).replace(tzinfo=None),
        created_by=user_id,
    )
    session.add(txn)

    if txn_in.type in [CustomerTransactionType.PAYMENT, CustomerTransactionType.DEPOSIT]:
        customer.balance = round((customer.balance or 0.0) + txn_in.amount, 2)
    elif txn_in.type in [CustomerTransactionType.ORDER_DEBT, CustomerTransactionType.ORDER_DEPOSIT]:
        customer.balance = round((customer.balance or 0.0) - txn_in.amount, 2)
    elif txn_in.type == CustomerTransactionType.ADJUSTMENT:
        customer.balance = round((customer.balance or 0.0) + txn_in.amount, 2)

    session.add(customer)
    await session.flush()

    # Cash transaction in shift if cash
    if txn_in.payment_method.lower() == "cash" and txn_in.type in [CustomerTransactionType.PAYMENT, CustomerTransactionType.DEPOSIT]:
        shift_stmt = select(Shift).where(Shift.is_open == True)
        shift_res = await session.execute(shift_stmt)
        open_shift = shift_res.scalars().first()
        if open_shift:
            cash_tx = CashTransaction(
                shift_id=open_shift.id,
                user_id=user_id or open_shift.opened_by,
                type=CashTransactionType.INCOME,
                amount=txn_in.amount,
                description=f"CRM: {txn_in.comment or 'Погашение долга/депозит'} ({customer.name})",
            )
            session.add(cash_tx)
            await session.flush()

    return CustomerTransactionRead(
        id=txn.id,
        customer_id=txn.customer_id,
        order_id=txn.order_id,
        type=txn.type,
        amount=txn.amount,
        payment_method=txn.payment_method,
        comment=txn.comment,
        date=txn.date,
        created_by=txn.created_by,
    )


async def get_customer_orders(session: AsyncSession, customer_id: int) -> list:
    """Fetch all orders placed by this customer."""
    from app.pos.models import Order
    from sqlalchemy.orm import selectinload
    stmt = (
        select(Order)
        .where(Order.customer_id == customer_id)
        .options(selectinload(Order.items))
        .order_by(Order.created_at.desc())
    )
    result = await session.execute(stmt)
    orders = result.scalars().all()
    return [
        {
            "id": o.id,
            "order_number": o.order_number,
            "status": o.status,
            "payment_method": o.payment_method,
            "total": o.total,
            "bonus_spent": getattr(o, 'bonus_spent', 0.0) or 0.0,
            "note": o.note,
            "created_at": o.created_at.isoformat(),
            "items": [
                {
                    "menu_item_name": oi.menu_item_name,
                    "quantity": oi.quantity,
                    "unit_price": oi.unit_price,
                    "subtotal": oi.subtotal,
                    "selected_options": oi.selected_options,
                    "item_type": oi.item_type,
                }
                for oi in o.items
            ],
        }
        for o in orders
    ]

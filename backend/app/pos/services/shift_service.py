from datetime import datetime, timezone
from typing import Optional

from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select, func

from app.pos.models import (
    Shift, CashTransaction, CashTransactionType, Order, PaymentMethod, OrderStatus
)


async def get_open_shift(
    session: AsyncSession,
) -> Optional[Shift]:
    """Get the currently open shift for a tenant (if any)."""
    stmt = select(Shift).where(Shift.is_open == True)
    result = await session.execute(stmt)
    return result.scalar_one_or_none()


async def calculate_expected_cash(
    session: AsyncSession,
    shift_id: int,
    opening_cash: float,
) -> float:
    """Calculate the current expected cash in drawer for a shift."""
    stmt_income = select(
        func.coalesce(func.sum(CashTransaction.amount), 0)
    ).where(
        CashTransaction.shift_id == shift_id,
        CashTransaction.type == CashTransactionType.INCOME.value,
    )
    res_inc = await session.execute(stmt_income)
    total_income = float(res_inc.scalar() or 0.0)

    stmt_expenses = select(
        func.coalesce(func.sum(CashTransaction.amount), 0)
    ).where(
        CashTransaction.shift_id == shift_id,
        CashTransaction.type.in_([
            CashTransactionType.EXPENSE.value,
            CashTransactionType.WITHDRAWAL.value,
        ]),
    )
    res_exp = await session.execute(stmt_expenses)
    total_expenses = float(res_exp.scalar() or 0.0)

    return round(opening_cash + total_income - total_expenses, 2)


async def open_shift(
    session: AsyncSession,
    user_id: int,
    opening_cash: float,
) -> Shift:
    """Open a new cash shift. Only one shift can be open at a time."""
    existing = await get_open_shift(session)
    if existing:
        raise ValueError(f"Shift #{existing.id} is already open. Close it first.")

    shift = Shift(
        opened_by=user_id,
        opening_cash=opening_cash,
        is_open=True,
    )
    session.add(shift)
    await session.flush()
    return shift


async def close_shift(
    session: AsyncSession,
    user_id: int,
    closing_cash_actual: float,
) -> Shift:
    """Close the current open shift and calculate discrepancy."""
    shift = await get_open_shift(session)
    if not shift:
        raise ValueError("Cannot close shift: no open shift found.")

    expected = await calculate_expected_cash(session, shift.id, shift.opening_cash)

    shift.closed_by = user_id
    shift.closed_at = datetime.now(timezone.utc).replace(tzinfo=None)
    shift.closing_cash_expected = round(expected, 2)
    shift.closing_cash_actual = closing_cash_actual
    shift.discrepancy = round(closing_cash_actual - expected, 2)
    shift.is_open = False
    session.add(shift)
    await session.flush()

    return shift


async def record_expense(
    session: AsyncSession,
    user_id: int,
    amount: float,
    description: str,
) -> CashTransaction:
    """Record a cash expense during an open shift (e.g., buying napkins)."""
    shift = await get_open_shift(session)
    if not shift:
        raise ValueError("Cannot record expense: no open shift.")

    txn = CashTransaction(
        shift_id=shift.id,
        user_id=user_id,
        type=CashTransactionType.EXPENSE,
        amount=amount,
        description=description,
    )
    session.add(txn)
    await session.flush()
    return txn


async def get_x_report(
    session: AsyncSession,
    shift_id: int,
) -> dict:
    """
    Generate X-Report statistics for a shift.
    Includes revenue by payment method (cash vs transfer), expected cash, orders count, average check.
    """
    stmt_shift = select(Shift).where(Shift.id == shift_id)
    res_shift = await session.execute(stmt_shift)
    shift = res_shift.scalar_one_or_none()
    if not shift:
        raise ValueError(f"Shift #{shift_id} not found.")

    # Calculate Cash Sales
    stmt_cash = select(func.coalesce(func.sum(Order.total), 0)).where(
        Order.shift_id == shift_id,
        Order.payment_method == PaymentMethod.CASH.value,
        Order.status != OrderStatus.CANCELLED.value,
    )
    res_cash = await session.execute(stmt_cash)
    cash_sales = float(res_cash.scalar() or 0.0)

    # Calculate Transfer Sales
    stmt_transfer = select(func.coalesce(func.sum(Order.total), 0)).where(
        Order.shift_id == shift_id,
        Order.payment_method.in_([PaymentMethod.TRANSFER.value, PaymentMethod.CARD.value]),
        Order.status != OrderStatus.CANCELLED.value,
    )
    res_transfer = await session.execute(stmt_transfer)
    transfer_sales = float(res_transfer.scalar() or 0.0)

    # Total Orders Count
    stmt_count = select(func.count(Order.id)).where(
        Order.shift_id == shift_id,
        Order.status != OrderStatus.CANCELLED.value,
    )
    res_count = await session.execute(stmt_count)
    orders_count = int(res_count.scalar() or 0)

    # Cancelled Orders Count
    stmt_cancelled = select(func.count(Order.id)).where(
        Order.shift_id == shift_id,
        Order.status == OrderStatus.CANCELLED.value,
    )
    res_cancelled = await session.execute(stmt_cancelled)
    cancelled_count = int(res_cancelled.scalar() or 0)

    total_revenue = cash_sales + transfer_sales
    avg_check = round(total_revenue / orders_count, 2) if orders_count > 0 else 0.0

    # Expenses / Withdrawals
    stmt_exp = select(func.coalesce(func.sum(CashTransaction.amount), 0)).where(
        CashTransaction.shift_id == shift_id,
        CashTransaction.type.in_([CashTransactionType.EXPENSE.value, CashTransactionType.WITHDRAWAL.value]),
    )
    res_exp = await session.execute(stmt_exp)
    cash_expenses = float(res_exp.scalar() or 0.0)

    # Expected Cash in drawer unified with calculate_expected_cash
    expected_cash = await calculate_expected_cash(session, shift.id, shift.opening_cash)

    return {
        "shift_id": shift.id,
        "is_open": shift.is_open,
        "opened_at": shift.opened_at.isoformat() if shift.opened_at else None,
        "opening_cash": shift.opening_cash,
        "cash_sales": cash_sales,
        "transfer_sales": transfer_sales,
        "total_revenue": round(total_revenue, 2),
        "orders_count": orders_count,
        "cancelled_count": cancelled_count,
        "average_check": avg_check,
        "cash_expenses": cash_expenses,
        "expected_cash": expected_cash,
    }


async def get_shifts_history(
    session: AsyncSession,
    limit: int = 50,
    offset: int = 0,
) -> list[dict]:
    """Retrieve history of past and current shifts with revenue and discrepancy metrics."""
    stmt_shifts = (
        select(Shift)
        .order_by(Shift.id.desc())
        .limit(limit)
        .offset(offset)
    )
    res_shifts = await session.execute(stmt_shifts)
    shifts = res_shifts.scalars().all()

    history = []
    for shift in shifts:
        stmt_sales = select(
            func.coalesce(func.sum(Order.total), 0).label("total_rev"),
            func.count(Order.id).label("orders_count"),
        ).where(
            Order.shift_id == shift.id,
            Order.status != OrderStatus.CANCELLED.value,
        )
        res_sales = await session.execute(stmt_sales)
        row = res_sales.one_or_none()
        total_rev = float(row[0] if row else 0.0)
        cnt = int(row[1] if row else 0)

        history.append({
            "id": shift.id,
            "is_open": shift.is_open,
            "opened_at": shift.opened_at.isoformat() if shift.opened_at else None,
            "closed_at": shift.closed_at.isoformat() if shift.closed_at else None,
            "opened_by": shift.opened_by,
            "closed_by": shift.closed_by,
            "opening_cash": shift.opening_cash,
            "total_revenue": round(total_rev, 2),
            "orders_count": cnt,
            "closing_cash_expected": shift.closing_cash_expected,
            "closing_cash_actual": shift.closing_cash_actual,
            "discrepancy": shift.discrepancy,
        })

    return history


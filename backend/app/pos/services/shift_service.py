from datetime import datetime, timezone
from typing import Optional

from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select, func

from app.pos.models import (
    Shift, CashTransaction, CashTransactionType
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
    """Calculate the current expected cash for a shift."""
    stmt_income = select(
        func.coalesce(func.sum(CashTransaction.amount), 0)
    ).where(
        CashTransaction.shift_id == shift_id,
        CashTransaction.type == CashTransactionType.INCOME,
    )
    res_inc = await session.execute(stmt_income)
    total_income = res_inc.scalar() or 0.0

    stmt_expenses = select(
        func.coalesce(func.sum(CashTransaction.amount), 0)
    ).where(
        CashTransaction.shift_id == shift_id,
        CashTransaction.type.in_([
            CashTransactionType.EXPENSE,
            CashTransactionType.WITHDRAWAL,
        ]),
    )
    res_exp = await session.execute(stmt_expenses)
    total_expenses = res_exp.scalar() or 0.0

    return opening_cash + total_income - total_expenses


async def open_shift(
    session: AsyncSession,
    user_id: int,
    opening_cash: float,
) -> Shift:
    """
    Open a new cash shift. Only one shift can be open per tenant.
    Raises ValueError if a shift is already open.
    """
    existing = await get_open_shift(session)
    if existing:
        raise ValueError(
            f"Shift #{existing.id} is already open. Close it before opening a new one."
        )

    shift = Shift(
        opened_by=user_id,
        opening_cash=opening_cash,
    )
    session.add(shift)
    await session.flush()
    return shift


async def close_shift(
    session: AsyncSession,
    user_id: int,
    closing_cash_actual: float,
) -> Shift:
    """
    Close the current shift.
    Calculates expected cash and discrepancy.
    Expected = opening_cash + cash_income - cash_expenses
    Discrepancy = actual - expected (negative = shortage)
    """
    shift = await get_open_shift(session)
    if not shift:
        raise ValueError("No open shift to close.")

    expected = await calculate_expected_cash(session, shift.id, shift.opening_cash)

    shift.closed_by = user_id
    shift.closed_at = datetime.now(timezone.utc)
    shift.closing_cash_expected = round(expected, 2)
    shift.closing_cash_actual = closing_cash_actual
    shift.discrepancy = round(closing_cash_actual - expected, 2)
    shift.is_open = False
    session.add(shift)

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
    return txn

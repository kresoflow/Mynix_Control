from typing import Optional

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from app.dependencies import require_permission, CurrentUser, TenantSession
from app.pos.models import (
    OpenShiftRequest, CloseShiftRequest, RecordExpenseRequest
)
from app.pos.services.shift_service import (
    open_shift, close_shift, get_open_shift,
    calculate_expected_cash, record_expense, get_x_report
)

router = APIRouter(tags=["POS — Shifts, Cash"])


@router.post(
    "/shifts/open",
    dependencies=[Depends(require_permission("shifts:open"))],
)
async def api_open_shift(
    data: OpenShiftRequest,
    current_user: CurrentUser,
    session: TenantSession,
):
    """Open a new cash shift. Only one open shift per tenant allowed."""
    try:
        shift = await open_shift(session, current_user.id, data.opening_cash)
        return {
            "status": "ok",
            "shift_id": shift.id,
            "message": f"Shift #{shift.id} opened with {data.opening_cash} RUB",
        }
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post(
    "/shifts/close",
    dependencies=[Depends(require_permission("shifts:close"))],
)
async def api_close_shift(
    data: CloseShiftRequest,
    current_user: CurrentUser,
    session: TenantSession,
):
    """Close the current shift with actual cash count."""
    try:
        shift = await close_shift(
            session, current_user.id, data.closing_cash_actual
        )
        return {
            "status": "ok",
            "shift_id": shift.id,
            "opening_cash": shift.opening_cash,
            "expected": shift.closing_cash_expected,
            "actual": shift.closing_cash_actual,
            "discrepancy": shift.discrepancy,
            "message": (
                "✅ No discrepancy" if shift.discrepancy == 0
                else f"⚠️ Discrepancy: {shift.discrepancy:+.2f} RUB"
            ),
        }
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get(
    "/shifts/current",
    dependencies=[Depends(require_permission("shifts:view"))],
)
async def api_current_shift(
    current_user: CurrentUser,
    session: TenantSession,
):
    """Get the currently open shift (or null if none)."""
    try:
        shift = await get_open_shift(session)
        if not shift:
            return {"shift": None, "message": "No open shift"}
        
        current_cash_expected = await calculate_expected_cash(
            session, shift.id, shift.opening_cash
        )

        return {
            "shift": {
                "id": shift.id,
                "opened_by": shift.opened_by,
                "opened_at": shift.opened_at.isoformat(),
                "opening_cash": shift.opening_cash,
                "current_cash_expected": current_cash_expected,
            }
        }
    except Exception as e:
        import traceback
        return {"error": str(e), "traceback": traceback.format_exc()}


@router.post(
    "/cash/expense",
    dependencies=[Depends(require_permission("cashbox:expense"))],
)
async def api_record_expense(
    data: RecordExpenseRequest,
    current_user: CurrentUser,
    session: TenantSession,
):
    """Record a cash expense during the current shift."""
    try:
        txn = await record_expense(
            session, current_user.id, data.amount, data.description
        )
        return {
            "status": "ok",
            "transaction_id": txn.id,
            "amount": data.amount,
            "description": data.description,
        }
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get(
    "/shifts/x-report",
    dependencies=[Depends(require_permission("shifts:view"))],
)
async def api_x_report(
    current_user: CurrentUser,
    session: TenantSession,
):
    """Get real-time intermediate X-Report for current open shift."""
    shift = await get_open_shift(session)
    if not shift:
        raise HTTPException(status_code=404, detail="No active open shift found.")
    
    report = await get_x_report(session, shift.id)
    return report

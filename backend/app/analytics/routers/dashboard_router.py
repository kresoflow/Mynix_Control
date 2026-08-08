from fastapi import APIRouter, Depends
from app.dependencies import require_permission, CurrentUser, TenantSession
from app.analytics.models import DashboardTodayRead
from app.analytics.services import dashboard_service as svc

router = APIRouter()

@router.get("/dashboard/today", response_model=DashboardTodayRead, dependencies=[Depends(require_permission("analytics:view"))])
async def get_dashboard_today(
    current_user: CurrentUser,
    session: TenantSession
):
    """
    Get dashboard analytics for the current active shift.
    """
    return await svc.get_today_dashboard(session)

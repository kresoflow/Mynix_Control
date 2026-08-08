from fastapi import APIRouter, Depends, Query
from datetime import datetime, date, timedelta, timezone
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Optional

from app.dependencies import get_tenant_session, require_permission
from app.analytics.models import AnalyticsMetrics, AnalyticsXRay
from app.analytics.services.analytics_service import get_analytics_metrics, get_analytics_xray

router = APIRouter(tags=["Analytics V2"])

def get_start_end(period: str, start: Optional[date] = None, end: Optional[date] = None):
    # Align 'now' with how DB saves timestamps (UTC naive)
    now = datetime.now(timezone.utc).replace(tzinfo=None)
    if period == "today":
        start_date = now.replace(hour=0, minute=0, second=0, microsecond=0)
        end_date = now.replace(hour=23, minute=59, second=59, microsecond=999999)
        group_by = "hour"
    elif period == "week":
        start_date = (now - timedelta(days=now.weekday())).replace(hour=0, minute=0, second=0, microsecond=0)
        end_date = start_date + timedelta(days=6, hours=23, minutes=59, seconds=59)
        group_by = "day"
    elif period == "month":
        start_date = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        # simplistic end of month
        next_month = start_date.replace(day=28) + timedelta(days=4)
        end_date = (next_month - timedelta(days=next_month.day)).replace(hour=23, minute=59, second=59)
        group_by = "day"
    elif period == "year":
        start_date = now.replace(month=1, day=1, hour=0, minute=0, second=0, microsecond=0)
        end_date = now.replace(month=12, day=31, hour=23, minute=59, second=59)
        group_by = "month"
    elif period == "custom" and start and end:
        start_date = datetime.combine(start, datetime.min.time())
        end_date = datetime.combine(end, datetime.max.time())
        days = (end_date - start_date).days
        if days <= 1:
            group_by = "hour"
        elif days <= 31:
            group_by = "day"
        else:
            group_by = "month"
    else:
        # Default to today
        start_date = now.replace(hour=0, minute=0, second=0, microsecond=0)
        end_date = now.replace(hour=23, minute=59, second=59, microsecond=999999)
        group_by = "hour"
        
    return start_date, end_date, group_by

@router.get("/metrics", response_model=AnalyticsMetrics)
async def get_metrics(
    period: str = Query("today", description="today, week, month, year, custom"),
    start: Optional[date] = None,
    end: Optional[date] = None,
    session: AsyncSession = Depends(get_tenant_session),
    _=Depends(require_permission("analytics:read"))
):
    start_date, end_date, group_by = get_start_end(period, start, end)
    return await get_analytics_metrics(session, start_date, end_date, group_by)

@router.get("/xray", response_model=AnalyticsXRay)
async def get_xray(
    period: str = Query("today", description="today, week, month, year, custom"),
    start: Optional[date] = None,
    end: Optional[date] = None,
    session: AsyncSession = Depends(get_tenant_session),
    _=Depends(require_permission("analytics:read"))
):
    start_date, end_date, _ = get_start_end(period, start, end)
    return await get_analytics_xray(session, start_date, end_date)

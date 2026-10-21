from typing import Annotated, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select

from app.database import get_session
from app.dependencies import require_permission, require_any_permission, CurrentUser
from app.users import services as svc
from app.users.models import Tenant
from app.users.permissions import Perm

router = APIRouter(tags=["Roles & Tenant Settings"])


class TenantSettingsUpdate(BaseModel):
    use_kds: bool
    use_orders: bool
    enable_inventory_deduction: bool
    blind_pos_enabled: Optional[bool] = None
    pos_master_pin: Optional[str] = None


class TenantSettingsRead(BaseModel):
    use_kds: bool
    use_orders: bool
    enable_inventory_deduction: bool
    blind_pos_enabled: bool = True
    pos_master_pin_set: bool = True


@router.get(
    "/roles/",
    dependencies=[Depends(require_any_permission("roles:manage", "users:manage"))],
)
async def list_roles(
    current_user: CurrentUser,
    session: Annotated[AsyncSession, Depends(get_session)],
):
    """List all roles and their permissions for the current tenant."""
    roles = await svc.list_roles(session)
    return [
        {
            "id": r.id,
            "name": r.name,
            "description": r.description,
            "is_superuser": r.is_superuser,
            "permissions": [p.code for p in r.permissions],
        }
        for r in roles
    ]


@router.get(
    "/permissions/",
    dependencies=[Depends(require_permission("roles:manage"))],
)
async def list_permissions(
    session: Annotated[AsyncSession, Depends(get_session)],
):
    """List all available permissions in the system."""
    perms = await svc.list_permissions(session)
    return [{"id": p.id, "code": p.code, "description": p.description} for p in perms]


@router.get(
    "/settings/",
    response_model=TenantSettingsRead,
    dependencies=[Depends(require_permission(Perm.SETTINGS_MANAGE))],
)
async def get_tenant_settings(
    current_user: CurrentUser,
    session: Annotated[AsyncSession, Depends(get_session)],
):
    stmt = select(Tenant).where(Tenant.id == current_user.tenant_id)
    tenant = (await session.execute(stmt)).scalar_one_or_none()
    if not tenant:
        raise HTTPException(status_code=404, detail="Tenant not found")
    return TenantSettingsRead(
        use_kds=tenant.use_kds,
        use_orders=tenant.use_orders,
        enable_inventory_deduction=tenant.enable_inventory_deduction,
        blind_pos_enabled=tenant.blind_pos_enabled,
        pos_master_pin_set=bool(tenant.pos_master_pin),
    )


@router.put(
    "/settings/",
    response_model=TenantSettingsRead,
    dependencies=[Depends(require_permission(Perm.SETTINGS_MANAGE))],
)
async def update_tenant_settings(
    data: TenantSettingsUpdate,
    current_user: CurrentUser,
    session: Annotated[AsyncSession, Depends(get_session)],
):
    stmt = select(Tenant).where(Tenant.id == current_user.tenant_id)
    tenant = (await session.execute(stmt)).scalar_one_or_none()
    if not tenant:
        raise HTTPException(status_code=404, detail="Tenant not found")

    tenant.use_kds = data.use_kds
    tenant.use_orders = data.use_orders
    tenant.enable_inventory_deduction = data.enable_inventory_deduction

    if data.blind_pos_enabled is not None:
        tenant.blind_pos_enabled = data.blind_pos_enabled

    if data.pos_master_pin is not None:
        pin = data.pos_master_pin.strip()
        if not (pin.isdigit() and 4 <= len(pin) <= 6):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="PIN-код кассы должен состоять из 4-6 цифр",
            )
        tenant.pos_master_pin = pin

    await session.commit()

    return TenantSettingsRead(
        use_kds=tenant.use_kds,
        use_orders=tenant.use_orders,
        enable_inventory_deduction=tenant.enable_inventory_deduction,
        blind_pos_enabled=tenant.blind_pos_enabled,
        pos_master_pin_set=bool(tenant.pos_master_pin),
    )

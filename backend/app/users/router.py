"""
Users module — API endpoints.

Routes:
  POST /auth/login       — JWT login (username + password)
  POST /auth/pin         — Quick PIN login
  GET  /auth/me          — Current user profile + permissions
  GET  /users/           — List tenant users          [users:manage]
  POST /users/           — Create user                [users:manage]
  GET  /roles/           — List tenant roles           [roles:manage]
  GET  /permissions/     — List all permissions         [roles:manage]
"""

from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_session
from app.dependencies import get_current_user, require_permission, CurrentUser
from app.users import services as svc
from app.users.models import (
    TokenResponse, LoginRequest, PinLoginRequest,
    UserRead, UserCreate, UserUpdate,
    RoleRead, PermissionRead
)

router = APIRouter(tags=["Authentication & Users"])


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  AUTH ENDPOINTS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


@router.post("/auth/login", response_model=TokenResponse)
async def login(
    form_data: Annotated[OAuth2PasswordRequestForm, Depends()],
    session: Annotated[AsyncSession, Depends(get_session)],
):
    """Authenticate via username + password, returns JWT."""
    user = await svc.authenticate_by_password(
        session, form_data.username, form_data.password
    )
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
        )

    permissions = svc.collect_permissions(user)
    token = svc.create_access_token(
        user_id=user.id,
        tenant_id=user.tenant_id,
        permissions=permissions,
        is_superuser=svc.is_superuser(user),
    )
    return TokenResponse(access_token=token)


@router.post("/auth/pin", response_model=TokenResponse)
async def login_by_pin(
    data: PinLoginRequest,
    session: Annotated[AsyncSession, Depends(get_session)],
):
    """Quick PIN login for booth workers (no keyboard needed)."""
    user = await svc.authenticate_by_pin(session, data.pin_code, data.tenant_id)
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid PIN code",
        )

    permissions = svc.collect_permissions(user)
    token = svc.create_access_token(
        user_id=user.id,
        tenant_id=user.tenant_id,
        permissions=permissions,
        is_superuser=svc.is_superuser(user),
    )
    return TokenResponse(access_token=token)


@router.get("/auth/me", response_model=UserRead)
async def me(current_user: CurrentUser):
    """Return current user profile with roles and permissions."""
    return UserRead(
        id=current_user.id,
        tenant_id=current_user.tenant_id,
        username=current_user.username,
        full_name=current_user.full_name,
        is_active=current_user.is_active,
        roles=[r.name for r in current_user.roles],
        permissions=svc.collect_permissions(current_user),
    )


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  USER MANAGEMENT (owner only)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


@router.get(
    "/users/",
    response_model=list[UserRead],
    dependencies=[Depends(require_permission("users:manage"))],
)
async def list_users(
    current_user: CurrentUser,
    session: Annotated[AsyncSession, Depends(get_session)],
):
    """List all users in the current tenant."""
    users = await svc.list_users(session, current_user.tenant_id)
    result = []
    for u in users:
        result.append(UserRead(
            id=u.id,
            tenant_id=u.tenant_id,
            username=u.username,
            full_name=u.full_name,
            is_active=u.is_active,
            roles=[r.name for r in u.roles],
            permissions=[],  # light listing
        ))
    return result


@router.post(
    "/users/",
    response_model=UserRead,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(require_permission("users:manage"))],
)
async def create_user(
    data: UserCreate,
    current_user: CurrentUser,
    session: Annotated[AsyncSession, Depends(get_session)],
):
    """Create a new staff user in the current tenant."""
    # Enforce tenant scope — user can only create within their tenant
    data.tenant_id = current_user.tenant_id

    user = await svc.create_user(session, data)
    return UserRead(
        id=user.id,
        tenant_id=user.tenant_id,
        username=user.username,
        full_name=user.full_name,
        is_active=user.is_active,
        roles=[],
        permissions=[],
    )


@router.put(
    "/users/{user_id}",
    response_model=UserRead,
    dependencies=[Depends(require_permission("users:manage"))],
)
async def update_user(
    user_id: int,
    data: UserUpdate,
    current_user: CurrentUser,
    session: Annotated[AsyncSession, Depends(get_session)],
):
    """Update a staff user."""
    user = await svc.get_user(session, user_id)
    if not user or user.tenant_id != current_user.tenant_id:
        raise HTTPException(status_code=404, detail="User not found")
        
    updated = await svc.update_user(session, user, data)
    return UserRead(
        id=updated.id,
        tenant_id=updated.tenant_id,
        username=updated.username,
        full_name=updated.full_name,
        is_active=updated.is_active,
        roles=[r.name for r in updated.roles] if getattr(updated, 'roles', None) else [],
        permissions=[],
    )


@router.delete(
    "/users/{user_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    dependencies=[Depends(require_permission("users:manage"))],
)
async def delete_user(
    user_id: int,
    current_user: CurrentUser,
    session: Annotated[AsyncSession, Depends(get_session)],
):
    """Deactivate a staff user."""
    user = await svc.get_user(session, user_id)
    if not user or user.tenant_id != current_user.tenant_id:
        raise HTTPException(status_code=404, detail="User not found")
        
    await svc.delete_user(session, user)
    return None


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  ROLES & PERMISSIONS (owner only)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


@router.get(
    "/roles/",
    dependencies=[Depends(require_permission("roles:manage"))],
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


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  SETTINGS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

from pydantic import BaseModel

class TenantSettingsUpdate(BaseModel):
    use_kds: bool
    use_orders: bool
    enable_inventory_deduction: bool

class TenantSettingsRead(BaseModel):
    use_kds: bool
    use_orders: bool
    enable_inventory_deduction: bool

@router.get(
    "/settings/",
    response_model=TenantSettingsRead,
    dependencies=[Depends(require_permission("settings:manage"))],
)
async def get_tenant_settings(
    current_user: CurrentUser,
    session: Annotated[AsyncSession, Depends(get_session)],
):
    from sqlmodel import select
    from app.users.models import Tenant
    stmt = select(Tenant).where(Tenant.id == current_user.tenant_id)
    tenant = (await session.execute(stmt)).scalar_one_or_none()
    if not tenant:
        raise HTTPException(status_code=404, detail="Tenant not found")
    return TenantSettingsRead(
        use_kds=tenant.use_kds,
        use_orders=tenant.use_orders,
        enable_inventory_deduction=tenant.enable_inventory_deduction
    )

@router.put(
    "/settings/",
    response_model=TenantSettingsRead,
    dependencies=[Depends(require_permission("settings:manage"))],
)
async def update_tenant_settings(
    data: TenantSettingsUpdate,
    current_user: CurrentUser,
    session: Annotated[AsyncSession, Depends(get_session)],
):
    from sqlmodel import select
    from app.users.models import Tenant
    stmt = select(Tenant).where(Tenant.id == current_user.tenant_id)
    tenant = (await session.execute(stmt)).scalar_one_or_none()
    if not tenant:
        raise HTTPException(status_code=404, detail="Tenant not found")
    
    tenant.use_kds = data.use_kds
    tenant.use_orders = data.use_orders
    tenant.enable_inventory_deduction = data.enable_inventory_deduction
    await session.commit()
    
    return TenantSettingsRead(
        use_kds=tenant.use_kds,
        use_orders=tenant.use_orders,
        enable_inventory_deduction=tenant.enable_inventory_deduction
    )

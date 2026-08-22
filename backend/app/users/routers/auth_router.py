from typing import Annotated
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_session
from app.dependencies import CurrentUser
from app.users import services as svc
from app.users.models import (
    TokenResponse, PinLoginRequest, UserRead, VerifyPinRequest, User, UpdateProfileRequest, Tenant
)
from sqlmodel import select

router = APIRouter(tags=["Authentication"])


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


@router.post("/auth/verify-pin")
async def verify_pin(
    data: VerifyPinRequest,
    current_user: CurrentUser,
    session: Annotated[AsyncSession, Depends(get_session)],
):
    """Verify owner or manager PIN to unlock protected financial data."""
    # 1. Check current logged-in user's pin_code
    if current_user.pin_code and current_user.pin_code == data.pin_code:
        return {"valid": True, "username": current_user.username}

    # 2. Check if any active user in this tenant with manager/admin privileges has this PIN
    stmt = select(User).where(
        User.tenant_id == current_user.tenant_id,
        User.pin_code == data.pin_code,
        User.is_active == True,
    )
    res = await session.execute(stmt)
    user = res.scalars().first()
    if user:
        return {"valid": True, "username": user.username}

    raise HTTPException(status_code=400, detail="Неверный PIN-код")


@router.get("/auth/me", response_model=UserRead)
async def me(
    current_user: CurrentUser,
    session: Annotated[AsyncSession, Depends(get_session)],
):
    """Return current user profile with roles, permissions, and tenant details."""
    tenant = await session.get(Tenant, current_user.tenant_id)
    tenant_name = tenant.name if tenant else "Mynix Point"
    tenant_address = tenant.address if tenant else None

    return UserRead(
        id=current_user.id,
        tenant_id=current_user.tenant_id,
        username=current_user.username,
        full_name=current_user.full_name,
        is_active=current_user.is_active,
        pin_code=current_user.pin_code,
        roles=[r.name for r in current_user.roles],
        permissions=svc.collect_permissions(current_user),
        tenant_name=tenant_name,
        tenant_address=tenant_address,
        use_kds=tenant.use_kds if tenant else True,
        use_orders=tenant.use_orders if tenant else True,
        enable_inventory_deduction=tenant.enable_inventory_deduction if tenant else True,
    )


@router.put("/auth/me", response_model=UserRead)
async def update_me(
    data: UpdateProfileRequest,
    current_user: CurrentUser,
    session: Annotated[AsyncSession, Depends(get_session)],
):
    """Allow logged-in employee to update their own full name, PIN code, or password."""
    if data.full_name is not None and data.full_name.strip():
        current_user.full_name = data.full_name.strip()
    if data.pin_code is not None:
        current_user.pin_code = data.pin_code.strip() if data.pin_code.strip() else None
    if data.password is not None and data.password.strip():
        # Validate old password before allowing password change
        if not data.old_password or not svc.verify_password(data.old_password, current_user.hashed_password):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Неверный текущий пароль"
            )
        current_user.hashed_password = svc.hash_password(data.password.strip())

    session.add(current_user)
    await session.flush()

    tenant = await session.get(Tenant, current_user.tenant_id)
    tenant_name = tenant.name if tenant else "Mynix Point"
    tenant_address = tenant.address if tenant else None

    return UserRead(
        id=current_user.id,
        tenant_id=current_user.tenant_id,
        username=current_user.username,
        full_name=current_user.full_name,
        is_active=current_user.is_active,
        pin_code=current_user.pin_code,
        roles=[r.name for r in current_user.roles],
        permissions=svc.collect_permissions(current_user),
        tenant_name=tenant_name,
        tenant_address=tenant_address,
        use_kds=tenant.use_kds if tenant else True,
        use_orders=tenant.use_orders if tenant else True,
        enable_inventory_deduction=tenant.enable_inventory_deduction if tenant else True,
    )


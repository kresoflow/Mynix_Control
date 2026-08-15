from typing import Annotated
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_session
from app.dependencies import CurrentUser
from app.users import services as svc
from app.users.models import (
    TokenResponse, PinLoginRequest, UserRead,
)

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

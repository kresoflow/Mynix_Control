from typing import Annotated
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_session
from app.dependencies import require_permission, CurrentUser
from app.users import services as svc
from app.users.models import (
    UserRead, UserCreate, UserUpdate,
)

router = APIRouter(tags=["User Management"])


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
            permissions=[],
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
        roles=[r.name for r in updated.roles] if getattr(updated, "roles", None) else [],
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

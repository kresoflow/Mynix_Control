"""
Shared FastAPI dependencies:
  - get_current_user:  extracts user from JWT
  - require_permission: factory for permission-based guards
  - get_tenant_id:     extracts tenant_id from current user
"""

from typing import Annotated

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import jwt, JWTError
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text

from app.config import settings
from app.database import get_session, async_session_factory
from app.users import services as user_svc
from app.users.models import User, Tenant

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")


async def get_current_user(
    token: Annotated[str, Depends(oauth2_scheme)],
    session: Annotated[AsyncSession, Depends(get_session)],
) -> User:
    """
    Decode JWT, load user with roles+permissions from DB.
    Raises 401 if token invalid or user not found.
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(
            token, settings.secret_key, algorithms=[settings.jwt_algorithm]
        )
        user_id: str | None = payload.get("sub")
        if user_id is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception

    user = await user_svc.get_user_by_id(session, int(user_id))
    if user is None or not user.is_active:
        raise credentials_exception
    return user


def require_permission(*required_codes: str):
    """
    Factory that returns a FastAPI dependency checking
    that the current user has ALL specified permission codes.

    Usage:
        @router.post("/orders", dependencies=[Depends(require_permission("orders:create"))])

    Owner (superuser) bypasses all checks automatically.
    """
    async def checker(
        current_user: Annotated[User, Depends(get_current_user)],
    ) -> User:
        # Superuser bypass
        if user_svc.is_superuser(current_user):
            return current_user

        user_perms = set(user_svc.collect_permissions(current_user))
        missing = set(required_codes) - user_perms

        if missing:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Missing permissions: {', '.join(sorted(missing))}",
            )
        return current_user

    return checker


# ── Convenience aliases ──────────────────────────────────────────

CurrentUser = Annotated[User, Depends(get_current_user)]
"""Type alias for injecting the current authenticated user."""

async def get_tenant_session(
    current_user: CurrentUser,
) -> AsyncSession:  # type: ignore[misc]
    """
    Yields a DB session bound to the user's specific tenant schema.
    """
    async with async_session_factory() as session:
        try:
            # We explicitly set search_path to public first to query the Tenant
            await session.execute(text("SET search_path TO public"))
            tenant = await session.get(Tenant, current_user.tenant_id)
            if not tenant:
                raise HTTPException(status_code=400, detail="Tenant not found")
            
            schema_name = tenant.schema_name
            await session.execute(text(f'SET search_path TO "{schema_name}"'))
            
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise

TenantSession = Annotated[AsyncSession, Depends(get_tenant_session)]
"""Type alias for injecting a tenant-scoped async DB session."""

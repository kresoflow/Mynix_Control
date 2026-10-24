import time
from typing import Annotated, Dict, List
from fastapi import APIRouter, Depends, HTTPException, Request, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_session
from app.dependencies import CurrentUser
from app.users import services as svc
from app.users.models import (
    TokenResponse, PinLoginRequest, UserRead, VerifyPinRequest, User, UpdateProfileRequest, Tenant
)
from sqlmodel import select

MAX_PIN_ATTEMPTS = 5
PIN_WINDOW_SECONDS = 300.0   # 5 minutes sliding window
PIN_LOCKOUT_SECONDS = 300.0  # 5 minutes lockout

_pin_failed_attempts: Dict[str, List[float]] = {}
_pin_locked_keys: Dict[str, float] = {}


def get_client_ip(request: Request) -> str:
    """Extract client IP handling x-forwarded-for headers."""
    forwarded = request.headers.get("x-forwarded-for")
    if forwarded:
        return forwarded.split(",")[0].strip()
    if request.client and request.client.host:
        return request.client.host
    return "unknown"


def check_pin_rate_limit(key: str) -> None:
    now = time.time()
    lockout_expiry = _pin_locked_keys.get(key)
    if lockout_expiry is not None:
        if now < lockout_expiry:
            retry_after = int(lockout_expiry - now)
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail=f"Слишком много неверных попыток ввода PIN-кода. Доступ заблокирован на {retry_after} сек.",
                headers={"Retry-After": str(retry_after)},
            )
        else:
            _pin_locked_keys.pop(key, None)
            _pin_failed_attempts.pop(key, None)


def record_pin_failed_attempt(key: str, raise_unauthorized: bool = True) -> int:
    now = time.time()
    attempts = [t for t in _pin_failed_attempts.get(key, []) if now - t < PIN_WINDOW_SECONDS]
    attempts.append(now)
    _pin_failed_attempts[key] = attempts
    if len(attempts) >= MAX_PIN_ATTEMPTS:
        _pin_locked_keys[key] = now + PIN_LOCKOUT_SECONDS
        _pin_failed_attempts.pop(key, None)
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail="Превышен лимит неверных попыток ввода PIN (5 попыток). Доступ заблокирован на 5 минут.",
            headers={"Retry-After": str(int(PIN_LOCKOUT_SECONDS))},
        )
    remaining = MAX_PIN_ATTEMPTS - len(attempts)
    if raise_unauthorized:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Неверный PIN-код. Осталось попыток до блокировки: {remaining}",
        )
    return remaining


def reset_pin_attempts(key: str) -> None:
    _pin_failed_attempts.pop(key, None)
    _pin_locked_keys.pop(key, None)


router = APIRouter(tags=["Authentication"])


@router.post("/auth/login", response_model=TokenResponse)
async def login(
    request: Request,
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

    # При успешном входе по паролю сбрасываем блокировки PIN для клиента
    ip = get_client_ip(request)
    for key in list(_pin_locked_keys.keys()):
        if ip in key:
            _pin_locked_keys.pop(key, None)
            _pin_failed_attempts.pop(key, None)

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
    request: Request,
    data: PinLoginRequest,
    session: Annotated[AsyncSession, Depends(get_session)],
):
    """Quick PIN login for booth workers (no keyboard needed)."""
    ip = get_client_ip(request)
    rate_key = f"pin_login_{data.tenant_id}_{ip}"
    check_pin_rate_limit(rate_key)

    user = await svc.authenticate_by_pin(session, data.pin_code, data.tenant_id)
    if user is None:
        record_pin_failed_attempt(rate_key)

    reset_pin_attempts(rate_key)

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
    request: Request,
    data: VerifyPinRequest,
    current_user: CurrentUser,
    session: Annotated[AsyncSession, Depends(get_session)],
):
    """Verify owner or manager PIN to unlock protected financial data."""
    rate_key = f"pin_verify_{current_user.tenant_id}_{current_user.id}"
    check_pin_rate_limit(rate_key)

    # 0. Check tenant's pos_master_pin
    tenant = await session.get(Tenant, current_user.tenant_id)
    if tenant and tenant.pos_master_pin and tenant.pos_master_pin == data.pin_code:
        reset_pin_attempts(rate_key)
        return {"valid": True, "username": "Мастер-PIN кассы"}

    # 1. Check current logged-in user's pin_code
    if current_user.pin_code and current_user.pin_code == data.pin_code:
        reset_pin_attempts(rate_key)
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
        reset_pin_attempts(rate_key)
        return {"valid": True, "username": user.username}

    remaining = record_pin_failed_attempt(rate_key, raise_unauthorized=False)
    return {
        "valid": False,
        "detail": f"Неверный PIN-код. Осталось попыток: {remaining}",
    }


@router.get("/auth/me", response_model=UserRead)
async def me(
    current_user: CurrentUser,
    session: Annotated[AsyncSession, Depends(get_session)],
):
    """Return current user profile with roles, permissions, and tenant details."""
    tenant = await session.get(Tenant, current_user.tenant_id)
    tenant_name = tenant.name if tenant else "Kreso Point"
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
        blind_pos_enabled=tenant.blind_pos_enabled if tenant else True,
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
    tenant_name = tenant.name if tenant else "Kreso Point"
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
        blind_pos_enabled=tenant.blind_pos_enabled if tenant else True,
    )


import time
import secrets
import asyncio
from typing import Dict, List
from fastapi import Request, Header, HTTPException, status

from app.config import settings
from app.system.telegram_service import send_telegram_message

MAX_FAILED_ATTEMPTS = 5
ATTEMPT_WINDOW_SECONDS = 60.0
LOCKOUT_DURATION_SECONDS = 900.0  # 15 minutes

# In-memory stores:
# _failed_attempts: ip -> [timestamp, timestamp, ...]
_failed_attempts: Dict[str, List[float]] = {}
# _locked_ips: ip -> lockout_expiration_timestamp
_locked_ips: Dict[str, float] = {}


def get_client_ip(request: Request) -> str:
    """Extract client IP handling x-forwarded-for headers if present."""
    forwarded = request.headers.get("x-forwarded-for")
    if forwarded:
        return forwarded.split(",")[0].strip()
    if request.client and request.client.host:
        return request.client.host
    return "unknown"


def reset_rate_limiter() -> None:
    """Helper used primarily for testing to clear rate-limiting state."""
    _failed_attempts.clear()
    _locked_ips.clear()


async def require_system_admin(
    request: Request,
    x_system_token: str = Header(..., description="System Admin Secret Token"),
) -> bool:
    """
    Security dependency for System Admin endpoints:
    - Protects against brute-force attacks via sliding window IP rate limiting.
    - Temporarily locks IP for 15 minutes upon 5 consecutive failed attempts.
    - Protects against timing attacks via secrets.compare_digest.
    - Sends security alerts via Telegram when IP lockout is triggered.
    """
    ip = get_client_ip(request)
    now = time.time()

    # 1. Check if IP is currently locked out
    lockout_expiry = _locked_ips.get(ip)
    if lockout_expiry is not None:
        if now < lockout_expiry:
            retry_after = int(lockout_expiry - now)
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail=f"Too many failed attempts. Access blocked for {retry_after}s.",
                headers={"Retry-After": str(retry_after)},
            )
        else:
            # Lockout expired, clean up
            _locked_ips.pop(ip, None)
            _failed_attempts.pop(ip, None)

    # 2. Timing-safe comparison of the secret token
    is_valid = secrets.compare_digest(
        x_system_token.strip(),
        settings.system_admin_token.strip(),
    )

    if not is_valid:
        # Filter attempts within the sliding window
        attempts = [t for t in _failed_attempts.get(ip, []) if now - t < ATTEMPT_WINDOW_SECONDS]
        attempts.append(now)
        _failed_attempts[ip] = attempts

        if len(attempts) > MAX_FAILED_ATTEMPTS:
            # Trigger 15-minute IP lockout
            _locked_ips[ip] = now + LOCKOUT_DURATION_SECONDS
            _failed_attempts.pop(ip, None)

            # Fire Telegram Security Alert in background
            alert_text = (
                f"🚨 <b>Mynix Security Alert</b>\n"
                f"Обнаружен брутфорс токена суперадмина!\n"
                f"<b>IP:</b> <code>{ip}</code>\n"
                f"<b>Действие:</b> IP заблокирован на 15 минут."
            )
            try:
                asyncio.create_task(send_telegram_message(alert_text))
            except Exception:
                pass

            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail="Too many failed attempts. Access blocked for 15 minutes.",
                headers={"Retry-After": str(int(LOCKOUT_DURATION_SECONDS))},
            )

        remaining = MAX_FAILED_ATTEMPTS - len(attempts)
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"Invalid System Admin Token. Remaining attempts before lockout: {remaining}",
        )

    # 3. Successful authentication: reset failed attempts
    _failed_attempts.pop(ip, None)
    return True

import time
import httpx
from datetime import datetime, timezone
from app.config import settings

# In-memory rate-limiter: error_signature -> last_sent_timestamp
_recent_alerts: dict[str, float] = {}
RATE_LIMIT_SECONDS = 30.0


async def send_telegram_message(text: str) -> bool:
    """Send a formatted HTML message to the configured Telegram chat."""
    token = settings.telegram_bot_token
    chat_id = settings.telegram_chat_id

    if not token or not chat_id:
        return False

    url = f"https://api.telegram.org/bot{token}/sendMessage"
    payload = {
        "chat_id": chat_id,
        "text": text,
        "parse_mode": "HTML",
        "disable_web_page_preview": True,
    }

    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            resp = await client.post(url, json=payload)
            return resp.status_code == 200
    except Exception as e:
        print(f"Telegram alert delivery notice: {e}")
        return False


async def send_error_alert(
    title: str,
    error: str,
    method: str = "",
    path: str = "",
    tenant: str | None = None,
) -> bool:
    """
    Format and send an error alert to Telegram with in-memory de-duplication.
    """
    token = settings.telegram_bot_token
    chat_id = settings.telegram_chat_id

    if not token or not chat_id:
        return False

    # Check de-duplication / rate-limiting
    signature = f"{method}:{path}:{error[:80]}"
    now = time.time()
    last_sent = _recent_alerts.get(signature, 0.0)

    if now - last_sent < RATE_LIMIT_SECONDS:
        return False

    _recent_alerts[signature] = now

    # Cleanup old entries if map grows
    if len(_recent_alerts) > 100:
        cutoff = now - RATE_LIMIT_SECONDS
        to_delete = [k for k, v in _recent_alerts.items() if v < cutoff]
        for k in to_delete:
            _recent_alerts.pop(k, None)

    timestamp = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")
    
    text = f"🚨 <b>{title}</b>\n\n"
    if method and path:
        text += f"📍 <b>Endpoint:</b> <code>{method} {path}</code>\n"
    if tenant:
        text += f"🏢 <b>Tenant:</b> <code>{tenant}</code>\n"
    text += f"⏰ <b>Time:</b> {timestamp}\n"
    text += f"💥 <b>Error:</b> <code>{error[:400]}</code>\n"

    return await send_telegram_message(text)

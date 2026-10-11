# ==============================================================================
# МОДУЛЬ: Интеграции и шлюз клиентских логов (Telegram, Sentry, Frontend Bridge)
# ДОМЕН: app/system/integrations.py
# ==============================================================================

import logging
from pydantic import BaseModel, Field
from fastapi import APIRouter, Request, BackgroundTasks, Depends
from app.config import settings
from app.system.telegram_service import send_telegram_message, send_error_alert
from app.system.security import require_system_admin

router = APIRouter(tags=["Integrations"])

# ── 1. Модели данных клиентских ошибок ────────────────────────────────────────

class ClientErrorPayload(BaseModel):
    """
    Модель сообщения об ошибке из Flutter UI (оверфлоу вёрстки, сбои BLoC, асинхронные ошибки).
    """
    error: str
    bloc: str | None = None
    category: str = Field(default="CLIENT_ERROR", description="LAYOUT_OVERFLOW | ASYNC_ERROR | BLOC_ERROR")
    component: str | None = None
    stack_trace: str | None = None
    tenant: str | None = None
    url: str | None = None


# ── 2. Эндпоинты приёма и чтения логов фронтенда ──────────────────────────────

@router.post("/system/client-error")
@router.post("/client-error")
@router.post("/system/client-logs")
@router.post("/client-logs")
async def report_client_error(payload: ClientErrorPayload, background_tasks: BackgroundTasks):
    """
    [ИНВАРИАНТ] Принимает ошибки фронтенда и сохраняет их в `backend/logs/frontend_errors.log`.
    Позволяет агенту и разработчику видеть оверфлоу вёрстки без ручного копирования из терминала.
    """
    frontend_logger = logging.getLogger("frontend_client")
    tag = payload.category or "CLIENT_ERROR"
    source = payload.component or payload.bloc or "FlutterClient"
    log_msg = f"[{tag}] [{source}] {payload.error}"
    if payload.url:
        log_msg += f" (Route: {payload.url})"

    frontend_logger.error(log_msg)
    if payload.stack_trace:
        frontend_logger.info(f"Stack trace for {source}:\n{payload.stack_trace}")

    # В продакшене критичные сбои дублируются в Telegram
    if not settings.debug and payload.category != "LAYOUT_OVERFLOW":
        background_tasks.add_task(
            send_error_alert,
            title=f"Frontend Crash [{tag}]",
            error=f"[{source}] {payload.error}",
            method="UI",
            path=payload.url or "Flutter Client",
            tenant=payload.tenant,
        )

    return {"status": "recorded"}


@router.get("/system/frontend-logs", dependencies=[Depends(require_system_admin)])
@router.get("/frontend-logs", dependencies=[Depends(require_system_admin)])
async def get_frontend_logs(lines: int = 100):
    """
    Возвращает последние строки клиентского лога для автономной диагностики агентом.
    """
    from app.core.logging_config import FRONTEND_LOG_FILE
    if not FRONTEND_LOG_FILE.exists():
        return {"lines": [], "file": str(FRONTEND_LOG_FILE)}
    try:
        with open(FRONTEND_LOG_FILE, "r", encoding="utf-8", errors="replace") as f:
            all_lines = f.readlines()
            return {"lines": all_lines[-lines:], "total_lines": len(all_lines)}
    except Exception as e:
        return {"error": str(e)}


@router.delete("/system/frontend-logs", dependencies=[Depends(require_system_admin)])
@router.delete("/frontend-logs", dependencies=[Depends(require_system_admin)])
async def clear_frontend_logs():
    """Очищает файл клиентских логов фронтенда перед новым прогоном тестов."""
    from app.core.logging_config import FRONTEND_LOG_FILE
    if FRONTEND_LOG_FILE.exists():
        FRONTEND_LOG_FILE.write_text("", encoding="utf-8")
    return {"status": "cleared"}


@router.post("/webhook/sentry")
async def sentry_webhook(request: Request, background_tasks: BackgroundTasks):
    """Webhook to receive Sentry alerts and forward them to Telegram."""
    try:
        payload = await request.json()
        
        project_name = payload.get("project_name", "Unknown Project")
        message = payload.get("message", "")
        level = payload.get("level", "error")
        url = payload.get("url", "")
        
        event = payload.get("event", {})
        title = event.get("title") or message or "New Issue"
        
        icon = "🚨" if level in ("error", "fatal") else "⚠️"
        
        text = f"{icon} <b>Sentry Alert | {project_name}</b>\n\n"
        text += f"<b>Message:</b> {title}\n"
        text += f"<b>Level:</b> {level.upper()}\n"
        
        if url:
            text += f"\n<a href='{url}'>[View Details in Sentry]</a>"
            
        background_tasks.add_task(send_telegram_message, text)
    except Exception as e:
        print(f"Error parsing sentry webhook: {e}")
        
    return {"status": "ok"}


from pydantic import BaseModel
from fastapi import APIRouter, Request, BackgroundTasks
from app.system.telegram_service import send_telegram_message, send_error_alert

router = APIRouter(tags=["Integrations"])


class ClientErrorPayload(BaseModel):
    bloc: str
    error: str
    stack_trace: str | None = None
    tenant: str | None = None


@router.post("/system/client-error")
@router.post("/client-error")
async def report_client_error(payload: ClientErrorPayload, background_tasks: BackgroundTasks):
    """
    Secure proxy for frontend crashes (Flutter Web / Mobile).
    Safely alerts Telegram without exposing bot tokens on the client.
    """
    background_tasks.add_task(
        send_error_alert,
        title="Frontend App Crash",
        error=f"[{payload.bloc}] {payload.error}",
        method="UI",
        path="Flutter Client",
        tenant=payload.tenant,
    )
    return {"status": "received"}


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


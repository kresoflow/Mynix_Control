import httpx
from fastapi import APIRouter, Request, BackgroundTasks

router = APIRouter(tags=["Integrations"])

TELEGRAM_BOT_TOKEN = "8811624266:AAEKba2stMRaRTLGKrlHo1BjaO1A8SyejZA"
TELEGRAM_CHAT_ID = "6968300145"


async def send_telegram_message(text: str):
    url = f"https://api.telegram.org/bot{TELEGRAM_BOT_TOKEN}/sendMessage"
    payload = {
        "chat_id": TELEGRAM_CHAT_ID,
        "text": text,
        "parse_mode": "HTML"
    }
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            await client.post(url, json=payload)
    except Exception as e:
        print(f"Failed to send telegram message: {e}")


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

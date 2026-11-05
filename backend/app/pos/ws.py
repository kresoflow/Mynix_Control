# ==============================================================================
# МОДУЛЬ: POS / WebSocket-хаб событий тенанта (Real-time Event Hub)
# ДОМЕН: backend/app/pos/ws.py
# ==============================================================================
#
# [ИНВАРИАНТ] [MULTI-TENANCY] Полная изоляция потоков событий по tenant_id:
# 1. Авторизация WebSocket через JWT-токен в query-параметрах с проверкой tenant_id.
# 2. Адресная рассылка доменных событий: order_created, inventory_updated, document_updated.
#
# ==============================================================================

from typing import Dict, Set, Optional

from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Query, status
from jose import jwt, JWTError

from app.config import settings
from app.database import async_session_factory
from app.users import services as user_svc

router = APIRouter()


# ─── 1. Менеджер WebSocket-подключений тенанта ────────────────────────────────

class TenantConnectionManager:
    """
    Управляет активными WebSocket-подключениями в разрезе тенантов.
    Гарантирует изоляцию: клиенты тенанта А никогда не получают события тенанта Б.
    """

    def __init__(self):
        # tenant_id → множество активных WebSocket-соединений
        self.active_connections: Dict[int, Set[WebSocket]] = {}

    async def connect(self, websocket: WebSocket, tenant_id: int):
        await websocket.accept()
        if tenant_id not in self.active_connections:
            self.active_connections[tenant_id] = set()
        self.active_connections[tenant_id].add(websocket)

    def disconnect(self, websocket: WebSocket, tenant_id: int):
        if tenant_id in self.active_connections:
            self.active_connections[tenant_id].discard(websocket)
            if not self.active_connections[tenant_id]:
                del self.active_connections[tenant_id]

    async def broadcast_to_tenant(self, tenant_id: int, message: dict):
        """Рассылка сообщения всем активным клиентам конкретного тенанта."""
        connections = self.active_connections.get(tenant_id, set())
        dead = []
        for ws in connections:
            try:
                await ws.send_json(message)
            except Exception:
                dead.append(ws)
        # Очистка оборванных соединений
        for ws in dead:
            self.disconnect(ws, tenant_id)


# Синглтон менеджера соединений
tenant_ws_hub = TenantConnectionManager()
kitchen_manager = tenant_ws_hub  # Алиас для обратной совместимости


# ─── 2. WebSocket-эндпоинт ───────────────────────────────────────────────────

@router.websocket("/ws/{tenant_id}")
@router.websocket("/ws/pos/{tenant_id}")
async def tenant_websocket(
    websocket: WebSocket,
    tenant_id: int,
    token: Optional[str] = Query(None),
):
    """
    Поток живых событий тенанта (заказы, остатки, накладные).
    Требует валидный JWT-токен пользователя, принадлежащего целевому tenant_id.
    """
    if not token:
        token = websocket.query_params.get("token")

    if not token:
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION, reason="Missing authentication token")
        return

    try:
        payload = jwt.decode(
            token, settings.secret_key, algorithms=[settings.jwt_algorithm]
        )
        user_id = payload.get("sub")
        if not user_id:
            await websocket.close(code=status.WS_1008_POLICY_VIOLATION, reason="Invalid token")
            return
    except JWTError:
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION, reason="Invalid token signature")
        return

    # Проверка активности пользователя и принадлежности к тенанту
    async with async_session_factory() as session:
        user = await user_svc.get_user_by_id(session, int(user_id))
        if not user or not user.is_active or user.tenant_id != tenant_id:
            await websocket.close(code=status.WS_1008_POLICY_VIOLATION, reason="Unauthorized tenant access")
            return

    await tenant_ws_hub.connect(websocket, tenant_id)
    try:
        while True:
            # Поддержание соединения живым (Heartbeat ping/pong)
            data = await websocket.receive_text()
            if data == "ping":
                await websocket.send_text("pong")
    except (WebSocketDisconnect, Exception):
        pass
    finally:
        tenant_ws_hub.disconnect(websocket, tenant_id)


# ─── 3. Доменные функции рассылки уведомлений ─────────────────────────────────

async def notify_order_created(tenant_id: int, order_data: dict):
    """Уведомление кассовых терминалов о создании нового чека/заказа."""
    await tenant_ws_hub.broadcast_to_tenant(tenant_id, {
        "event": "order_created",
        "order": order_data,
    })


async def notify_document_updated(tenant_id: int):
    """Уведомление складских экранов об изменении журнала накладных (приход, списание)."""
    await tenant_ws_hub.broadcast_to_tenant(tenant_id, {
        "event": "document_updated",
    })


async def notify_inventory_updated(tenant_id: int):
    """Уведомление об изменении остатков товаров/ингредиентов на складе."""
    await tenant_ws_hub.broadcast_to_tenant(tenant_id, {
        "event": "inventory_updated",
    })


# Алиасы обратной совместимости
notify_kitchen_new_order = notify_order_created

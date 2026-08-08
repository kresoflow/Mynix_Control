"""
POS module — WebSocket for real-time kitchen order streaming.

The cook's screen connects via WebSocket and receives new/updated orders
in real-time as they are created or their status changes.
"""

import json
from typing import Dict, Set

from fastapi import APIRouter, WebSocket, WebSocketDisconnect

router = APIRouter()


# ── Connection Manager ───────────────────────────────────────────

class KitchenConnectionManager:
    """
    Manages WebSocket connections per tenant.
    Multiple kitchen screens can connect for the same tenant.
    """

    def __init__(self):
        # tenant_id → set of active WebSocket connections
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
        """Send a message to all kitchen screens for a given tenant."""
        connections = self.active_connections.get(tenant_id, set())
        dead = []
        for ws in connections:
            try:
                await ws.send_json(message)
            except Exception:
                dead.append(ws)
        # Clean up dead connections
        for ws in dead:
            self.disconnect(ws, tenant_id)


# Singleton manager instance
kitchen_manager = KitchenConnectionManager()


# ── WebSocket Endpoint ───────────────────────────────────────────

@router.websocket("/ws/kitchen/{tenant_id}")
async def kitchen_websocket(websocket: WebSocket, tenant_id: int):
    """
    Kitchen screen connects here and stays open.
    Receives JSON messages like:
    {
      "event": "new_order" | "status_update",
      "order": { ... order data ... }
    }
    """
    await kitchen_manager.connect(websocket, tenant_id)
    try:
        while True:
            # Keep connection alive; listen for pings/heartbeats
            data = await websocket.receive_text()
            # Client can send "ping" to keep alive
            if data == "ping":
                await websocket.send_text("pong")
    except WebSocketDisconnect:
        kitchen_manager.disconnect(websocket, tenant_id)


# ── Helper: notify kitchen about new/updated orders ─────────────

async def notify_kitchen_new_order(tenant_id: int, order_data: dict):
    """Called by POS services when a new order is created."""
    await kitchen_manager.broadcast_to_tenant(tenant_id, {
        "event": "new_order",
        "order": order_data,
    })


async def notify_kitchen_status_update(
    tenant_id: int, order_id: int, new_status: str
):
    """Called when an order status changes."""
    await kitchen_manager.broadcast_to_tenant(tenant_id, {
        "event": "status_update",
        "order_id": order_id,
        "new_status": new_status,
    })

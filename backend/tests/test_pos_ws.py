# ==============================================================================
# ТЕСТ: WebSocket Hub и TenantConnectionManager (Real-time синхронизация)
# ДОМЕН: backend/tests/test_pos_ws.py
# ==============================================================================

import pytest
from unittest.mock import AsyncMock, MagicMock
from app.pos.ws import (
    TenantConnectionManager,
    notify_order_created,
    notify_document_updated,
    notify_inventory_updated,
)


def _make_mock_ws(send_side_effect=None):
    """Фабрика мока WebSocket соединения с асинхронными accept и send_json."""
    ws = MagicMock()
    ws.accept = AsyncMock()
    if send_side_effect:
        ws.send_json = AsyncMock(side_effect=send_side_effect)
    else:
        ws.send_json = AsyncMock()
    return ws


@pytest.fixture
def mock_ws():
    """Создает стандартный мок WebSocket соединения."""
    return _make_mock_ws()


@pytest.mark.asyncio
async def test_tenant_connection_manager_connect_and_disconnect(mock_ws):
    """Проверяет подключение и корректное отключение сокета."""
    hub = TenantConnectionManager()
    await hub.connect(mock_ws, "tenant_1")
    assert "tenant_1" in hub.active_connections
    assert mock_ws in hub.active_connections["tenant_1"]

    hub.disconnect(mock_ws, "tenant_1")
    assert "tenant_1" not in hub.active_connections


@pytest.mark.asyncio
async def test_multitenant_websocket_isolation():
    """[ИНВАРИАНТ] Изоляция: событие тенанта А не должно попадать тенанту Б."""
    hub = TenantConnectionManager()
    ws_tenant_a = _make_mock_ws()
    ws_tenant_b = _make_mock_ws()

    await hub.connect(ws_tenant_a, "tenant_a")
    await hub.connect(ws_tenant_b, "tenant_b")

    payload = {"event": "order_created", "order_id": 101}
    await hub.broadcast_to_tenant("tenant_a", payload)

    ws_tenant_a.send_json.assert_awaited_once_with(payload)
    ws_tenant_b.send_json.assert_not_awaited()


@pytest.mark.asyncio
async def test_dead_connection_cleanup():
    """Отпавшие или разорванные соединения автоматически удаляются из хаба."""
    hub = TenantConnectionManager()
    broken_ws = _make_mock_ws(send_side_effect=RuntimeError("Connection reset by peer"))

    await hub.connect(broken_ws, "tenant_1")
    assert broken_ws in hub.active_connections["tenant_1"]

    # Рассылка должна перехватить ошибку и удалить разорванный сокет
    await hub.broadcast_to_tenant("tenant_1", {"event": "ping"})
    assert "tenant_1" not in hub.active_connections


@pytest.mark.asyncio
async def test_typed_notification_helpers(mock_ws, monkeypatch):
    """Проверяет типизированные хелперы notify_order_created, notify_document_updated, notify_inventory_updated."""
    test_hub = TenantConnectionManager()
    await test_hub.connect(mock_ws, "tenant_test")
    monkeypatch.setattr("app.pos.ws.tenant_ws_hub", test_hub)

    # 1. notify_order_created
    await notify_order_created("tenant_test", {"id": 55, "total": 1200})
    mock_ws.send_json.assert_awaited_with({
        "event": "order_created",
        "order": {"id": 55, "total": 1200},
    })

    # 2. notify_document_updated
    mock_ws.send_json.reset_mock()
    await notify_document_updated("tenant_test")
    mock_ws.send_json.assert_awaited_with({
        "event": "document_updated",
    })

    # 3. notify_inventory_updated
    mock_ws.send_json.reset_mock()
    await notify_inventory_updated("tenant_test")
    mock_ws.send_json.assert_awaited_with({
        "event": "inventory_updated",
    })

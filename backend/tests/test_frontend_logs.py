# ==============================================================================
# ТЕСТ: Клиентский логгер и мост ошибок фронтенда (Frontend Logs Bridge)
# ДОМЕН: tests/test_frontend_logs.py
# ==============================================================================

import pytest
from httpx import AsyncClient, ASGITransport
from app.main import app
from app.config import settings
from app.core.logging_config import FRONTEND_LOG_FILE, setup_logging


@pytest.mark.asyncio
async def test_frontend_client_logs_lifecycle():
    """
    [ИНВАРИАНТ] Проверяет прием клиентских логов (RenderFlex overflow, UI сбои),
    запись в `frontend_errors.log`, чтение через GET и очистку через DELETE.
    """
    setup_logging()
    transport = ASGITransport(app=app)
    admin_headers = {"X-System-Token": settings.system_admin_token}

    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        # 1. Очищаем лог перед тестом (требует токен системного администратора)
        clear_resp = await ac.delete("/api/v1/system/frontend-logs", headers=admin_headers)
        assert clear_resp.status_code == 200
        assert clear_resp.json()["status"] == "cleared"

        # 2. Отправляем тестовую ошибку оверфлоу вёрстки (публичный прием с фронтенда)
        error_payload = {
            "error": "A RenderFlex overflowed by 118 pixels on the right.",
            "category": "LAYOUT_OVERFLOW",
            "component": "Row (ingredient_tab.dart:111)",
            "stack_trace": "line 1\nline 2",
            "url": "/catalog/ingredients",
        }
        post_resp = await ac.post("/api/v1/system/client-logs", json=error_payload)
        assert post_resp.status_code == 200
        assert post_resp.json()["status"] == "recorded"

        # 3. Проверяем наличие записи в файле
        assert FRONTEND_LOG_FILE.exists()
        content = FRONTEND_LOG_FILE.read_text(encoding="utf-8")
        assert "LAYOUT_OVERFLOW" in content
        assert "Row (ingredient_tab.dart:111)" in content
        assert "A RenderFlex overflowed" in content

        # 4. Проверяем получение логов через GET эндпоинт (требует токен системного администратора)
        get_resp = await ac.get("/api/v1/system/frontend-logs?lines=10", headers=admin_headers)
        assert get_resp.status_code == 200
        data = get_resp.json()
        assert data["total_lines"] >= 1
        assert any("LAYOUT_OVERFLOW" in line for line in data["lines"])

        # 5. Очищаем за собой
        del_resp = await ac.delete("/api/v1/system/frontend-logs", headers=admin_headers)
        assert del_resp.status_code == 200

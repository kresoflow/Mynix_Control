# ==============================================================================
# МОДУЛЬ: Аудит трафика, детекция бесконечных циклов и медленных запросов
# ДОМЕН: app/core/traffic_audit.py
# ==============================================================================

import logging
import time
from collections import defaultdict, deque
from typing import Callable
from fastapi import Request, Response
from starlette.middleware.base import BaseHTTPMiddleware

audit_logger = logging.getLogger("traffic_audit")

# ── 1. Пороги детекции аномалий ───────────────────────────────────────────────

SLIDING_WINDOW_SECONDS = 1.0
BURST_THRESHOLD_RPS = 10       # Более 10 запросов в секунду на 1 эндпоинт от одного клиента
SLOW_REQUEST_THRESHOLD_MS = 350 # Запросы дольше 350мс фиксируются как медленные

# ── 2. Middleware аудита и мониторинга запросов ────────────────────────────────

class TrafficAuditMiddleware(BaseHTTPMiddleware):
    """
    Анализирует входящий поток HTTP-запросов в реальном времени:
    1. Детектирует зацикливания фронтенда (DDoS, забытые Timer.periodic, частый поллинг).
    2. Фиксирует медленные ответы БД и блокировки транзакций (>350ms).
    3. Записывает аномалии в logs/traffic_audit.log и logs/backend.log.
    """

    def __init__(self, app):
        super().__init__(app)
        # Хранилище временных меток запросов: key -> deque([t1, t2, ...])
        self._request_history: dict[str, deque[float]] = defaultdict(deque)

    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        # Пропускаем WebSocket рукопожатия и статику
        if request.scope.get("type") == "websocket" or request.url.path.startswith("/docs"):
            return await call_next(request)

        client_ip = request.client.host if request.client else "unknown"
        path = request.url.path
        method = request.method
        now = time.time()

        # ── Проверка на шторм запросов (Hot Loop / Burst) ─────────────────────
        endpoint_key = f"{client_ip}:{method}:{path}"
        history = self._request_history[endpoint_key]

        # Очищаем устаревшие метки за пределами скользящего окна
        while history and (now - history[0] > SLIDING_WINDOW_SECONDS):
            history.popleft()

        history.append(now)
        request_count = len(history)

        if request_count >= BURST_THRESHOLD_RPS:
            # Логируем только при превышении порога, чтобы не спамить
            audit_logger.warning(
                f"[HOT-LOOP-DETECTED] High frequency: {request_count} req/sec on {method} {path} "
                f"from {client_ip}! Suspected frontend loop, unbounced watcher or DDoS."
            )

        # ── Замер времени выполнения запроса ──────────────────────────────────
        start_time = time.perf_counter()
        try:
            response = await call_next(request)
        except Exception as exc:
            duration_ms = (time.perf_counter() - start_time) * 1000.0
            audit_logger.error(
                f"[UNHANDLED-EXCEPTION] {method} {path} failed in {duration_ms:.1f}ms: {exc}"
            )
            raise exc

        duration_ms = (time.perf_counter() - start_time) * 1000.0

        # ── Анализ задержки и кодов ответа ────────────────────────────────────
        if duration_ms >= SLOW_REQUEST_THRESHOLD_MS:
            audit_logger.warning(
                f"[SLOW-REQUEST] {duration_ms:.1f}ms on {method} {path} "
                f"(status={response.status_code}, client={client_ip})"
            )

        if response.status_code >= 500:
            audit_logger.error(
                f"[SERVER-ERROR] HTTP {response.status_code} on {method} {path} ({duration_ms:.1f}ms)"
            )

        return response

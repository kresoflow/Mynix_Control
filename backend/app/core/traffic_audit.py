# ==============================================================================
# МОДУЛЬ: Аудит трафика, детекция дублей, бесконечных циклов и задержек
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
DUPLICATE_WINDOW_SECONDS = 0.5   # Скользящее окно для выявления дублирующих вызовов
BURST_THRESHOLD_RPS = 8          # Более 8 запросов в секунду на 1 эндпоинт
SLOW_REQUEST_THRESHOLD_MS = 350  # Запросы дольше 350мс фиксируются как медленные

# ── 2. Middleware аудита и мониторинга запросов ────────────────────────────────

class TrafficAuditMiddleware(BaseHTTPMiddleware):
    """
    Анализирует входящий поток HTTP-запросов в реальном времени:
    1. Детектирует дублирующие вызовы UI (Double/Triple Fetch в пределах 500мс).
    2. Детектирует зацикливания фронтенда (DDoS, забытые Timer.periodic, частый поллинг).
    3. Фиксирует медленные ответы БД и блокировки транзакций (>350ms).
    4. Записывает полный аудит в logs/backend.log и аномалии в logs/traffic_audit.log.
    """

    def __init__(self, app):
        super().__init__(app)
        self._request_history: dict[str, deque[float]] = defaultdict(deque)

    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        if request.scope.get("type") == "websocket" or request.url.path.startswith("/docs"):
            return await call_next(request)

        client_ip = request.client.host if request.client else "unknown"
        path = request.url.path
        method = request.method
        query_str = str(request.url.query) if request.url.query else ""
        now = time.time()

        # ── Проверка на дубли и штормы запросов ───────────────────────────────
        endpoint_key = f"{client_ip}:{method}:{path}?{query_str}"
        history = self._request_history[endpoint_key]

        while history and (now - history[0] > SLIDING_WINDOW_SECONDS):
            history.popleft()

        history.append(now)
        request_count = len(history)

        # Подсчет вызовов за последние 500мс (типичный UI duplicate-fetch)
        recent_duplicates = sum(1 for t in history if (now - t) <= DUPLICATE_WINDOW_SECONDS)
        if recent_duplicates >= 2:
            audit_logger.warning(
                f"[DUPLICATE-FETCH-DETECTED] Repeated call {recent_duplicates}x in 500ms: "
                f"{method} {path}{'?' + query_str if query_str else ''} from {client_ip}. "
                "Suspected uncoordinated BLoC initialization or missing debounce."
            )

        if request_count >= BURST_THRESHOLD_RPS:
            audit_logger.warning(
                f"[HOT-LOOP-DETECTED] High frequency: {request_count} req/sec on {method} {path} "
                f"from {client_ip}! Suspected frontend loop or DDoS."
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

        # ── Логирование каждого запроса и аномалий ────────────────────────────
        audit_logger.info(
            f"[HTTP] {method} {path}{'?' + query_str if query_str else ''} "
            f"-> {response.status_code} ({duration_ms:.1f}ms)"
        )

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

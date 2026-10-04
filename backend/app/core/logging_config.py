# ==============================================================================
# МОДУЛЬ: Системный логгер и файловая ротация логов (Unified Log Stream)
# ДОМЕН: app/core/logging_config.py
# ==============================================================================

import logging
import sys
from logging.handlers import RotatingFileHandler
from pathlib import Path

# ── 1. Пути и параметры ротации ───────────────────────────────────────────────

# Располагаем логи в корне проекта (вне backend/), чтобы вотчер uvicorn --reload не входил в цикл
_project_root = Path(__file__).resolve().parents[3]
LOGS_DIR = _project_root / "logs" if (_project_root / "backend").exists() else Path(__file__).resolve().parents[2] / "logs"
BACKEND_LOG_FILE = LOGS_DIR / "backend.log"
AUDIT_LOG_FILE = LOGS_DIR / "traffic_audit.log"
FRONTEND_LOG_FILE = LOGS_DIR / "frontend_errors.log"

LOG_FORMAT = "%(asctime)s [%(levelname)s] [%(name)s] %(message)s"
DATE_FORMAT = "%Y-%m-%d %H:%M:%S"

# ── 2. Инициализация логирования ──────────────────────────────────────────────

def setup_logging() -> None:
    """
    Настраивает вывод логов одновременно в консоль (stdout) и в локальные файлы.
    Файлы ротируются автоматически при достижении 15 МБ (до 5 архивных копий).
    """
    LOGS_DIR.mkdir(parents=True, exist_ok=True)

    formatter = logging.Formatter(fmt=LOG_FORMAT, datefmt=DATE_FORMAT)

    # Консольный поток (для терминала VS Code)
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setFormatter(formatter)
    console_handler.setLevel(logging.INFO)

    # Файловый поток общего бэкенда (для чтения агентом и анализа ошибок)
    file_handler = RotatingFileHandler(
        filename=BACKEND_LOG_FILE,
        maxBytes=15 * 1024 * 1024,  # 15 MB
        backupCount=5,
        encoding="utf-8",
    )
    file_handler.setFormatter(formatter)
    file_handler.setLevel(logging.INFO)

    # Защита от бесконечного цикла вотчера: исключаем логи watchfiles из записи в файл
    class _ExcludeWatchfilesFilter(logging.Filter):
        def filter(self, record: logging.LogRecord) -> bool:
            return not record.name.startswith("watchfiles")

    file_handler.addFilter(_ExcludeWatchfilesFilter())

    # Глушим шумные логи вотчера в целом
    for watch_name in ("watchfiles", "watchfiles.main"):
        logging.getLogger(watch_name).setLevel(logging.WARNING)

    # Файловый поток для алертов подозрительного трафика и медленных запросов
    audit_handler = RotatingFileHandler(
        filename=AUDIT_LOG_FILE,
        maxBytes=10 * 1024 * 1024,  # 10 MB
        backupCount=3,
        encoding="utf-8",
    )
    audit_handler.setFormatter(formatter)
    audit_handler.setLevel(logging.WARNING)

    # Файловый поток для клиентских ошибок фронтенда (RenderFlex overflow, UI crashes)
    frontend_handler = RotatingFileHandler(
        filename=FRONTEND_LOG_FILE,
        maxBytes=10 * 1024 * 1024,  # 10 MB
        backupCount=3,
        encoding="utf-8",
    )
    frontend_handler.setFormatter(formatter)
    frontend_handler.setLevel(logging.INFO)

    # Настройка корневого логгера
    root_logger = logging.getLogger()
    root_logger.setLevel(logging.INFO)

    # Очищаем дефолтные хендлеры, чтобы избежать дублирования строк
    if not root_logger.handlers:
        root_logger.addHandler(console_handler)
        root_logger.addHandler(file_handler)

    # Настройка логгеров Uvicorn и приложения
    for logger_name in ("uvicorn", "uvicorn.error", "uvicorn.access", "app"):
        target_logger = logging.getLogger(logger_name)
        target_logger.setLevel(logging.INFO)
        if not any(isinstance(h, RotatingFileHandler) for h in target_logger.handlers):
            target_logger.addHandler(file_handler)

    # Отдельный логгер для аудита трафика
    audit_logger = logging.getLogger("traffic_audit")
    audit_logger.setLevel(logging.INFO)
    if not any(h == audit_handler for h in audit_logger.handlers):
        audit_logger.addHandler(audit_handler)
        audit_logger.addHandler(file_handler)

    # Отдельный логгер для клиентских ошибок фронтенда
    frontend_logger = logging.getLogger("frontend_client")
    frontend_logger.setLevel(logging.INFO)
    if not any(h == frontend_handler for h in frontend_logger.handlers):
        frontend_logger.addHandler(frontend_handler)
        frontend_logger.addHandler(console_handler)

    logging.info(
        f"[LOGGING] Файловые потоки активны: {BACKEND_LOG_FILE}, {AUDIT_LOG_FILE}, {FRONTEND_LOG_FILE}"
    )

# ==============================================================================
# Title: Backend Server Launcher (run_server.py)
# Path: backend/run_server.py
# Description: Надежный запуск Uvicorn с защитой от конфликтов портов и ложных рестартов.
# ==============================================================================

import os
import sys
import subprocess
import uvicorn

# ── 1. Настройка кодировки Windows-терминала ──────────────────────────────────
if sys.platform == "win32":
    try:
        if hasattr(sys.stdout, "reconfigure"):
            sys.stdout.reconfigure(encoding="utf-8", errors="replace")
        if hasattr(sys.stderr, "reconfigure"):
            sys.stderr.reconfigure(encoding="utf-8", errors="replace")
    except Exception:
        pass


def free_port(port: int = 8000) -> None:
    """Освобождает указанный порт на Windows от зависших зомби-процессов."""
    if sys.platform != "win32":
        return

    try:
        # Ищем PID процессов, слушающих порт
        cmd = f"Get-NetTCPConnection -LocalPort {port} -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess"
        result = subprocess.run(["powershell", "-Command", cmd], capture_output=True, text=True)
        pids = [p.strip() for p in result.stdout.splitlines() if p.strip() and p.strip() != "0"]
        current_pid = str(os.getpid())

        for pid in set(pids):
            if pid != current_pid:
                print(f"[PORT-CLEANER] Освобождаем порт {port} от зависшего процесса PID {pid}...")
                subprocess.run(["taskkill", "/F", "/PID", pid], capture_output=True)
    except Exception as e:
        print(f"[PORT-CLEANER] Замечание проверки порта: {e}")


def main() -> None:
    """Основная точка входа для локальной разработки."""
    # Защита от WinError 10048 (порт занят предыдущим запуском)
    free_port(8000)

    print("=" * 60)
    print("  KRESO FLOW — BACKEND SERVER (Development Mode)")
    print("  URL: http://127.0.0.1:8000")
    print("  Docs: http://127.0.0.1:8000/docs")
    print("  Reload-Scope: backend/app/ (исключены логи и кэши)")
    print("=" * 60)

    # Запуск Uvicorn со строгим скоупом отслеживания
    uvicorn.run(
        "app.main:app",
        host="127.0.0.1",
        port=8000,
        reload=True,
        reload_dirs=["app"],
        reload_excludes=["logs/*", "*.log", "__pycache__/*", "*.pyc", ".pytest_cache/*"],
        log_level="info",
    )


if __name__ == "__main__":
    main()

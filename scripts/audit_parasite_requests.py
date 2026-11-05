#!/usr/bin/env python3
# ==============================================================================
# KRESO FLOW — СТАТИЧЕСКИЙ АУДИТОР ПАРАЗИТНЫХ СЕТЕВЫХ ЗАПРОСОВ
# Путь: scripts/audit_parasite_requests.py
# ==============================================================================
#
# Назначение:
# Сканирует Dart-файлы frontend/lib на предмет:
# 1. Повторных сетевых вызовов в initState / didUpdateWidget без проверки кэша.
# 2. Прямых вызовов repository.get...() при открытии диалогов/экранов.
# 3. Автосохранений в BLoC / UI без debounce и проверки dirty-state.
#
# ==============================================================================

import os
import re
import sys
from pathlib import Path
from typing import List, Dict, Any

if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8', errors='replace')

FRONTEND_LIB = Path("frontend/lib")


def scan_file(file_path: Path) -> List[Dict[str, Any]]:
    issues = []
    content = file_path.read_text(encoding="utf-8", errors="ignore")
    lines = content.splitlines()

    # 1. Поиск initState с неконтролируемым add(Load...) или get...()
    in_init_state = False
    init_state_line = 0
    init_state_body = []

    for idx, line in enumerate(lines, start=1):
        stripped = line.strip()

        # Детекция начала initState
        if "void initState()" in stripped or "@override\n  void initState()" in stripped:
            in_init_state = True
            init_state_line = idx
            init_state_body = []
            continue

        if in_init_state:
            init_state_body.append((idx, line))
            # Окончание initState (упрощенная эвристика по закрывающей фигурной скобке на том же уровне)
            if stripped == "}":
                in_init_state = False
                body_text = "\n".join(l for _, l in init_state_body)

                # Ищем add(Load...)
                load_matches = re.finditer(r"\.add\(const?\s*(Load\w+)\(", body_text)
                for lm in load_matches:
                    event_name = lm.group(1)
                    # Проверяем, есть ли рядом проверка isEmpty / isLoaded / == null
                    # Если в теле нет 'isEmpty' или 'isNotEmpty' или 'state is'
                    if not re.search(r"(isEmpty|isNotEmpty|isLoaded|state is|\?\?)", body_text):
                        issues.append({
                            "file": str(file_path.as_posix()),
                            "line": init_state_line,
                            "type": "UNGUARDED_FETCH_IN_INITSTATE",
                            "severity": "MEDIUM",
                            "message": f"Событие `{event_name}` вызывается в initState() без проверки кэша (isEmpty/isLoaded). Каждый вход спамит бэкенд.",
                        })

                # Ищем прямые вызовы repo.get...() в initState
                repo_get_matches = re.finditer(r"\.get(\w+)\(", body_text)
                for rgm in repo_get_matches:
                    method_name = f"get{rgm.group(1)}"
                    if not re.search(r"(isEmpty|isNotEmpty|isLoaded|state is|\?\?|!= null)", body_text):
                        issues.append({
                            "file": str(file_path.as_posix()),
                            "line": init_state_line,
                            "type": "DIRECT_REPO_GET_IN_INITSTATE",
                            "severity": "MEDIUM",
                            "message": f"Прямой вызов `repo.{method_name}()` в initState(). Отсутствует кэширование в BLoC/State.",
                        })

        # 2. Поиск мутаций без debounce в BLoC (on<Update...>, on<Save...>)
        if re.search(r"on<Update\w+>\s*\(\s*_\w+\s*\)", stripped):
            # Проверяем, есть ли transformer в строке регистрации
            if "transformer:" not in stripped:
                issues.append({
                    "file": str(file_path.as_posix()),
                    "line": idx,
                    "type": "BLOC_MUTATION_WITHOUT_TRANSFORMER",
                    "severity": "HIGH",
                    "message": f"BLoC обработчик `{stripped}` зарегистрирован без дебаунс-трансформера (restartable/debounce). Опасность спама при вводе.",
                })

        # 3. Поиск прямых мутаций в UI на onQuantityChanged / onChanged без дебаунса
        if re.search(r"onQuantityChanged:\s*\([^)]*\)\s*\{", stripped) or re.search(r"onChanged:\s*\([^)]*\)\s*\{", stripped):
            # Проверяем следующие 5 строк на вызов .add(Update...)
            next_chunk = "\n".join(lines[idx: min(len(lines), idx + 6)])
            if re.search(r"\.add\(\s*Update\w+", next_chunk) and "debounce" not in next_chunk.lower() and "timer" not in next_chunk.lower():
                issues.append({
                    "file": str(file_path.as_posix()),
                    "line": idx,
                    "type": "IMMEDIATE_MUTATION_ON_INPUT",
                    "severity": "HIGH",
                    "message": "Ввод пользователя (onQuantityChanged/onChanged) напрямую диспатчит событие обновления без проверки равенства или дебаунса.",
                })

    return issues


def main():
    print("=" * 60)
    print("      KRESO FLOW — АУДИТ ПАРАЗИТНЫХ СЕТЕВЫХ ЗАПРОСОВ        ")
    print("=" * 60)

    if not FRONTEND_LIB.exists():
        print(f"Каталог {FRONTEND_LIB} не найден!")
        return

    all_issues = []
    scanned_count = 0

    for root, _, files in os.walk(FRONTEND_LIB):
        for file in files:
            if file.endswith(".dart"):
                p = Path(root) / file
                scanned_count += 1
                issues = scan_file(p)
                all_issues.extend(issues)

    high_issues = [i for i in all_issues if i["severity"] == "HIGH"]
    medium_issues = [i for i in all_issues if i["severity"] == "MEDIUM"]

    print(f"\nВсего проверено файлов: {scanned_count}")
    print(f"Найдено потенциальных паразитных сетевых точек: {len(all_issues)}")
    print(f"  • Критичных (Автосохранения / Спам мутаций): {len(high_issues)}")
    print(f"  • Средних (Повторный fetch на монтировании):  {len(medium_issues)}")
    print("-" * 60)

    if not all_issues:
        print("✔ Паразитных сетевых точек не обнаружено!")
        return

    print("\n[!] ДЕТАЛИЗАЦИЯ НАЙДЕННЫХ ТОЧЕК:")
    current_file = ""
    for issue in all_issues:
        if issue["file"] != current_file:
            current_file = issue["file"]
            print(f"\n📂 {current_file}:")
        prefix = "🚨 [HIGH]" if issue["severity"] == "HIGH" else "⚠️ [MEDIUM]"
        print(f"  {prefix} L{issue['line']}: {issue['message']}")

    print("\n" + "=" * 60)


if __name__ == "__main__":
    main()

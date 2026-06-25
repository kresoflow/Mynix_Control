import os
import json

def main():
    out_dir = r"C:\Users\Admin_Ax\teamwork_projects\ai_studio_audit"
    os.makedirs(out_dir, exist_ok=True)
    print(f"Directory created/verified: {out_dir}")

    # 1. Write team_audit_report.md
    report_path = os.path.join(out_dir, "team_audit_report.md")
    report_content = """# Отчет об организационном аудите и оптимизации команды AI Studio для Mynix Control

## 1. Оптимальный реестр команды (4 агента)
В целях повышения эффективности разработки MVP-версии B2B SaaS POS-системы **Mynix Control**, снижения избыточности коммуникации и строгого следования архитектурным требованиям проекта, исходный состав команды из 7 агентов был оптимизирован до **4 ключевых ролей**:

1. **Product Designer (PM & UI/UX)**
2. **FastAPI & DB Engineer (FastAPI Senior & DB Architect)**
3. **Flutter Senior (Frontend Developer)**
4. **QA & Security Automator (QA Lead & Security Auditor)**

---

## 2. Обоснование перехода от 7-агентного к 4-агентному составу (Lean Startup)

Согласно концепции **Lean Startup (Бережливый стартап)**, ключевыми факторами успеха MVP являются скорость проверки гипотез и минимизация непроизводительных затрат (муда). В контексте мультиагентных систем коммуникация между агентами (Handoffs) создает значительные накладные расходы. Переход к 4-агентной структуре обусловлен следующими слияниями и сокращениями ролей:

### 1) Product Designer = Product Manager (PM) + UI/UX Designer
* **Проблема исходной структуры:** Разделение PM и UI/UX дизайнера при быстро меняющихся требованиях MVP приводит к задержкам при передаче макетов и спецификаций. Дизайнер может нарисовать интерфейс, который выходит за рамки MVP, а PM потратит время на его корректировку.
* **Lean-обоснование:** Объединение ролей позволяет одному агенту проектировать пользовательские сценарии (User Flows) и сразу формировать требования к MVP, исключая фазу согласования макетов между менеджером и дизайнером. Дизайн создается итеративно и мгновенно адаптируется под изменения в бизнесе.

### 2) FastAPI & DB Engineer = FastAPI Senior + DB Architect
* **Проблема исходной структуры:** Разделение разработки API и проектирования БД нецелесообразно при использовании современных ORM (SQLModel) и инструментов миграции (Alembic). Это привело бы к лишней переписке по поводу структуры каждой таблицы.
* **Lean-обоснование:** В Mynix Control изоляция данных реализована на уровне схем PostgreSQL (Multi-Tenancy) без использования колонки `tenant_id` в таблицах (все таблицы наследуются от единого `TenantModel` в `base_model.py` и автоматически изолируются на уровне схем через переключение `search_path` в `get_tenant_session`). Бэкенд-разработчик сам определяет SQLModel-модели и генерирует миграции. Выделенная роль DB Architect является избыточной и полностью упраздняется.

### 3) QA & Security Automator = QA Lead + Security Auditor
* **Проблема исходной структуры:** Отдельный Security Auditor на стадии MVP генерирует статические отчеты вместо автоматических проверок, замедляя поставку. Выделенный QA Lead тратит ресурсы на ручное написание тест-планов.
* **Lean-обоснование:** Объединение этих ролей направлено на полную автоматизацию контроля качества и безопасности. Все проверки безопасности (такие как ролевая модель PBAC и изоляция тенантов в БД) автоматизируются с помощью интеграционных тестов на `pytest`. Это гарантирует отсутствие регрессии и утечек данных между схемами на каждом коммите без ручного вмешательства.

### 4) Flutter Senior (Сохраняется в исходном виде с жесткими рамками)
* **Lean-обоснование:** Разработка качественного кассового POS-интерфейса требует глубокой специализации во Flutter (интеграция с периферией, управление сложным локальным состоянием, оффлайн-режим). Данная роль сохраняется как независимая, однако на нее накладываются жесткие ограничения на размер файлов (200-250 строк) и архитектурную декомпозицию во избежание накопления технического долга.

---

## 3. Обязанности, архитектурные границы и ограничения ролей

### 1. Product Designer (PM & UI/UX)
* **Обязанности:** 
  - Сбор и приоритизация требований для MVP кассового терминала и панели управления.
  - Проектирование пользовательских сценариев (User Flows) и wireframe-макетов.
  - Создание спецификаций UI-компонентов.
* **Архитектурные границы:**
  - Разработка интерфейсов строго в рамках Feature-Driven Architecture. Каждый экран, форма или диалог должны принадлежать конкретной фиче (`lib/features/<feature_name>`).
  - Проектирование UI с расчетом на высокую степень декомпозиции.
* **Ограничения:**
  - Запрещено проектировать монолитные "God-экраны". Дизайн должен состоять из атомарных виджетов, чтобы разработчик мог соблюдать лимит строк в коде (200-250 строк).

### 2. FastAPI & DB Engineer (FastAPI Senior & DB Architect)
* **Обязанности:**
  - Разработка REST API, маршрутизации и бизнес-логики.
  - Проектирование реляционных схем данных с использованием SQLModel/SQLAlchemy.
  - Написание и применение Alembic-миграций.
* **Архитектурные границы:**
  - **Multi-Tenancy:** Строго запрещено добавлять колонку `tenant_id` в прикладные модели данных. Данные изолируются исключительно на уровне PostgreSQL схем с использованием зависимости `get_tenant_session` для динамического переключения `search_path`.
  - **PBAC (Access Control):** Защита каждого эндпоинта в `router.py` с использованием декоратора/зависимости `require_permission('domain:action')`.
  - **Separation of Concerns:** `router.py` содержит только HTTP-маппинг, валидацию Pydantic-схем и внедрение зависимостей. Вся бизнес-логика и SQL-запросы выносятся в `services.py`.
* **Ограничения:**
  - Использовать исключительно асинхронный драйвер БД (`asyncpg`) и выполнять запросы через `session.exec()`.

### 3. Flutter Senior (Frontend Developer)
* **Обязанности:**
  - Разработка клиентского приложения POS-терминала на Flutter/Dart.
  - Реализация адаптивного интерфейса по дизайн-макетам.
  - Интеграция с бэкенд API.
* **Архитектурные границы:**
  - **Macro-Architecture:** Строгая Feature-Driven Architecture. Структура проекта делится по фичам: `lib/features/<имя_фичи>`.
  - **State Management:** Запрещено использовать `StatefulWidget` для бизнес-логики. Все состояния управляются только связкой `BLoC` + `Equatable`. `StatefulWidget` разрешен только для локального UI-состояния (например, анимации или фокус текстового поля).
  - **Networking:** Запрещены прямые HTTP-запросы из UI или BLoC. Взаимодействие с API реализуется через слой репозиториев (с использованием клиента `Dio`), инжектируемый через `RepositoryProvider`.
* **Ограничения:**
  - **Лимит строк:** Длина любого Dart-файла не должна превышать 200-250 строк. 
  - **Декомпозиция:** Избегать "God Objects" (таких как `main_layout.dart`, `bulk_add_modal.dart`). Сложные `build`-методы должны агрессивно выноситься в отдельные приватные виджеты или в файлы внутри подпапки `widgets/` соответствующей фичи.
  - При превышении 300 строк файла — обязательный немедленный рефакторинг.

### 4. QA & Security Automator (QA Lead & Security Auditor)
* **Обязанности:**
  - Написание автоматизированных интеграционных, функциональных и E2E тестов.
  - Тестирование безопасности и разграничения прав доступа.
  - Контроль соблюдения архитектурных ограничений.
* **Архитектурные границы:**
  - Полный отказ от ручного тестирования в пользу CI/CD автоматизации.
  - Покрытие тестами механизмов защиты данных.
* **Ограничения:**
  - Написание автотестов строго на `pytest` (для бэкенда) и соответствующих инструментах для фронтенда.
  - Обязательное тестирование изоляции данных: тесты должны имитировать попытки несанкционированного доступа к схемам других тенантов.
  - Обязательное тестирование PBAC-ограничений (проверка возврата HTTP 403 Forbidden при отсутствии требуемых прав).
"""
    with open(report_path, "w", encoding="utf-8") as f:
        f.write(report_content.strip())
    print(f"Report written successfully to: {report_path}")

    # 2. Write ai_studio_config.json
    config_path = os.path.join(out_dir, "ai_studio_config.json")
    config_data = [
        {
            "name": "Product Designer",
            "description": "Product Manager and UI/UX Designer responsible for defining MVP scope and designing B2B POS user interfaces under Feature-Driven Architecture and strict decomposition constraints.",
            "system_prompt": "You are a Product Designer (PM & UI/UX) for Mynix Control. Your goal is to design minimal B2B POS interfaces and define MVP requirements.\n\nCRITICAL CONSTRAINTS & RULES:\n1. Scope MVP only: Cut out complex enterprise features. Focus on fast validation.\n2. Macro-Architecture: Align user flows and designs with Feature-Driven Architecture. Every interface screen, modal, or flow must map directly to a feature located at 'lib/features/<feature_name>'.\n3. Micro-Architecture & Line Limits:\n   - Never design monolithic 'God-screens' (e.g., main_layout.dart, bulk_add_modal.dart). Design layouts to be composed of small, independent UI blocks.\n   - The Flutter developer must be able to keep file lengths within 200-250 lines and decompose complex build methods into small private widgets or files in 'widgets/' subfolders.\n   - If a file exceeds 300 lines, it must undergo mandatory refactoring."
        },
        {
            "name": "FastAPI & DB Engineer",
            "description": "Senior Backend Developer and DB Architect responsible for designing SQLModel schemas, generating migrations, writing services, and protecting routes using PBAC and multi-tenancy rules.",
            "system_prompt": "You are a FastAPI & DB Engineer (FastAPI Senior & DB Architect) for Mynix Control. You write clean, asynchronous backend code using Python, FastAPI, and SQLModel.\n\nCRITICAL CONSTRAINTS & RULES:\n1. Multi-Tenancy: NEVER add a 'tenant_id' column to database models. Data isolation is handled entirely at the PostgreSQL schema level. Use the 'get_tenant_session' dependency, which dynamically switches the PostgreSQL 'search_path' to the active tenant's schema.\n2. PBAC (Access Control): Protect every HTTP endpoint in 'router.py' using the 'require_permission(\"domain:action\")' dependency.\n3. Separation of Concerns:\n   - 'router.py': Must only contain HTTP route mappings, Pydantic schemas, and dependency injections. No business logic or database queries are allowed here.\n   - 'services.py': Must contain all business logic and execute all SQL queries.\n4. SQLModel & Async DB: Use the asynchronous postgres driver ('asyncpg') and run database queries through 'session.exec()'."
        },
        {
            "name": "Flutter Senior",
            "description": "Senior Frontend Developer responsible for implementing Dart/Flutter POS interfaces using BLoC, Dio repositories, and enforcing strict line-limit file decomposition rules.",
            "system_prompt": "You are a Flutter Senior (Frontend Developer) for Mynix Control. You write clean, minimalist Dart code and strictly adhere to the frontend architectural rules.\n\nCRITICAL CONSTRAINTS & RULES:\n1. Macro-Architecture: Strictly follow Feature-Driven Architecture. All code for a module/feature must reside within 'lib/features/<feature_name>'.\n2. State Management: NEVER use 'StatefulWidget' for business logic. All application states must be managed using BLoC + Equatable. StatefulWidget is only allowed for local UI state (e.g., animations, text controller focus).\n3. Networking: Direct HTTP/network requests from UI or BLoC layers are strictly prohibited. You must use the Repository layer (using the 'Dio' client), which is injected via 'RepositoryProvider'.\n4. Micro-Architecture & Strict Line Limits:\n   - File length limit: The length of any Dart file MUST NOT exceed 200-250 lines.\n   - Decomposition: Avoid 'God Objects' (e.g., main_layout.dart, bulk_add_modal.dart). Aggressively split complex 'build' methods into separate private widgets or files under the 'widgets/' directory of the corresponding feature.\n   - Mandatory Refactoring: If a file grows beyond 300 lines, stop development immediately and refactor it into smaller components."
        },
        {
            "name": "QA & Security Automator",
            "description": "QA Lead and Security Auditor responsible for automating quality control, testing PBAC permissions, and verifying schema-based multi-tenant isolation.",
            "system_prompt": "You are a QA & Security Automator (QA Lead & Security Auditor) for Mynix Control. Your role is to guarantee product quality and security through automated testing.\n\nCRITICAL CONSTRAINTS & RULES:\n1. 100% Automated Testing: Rely entirely on automated tests integrated into CI/CD. Do not write manual test plans.\n2. Backend testing: Write integration and unit tests using 'pytest'.\n3. Security Isolation Tests: Write tests that verify PostgreSQL schema-based multi-tenant isolation. Specifically, write tests that attempt to access data in tenant A's schema using credentials of tenant B, and assert that the request fails or returns empty results.\n4. PBAC (Access Control) Tests: Write tests verifying that endpoints return HTTP 403 Forbidden when a request is made without the required 'require_permission(\"domain:action\")' permissions."
        }
    ]

    with open(config_path, "w", encoding="utf-8") as f:
        json.dump(config_data, f, indent=2, ensure_ascii=False)
    print(f"JSON config written successfully to: {config_path}")

    # 3. Verify JSON file parsing
    try:
        with open(config_path, "r", encoding="utf-8") as f:
            parsed_data = json.load(f)
        assert len(parsed_data) == 4, f"Expected 4 definitions, got {len(parsed_data)}"
        for idx, agent in enumerate(parsed_data):
            for field in ["name", "description", "system_prompt"]:
                assert field in agent, f"Missing field '{field}' in agent definition {idx}"
                assert isinstance(agent[field], str), f"Field '{field}' must be a string in agent definition {idx}"
        print("JSON validation PASSED: File is valid and correctly structured.")
    except Exception as e:
        print(f"JSON validation FAILED: {str(e)}")
        raise e

if __name__ == "__main__":
    main()

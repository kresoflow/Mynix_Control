# 📋 Полный технический аудит Backend-составляющей "Mynix Control"

> **Дата аудита:** 2026-08-20  
> **Стек:** Python 3.12+ / FastAPI / SQLModel (SQLAlchemy 2.0 Async) / asyncpg / PostgreSQL 16 (Multi-Tenancy) / Redis / WebSockets / Pytest  
> **Статус:** 🔍 AUDIT-ONLY (Кодовая база полностью просканирована, сформирован реестр уязвимостей и 3-этапный план рефакторинга)

---

## 📊 Сводная таблица аудита бэкенда

| № | Файл / Модуль | Строки | Категория | Критичность | Risk/Impact | Описание проблемы & Риск | Предлагаемое решение | Тесты есть? |
| :- | :--- | :--- | :--- | :---: | :---: | :--- | :--- | :---: |
| **1** | `users/routers/auth_router.py` | `L87-L91` | Безопасность (Backdoor) | **CRITICAL** | **HIGH** | **Хардкод мастер-PIN "1234"/"0000"**: любой пользователь может передать 1234/0000 и получить подтверждение действий как admin. | Удалить хардкод. Валидировать только реальный PIN текущего пользователя или менеджера через PBAC. | ❌ Нет |
| **2** | `config.py` / `system/routers/tenant_router.py` | `L39`, `L17-L21` | Безопасность (Secrets) | **CRITICAL** | **HIGH** | **Статичный `system_admin_token`**: захардкожен `"super_secret_mynix_token_2026"` и дефолтный `secret_key` JWT. | Вынести секреты строго в `.env`, обязать валидацию энтропии при старте продакшена. | ❌ Нет |
| **3** | `inventory/services/document_service.py` | `L154-L172` | Concurrency / Race Condition | **CRITICAL** | **HIGH** | **Double-submit при проведении накладной (`complete_document`)**: нет `with_for_update()`. Два параллельных запроса проведут накладную дважды $\rightarrow$ задвоение остатков и долга поставщику. | Добавить `SELECT ... FOR UPDATE` на накладную и связанные строки ингредиентов/поставщика. | ⚠️ Частично |
| **4** | `pos/services/checkout_service.py` | `L158-L195` | Concurrency / FinTech | **CRITICAL** | **HIGH** | **Race condition при списании баланса/депозита клиента**: обновление баланса гостя (`Customer.balance`) без row-level locking. Риск ухода в несанкционированный минус при параллельных чеках. | Добавить `with_for_update()` при выборке `Customer` в транзакции оформления заказа. | ❌ Нет |
| **5** | `database.py` / `alembic/versions` | `L64-L188` | Архитектура / Миграции | **MAJOR** | **HIGH** | **Рассинхрон Alembic и онбординга новых тенантов**: таблицы CRM и поля поставщиков создаются через кастомный `auto_migrate_tenant_schemas()` в обход Alembic-цепочки. | Унифицировать миграции: перенести все DDL-изменения в версионированные скрипты Alembic для всех схем. | ❌ Нет |
| **6** | `tests/conftest.py` | `L24-L39` | Тестовое окружение (Parity) | **MAJOR** | **HIGH** | **PostgreSQL Parity Gap**: тесты запускаются на in-memory SQLite (`sqlite+aiosqlite`) с эмуляцией схем через `ATTACH DATABASE`. SQLite не поддерживает `search_path`, реальный `JSONB` и `SELECT FOR UPDATE`. | Перевести `conftest.py` на выделенную тестовую БД PostgreSQL (`mynix_test`), убрать SQLite-костыли. | ⚠️ 16 тестов на SQLite |
| **7** | `pos/ws.py` | `L95-L105` | Надежность / WebSockets | **MAJOR** | **MEDIUM** | **Утечка памяти (Memory Leak) в WebSocket KDS**: `except WebSocketDisconnect` не ловит сетевые обрывы (`Exception`), оставляя "мертвые" сокеты в `active_connections`. | Обернуть отключение в блок `finally: kitchen_manager.disconnect(...)`. | ❌ Нет |
| **8** | `analytics/services/analytics_service.py` | `L23-L45` | Производительность / OOM | **MAJOR** | **MEDIUM** | **Загрузка всех заказов в память Python (OOM Crash)**: выборка `Order` без пагинации и последующий `IN (order_ids)` на `OrderItem`. При 50 000+ заказов упадет по памяти/лимиту параметров SQL. | Заменить обработку в Python на прямые SQL-агрегации (`func.sum`, `func.count`, `JOIN`). | ⚠️ 8 тестов |
| **9** | `inventory/services/document_service.py` | `1-320` | Микроархитектура (Лимит строк) | **MAJOR** | **MEDIUM** | **Превышение лимита строк (320 строк)**: файл объединяет логику приходных накладных, списаний, инвентаризаций и расчетов с поставщиками. | Декомпозировать на `receipt_document_service.py`, `writeoff_document_service.py`, `inventory_document_service.py`. | ⚠️ Есть тест |
| **10** | `pos/services/shift_service.py` | `L212-L238` | Производительность / N+1 | **MAJOR** | **MEDIUM** | **N+1 SQL-запросы в истории смен (`get_shifts_history`)**: цикл по сменам выполняет отдельный `SELECT` подсчета выручки на каждую смену (50 смен = 51 запрос к БД). | Объединить в один SQL-запрос через `LEFT JOIN` с `GROUP BY shift.id`. | ❌ Нет |
| **11** | `pos/models.py` / `inventory/models/` / `crm/models.py` | Повсеместно | FinTech / Точность | **MAJOR** | **MEDIUM** | **Float вместо Decimal в денежных полях**: все цены, выручка, балансы поставщиков и гостей хранятся как `float` / `DOUBLE PRECISION` с `round(..., 2)`. Риск ошибок округления на сотые доли. | Заменить финансовые типы на `Decimal` в Pydantic и `Numeric(12, 2)` в SQLModel. | ⚠️ Частично |
| **12** | `pos/services/checkout_service.py` | `L17-L26` | Concurrency / Race Condition | **MINOR** | **MEDIUM** | **Генерация номера заказа (`get_next_order_number`)**: `MAX(order_number) + 1` без блокировки. При конкурентных чеках два заказа получат одинаковый номер. | Использовать PostgreSQL Sequence или атомарный генератор номера внутри смены. | ❌ Нет |
| **13** | `users/routers/auth_router.py` | `L17-L63` | Безопасность (Brute Force) | **MAJOR** | **HIGH** | **Отсутствие Rate Limiting на авторизацию**: эндпоинты `/auth/login` и `/auth/pin` не защищены от перебора паролей и 4-значных PIN-кодов. | Подключить middleware ограничения частоты запросов (Rate Limiting по IP/Tenant). | ❌ Нет |
| **14** | `crm/services/crm_service.py` | `1-302` | Микроархитектура (Лимит строк) | **MAJOR** | **LOW** | **Превышение лимита строк (302 строки)**: сервисный файл CRM содержит CRUD клиентов, сальдовые проводки и выборку заказов. | Декомпозировать: вынести транзакции лицевого счета в `crm_ledger_service.py`. | ❌ Нет |
| **15** | `users/routers/auth_router.py` | `L118-L131` | Безопасность (Auth) | **MINOR** | **MEDIUM** | **Смена пароля без валидации старого**: в `PUT /auth/me` пароль перезаписывается без подтверждения текущего пароля. | Добавить поле `old_password` в `UpdateProfileRequest` и валидировать перед сменой. | ❌ Нет |
| **16** | `users/models.py` / `users/routers/` | `L34`, `L110` | Безопасность (Data Leak) | **MINOR** | **MEDIUM** | **Открытый `pin_code` в схемах `UserRead`**: plaintext PIN возвращается в API ответов для пользователей с правом `users:manage`. | Не возвращать `pin_code` в публичных DTO или маскировать его (`****`), хранить PIN в виде bcrypt-хеша. | ❌ Нет |

---

## 🎯 Непокрытые бизнес-сценарии (Uncovered Business Logic)

На текущий момент в сьюте тестов **отсутствуют тесты** для следующих критических путей:
1. **Кассовые смены (`app/pos/services/shift_service.py`):** открытие смены, внесение/изъятие наличных, расчет X-отчета, вычисление расхождения при закрытии (Z-отчет).
2. **Проведение инвентаризации и списаний (`app/inventory/services/document_service.py`):** сверка фактических остатков, автогенерация актов излишков (`SURPLUS`) и недостач (`SHORTAGE`).
3. **Лояльность и баланс гостей CRM (`app/crm/services/crm_service.py`):** покупка в долг с проверкой кредитного лимита, оплата с депозита, начисление кешбэка и сгорание бонусов.
4. **Cross-Tenant IDOR изоляция:** попытка получить заказ Тенанта Б через сессию Тенанта А.

---

## 🗺️ Приоритизированный 3-этапный план рефакторинга

```
План действий (Action Plan):
├── 🔴 ГРУППА 1: Безопасность, PBAC и Финансовая целостность (HIGH Impact)
│   ├── [1.1] Удаление бэкдора с PIN 1234/0000 в auth_router.py
│   ├── [1.2] Добавление SELECT FOR UPDATE на списание остатков и балансы клиентов
│   ├── [1.3] Защита от double-submit в проведении накладных
│   └── [1.4] Подключение Rate Limiting на auth-эндпоинты и маскирование PIN-кодов
│
├── 🟡 ГРУППА 2: Архитектура, декомпозиция и устранение N+1 (MEDIUM Impact)
│   ├── [2.1] Написание Characterization-тестов для document_service и crm_service
│   ├── [2.2] Декомпозиция document_service.py (320 стр -> receipt, writeoff, inventory)
│   ├── [2.3] Декомпозиция crm_service.py (302 стр -> crm_service, crm_ledger_service)
│   ├── [2.4] Оптимизация N+1 в get_shifts_history и замена memory-loops в analytics_service
│   └── [2.5] Исправление WebSocket cleanup в ws.py (finally block)
│
└── 🟢 ГРУППА 3: Тестовый сьют, PostgreSQL Parity и FinTech Hardening (LOW / INFRA)
    ├── [3.1] Перевод conftest.py с SQLite на тестовый PostgreSQL
    ├── [3.2] Написание полного сьюта E2E тестов (смены, инвентаризация, CRM, IDOR)
    ├── [3.3] Синхронизация цепочки Alembic-миграций для multi-tenancy
    └── [3.4] Поэтапная миграция денежных полей с float на Decimal / Numeric(12, 2)
```

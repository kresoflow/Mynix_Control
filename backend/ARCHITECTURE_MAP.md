<!-- =========================================================================== -->
<!-- ДОКУМЕНТ: Backend Architecture Map (backend/ARCHITECTURE_MAP.md)            -->
<!-- СТАТУС:   АКТУАЛЬНО (Phase 1: Real-time WebSockets, PBAC Hardening & SWR)   -->
<!-- ДАТА:     2026-10-24 | Контрольный коммит: f5ff7f1                         -->
<!-- =========================================================================== -->
# Kreso Flow — Backend Architecture Map
**Стек:** Python 3.12, FastAPI, SQLModel / SQLAlchemy 2.0 (asyncpg), PostgreSQL (Multi-Tenancy по схемам).  
**Порядок отображения:** **100% точное соответствие проводнику VS Code (Explorer)**: каталог за каталогом, файл за файлом, включая виртуальные окружения и служебные кэши.
> [!IMPORTANT] РЕГЛАМЕНТ АКТУАЛИЗАЦИИ КАРТЫ (PHASE-DRIVEN SYNC)
> 1. **Фазовый жизненный цикл:** Данная карта обновляется **централизованно по завершении ключевых архитектурных/бизнес-фаз (Milestones / Sprints)** или при крупных рефакторингах структуры, а **не** при каждом мелком коммите.
> 2. **Правило недоверия для AI-агентов:** Если текущая дата или состояние репозитория (Git HEAD) новее даты, указанной в шапке этой карты — **НЕ доверяйте структуре слепо**. Перед чтением, редактированием или удалением файлов всегда проверяйте реальное существование путей через `find_by_name`, `list_dir` или `git status`.

---

## 1. Фундаментальные инварианты бэкенда

1. **Multi-Tenancy (Изоляция по схемам):**
   - Данные каждого тенанта изолированы в схеме `tenant_<slug>`.
   - Схема `public` содержит только системные таблицы: `tenants`, `users`, `roles`, `permissions`, `role_permissions`.
   - **Закон:** В моделях данных тенанта **СТРОГО ЗАПРЕЩЕНО** добавлять колонку `tenant_id`. Сессия `TenantSession` автоматически устанавливает `search_path`.
2. **PBAC (Контроль доступа на уровне прав):**
   - Все эндпоинты защищаются через `require_permission(Perm.<ACTION>)` или `require_any_permission(...)`.
   - Реестр прав строго централизован в `app.users.permissions.Perm` (никакого хардкода строк).
   - Суперпользователь (`is_superuser=True`) обходит проверки автоматически.
3. **Разделение ответственности слоёв (Separation of Concerns):**
   - `routers/` — только маппинг URL, Pydantic-валидация, зависимости и HTTP статус-коды (целевой лимит: <=250 строк).
   - `services/` — вся бизнес-логика, расчет себестоимости, списание остатков и транзакции с базой данных.
4. **Связанность кода (Locality of Behavior):**
   - Монолитные связные транзакции допускают до 300–350 строк, механический распил единых методов запрещен.
5. **Real-time Синхронизация (WebSockets):**
   - Любые изменения заказов, остатков и документов склада автоматически транслируются через `kitchen_manager.broadcast_to_tenant` (`new_order`, `status_update`, `inventory_updated`).

---

## 2. Полная структура дерева `backend/` (Точно по проводнику VS Code)

```
backend/
├── __pycache__/                      # [1] Служебный кэш скомпилированного байт-кода Python для файлов корня backend (cli.pyc)
├── .pytest_cache/                    # [2] Служебный кэш тестового фреймворка pytest (статусы прогонов, stepwise, dircache)
├── .venv/                            # [3] Изолированное виртуальное окружение Python (интерпретатор Python 3.12, Lib/site-packages)
│
├── alembic/                          # Каталог миграций системной схемы public
│   ├── versions/                     # Версионированные скрипты миграций
│   ├── env.py                        # Окружение Alembic с асинхронным движком
│   ├── README                        # Инструкция по работе с Alembic
│   └── script.py.mako                # Шаблон генерации новых ревизий миграций
│
├── app/                              # Исходный код бэкенд-приложения
│   ├── __pycache__/                  # Служебный кэш байт-кода модулей верхнего уровня app
│   ├── analytics/                    # Модуль: Аналитика и Отчеты
│   │   ├── __pycache__/              # Байт-код модуля аналитики
│   │   ├── routers/                  # HTTP-маршруты (analytics_router, dashboard_router)
│   │   ├── services/                 # Бизнес-логика (analytics_service, dashboard_service)
│   │   ├── __init__.py               # Инициализация пакета analytics
│   │   ├── models.py                 # DTO и схемы финансовых KPI и сменных отчетов
│   │   ├── router.py                 # Главный объединяющий роутер аналитики
│   │   └── utils.py                  # Хелперы форматирования дат и периодов
│   ├── core/                         # Ядро: Системное логирование и аудит трафика
│   │   ├── __init__.py               # Инициализация пакета core
│   │   ├── logging_config.py         # Настройка многопоточного логирования (консоль + backend.log)
│   │   └── traffic_audit.py          # Middleware аудита HTTP-трафика и задержек
│   ├── crm/                          # [Спящая схема] Клиенты и история операций
│   │   └── models.py                 # Модели схемы: Customer, CustomerTransaction, BonusTransaction (сохранены для FK orders.customer_id и целостности БД)
│   ├── gift_cards/                   # [Спящая схема] Сертификаты и подарочные карты
│   │   ├── __init__.py               # Экспорт моделей пакета gift_cards
│   │   └── models.py                 # Модели схемы: GiftCard, GiftCardTransaction (сохранены для целостности существующих таблиц БД)
│   ├── inventory/                    # Модуль: Склад, Меню, Техкарты и Поставщики
│   │   ├── __pycache__/              # Байт-код модуля склада
│   │   ├── models/                   # Модели: menu_models, ingredient_models, document_models, enums
│   │   ├── routers/                  # HTTP-маршруты: menu, ingredient, category, document (с WS-broadcast), supplier, stock
│   │   ├── services/                 # Бизнес-логика: menu_service, ingredient_service, document_service
│   │   ├── __init__.py               # Инициализация пакета inventory
│   │   ├── router.py                 # Главный роутер склада и каталога
│   │   └── seed.py                   # Базовый сид тестового меню и ингредиентов
│   ├── pos/                          # Модуль: Кассовый терминал, Заказы, Смены и WebSocket
│   │   ├── __pycache__/              # Байт-код модуля POS
│   │   ├── routers/                  # HTTP-маршруты: checkout_router, shift_router, cashbox_router, table_router
│   │   ├── services/                 # Бизнес-логика: checkout_service, shift_service, order_table_service
│   │   ├── __init__.py               # Инициализация пакета pos
│   │   ├── models.py                 # Модели: Order, OrderItem, Shift, Cashbox, OrderTable
│   │   └── ws.py                     # WebSocket хаб реального времени (уведомления касс, кухни и склада)
│   ├── system/                       # Модуль: Системные настройки, Управление кластером и Диагностика
│   │   ├── __pycache__/              # Байт-код модуля system
│   │   ├── routers/                  # HTTP-маршруты системного управления
│   │   │   ├── database_router.py    # Инспектор таблиц и данных схемы тенанта
│   │   │   └── tenant_router.py      # Управление тенантами, владельцами, статусом и валютами
│   │   ├── __init__.py               # Инициализация пакета system
│   │   ├── integrations.py           # Сервисы внешних интеграций
│   │   ├── router.py                 # Главный роутер системного модуля и healthcheck (/health)
│   │   ├── schemas.py                # Pydantic DTO запросов и ответов тенантов/владельцев
│   │   ├── security.py               # Валидация x-system-token суперадминистратора
│   │   └── telegram_service.py       # Интеграция с Telegram Bot API
│   ├── users/                        # Модуль: Авторизация и Управление доступом (PBAC)
│   │   ├── __pycache__/              # Байт-код модуля users
│   │   ├── routers/                  # HTTP-маршруты: auth_router, users_router
│   │   ├── __init__.py               # Инициализация пакета users
│   │   ├── models.py                 # Модели схемы public: Tenant, User, Role, Permission
│   │   ├── permissions.py            # Централизованный реестр прав Perm (22 системных разрешения)
│   │   ├── seed.py                   # Сид системных ролей и прав по умолчанию
│   │   └── services.py               # Хэширование паролей, JWT, проверка суперюзера, сбор прав
│   │
│   ├── __init__.py                   # Корневой маркер Python-пакета app
│   ├── base_model.py                 # Базовый класс TenantModel (created_at, updated_at)
│   ├── config.py                     # Настройки Settings (.env, JWT secret, DB URL)
│   ├── database.py                   # Async Engine, session factory, раннер SQL-миграций
│   ├── dependencies.py               # Зависимости FastAPI: require_permission, get_tenant_session
│   ├── exceptions.py                 # Кастомные доменные исключения (нехватка остатков, закрытая смена)
│   └── main.py                       # Точка входа FastAPI, CORS, lifespan, подключение роутеров
│
├── migrations/                       # SQL-миграции схем тенантов
│   └── tenant_patches/               # Файловые патчи структуры таблиц тенантов
│       ├── 001_initial_schema.sql    # Базовый DDL-патч (оплаты, балансы, CRM, индексы)
│       ├── 002_add_ingredient_is_archived.sql # Добавление флага архивации ингредиентов
│       ├── 003_purge_dummy_parent_retail_products.sql # Очистка фиктивных RetailProduct для серий
│       ├── 004_add_gift_card_client_uuid.sql # Идемпотентность транзакций сертификатов
│       ├── 005_normalize_retail_product_units.sql # Нормализация единиц учета в 'PCS' и названий плоских товаров
│       ├── 006_heal_orphaned_flat_variations.sql # Восстановление связей плоских вариаций номенклатуры
│       └── 007_sync_archived_retail_products.sql # Синхронизация статусов архивации товаров ритейла
│
├── scripts/                          # Скрипты ручного тестирования и утилиты
│   ├── manual_tests/                 # Ручные сценарии проверки API (смены, печать, X-отчеты)
│   └── seed_data.py                  # Утилита наполнения тестовыми данными
│
├── tests/                            # Набор автоматических тестов pytest (127 тестов)
│   ├── __pycache__/                  # Служебный кэш байт-кода тестов
│   ├── conftest.py                   # Корневые фикстуры (SQLite in-memory, моки сессий)
│   ├── test_adversarial_m1.py        # Стресс-тестирование граничных условий
│   ├── test_analytics.py             # Тесты аналитики и сменных отчетов
│   ├── test_bulk_endpoints.py        # Тесты батч-эндпоинтов номенклатуры
│   ├── test_cash_operations.py       # Тесты кассовых операций и инкассации
│   ├── test_e2e_requirements.py      # E2E приёмочные сценарии
│   ├── test_frontend_logs.py         # Тесты ingestion логов фронтенда
│   ├── test_inventory_deduction.py   # Тесты автоматического списания ингредиентов
│   ├── test_m1_adversarial.py        # Стресс-тесты PBAC прав и безопасности
│   ├── test_main.py                  # Тесты точки входа и healthcheck
│   ├── test_menu_topology.py         # Тесты топологии категорий и позиций меню
│   ├── test_multitenancy_and_idor.py # Тесты изоляции схем тенантов и IDOR защиты
│   ├── test_pbac_three_roles.py      # Тесты матриц ролей PBAC
│   ├── test_poka_yoke_guards.py      # Тесты защиты от дублей и ошибок ввода (Poka-Yoke)
│   ├── test_pos_offline_idempotency.py # Тесты идемпотентности кассы
│   ├── test_pos_security_admin.py    # Тесты безопасности суперадминистратора и PIN-кодов кассы
│   ├── test_pos_shifts.py            # Тесты открытия и закрытия смен
│   ├── test_recipe_api.py            # Тесты калькуляций техкарт и граммовок
│   ├── test_retail_variations.py     # Тесты вариаций штучного ритейла и упаковок
│   ├── test_supplier_debt_and_documents.py # Тесты долгов поставщиков и накладных
│   ├── test_system_security.py       # Тесты управления тенантами, сброса паролей и системного токена
│   ├── test_tenant_migrations.py     # Тесты миграций схем тенантов
│   └── test_users.py                 # Тесты пользователей и авторизации
│
├── .env                              # Локальные переменные окружения разработчика
├── .env.example                      # Публичный образец переменных окружения
├── .gitignore                        # Правила исключения временных файлов и кэша из Git
├── .python-version                   # Указание версии интерпретатора (Python 3.12)
├── alembic.ini                       # Файл конфигурации Alembic
├── ARCHITECTURE_MAP.md               # Данная архитектурная карта бэкенда
├── cli.py                            # Консольный интерфейс администратора
├── docker-compose.prod.yml           # Конфигурация запуска в production
├── docker-compose.yml                # Конфигурация локального окружения с PostgreSQL
├── Dockerfile                        # Инструкция сборки Docker-образа бэкенда
├── pyproject.toml                    # Декларация пакетов и зависимостей Poetry/UV
├── pytest.ini                        # Конфигурация запуска тестов pytest
└── uv.lock                           # Lock-файл детерминированных версий библиотек
```

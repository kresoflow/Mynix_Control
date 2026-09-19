# Kreso Flow — Master Repository Architecture Map
**Проект:** Kreso Flow — Enterprise ERP / POS система для ресторанов, кафе и ритейла.  
**Порядок отображения:** **100% точное соответствие проводнику VS Code (Explorer)**: каталог за каталогом, файл за файлом, включая виртуальные окружения и служебные кэши.

---

## 1. Фундаментальные законы репозитория (Конституция проекта)

1. **Multi-Tenancy:** Данные изолируются по схемам PostgreSQL (`tenant_<slug>`). Колонка `tenant_id` в таблицах тенанта **СТРОГО ЗАПРЕЩЕНА**.
2. **PBAC Безопасность:** Доступ к любому эндпоинту бэкенда защищается через `app.users.permissions.Perm`.
3. **UI Kit & Design System:** Запрещены `Colors.*` и стандартные кнопки `ElevatedButton`/`TextButton`. Все компоненты строятся строго на `AppColors.*`, `AppRadii.*` и семействе `AppButton`.
4. **Баланс связности (Locality of Behavior > Line Count):** Лимит файлов 200–250 строк, потолок 300 строк. Для связных монолитов (BLoC с эвентами/стейтами, транзакции склада) разрешено до 300–350 строк. Файлы-карлики (<60 строк) строго запрещены.
5. **Автоматический контроль (Shift-Left):** Перед коммитом и сдачей обязателен успешный прогон `python scripts/verify_rules.py`, `pytest` и `flutter test`.

---

## 2. Полная структура корня репозитория (Точно по проводнику VS Code)

```
d:\Kreso Flow_Control/
├── .agents/                          # Каталог агентной системы и базы стандартов
│   ├── sentinel/                     # Мониторинг и супервизия мульти-агентных сессий
│   ├── skills/                       # 7 инженерных навыков: art_director, delivery, fastapi, flutter, product_designer, qa, refactor
│   ├── AGENTS.md                     # Главная конституция проекта и правила разработки
│   └── ORIGINAL_REQUEST.md           # Первоначальное техническое задание
│
├── .git/                             # Служебный репозиторий Git
├── .github/                          # Конфигурация GitHub Actions CI/CD пайплайнов
├── .pytest_cache/                    # Временный кэш тестового фреймворка pytest в корне
│
├── backend/                          # Бэкенд на FastAPI, SQLModel и PostgreSQL Multi-Tenancy
│   ├── __pycache__/                  # Служебный кэш скомпилированного байт-кода корня бэкенда
│   ├── .pytest_cache/                # Служебный кэш pytest в backend
│   ├── .venv/                        # Виртуальное окружение Python 3.12 со всеми библиотеками
│   ├── alembic/                      # Миграции схемы public (tenants, users, roles)
│   ├── app/                          # Исходный код бэкенда (analytics, crm, hardware, inventory, kitchen, pos, system, users)
│   ├── migrations/                   # SQL-миграции схем тенантов (tenant_patches/001_initial_schema.sql)
│   ├── scripts/                      # Скрипты ручного тестирования и сиды
│   ├── tests/                        # 14 тестовых наборов pytest + conftest.py
│   └── ARCHITECTURE_MAP.md           # Детальная архитектурная карта бэкенда
│
├── docs/                             # Документация, отчеты аудитов и архив сессий
│   ├── archive_audits/               # Консолидированный аудит и отчеты инспекций
│   └── archive_sessions/             # Заархивированные в .zip логи прошедших сессий
│
├── frontend/                         # Клиентское приложение на Flutter (POS, Склад, KDS)
│   ├── .dart_tool/                   # Кэш инструментов Dart SDK
│   ├── .idea/                        # Настройки IDE JetBrains
│   ├── android/                      # Нативный проект Android (APK для сенсорных POS)
│   ├── assets/                       # Иконки и изображения
│   ├── build/                        # Каталог артефактов компиляции Flutter
│   ├── ios/                          # Нативный проект iOS (iPad для кассы и кухни)
│   ├── lib/                          # Исходный код: core/ (UI Kit, темы, сеть) и features/ (11 доменных модулей)
│   ├── linux/                        # Нативный проект Linux
│   ├── macos/                        # Нативный проект macOS
│   ├── test/                         # Unit- и widget-тесты Flutter
│   ├── web/                          # Нативный проект Web
│   ├── windows/                      # Нативный проект Windows (главный таргет POS кассы)
│   └── ARCHITECTURE_MAP.md           # Детальная архитектурная карта фронтенда
│
├── landing/                          # Промо-лендинг и презентационные материалы продукта
│   ├── index.html                    # Разметка лендинга
│   ├── script.js                     # Интерактивная логика
│   └── styles.css                    # Стилизация и адаптивная верстка
│
├── scripts/                          # Инструменты автоматизации контроля качества
│   ├── __pycache__/                  # Служебный кэш скомпилированного байт-кода скриптов (xray.pyc)
│   ├── verify_rules.py               # Главный архитектурный linter проекта
│   └── xray.py                       # Интерактивная консоль архитектурного анализа кодовой базы
│
├── tg_web_app/                       # Telegram Web App интерфейс для гостей и курьеров
│   ├── node_modules/                 # Зависимости Node.js/Vite
│   ├── public/                       # Статические ассеты Web App
│   ├── src/                          # Исходный код TypeScript / React (или Vanilla)
│   ├── .gitignore                    # Исключения Git для Mini App
│   ├── .oxlintrc.json                # Конфигурация линтера Oxlint
│   ├── index.html                    # Точка входа Mini App
│   ├── package.json                  # Манифест зависимостей npm
│   ├── tsconfig.json                 # Настройки компилятора TypeScript
│   ├── vite.config.ts                # Конфигурация сборщика Vite
│   └── README.md                     # Документация Telegram Mini App
│
├── .gitignore                        # Глобальные правила игнорирования файлов в Git
├── ARCHITECTURE_MAP.md               # Данная генеральная мастер-карта репозитория
├── DESIGN.md                         # Брендбук, типографика, правила контраста и темы
├── mynix_control_agents_skills_docs.zip # Архив документации и навыков агентов
├── PROJECT.md                        # Инженерная спецификация доменов и контракты API
├── TEST_INFRA.md                     # Документация по тестовой инфраструктуре
└── TEST_READY.md                     # Чеклист готовности к релизу и верификации
```

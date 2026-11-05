<!-- =========================================================================== -->
<!-- ДОКУМЕНТ: Frontend Architecture Map (frontend/ARCHITECTURE_MAP.md)          -->
<!-- СТАТУС:   АКТУАЛЬНО (Phase 1: Stateful Shell, SWR, Desktop UX & Bloat Decomposition) -->
<!-- ДАТА:     2026-10-24 | Контрольный коммит: fb5322e                         -->
<!-- =========================================================================== -->
# Kreso Flow — Frontend Architecture Map
**Стек:** Flutter 3.x, Dart, BLoC (`flutter_bloc` + `equatable`), Dio, Feature-Driven Architecture.  
**Дизайн-система:** Строгий UI Kit, 100% токенизация, шкала размеров `AppButtonSize`, запрет сырых `Colors.*` и стандартных кнопок.  
**Порядок отображения:** **100% точное соответствие проводнику VS Code (Explorer)**: каталог за каталогом, файл за файлом, включая слои архитектуры внутри каждой фичи.
> [!IMPORTANT] РЕГЛАМЕНТ АКТУАЛИЗАЦИИ КАРТЫ (PHASE-DRIVEN SYNC)
> 1. **Фазовый жизненный цикл:** Данная карта обновляется **централизованно по завершении ключевых архитектурных/бизнес-фаз (Milestones / Sprints)** или при крупных рефакторингах структуры, а **не** при каждом мелком коммите.
> 2. **Правило недоверия для AI-агентов:** Если текущая дата или состояние репозитория (Git HEAD) новее даты, указанной в шапке этой карты — **НЕ доверяйте структуре слепо**. Перед чтением, редактированием или удалением файлов всегда проверяйте реальное существование путей через `find_by_name`, `list_dir` или `git status`.

---

## 1. Фундаментальные инварианты фронтенда

1. **Запрет сырых кнопок Material:**
   - Запрещено использовать `ElevatedButton`, `TextButton`, `OutlinedButton`.
   - Разрешены только компоненты дизайн-системы: `AppPrimaryButton`, `AppSecondaryButton`, `AppGhostButton`, `AppDangerButton`, `AppMenuButton`.
   - Шкала размеров `AppButtonSize`: `xs (28px)`, `sm (32px)`, `md (36px)`, `lg (44-48px)`, `xl (52px)`.
2. **Запрет хардкода цветов и стилей (100% UI Kit Tokenization):**
   - Запрещено использовать `Colors.*` и сырые `Color(0x...)` в коде виджетов (за исключением `core/theme/`).
   - Все цвета берутся только из `AppColors.*` (`brandPrimary`, `darkCard`, `lightCard`, `pureWhite`, `transparent`, `danger`, `success`, `warning`).
   - Скругления: `AppRadii.*`. Тени: `AppShadows.*`. Типографика: `AppTextStyles.*`.
3. **Stateful Навигация & SWR:**
   - Сохранение состояния экранов при навигации через `StatefulShellRoute.indexedStack` (0 мс переключение, сохранение скролла и форм).
   - Stale-While-Revalidate: при повторном открытии или ревалидации данные отображаются из памяти мгновенно, фоновое обновление происходит тихо, без пульсирующих скелетонов (`SkeletonList` только при холодном старте).
   - Живая синхронизация через `webSocketService` (Склад, Аналитика, Касса).
4. **Графическая изоляция (FPS & Repaint Optimization):**
   - Установка `RepaintBoundary` на тяжелые поддеревья: графики аналитики (`fl_chart`), плитки каталога кассы, корзина и активные столы.
5. **Принцип связности и лимиты строк (Locality of Behavior):**
   - Целевой размер файлов: 200–250 строк. Жесткий потолок: 300 строк.
   - Запрещены файлы-карлики (<60 строк).
6. **Desktop Инварианты & Hotkeys:**
   - Каскадная иерархия Esc: 1) очистка текста активного поиска -> 2) расфокусировка/сворачивание активного поиска (соседние открытые колонки поиска изолированы и не схлопываются) -> 3) закрытие модального окна (AppSaveShortcutScope).
   - Хоткеи поиска: Ctrl + F / Cmd + K / F2 (поддержка RU/EN через physicalKey) во всех модалках и разделах; строгая изоляция от корневых диалогов rootNavigator (фоновый поиск блокируется); чистый UI без визуального мусора бейджей; автокурсор при смене вкладок и режимов строк/категорий.
   - Аппаратные хоткеи: Ctrl + S / Cmd + S (сохранение в модальных окнах), Ctrl + 1..6 (быстрая навигация по сайдбару), Ctrl + B (свернуть/развернуть меню).
   - Ограничение окна Windows Desktop (WM_GETMINMAXINFO): минимальный размер 1024x700 px (защита от сжатия POS-терминалов кассы).

---

## 2. Полная структура дерева `frontend/` (Точно по проводнику VS Code)

```
frontend/
├── .dart_tool/                       # [1] Служебный кэш Dart SDK и генераторов кода build_runner
├── .idea/                            # [2] Настройки проекта среды разработки JetBrains/Android Studio
├── android/                          # [3] Нативный проект Android (сборка APK/AAB для POS-терминалов)
│
├── assets/                           # [4] Статические медиа-ресурсы
│   ├── icons/                        # Пиктограммы способов оплаты, категорий и статусов
│   └── images/                       # Логотипы Kreso Flow, плейсхолдеры товаров
│
├── build/                            # [5] Каталог скомпилированных бинарных артефактов сборки Flutter
├── ios/                              # [6] Нативный проект iOS (iPad для кассы и кухни)
│
├── lib/                              # [7] Исходный код приложения на Dart
│   ├── core/                         # Общесистемное ядро и инфраструктура
│   │   ├── layout/                   # Адаптивные каркасы главного лейаута
│   │   ├── network/                  # Сетевой транспорт: api_client.dart (Dio), websocket_service.dart
│   │   ├── router/                   # Навигация: app_router.dart (StatefulShellRoute.indexedStack)
│   │   ├── theme/                    # Дизайн-система (SSOT): app_colors, app_radii, app_shadows, app_text_styles, theme_bloc
│   │   ├── utils/                    # Хелперы: app_bloc_observer, audio_helper, currency_formatter, role_formatter
│   │   └── widgets/                  # Библиотека компонентов UI Kit (100% токенизирована):
│   │       ├── color_picker/         # Виджеты пикера цветов номенклатуры (HSV plane, hue slider, dialog)
│   │       ├── main_layout/          # Адаптивные каркасы (desktop_layout, mobile_layout, app_nav_bar, app_nav_rail)
│   │       ├── profile/              # Модальное окно профиля кассира и выход из системы
│   │       ├── ui_kit/               # Специализированные контролы (AppFilterChip, AppSearchField, AppSegmentedControl)
│   │       ├── app_button.dart       # Семейство кнопок AppButton со шкалой размеров AppButtonSize
│   │       ├── app_card.dart         # Универсальные карточки с поддержкой тёмной и светлой тем
│   │       ├── app_dialog_scaffold.dart # Каркас модальных диалогов с фиксированной шапкой и футером
│   │       ├── app_segmented_tab.dart   # Анимированный сегментированный переключатель вкладок
│   │       ├── app_text_field.dart   # Стилизованные текстовые поля ввода с поддержкой POS-клавиатуры
│   │       ├── app_toast.dart        # Всплывающие toast-уведомления об успехе или ошибке
│   │       ├── date_time_picker_*.dart # Календарь и время с токенами дизайн-системы
│   │       ├── logout_confirm_dialog.dart # Диалог подтверждения выхода с защитой
│   │       └── skeleton_loader.dart  # Скелетонные плейсхолдеры для первичной загрузки данных
│   │
│   ├── features/                     # Модули бизнес-логики (Feature-Driven Architecture)
│   │   ├── analytics/                # Модуль: Аналитика и Отчетность
│   │   │   ├── bloc/                 # analytics_bloc.dart (SWR + WS), analytics_event.dart, analytics_state.dart
│   │   │   ├── models/               # analytics_models.dart, dashboard_data.dart
│   │   │   ├── repository/           # analytics_repository.dart
│   │   │   └── view/                 # analytics_dashboard_screen.dart (SWR), tabs/ (сводка, чеки, смены), widgets/
│   │   ├── auth/                     # Модуль: Авторизация и Смена кассира
│   │   │   ├── bloc/                 # auth_bloc.dart, auth_event.dart, auth_state.dart
│   │   │   ├── repository/           # auth_repository.dart (вход по логину/паролю и PIN-коду)
│   │   │   └── view/                 # login_screen.dart (декомпозирован), splash_screen.dart, widgets/ (pin_keypad.dart)
│   │   ├── crm/                      # Модуль: База клиентов и Программа лояльности
│   │   │   ├── bloc/                 # crm_bloc.dart, crm_event.dart, crm_state.dart
│   │   │   ├── models/               # customer.dart, bonus_transaction.dart, customer_transaction.dart
│   │   │   ├── repository/           # crm_repository.dart
│   │   │   └── view/                 # crm_screen.dart, widgets/ (модалки начисления бонусов, история баланса)
│   │   ├── hub/                      # Модуль: Стартовый лаунчер (Hub)
│   │   │   └── view/                 # hub_screen.dart (быстрый переход между Кассой, Складом и Аналитикой)
│   │   ├── inventory/                # Модуль: Складской учет и Товародвижение
│   │   │   ├── bloc/                 # category_bloc, document_bloc (SWR + WS + handlers), ingredient_bloc (SWR + WS)
│   │   │   ├── models/               # document.dart, ingredient.dart, supplier.dart, supplier_transaction.dart
│   │   │   ├── repository/           # inventory_repository.dart, parts/ (stock_part, documents_part)
│   │   │   ├── services/             # document_export_service.dart, export_helper (web/stub)
│   │   │   └── view/                 # warehouse_screen.dart, widgets/ (dialogs/ с корзинами cart_sheet и 2 режимами)
│   │   ├── kitchen/                  # [Архивирован в пилоте] Модуль: Кухонный терминал (KDS)
│   │   │   ├── bloc/                 # kitchen_bloc.dart, kitchen_event.dart, kitchen_state.dart
│   │   │   ├── repository/           # kitchen_repository.dart
│   │   │   └── view/                 # kitchen_screen.dart, kds_board.dart, widgets/ (карточки заказов, таймеры)
│   │   ├── menu/                     # Модуль: Меню, Каталог блюд и Техкарты
│   │   │   ├── services/             # duplicate_detector.dart (предотвращение дубликатов позиций)
│   │   │   └── view/                 # catalog_screen.dart, widgets/ (каталог блюд, модификаторы, техкарты)
│   │   ├── orders/                   # Модуль: Журнал чеков и История заказов
│   │   │   ├── bloc/                 # orders_bloc.dart (live-обновление чеков по WebSocket)
│   │   │   ├── models/               # pos_order.dart (модель чека с позициями и скидками)
│   │   │   ├── repository/           # orders_repository.dart
│   │   │   └── view/                 # orders_screen.dart, widgets/ (order_details_dialog.dart, возврат)
│   │   ├── pos/                      # Модуль: Сенсорная POS-касса
│   │   │   ├── bloc/                 # cart_bloc.dart, menu_bloc.dart, shift_bloc.dart, pos_tab_cubit.dart
│   │   │   ├── models/               # cart_item.dart, menu_category.dart, menu_item.dart, cash_operation.dart
│   │   │   ├── repository/           # menu_repository.dart, order_repository.dart, shift_repository.dart
│   │   │   ├── services/             # pos_outbox_service.dart, pos_sync_service.dart, lan/ (локальный POS-сервер)
│   │   │   └── view/                 # pos_screen.dart, widgets/ (столы зала, диалог модификаторов, закрытие смены)
│   │   ├── settings/                 # Модуль: Настройки заведения
│   │   │   ├── bloc/                 # settings_bloc.dart, user_bloc.dart (pre-cached)
│   │   │   ├── models/               # user_model.dart
│   │   │   ├── repository/           # settings_repository.dart, user_repository.dart
│   │   │   ├── services/             # lan_settings_service.dart (сетевые принтеры и сканеры)
│   │   │   └── view/                 # settings_screen.dart, ui_kit_showcase_screen.dart (ListView.builder), tabs/
│   │   └── superadmin/               # Модуль: SaaS-управление тенантами
│   │       ├── bloc/                 # superadmin_bloc.dart, tenant_explorer_bloc.dart
│   │       ├── models/               # tenant.dart (сущность организации и владельца)
│   │       ├── repository/           # superadmin_repository.dart (CRUD тенантов и инспектор БД)
│   │       └── view/                 # superadmin_screen.dart, tenant_explorer_screen.dart, widgets/
│   │
│   └── main.dart                     # Точка входа Flutter: runApp, регистрация провайдеров и тем
│
├── linux/                            # [8] Нативный проект Linux Desktop
├── macos/                            # [9] Нативный проект macOS Desktop
│
├── test/                             # [10] Автоматические тесты Flutter (11 наборов, 76 тестов)
│   ├── api_test.dart                 # Тесты сериализации моделей поставщиков и взаиморасчетов
│   ├── bulk_add_duplicate_validator_test.dart # Тесты валидатора коллизий и дубликатов при пакетном добавлении
│   ├── bulk_add_test.dart            # Комплексные тесты пакетного создания номенклатуры и навигации
│   ├── cash_operation_test.dart      # Тесты моделей кассовых операций (инкассация, размен)
│   ├── document_export_test.dart     # Тесты экспорта складских документов в Excel / PDF
│   ├── duplicate_detector_test.dart  # Тесты детектора дубликатов позиций меню
│   ├── goods_receipt_test.dart       # Тесты проведения складских накладных и синхронизации BLoC
│   ├── menu_item_variations_test.dart# Тесты вариаций блюд и упаковок номенклатуры
│   ├── unit_formatter_test.dart      # Тесты форматирования единиц измерения
│   ├── widget_test.dart              # Тесты дизайн-системы и кнопок AppButton
│   └── write_off_hybrid_test.dart    # Тесты гибридного списания номенклатуры
│
├── web/                              # [11] Нативный проект Web (PWA для браузеров)
├── windows/                          # [12] Нативный проект Windows Desktop (основной таргет POS кассы)
│
├── .flutter-plugins-dependencies     # Служебный файл зарегистрированных зависимостей плагинов
├── .gitignore                        # Правила исключения временных файлов и сборки Flutter из Git
├── .metadata                         # Метаданные версии и каналов Flutter SDK
├── analysis_options.yaml             # Конфигурация линтера Dart (flutter analyze)
├── ARCHITECTURE_MAP.md               # Данная архитектурная карта фронтенда
├── devtools_options.yaml             # Настройки инструментов DevTools профилирования
├── flutter_01.log                    # Лог последнего локального запуска приложения
├── pubspec.lock                      # Зафиксированные точные версии всех Dart пакетов
├── pubspec.yaml                      # Главный манифест зависимостей Flutter проекта
└── README.md                         # Инструкция по сборке и запуску фронтенда
```

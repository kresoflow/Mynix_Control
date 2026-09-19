# Mynix Control — Frontend Architecture Map
**Стек:** Flutter 3.x, Dart, BLoC (`flutter_bloc` + `equatable`), Dio, Feature-Driven Architecture.  
**Дизайн-система:** Строгий UI Kit, шкала размеров `AppButtonSize`, запрет сырых `Colors.*` и стандартных кнопок.  
**Порядок отображения:** **100% точное соответствие проводнику VS Code (Explorer)**: каталог за каталогом, файл за файлом, включая слои архитектуры внутри каждой фичи.

---

## 1. Фундаментальные инварианты фронтенда

1. **Запрет сырых кнопок Material:**
   - Запрещено использовать `ElevatedButton`, `TextButton`, `OutlinedButton`.
   - Разрешены только компоненты дизайн-системы: `AppPrimaryButton`, `AppSecondaryButton`, `AppGhostButton`, `AppDangerButton`, `AppMenuButton`.
   - Шкала размеров `AppButtonSize`: `xs (28px)`, `sm (32px)`, `md (36px)`, `lg (44-48px)`, `xl (52px)`.
2. **Запрет хардкода цветов и стилей:**
   - Запрещено использовать `Colors.*` и сырые `Color(0x...)` в коде виджетов (за исключением `core/theme/`).
   - Все цвета берутся только из `AppColors.*` (`brandPrimary`, `darkCard`, `lightCard`, `pureWhite`, `transparent`, `danger`, `success`, `warning`).
   - Скругления: `AppRadii.*`. Тени: `AppShadows.*`. Типографика: `AppTextStyles.*`.
3. **Принцип связности (Locality of Behavior > Line Count):**
   - Целевой размер файлов: 200–250 строк. Потолок: 300 строк.
   - Для связных монолитов (BLoC со своими Event и State) разрешено до 300–350 строк.
   - Табу на файлы-карлики (<60 строк): приватные виджеты экрана обязаны оставаться в файле экрана.
4. **Сетевой слой:**
   - Прямые HTTP-запросы из UI или BLoC запрещены. Используется слой `Repository`, инжектируемый через `RepositoryProvider`.

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
│   └── images/                       # Логотипы Mynix, плейсхолдеры товаров
│
├── build/                            # [5] Каталог скомпилированных бинарных артефактов сборки Flutter
├── ios/                              # [6] Нативный проект iOS (iPad для кассы и кухни)
│
├── lib/                              # [7] Исходный код приложения на Dart
│   ├── core/                         # Общесистемное ядро и инфраструктура
│   │   ├── network/                  # Сетевой транспорт: api_client.dart (Dio), websocket_service.dart
│   │   ├── router/                   # Навигация: app_router.dart (декларативный GoRouter)
│   │   ├── theme/                    # Дизайн-система (SSOT): app_colors, app_radii, app_shadows, app_text_styles, theme_bloc
│   │   ├── utils/                    # Хелперы: app_bloc_observer, audio_helper, currency_formatter, role_formatter
│   │   └── widgets/                  # Библиотека компонентов UI Kit:
│   │       ├── color_picker/         # Виджеты пикера цветов номенклатуры (HSV plane, hue slider, dialog)
│   │       ├── main_layout/          # Адаптивные каркасы (desktop_layout, mobile_layout, nav_rail)
│   │       ├── profile/              # Модальное окно профиля кассира и выход из системы
│   │       ├── ui_kit/               # Специализированные контролы (AppFilterChip, AppSearchField)
│   │       ├── app_button.dart       # Семейство кнопок AppButton со шкалой размеров AppButtonSize
│   │       ├── app_card.dart         # Универсальные карточки с поддержкой тёмной и светлой тем
│   │       ├── app_dialog_scaffold.dart # Каркас модальных диалогов с фиксированной шапкой и футером
│   │       ├── app_segmented_tab.dart   # Анимированный сегментированный переключатель вкладок
│   │       ├── app_text_field.dart   # Стилизованные текстовые поля ввода с поддержкой POS-клавиатуры
│   │       └── app_toast.dart        # Всплывающие toast-уведомления об успехе или ошибке
│   │
│   ├── features/                     # Модули бизнес-логики (Feature-Driven Architecture)
│   │   ├── analytics/                # Модуль: Аналитика и Отчетность
│   │   │   ├── bloc/                 # analytics_bloc.dart, analytics_event.dart, analytics_state.dart
│   │   │   ├── models/               # analytics_models.dart, dashboard_data.dart
│   │   │   ├── repository/           # analytics_repository.dart
│   │   │   └── view/                 # analytics_dashboard_screen.dart, tabs/ (смены, продажи), widgets/
│   │   ├── auth/                     # Модуль: Авторизация и Смена кассира
│   │   │   ├── bloc/                 # auth_bloc.dart, auth_event.dart, auth_state.dart
│   │   │   ├── repository/           # auth_repository.dart (вход по логину/паролю и PIN-коду)
│   │   │   └── view/                 # login_screen.dart, splash_screen.dart, widgets/ (pin_keypad.dart)
│   │   ├── crm/                      # Модуль: База клиентов и Программа лояльности
│   │   │   ├── bloc/                 # crm_bloc.dart, crm_event.dart, crm_state.dart
│   │   │   ├── models/               # customer.dart, bonus_transaction.dart, customer_transaction.dart
│   │   │   ├── repository/           # crm_repository.dart
│   │   │   └── view/                 # crm_screen.dart, widgets/ (модалки начисления бонусов, история баланса)
│   │   ├── hub/                      # Модуль: Стартовый лаунчер (Hub)
│   │   │   └── view/                 # hub_screen.dart (быстрый переход между Кассой, Складом и Аналитикой)
│   │   ├── inventory/                # Модуль: Складской учет и Товародвижение
│   │   │   ├── bloc/                 # category_bloc, document_bloc, inventory_bloc, receive_retail_bloc
│   │   │   ├── models/               # document.dart, ingredient.dart, supplier.dart, supplier_transaction.dart
│   │   │   ├── repository/           # inventory_repository.dart, parts/ (stock_part, documents_part)
│   │   │   ├── services/             # document_export_service.dart, export_helper (web/stub)
│   │   │   └── view/                 # warehouse_screen.dart, receive_retail_screen.dart, widgets/ (bulk_add/, stock_tab)
│   │   ├── kitchen/                  # Модуль: Кухонный терминал (KDS)
│   │   │   ├── bloc/                 # kitchen_bloc.dart, kitchen_event.dart, kitchen_state.dart
│   │   │   ├── repository/           # kitchen_repository.dart
│   │   │   └── view/                 # kitchen_screen.dart, kds_board.dart, widgets/ (карточки заказов, таймеры)
│   │   ├── menu/                     # Модуль: Меню, Каталог блюд и Техкарты
│   │   │   ├── services/             # duplicate_detector.dart (предотвращение дубликатов позиций)
│   │   │   └── view/                 # catalog_screen.dart, widgets/ (каталог блюд, модификаторы, техкарты)
│   │   ├── orders/                   # Модуль: Журнал чеков и История заказов
│   │   │   ├── bloc/                 # orders_bloc.dart
│   │   │   ├── models/               # pos_order.dart (модель чека с позициями и скидками)
│   │   │   ├── repository/           # orders_repository.dart
│   │   │   └── view/                 # orders_screen.dart, widgets/ (order_details_dialog.dart, возврат)
│   │   ├── pos/                      # Модуль: Сенсорная POS-касса
│   │   │   ├── bloc/                 # cart_bloc.dart, menu_bloc.dart (связный BLoC), pos_settings_cubit.dart
│   │   │   ├── models/               # cart_item.dart, menu_category.dart, menu_item.dart
│   │   │   ├── repository/           # menu_repository.dart, order_repository.dart, shift_repository.dart
│   │   │   ├── services/             # pos_outbox_service.dart, pos_sync_service.dart, lan/ (локальный POS-сервер)
│   │   │   └── view/                 # pos_screen.dart, widgets/ (столы зала, диалог модификаторов, закрытие смены)
│   │   ├── settings/                 # Модуль: Настройки заведения
│   │   │   ├── bloc/                 # settings_bloc.dart, user_bloc.dart
│   │   │   ├── models/               # user_model.dart
│   │   │   ├── repository/           # settings_repository.dart, user_repository.dart
│   │   │   ├── services/             # lan_settings_service.dart (сетевые принтеры и сканеры)
│   │   │   └── view/                 # settings_screen.dart, ui_kit_showcase_screen.dart, tabs/ (принтеры, сотрудники)
│   │   └── superadmin/               # Модуль: SaaS-управление тенантами
│   │       ├── data/                 # Источники данных и DTO
│   │       ├── domain/               # superadmin_repository.dart
│   │       └── presentation/         # tenant_explorer_screen.dart, superadmin_screen.dart, bloc/, widgets/
│   │
│   └── main.dart                     # Точка входа Flutter: runApp, регистрация провайдеров и тем
│
├── linux/                            # [8] Нативный проект Linux Desktop
├── macos/                            # [9] Нативный проект macOS Desktop
│
├── test/                             # [10] Автоматические тесты Flutter (flutter test)
│   ├── api_test.dart                 # Тесты сериализации моделей поставщиков и взаиморасчетов
│   ├── bulk_add_test.dart            # Комплексные тесты пакетного создания номенклатуры и навигации
│   ├── goods_receipt_test.dart       # Тесты проведения складских накладных
│   └── widget_test.dart              # Тесты дизайн-системы и кнопок AppButton
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

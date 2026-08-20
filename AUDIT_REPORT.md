# 📋 Полный технический аудит Flutter-проекта "Mynix Control"

> **Дата аудита:** 2026-08-20  
> **Стек:** Dart 3.11+ / Flutter (Null Safety), `flutter_bloc ^9.1.1`, `equatable ^2.0.8`, `dio ^5.9.2`  
> **Метод:** Сплошной статический и семантический анализ всей кодовой базы `frontend/lib/`.

---

## 📊 Сводная таблица нарушений (Шаг 1)

| № | Файл | Строка | Категория | Критичность | Risk/Impact | Что нарушено | Тесты есть? |
| :- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **1** | `lib/features/pos/view/widgets/components/pos_checkout_panel.dart` | 1-434 | 2. Микроархитектура | MAJOR | **HIGH** | Файл-великан (434 строки). Смешаны логика способов оплаты, UI скидок, выбор клиента, выпадающие списки переводов и оформление долга | ❌ Нет |
| **2** | `lib/features/pos/view/widgets/shift_hub/shift_pin_dialog.dart` | 29 | 1. Сеть / DI | CRITICAL | **HIGH** | Прямой вызов `apiClient.dio.post('/auth/verify-pin')` из UI-диалога вместо `AuthRepository` / `ShiftBloc` | ❌ Нет |
| **3** | `lib/features/pos/view/widgets/shift_hub/shift_pin_dialog.dart` | 34, 40 | 4. Async Safety | MAJOR | **HIGH** | Вызов `Navigator.of(ctx)` через async gap без проверки `mounted` | ❌ Нет |
| **4** | `lib/features/pos/view/widgets/shift_hub/shift_z_close_tab.dart` | 69 | 3. Хардкод | MINOR | **HIGH** | Захардкоженный текст валюты `suffixText: 'сомони'` вместо вызова `.toCurrency(context)` | ❌ Нет |
| **5** | `lib/features/pos/view/widgets/shift_hub/shift_history_tab.dart` | 25 | 1. Сеть / DI | MAJOR | **HIGH** | Инстанцирование `ShiftRepository(apiClient.dio)` в `initState` и ручной `setState` вместо BLoC | ❌ Нет |
| **6** | `lib/features/pos/view/widgets/customer_picker_modal.dart` | 45, 63 | 1. Сеть / DI | MAJOR | **HIGH** | Создание `CrmRepository(apiClient.dio)` внутри кнопки и модалки вместо `RepositoryProvider` | ❌ Нет |
| **7** | `lib/features/pos/view/widgets/customer_picker_modal.dart` | 66, 68 | 4. Async Safety | MAJOR | **HIGH** | Использование `Navigator.of(context)` и `ScaffoldMessenger` через async gap | ❌ Нет |
| **8** | `lib/features/pos/view/widgets/menu_modifiers_dialog.dart` | 1-271 | 2. Микроархитектура | MAJOR | **HIGH** | Превышение лимита (271 строка). Выбор модификаторов, расчет надбавок и верстка в одном файле | ❌ Нет |
| **9** | `lib/core/widgets/profile/user_profile_modal.dart` | 55, 87 | 1. Сеть / DI | CRITICAL | **MEDIUM** | Прямые HTTP-запросы `apiClient.dio.get/put('/auth/me')` из модалки вместо `AuthRepository` | ❌ Нет |
| **10** | `lib/features/settings/view/tabs/general_settings_tab.dart` | 33, 53 | 1. Сеть / DI | CRITICAL | **MEDIUM** | Прямые вызовы `apiClient.dio.get/put('/settings/')` в `initState` и методе сохранения | ❌ Нет |
| **11** | `lib/features/settings/view/tabs/personnel_settings_tab.dart` | 108, 172 | 3. Дизайн-система | MINOR | **MEDIUM** | Сырой цвет `Colors.red` в кнопке удаления вместо `AppColors.danger` | ❌ Нет |
| **12** | `lib/features/settings/view/settings_screen.dart` | 1-275 | 2. Микроархитектура | MAJOR | **LOW** | Превышение лимита (275 строк). Боковое меню настроек и контейнер вкладок не разделены | ❌ Нет |
| **13** | `lib/features/inventory/view/widgets/bulk_add_modal.dart` | 1-407 | 2. Микроархитектура | MAJOR | **MEDIUM** | Файл-великан (407 строк). Содержит парсер строк, селектор категорий, валидацию и таблицу | ❌ Нет |
| **14** | `lib/features/inventory/view/widgets/warehouse/dialogs/receive_document_dialog.dart` | 1-339 | 2. Микроархитектура | MAJOR | **MEDIUM** | Файл-великан (339 строк). Формирование накладной поставщика, расчет НДС/цен и выбор сырья | ❌ Нет |
| **15** | `lib/features/inventory/view/widgets/warehouse/dialogs/receive_document_dialog.dart` | 277 | 4. Async Safety | MAJOR | **MEDIUM** | Использование `BuildContext` после async gap без проверки `mounted` | ❌ Нет |
| **16** | `lib/features/inventory/view/widgets/warehouse/dialogs/receive_document/receive_document_save_helper.dart` | 144, 149 | 4. Async Safety | MAJOR | **MEDIUM** | Использование `BuildContext` после async сохранения документа | ❌ Нет |
| **17** | `lib/features/inventory/view/widgets/warehouse/dialogs/supplier_settlement/supplier_settlement_dialog.dart` | 62, 81 | 4. Async Safety | MAJOR | **MEDIUM** | Использование `BuildContext` после сохранения акта сверки поставщика | ❌ Нет |
| **18** | `lib/features/inventory/view/widgets/warehouse/suppliers_tab.dart` | 39 | 4. Async Safety | MAJOR | **MEDIUM** | Использование `BuildContext` после async удаления поставщика | ❌ Нет |
| **19** | `lib/features/inventory/view/widgets/warehouse/suppliers_tab.dart` | 1-291 | 2. Микроархитектура | MAJOR | **MEDIUM** | Превышение лимита (291 строка). Список поставщиков, фильтры и балансы в одном файле | ❌ Нет |
| **20** | `lib/features/inventory/view/widgets/warehouse/dialogs/document_detail/document_detail_dialog.dart` | 1-272 | 2. Микроархитектура | MAJOR | **MEDIUM** | Превышение лимита (272 строки). Просмотр позиций накладной, статусы и история | ❌ Нет |
| **21** | `lib/features/inventory/view/widgets/bulk_receipt_view.dart` | 1-259 | 2. Микроархитектура | MAJOR | **MEDIUM** | Превышение лимита (259 строк). Ввод массовых остатков | ❌ Нет |
| **22** | `lib/features/menu/view/widgets/catalog/ingredient/ingredient_category_sidebar.dart` | 1-342 | 2. Микроархитектура | MAJOR | **MEDIUM** | Файл-великан (342 строки). Дерево категорий, drag-and-drop и контекстное меню | ❌ Нет |
| **23** | `lib/features/menu/view/widgets/catalog/catalog_browser_tab.dart` | 1-334 | 2. Микроархитектура | MAJOR | **MEDIUM** | Файл-великан (334 строки). Грид товаров, поиск, фильтры по категориям и тулбар | ❌ Нет |
| **24** | `lib/features/menu/view/widgets/catalog/catalog_header.dart` | 1-257 | 2. Микроархитектура | MAJOR | **MEDIUM** | Превышение лимита (257 строк). Панель поиска, переключатели вида (плитка/список) | ❌ Нет |
| **25** | `lib/features/crm/view/widgets/dialogs/customer_details_dialog.dart` | 1-331 | 2. Микроархитектура | MAJOR | **MEDIUM** | Файл-великан (331 строка). Карточка гостя, баланс бонусов, депозиты и история заказов | ❌ Нет |
| **26** | `lib/features/crm/view/widgets/dialogs/customer_form_modal.dart` | 1-307 | 2. Микроархитектура | MAJOR | **MEDIUM** | Файл-великан (307 строк). Форма регистрации гостя, дата рождения, дисконтные группы | ❌ Нет |
| **27** | `lib/features/crm/view/widgets/dialogs/customer_payment_modal.dart` | 1-293 | 2. Микроархитектура | MAJOR | **HIGH** | Превышение лимита (293 строки). Пополнение баланса депозита гостя, ввод суммы | ❌ Нет |
| **28** | `lib/features/analytics/view/tabs/shift_history_analytics_tab.dart` | 1-323 | 2. Микроархитектура | MAJOR | **MEDIUM** | Файл-великан (323 строки). Таблица смен, ручной `ShiftRepository(apiClient.dio)` в `initState` | ❌ Нет |
| **29** | `lib/features/superadmin/presentation/widgets/create_tenant_modal.dart` | 1-439 | 2. Микроархитектура | MAJOR | **LOW** | Файл-великан (439 строк). Создание тенанта, выбор тарифа, ввод паролей и реквизитов | ❌ Нет |
| **30** | `lib/core/widgets/mynix_date_time_picker.dart` | 1-402 | 2. Микроархитектура | MAJOR | **LOW** | Файл-великан (402 строки). Кастомный календарь и выбор диапазона времени | ❌ Нет |

---

## 🎯 Выводы и приоритеты рефакторинга:

1. **Группа HIGH (Касса, Оплата, Смены, Профиль):** 
   - Требует немедленного устранения прямых сетевых вызовов (`apiClient.dio` $\rightarrow$ `Repository`) и декомпозиции `pos_checkout_panel.dart` (434 строки) и `shift_pin_dialog.dart`.
2. **Группа MEDIUM (Склад, Каталог Меню, CRM):**
   - Распил `bulk_add_modal.dart`, `receive_document_dialog.dart`, `catalog_browser_tab.dart`, `customer_details_dialog.dart` на выделенные виджеты в папках `widgets/`.
3. **Группа LOW (Суперадмин, Настройки, Core Picker):**
   - Декомпозиция модалки создания тенанта и дата-пикера.

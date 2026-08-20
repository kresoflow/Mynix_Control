# 📋 Полный технический аудит Flutter-проекта "Mynix Control"

> **Дата аудита:** 2026-08-20  
> **Метод:** Сплошной статический и семантический анализ всей кодовой базы `frontend/lib/`.  
> **Статус:** 🟢 Группы HIGH и MEDIUM полностью отрефакторены!

---

## 📊 Сводная таблица статуса рефакторинга

| № | Файл | Категория | Критичность | Risk/Impact | Что нарушено | Статус решения |
| :- | :--- | :--- | :--- | :--- | :--- | :---: |
| **1** | `pos_checkout_panel.dart` | 2. Микроархитектура | MAJOR | **HIGH** | Файл-великан (434 строки) | ✅ **ИСПРАВЛЕНО (`549dafc`):** разбит на `pos_checkout_panel.dart` (128 стр), `pos_checkout_panel_payment_methods.dart` (222 стр), `pos_checkout_panel_action_button.dart` (106 стр). |
| **2** | `shift_pin_dialog.dart` | 1. Сеть / DI | CRITICAL | **HIGH** | Прямой вызов `apiClient.dio.post` | ✅ **ИСПРАВЛЕНО (`0c4b690`):** вызов перенесен в `AuthRepository.verifyPin`. |
| **3** | `shift_pin_dialog.dart` | 4. Async Safety | MAJOR | **HIGH** | Вызов `Navigator.pop` через async gap | ✅ **ИСПРАВЛЕНО (`0c4b690`):** обернут в `if (ctx.mounted)`. |
| **4** | `shift_z_close_tab.dart` | 3. Хардкод | MINOR | **HIGH** | Захардкоженный текст `suffixText: 'сомони'` | ✅ **ИСПРАВЛЕНО (`0c4b690`):** заменен на `CurrencyFormatter.symbol(context)`. |
| **5** | `shift_history_tab.dart` | 1. Сеть / DI | MAJOR | **HIGH** | Создание репозитория в `initState` | ✅ **ИСПРАВЛЕНО (`f0c252c`):** репозиторий инжектируется через `RepositoryProvider`. |
| **6** | `customer_picker_modal.dart` | 1. Сеть / DI | MAJOR | **HIGH** | Создание `CrmRepository` внутри кнопки | ✅ **ИСПРАВЛЕНО (`f0c252c`):** репозиторий инжектируется через `RepositoryProvider`. |
| **7** | `customer_picker_modal.dart` | 4. Async Safety | MAJOR | **HIGH** | Асинхронные гэпы в модалке | ✅ **ИСПРАВЛЕНО (`f0c252c`):** добавлены проверки `dialogCtx.mounted` и `context.mounted`. |
| **8** | `menu_modifiers_dialog.dart` | 2. Микроархитектура | MAJOR | **HIGH** | Превышение лимита (294 строки) | ✅ **ИСПРАВЛЕНО (`027c5a8`):** декомпозирован на `menu_modifiers_dialog.dart` (180 стр), `modifiers_calculator.dart`, `dialog_modifiers_body.dart`. |
| **9** | `customer_payment_modal.dart` | 2. Микроархитектура | MAJOR | **HIGH** | Превышение лимита (314 строк) | ✅ **ИСПРАВЛЕНО (`2ced05d`):** декомпозирован до 200 строк с переходом на `MynixDialog` и `CurrencyFormatter`. |
| **10** | `user_profile_modal.dart` | 1. Сеть / DI | CRITICAL | **HIGH** | Прямой вызов `apiClient.dio` | ✅ **ИСПРАВЛЕНО (`2ced05d`):** запросы переведены на методы `AuthRepository`. |
| **11** | `bulk_add_modal.dart` | 2. Микроархитектура | MAJOR | **MEDIUM** | Файл-великан (428 строк) | ✅ **ИСПРАВЛЕНО (`0530a3d`):** декомпозирован до 230 строк, пресеты вынесены в `bulk_add_presets.dart`. |
| **12** | `receive_document_dialog.dart` | 2. Микроархитектура | MAJOR | **MEDIUM** | Файл-великан (364 строки) | ✅ **ИСПРАВЛЕНО (`8743f85`):** сокращен до 250 строк, вынесен `receive_document_unit_helper.dart` и исправлен async gap. |
| **13** | `catalog_browser_tab.dart` | 2. Микроархитектура | MAJOR | **MEDIUM** | Файл-великан (353 строки) | ✅ **ИСПРАВЛЕНО (`09877a0`):** сокращен до 220 строк, диалоги удаления вынесены в `catalog_deletion_dialogs.dart`. |
| **14** | `customer_details_dialog.dart` | 2. Микроархитектура | MAJOR | **MEDIUM** | Файл-великан (351 строка) | ✅ **ИСПРАВЛЕНО (`7edad87`):** сокращен до 210 строк, вынесен `customer_ledger_tab.dart`. |
| **15** | `shift_history_analytics_tab.dart` | 2. Микроархитектура | MAJOR | **MEDIUM** | Файл-великан (343 строки) | ✅ **ИСПРАВЛЕНО (`a13bc36`):** сокращен до 150 строк, вынесены `analytics_kpi_card.dart` и `analytics_shift_row.dart`, репозиторий инжектирован. |
| **16** | `customer_form_modal.dart` | 2. Микроархитектура | MAJOR | **MEDIUM** | Файл-великан (326 строк) | ✅ **ИСПРАВЛЕНО (`47580ca`):** сокращен до 200 строк с переходом на `MynixDialog` и `CurrencyFormatter`. |
| **17** | `suppliers_tab.dart` | 2. Микроархитектура | MAJOR | **MEDIUM** | Превышение лимита (303 строки) | ✅ **ИСПРАВЛЕНО (`bc7539f`):** сокращен до 190 строк, вынесен `suppliers_table_header.dart`, исправлен async gap. |
| **18** | `general_settings_tab.dart` | 1. Сеть / DI | CRITICAL | **MEDIUM** | Прямой вызов `apiClient.dio` | ✅ **ИСПРАВЛЕНО (`bc7539f`):** создан `SettingsRepository`, вызовы инжектированы. |
| **19** | `create_tenant_modal.dart` | 2. Микроархитектура | MAJOR | **LOW** | Файл-великан (439 строк) | ⏳ Ожидает (Группа LOW) |
| **20** | `mynix_date_time_picker.dart` | 2. Микроархитектура | MAJOR | **LOW** | Файл-великан (402 строки) | ⏳ Ожидает (Группа LOW) |
| **21** | `settings_screen.dart` | 2. Микроархитектура | MAJOR | **LOW** | Превышение лимита (275 строк) | ⏳ Ожидает (Группа LOW) |

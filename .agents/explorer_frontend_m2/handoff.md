# Frontend Codebase Audit Handoff Report

## 1. Observation

Direct observations of file lengths, architecture, logic defects, and Null Safety issues across the Flutter frontend codebase (`D:\Mynix_Control\frontend\lib`).

### A. File Length & UI Decomposition Violations
The global rules (`D:\Mynix_Control\AGENTS.md`) specify:
> **Micro-Architecture (Критически важно!):**
> - **Лимит строк:** Длина файла не должна превышать 200-250 строк.
> - **Декомпозиция:** Избегай "God Objects" (`main_layout.dart`, `bulk_add_modal.dart`). Агрессивно выноси сложные `build`-методы в отдельные приватные виджеты или в файлы внутри подпапки `widgets/`. Если файл становится длиннее 300 строк, остановись и проведи рефакторинг с выносом компонентов.

Ten (10) files violate these limits:
1. **`lib/features/inventory/view/inventory_screen.dart` (1,477 lines)**
   - *Observation*: Contains the main layout + five large private tab widgets inline: `_CategoryTab` (line 312, 748 lines), `_MenuTab` (line 1061), `_IngredientTab` (line 1112), `_RecipeTab` (line 1161), and `_ReceiptTab` (line 1374), plus several inline `showDialog` builders.
2. **`lib/features/settings/view/settings_screen.dart` (727 lines)**
   - *Observation*: Contains inline private widget classes: `_GeneralSettings` (line 172), `_HardwareSettings`, `_PersonnelSettings`, `_TaxSettings`, and `_SystemSettings`. However, public counterparts (`GeneralSettings`, etc.) already exist as modular widgets under `lib/features/settings/view/widgets/` but are unused.
3. **`lib/features/inventory/view/widgets/warehouse/dialogs/receive_document_dialog.dart` (401 lines)**
   - *Observation*: Handles complex item list manipulation and multi-step asynchronous creation of ingredients and retail products directly in the widget's UI code (`_save` method on line 96).
4. **`lib/features/inventory/view/widgets/warehouse/suppliers_tab.dart` (384 lines)**
   - *Observation*: Contains the `SuppliersTab` widget, inline `_SupplierRow` widget (line 233) with hover animations, and multiple inline dialog invocations.
5. **`lib/features/kitchen/view/kds_board.dart` (355 lines)**
   - *Observation*: Defines `KdsBoard`, `_KdsOrderCard` (line 153), and `_ReadyButton` (line 301) inline in a single file.
6. **`lib/features/inventory/view/widgets/bulk_add_modal.dart` (334 lines)**
   - *Observation*: Dead/unused code (never imported or called). Defines tabs and row state machines.
7. **`lib/features/inventory/view/widgets/retail_product_modal.dart` (294 lines)**
   - *Observation*: Dead/unused code. Contains forms for creating retail products.
8. **`lib/features/inventory/view/widgets/bulk_receipt_view.dart` (281 lines)**
   - *Observation*: Dead/unused code. Contains complex row-adding layout for receiving stock.
9. **`lib/features/analytics/view/analytics_dashboard_screen.dart` (275 lines)**
   - *Observation*: Combines UI layouts for metrics, charts, tables, and directly instantiates repositories in a `BlocProvider` wrapper.
10. **`lib/features/inventory/view/widgets/warehouse/stock_tab.dart` (256 lines)**
    - *Observation*: Slightly exceeds the 250-line limit due to category accordion logic.

---

### B. BLoC & Memory/State Leaks
1. **Unwired WebSocket connection / missing lifecycle triggers in KDS Board (`lib/features/kitchen/view/kds_board.dart`)**
   - *Observation*: `kitchen_bloc.dart` implements WebSocket stream listeners (`ConnectKitchen` on line 30, `DisconnectKitchen` on line 72), but `kds_board.dart` only triggers `FetchActiveOrders()` on init:
     ```dart
     // kds_board.dart (Lines 21-27):
     @override
     void initState() {
       super.initState();
       final authState = context.read<AuthBloc>().state;
       if (authState is AuthAuthenticated) {
         context.read<KitchenBloc>().add(FetchActiveOrders());
       }
     }
     ```
     It **never** adds `ConnectKitchen` to start real-time updates. Additionally, `_KdsBoardState` lacks a `dispose` method to call `DisconnectKitchen()`, resulting in a connection lifecycle and stream resource leak.
2. **Global Mutable State in AppColors (`lib/core/theme/app_colors.dart`)**
   - *Observation*: `AppColors` defines brand and surface colors as non-final static variables (e.g. `static Color brandPrimary = const Color(0xFFE8A020);`) which are globally mutated inside `applyThemeVariant` (line 53).
   - *Observation*: `SettingsBloc` (line 62) directly mutates this:
     ```dart
     on<UpdateThemeVariant>((event, emit) {
       AppColors.applyThemeVariant(event.themeVariant);
       emit(state.copyWith(themeVariant: event.themeVariant));
     });
     ```
     This causes a global state leak and concurrency/thread-safety issues. It also fails to trigger automatic redraws for any widget that doesn't explicitly listen to `SettingsBloc`.
3. **Direct Repository Instantiation in View (`lib/features/analytics/view/analytics_dashboard_screen.dart`)**
   - *Observation*: `AnalyticsDashboardScreen` instantiates the repository inline rather than resolving it via `RepositoryProvider` (line 24):
     ```dart
     create: (context) => AnalyticsBloc(AnalyticsRepository(apiClient.dio))
     ```
     This violates the rule: `"Networking: Прямые HTTP-запросы из UI или BLoC запрещены. Используй слой Repository (Dio), который инжектируется через RepositoryProvider."`
4. **Asynchronous Orchestration and Direct Creation calls in Dialog (`lib/features/inventory/view/widgets/warehouse/dialogs/receive_document_dialog.dart`)**
   - *Observation*: Inside the dialog's `_save()` method (line 96), the UI directly calls repositories to create retail products and ingredients sequentially before creating the document:
     ```dart
     finalRetailProductId = await menuRepo.createRetailProduct(...) // Line 161
     // or
     finalIngredientId = await repo.createIngredient(...) // Line 171
     ```
     If one request fails, the app is left in a partially written state, and the UI blocks waiting for asynchronous requests. This violates the separation of concerns.

---

### C. Null Safety & Crash Vulnerabilities
1. **Unsafe JSON Deserialization in Data Models**
   - *Observation*: Models deserialize JSON directly without type checking or default fallback values.
     - `lib/features/inventory/models/ingredient.dart` (Line 30):
       ```dart
       id: json['id'],
       name: json['name'],
       unit: json['unit'],
       ```
       If `id`, `name`, or `unit` is null or a mismatch type, it will crash the parser.
     - `lib/features/inventory/models/supplier.dart` (Line 14):
       ```dart
       id: json['id'],
       name: json['name'],
       ```
     - `lib/features/inventory/models/document.dart` (Line 79):
       ```dart
       date: DateTime.parse(json['date']),
       ```
       Will throw a `FormatException` if `date` is null, empty, or not formatted.
2. **Unsafe Cast in AuthBloc (`lib/features/auth/bloc/auth_bloc.dart`)**
   - *Observation*: Assumes `profile['roles']` is always a List:
     ```dart
     role: (profile['roles'] as List<dynamic>).firstOrNull ?? 'unknown', // Lines 24 and 43
     ```
     If `roles` is null or a string in the API response, it throws a type cast exception.

---

### D. Code Duplication / Dead Files
1. **Unused Repositories Split Parts**
   - *Observation*: `lib/features/inventory/repository/parts/` contains `categories_part.dart` etc. defined as `part of '../inventory_repository.dart';`. However, the main `inventory_repository.dart` contains all the implementations inline and does NOT declare the `part` directives. The parts are dead files and the code is duplicate.
2. **Unused UI Code in Inventory**
   - *Observation*: `bulk_receipt_view.dart`, `retail_product_modal.dart`, and `MenuManagerTab` (in `menu_manager_tab.dart`) are never imported or used. They duplicate functionality that was kept inline in `inventory_screen.dart`.

---

## 2. Logic Chain

1. **Rule Constraint**: A file must not exceed 200-250 lines (300 line limit triggers refactoring).
   - *Observation*: `inventory_screen.dart` is 1,477 lines, `settings_screen.dart` is 727 lines, `receive_document_dialog.dart` is 401 lines, `suppliers_tab.dart` is 384 lines, `kds_board.dart` is 355 lines.
   - *Conclusion*: These files must be refactored by decomposing their nested layout widgets into dedicated widgets.
2. **Rule Constraint**: StatefulWidgets should not manage business/networking states; streams/websockets must be properly closed to avoid leaks.
   - *Observation*: `kds_board.dart` does not dispatch `ConnectKitchen` on load and does not dispatch `DisconnectKitchen` on dispose, leaving the WebSocket uncalled and streams open if connected.
   - *Conclusion*: This breaks the real-time order feature of the kitchen and causes a connection leak.
3. **Rule Constraint**: Direct HTTP requests from UI are forbidden; Repository must be resolved through `RepositoryProvider`.
   - *Observation*: `analytics_dashboard_screen.dart` instantiates `AnalyticsRepository(apiClient.dio)` inline. `receive_document_dialog.dart` makes multiple `await repository.createIngredient` and `createRetailProduct` calls sequentially from a UI dialog action.
   - *Conclusion*: These violate repository injection rules and cause unsafe asynchronous side effects directly from the UI context.
4. **Rule Constraint**: Stable Null Safety prevents crashes on unexpected data.
   - *Observation*: Data models in `lib/features/inventory/models/` assign fields like `id: json['id']` and `date: DateTime.parse(json['date'])` directly.
   - *Conclusion*: If the backend returns a null field or malformed date, the parser throws a runtime exception and crashes the view.

---

## 3. Caveats

- We assumed that the unused parts in `lib/features/inventory/repository/parts/` were meant to split `inventory_repository.dart`, but the refactoring was left unfinished.
- We assumed that the dead files (`bulk_receipt_view.dart`, `retail_product_modal.dart`, `menu_manager_tab.dart`) are duplicates of inline layouts in `inventory_screen.dart` and settings. Deleting them is safe, but check with the implementation team first.

---

## 4. Conclusion

The Flutter codebase complies with the Feature-Driven Architecture but violates several critical global rules:
- **God Objects**: UI files are bloated due to massive inline tab widgets and dialogs (e.g. `inventory_screen.dart` at 1477 lines, `settings_screen.dart` at 727 lines).
- **Architecture Leaks**: Views are calling database-modifying repository methods directly, bypassing BLoCs, and instantiating repositories without `RepositoryProvider`.
- **WS Connection Defect**: The kitchen board will not receive real-time updates because `ConnectKitchen` is never triggered by `kds_board.dart`.
- **Null Safety/Crashes**: Unsafe JSON deserialization in models makes the app vulnerable to runtime type errors if backend responses lack fields.

---

## 5. Verification Method

To verify these findings:
1. **Line Length Check**:
   Inspect the line count of the files:
   - `lib/features/inventory/view/inventory_screen.dart`
   - `lib/features/settings/view/settings_screen.dart`
   - `lib/features/inventory/view/widgets/warehouse/dialogs/receive_document_dialog.dart`
2. **WebSocket Connection Verification**:
   Inspect `lib/features/kitchen/view/kds_board.dart` to verify there is no reference to `ConnectKitchen` or `DisconnectKitchen`.
3. **Repository Injection Check**:
   Inspect `lib/features/analytics/view/analytics_dashboard_screen.dart` line 24 to verify it instantiates the repository using `AnalyticsRepository(apiClient.dio)`.
4. **Data Deserialization Crash Test**:
   Inspect `lib/features/inventory/models/ingredient.dart` line 30 to verify that fields like `id` and `name` are assigned directly from JSON without type casting (`as String?`) or null fallbacks.

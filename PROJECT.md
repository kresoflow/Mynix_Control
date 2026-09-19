<!-- =========================================================================== -->
<!-- ДОКУМЕНТ: Project Specification & Domain Contracts (PROJECT.md)             -->
<!-- СТАТУС:   АКТУАЛЬНО (Phase 0: Rebranding, CI/CD & Documentation Hardening)   -->
<!-- ДАТА:     2026-09-19 | Контрольный коммит: e5ae1c6                         -->
<!-- =========================================================================== -->

> [!IMPORTANT] РЕГЛАМЕНТ АКТУАЛИЗАЦИИ ДОКУМЕНТАЦИИ (PHASE-DRIVEN SYNC)
> Данный документ обновляется **централизованно по завершении фаз разработки (Milestones)**. AI-агенты обязаны проверять актуальное состояние кодовой базы инструментами поиска перед внесением изменений.

﻿# Project: Kreso Flow — Bulk Add & Goods Receipt Optimization

## Architecture

Kreso Flow employs a modern client-server architecture with multi-tenant schema isolation:
- **Backend**: FastAPI + SQLModel + PostgreSQL (via `asyncpg`). Multi-tenancy operates via PostgreSQL schemas (`search_path` set per request via `TenantSession`), with zero `tenant_id` columns in business models. Role- and domain-based access control (PBAC) is enforced using `require_permission(...)` decorators.
- **Frontend**: Flutter + Dart with Feature-Driven Architecture (`lib/features/<module>`). State management is strictly handled by `BLoC` + `Equatable`. Networking is isolated in Repositories (using `Dio`) injected via `RepositoryProvider`. UI adheres strictly to the Kreso Flow Design System (`AppColors`, `AppPrimaryButton`, `AppButtonSize`, `AppRadii`).
- **Domain Separation**:
  - **Catalog (Menu)**: Nomenclature definition (dishes, retail items, categories, ingredients, pricing, variations, barcodes, units). Responsible for card management with zero initial physical stock.
  - **Warehouse (Inventory)**: Physical stock tracking and movements. Stock quantities are increased strictly through movement documents (`InventoryDocument` with status `completed`, e.g., Goods Receipt / Инвентаризация). Goods Receipt operates strictly upon pre-existing nomenclature items from the Catalog.

---

## Code Layout

### Backend (`backend/app/inventory/`)
- `routers/menu_router.py`: Dish and retail product endpoints (single + bulk).
- `routers/ingredient_router.py`: Ingredient / raw material endpoints (single + bulk).
- `routers/document_router.py`: Warehouse movement document endpoints (`/documents/`, `/documents/{id}/complete`).
- `services/menu_service.py`: Dish business logic and variation synchronization.
- `services/retail_service.py`: Retail goods logic (batch creation, zero initial stock).
- `services/ingredient_service.py`: Raw material logic (batch creation, zero initial stock).
- `services/document_service.py` & `document_completion_helper.py`: Document lifecycle, weighted average cost recalculation, supplier liabilities.

### Frontend Catalog (`frontend/lib/features/`)
- `pos/bloc/menu_bloc.dart`: `MenuBloc` events and states (adding `CreateMenuItemsBulk`, `CreateRetailProductsBulk`, single `LoadMenu` refresh).
- `pos/repository/menu_repository.dart`: Menu HTTP client (batch POST calls to `/menu/bulk`, `/retail-product/bulk`).
- `inventory/bloc/ingredient_bloc.dart`: `IngredientBloc` bulk creation and load events.
- `inventory/repository/parts/ingredients_part.dart`: Batch HTTP call to `/ingredients/bulk`.
- `inventory/view/widgets/bulk_add/`: Decomposed Bulk Add modal and row components:
  - `bulk_add_modal.dart` (<= 250 lines)
  - `bulk_add_header.dart`
  - `bulk_add_footer.dart` (`AppPrimaryButton`, `AppButtonSize.lg`)
  - `bulk_add_tabs_bar.dart` (`AppSecondaryButton`, `AppColors`)
  - `bulk_add_category_selector.dart` (<= 250 lines)
  - `bulk_add_list_widget.dart` (`RepaintBoundary`, `ValueNotifier` hover isolation, keyboard traversal)
  - `dish_row.dart`, `retail_row.dart` (no stock field), `ingredient_row.dart` (no stock field), `category_row.dart`
  - `bulk_add_presets.dart` (zero initial stock)

### Frontend Warehouse (`frontend/lib/features/inventory/`)
- `bloc/document_bloc.dart`: Document creation, completion, and cross-bloc sync trigger (`IngredientBloc.add(LoadIngredients())`).
- `view/widgets/warehouse/dialogs/receive_document/`: Decomposed Goods Receipt dialog components:
  - `receive_document_dialog.dart` (<= 250 lines, no raw buttons)
  - `receive_document_header.dart`
  - `receive_document_footer.dart` (<= 250 lines, `AppPrimaryButton`, design system tokens)
  - `receive_document_items_list.dart` (isolated row totals via `ValueNotifier`)
  - `receive_document_item_row.dart` (<= 250 lines, strict card selection, Enter/Arrow key navigation)
  - `receive_document_processor.dart` (strict existing item validation; complete removal of on-the-fly dummy item creation and fake IDs)
  - `receive_document_supplier_select.dart`, `receive_document_meta_row.dart`

---

## Feature Inventory

Every requirement and survey discovery mapped to milestone:

| # | Feature | Description | Milestone | Source |
|---|---------|-------------|-----------|--------|
| 1 | Backend Batch Endpoints | Implement `POST /menu/bulk`, `POST /retail-product/bulk`, `POST /ingredients/bulk` in FastAPI with atomic transaction and PBAC | M1 | Survey (Explorer 3) & R1 |
| 2 | Backend Document Integrity | Prohibit initial stock in catalog creation services (`current_stock = 0.0`); require existing item IDs for document completion | M1 | Survey (Explorer 2, 3) & R2 |
| 3 | Single State Update in MenuBloc | Add `CreateMenuItemsBulk` and `CreateRetailProductsBulk` events; call `add(LoadMenu())` strictly once at end of batch | M2 | Survey (Explorer 1) & R1 |
| 4 | Bulk Add Virtual Stock Removal | Remove `stockController` and "Остаток" UI column from `retail_row.dart` and `ingredient_row.dart`; remove stock defaults from presets | M2 | Survey (Explorer 1) & R2 |
| 5 | Bulk Add UI Kit & Micro-Architecture | Refactor `bulk_add_modal.dart`, `bulk_add_category_selector.dart`, `bulk_add_save_helper.dart` to <= 250 lines; replace raw buttons with `AppPrimaryButton`/`AppSecondaryButton` | M2 | Survey (Explorer 1) & R3 |
| 6 | Bulk Add Keyboard UX & Rerender Isolation | Isolate row hover via `ValueNotifier`; add `RepaintBoundary` with `ValueKey`; support `Enter` row-creation and grid arrow navigation | M2 | Survey (Explorer 1) & R3 |
| 7 | Goods Receipt On-The-Fly Item Removal | Remove "Умное создание" (`ReceiveDocumentSmartHeader`) and creation loop in `ReceiveDocumentProcessor`; enforce strictly existing nomenclature selection | M3 | Survey (Explorer 2) & R2 |
| 8 | DocumentBloc -> IngredientBloc Sync | On receipt document completion, dispatch `LoadIngredients()` so `StockTab` immediately reflects new physical stock balances | M3 | Survey (Explorer 2) & R2 |
| 9 | Goods Receipt Keyboard UX & Rerender Isolation | Isolate row totals and footer sums with `ValueNotifier`; fix `Enter` navigation in raw ingredients mode; add arrow key navigation | M3 | Survey (Explorer 2) & R3 |
| 10 | Goods Receipt UI Kit & Micro-Architecture | Refactor `receive_document_dialog.dart`, `receive_document_footer.dart`, and `receive_document_item_row.dart` to <= 250 lines; eliminate raw buttons/colors | M3 | Survey (Explorer 2) & R3 |
| 11 | Comprehensive E2E & Regression Test Suite | Create automated tests for batch creation, document movement integrity, and UI state stability | M4 (E2E Track) | System Policy & AC |
| 12 | Full Verification & Forensic Audit | Run pytest, flutter analyze/test, stress tests, and verify zero integrity violations | M5 | System Policy |

---

## Milestones

| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| M1 | Backend Batch & Movement Integrity | Add `/menu/bulk`, `/retail-product/bulk`, `/ingredients/bulk`; enforce zero initial stock on catalog items; ensure document completion validates real item IDs | none | DONE (Passed all gates) |
| M2 | Frontend Bulk Add Optimization | Implement BLoC batch events (`CreateMenuItemsBulk`, `CreateRetailProductsBulk`); single `LoadMenu`; remove virtual stock; isolate row rerenders; keyboard navigation; UI Kit & line limits | M1 | DONE (Worker verified) |
| M3 | Frontend Goods Receipt Refactoring | Remove on-the-fly dummy creation; enforce existing items only; trigger `IngredientBloc.add(LoadIngredients())` upon document completion; fix Enter/Arrow navigation; UI Kit & line limits | M1 | DONE (Worker verified) |
| M4 | E2E Testing Suite | Multi-tier tests: batch operations without network storm, document receipt inventory updates, keyboard navigation, UI Kit compliance | none (parallel) | DONE (TEST_READY published) |
| M5 | Final Integration & Coverage Hardening | Run all test suites, verify 100% pass, reviewer verification, forensic audit verification | M1, M2, M3, M4 | IN_PROGRESS (Review & Audit) |

---

## Interface Contracts

### 1. Frontend Repository ↔ Backend API (`/menu/bulk`)
- **Request**: `POST /menu/bulk`
  - Headers: `Authorization: Bearer <token>`
  - Body: `List<MenuItemCreate>`
  - PBAC: `require_permission("menu:create")`
- **Response**: `201 Created` with `List<MenuItemRead>`
- **Error Handling**: `400 Bad Request` with `{"detail": "Validation error"}`

### 2. Frontend Repository ↔ Backend API (`/retail-product/bulk`)
- **Request**: `POST /retail-product/bulk`
  - Headers: `Authorization: Bearer <token>`
  - Body: `List<RetailProductCreate>` (strictly with `initial_stock: 0.0`)
  - PBAC: `require_permission("menu:create")`
- **Response**: `201 Created` with `List<RetailProductRead>`

### 3. Frontend Repository ↔ Backend API (`/ingredients/bulk`)
- **Request**: `POST /ingredients/bulk`
  - Headers: `Authorization: Bearer <token>`
  - Body: `List<IngredientCreate>` (strictly with `initial_stock: 0.0`)
  - PBAC: `require_permission("inventory:create")`
- **Response**: `201 Created` with `List<IngredientRead>`

### 4. `DocumentBloc` ↔ `IngredientBloc` (Frontend Inter-Bloc Communication)
- When `DocumentBloc` successfully completes a receipt document (`completeDocument` succeeds):
  - Notification mechanism: `context.read<IngredientBloc>().add(const LoadIngredients())` or an injected callback/listener in the inventory screen provider.
  - Ensures `StockTab` updates physical balances without requiring a manual pull-to-refresh or app restart.

### 5. `ReceiveDocumentProcessor` ↔ Warehouse Document Service
- `ReceiptRowData` must have a valid, non-null `ingredient.id` or `retailProduct.id` corresponding to a persisted database entity.
- If `item.ingredient == null && item.retailProduct == null`, validation fails with user error: "Выберите товар из номенклатуры".
- No dummy random or timestamp IDs (`DateTime.now().millisecondsSinceEpoch`) may ever be submitted.

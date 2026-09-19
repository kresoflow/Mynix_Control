<!-- =========================================================================== -->
<!-- ДОКУМЕНТ: Test Infrastructure & Verification Standards (TEST_INFRA.md)      -->
<!-- СТАТУС:   АКТУАЛЬНО (Phase 0: Rebranding, CI/CD & Documentation Hardening)   -->
<!-- ДАТА:     2026-09-19 | Контрольный коммит: e5ae1c6                         -->
<!-- =========================================================================== -->

> [!IMPORTANT] РЕГЛАМЕНТ АКТУАЛИЗАЦИИ ДОКУМЕНТАЦИИ (PHASE-DRIVEN SYNC)
> Данный документ обновляется **централизованно по завершении фаз разработки (Milestones)**. AI-агенты обязаны проверять актуальное состояние кодовой базы инструментами поиска перед внесением изменений.

# Kreso Flow — Test Infrastructure & Quality Specification (TEST_INFRA)

## 1. Test Philosophy

### 1.1 Opaque-Box & Requirement-Driven Testing
Testing in Kreso Flow adheres strictly to **opaque-box (black-box), requirement-driven verification**. Every automated test is derived directly from user requirements (`ORIGINAL_REQUEST.md`) and system interface contracts (`PROJECT.md`). Rather than asserting internal implementation details or private methods, tests stimulate public API routes, BLoC events, and database transaction boundaries, evaluating observable behavior:
- HTTP status codes, response payloads, and headers.
- Persistent entity state in PostgreSQL (simulated via SQLite in-memory with PostgreSQL dialect extensions).
- Domain invariants, financial calculations, and inventory balances.
- Role- and domain-based access control (PBAC) permissions.

### 1.2 Anti-Facade Guarantee
No facade tests or tautological assertions are permitted. Every test executes real application code end-to-end through `httpx.AsyncClient` with real session managers and schema isolation. Mocks are restricted strictly to external third-party services (e.g., Telegram alerts, Sentry SDK). All core domain calculations (weighted average costs, debt balances, stock movements) are exercised against actual database tables.

### 1.3 Strict Separation of Concerns (Catalog vs. Warehouse)
Per user requirement **R2**:
1. **Catalog Domain (Menu, Retail, Ingredients, Categories)**:
   - Responsible strictly for nomenclature definitions (names, prices, units, barcodes, categories, variations).
   - Zero physical stock may be created during catalog entity registration.
   - All newly created catalog items must initialize with `current_stock = 0.0`.
   - Creation of virtual/phantom warehouse stock or unsolicited `StockTransaction` records during catalog insertion is prohibited.
2. **Warehouse Domain (Goods Receipt, Write-off, Inventory Audit)**:
   - Responsible strictly for physical stock movements and supplier balance adjustments.
   - Physical stock increments occur exclusively through completed `InventoryDocument`s (e.g. type `receipt` with status `completed`).
   - Goods receipt documents must reference valid, pre-existing catalog cards; on-the-fly phantom item creation is forbidden.

### 1.4 Financial & Inventory Accounting Invariants
- **Weighted Average Cost (Moving Average)**:
  $$\text{New Cost} = \frac{(\text{Current Stock} \times \text{Current Cost}) + (\text{Received Qty} \times \text{Received Price})}{\text{Current Stock} + \text{Received Qty}}$$
- **Supplier Debt Invariant**:
  $$\text{Supplier Balance}_{\text{new}} = \text{Supplier Balance}_{\text{prev}} - (\text{Total Document Amount} - \text{Paid Amount})$$
  *(Where negative balance represents debt owed by the business to the supplier).*
- **Stock Balance Invariant**:
  $$\text{Stock Balance} = \sum_{\text{completed docs}} \Delta Q$$

---

## 2. Feature Inventory & Coverage Matrix

| Feature ID | Requirement / Scope | Primary Endpoint / Target | Test Tier | Coverage Target | Automated Test Method(s) |
|---|---|---|---|---|---|
| **F-01** | Bulk Dish Creation | `POST /api/v1/menu/bulk` | Tier 1 | $\ge 5$ tests | `test_bulk_create_dishes_happy_path`<br>`test_bulk_create_dishes_with_variations`<br>`test_bulk_create_dishes_attributes_and_tags`<br>`test_bulk_create_dishes_zero_and_custom_prices`<br>`test_bulk_create_dishes_category_association` |
| **F-02** | Bulk Retail Product Creation | `POST /api/v1/retail-product/bulk` | Tier 1 | $\ge 5$ tests | `test_bulk_create_retail_products_happy_path`<br>`test_bulk_create_retail_products_units`<br>`test_bulk_create_retail_products_barcodes`<br>`test_bulk_create_retail_products_cost_and_price`<br>`test_bulk_create_retail_zero_initial_stock` |
| **F-03** | Bulk Raw Ingredient Creation | `POST /api/v1/ingredients/bulk` | Tier 1 | $\ge 5$ tests | `test_bulk_create_ingredients_happy_path`<br>`test_bulk_create_ingredients_units`<br>`test_bulk_create_ingredients_min_stock_alert`<br>`test_bulk_create_ingredients_barcode`<br>`test_bulk_create_ingredients_zero_initial_stock` |
| **F-04** | Bulk Menu Categories Creation | `POST /api/v1/categories/bulk` | Tier 1 | $\ge 5$ tests | `test_bulk_create_categories_happy_path`<br>`test_bulk_create_categories_hierarchy`<br>`test_bulk_create_categories_types`<br>`test_bulk_create_categories_ordering_and_colors`<br>`test_bulk_create_categories_visibility_flags` |
| **F-05** | Goods Receipt Document Processing | `POST /api/v1/documents/`<br>`POST /api/v1/documents/{id}/complete` | Tier 1 | $\ge 5$ tests | `test_receipt_document_creation_multi_item`<br>`test_receipt_document_completion_status_transition`<br>`test_receipt_document_unpaid_supplier_debt`<br>`test_receipt_document_paid_balance_neutral`<br>`test_receipt_document_stock_transaction_logged` |
| **B-01** | Empty Batch Resilience | Bulk endpoints with `[]` | Tier 2 | Boundary | `test_boundary_empty_batch_dishes`<br>`test_boundary_empty_batch_retail`<br>`test_boundary_empty_batch_ingredients`<br>`test_boundary_empty_batch_categories` |
| **B-02** | High-Volume Batch Stress (50+ items) | Bulk endpoints with 50+ items | Tier 2 | Boundary | `test_boundary_large_batch_50_plus_items` |
| **B-03** | Special Characters & Unicode Sanitization | Names with symbols, Cyrillic, quotes, emojis | Tier 2 | Boundary | `test_boundary_special_characters_and_quotes` |
| **B-04** | Zero & Fractional Price / Quantity Values | Zero prices, fractional weights | Tier 2 | Boundary | `test_boundary_zero_and_fractional_pricing` |
| **B-05** | Barcode Collision & Duplicate Handling | Same barcode in batch or existing | Tier 2 | Boundary | `test_boundary_duplicate_barcodes_behavior` |
| **B-06** | Invalid / Bogus Item ID in Document | Fake IDs in Goods Receipt | Tier 2 | Boundary | `test_boundary_goods_receipt_invalid_item_id_rejection` |
| **C-01** | Catalog Zero-Stock Guarantee | Catalog creation vs stock state | Tier 3 | Cross-Feature | `test_cross_catalog_creation_never_increments_stock` |
| **C-02** | Bulk Nomenclature $\rightarrow$ Goods Receipt $\rightarrow$ Stock Update | End-to-end movement flow | Tier 3 | Cross-Feature | `test_cross_bulk_catalog_to_goods_receipt_stock_sync` |
| **C-03** | Weighted Average Cost Calculation | Multiple successive receipts | Tier 3 | Cross-Feature | `test_cross_moving_average_cost_recalculation` |
| **C-04** | Supplier Debt vs. Physical Stock Verification | Partial payments & ledger | Tier 3 | Cross-Feature | `test_cross_partial_payment_supplier_debt_and_stock` |
| **C-05** | Goods Receipt Followed by Stock Write-off | Receipt $\rightarrow$ Write-off lifecycle | Tier 3 | Cross-Feature | `test_cross_goods_receipt_followed_by_writeoff` |
| **W-01** | Restaurant Opening Inventory Setup | Complete establishment startup | Tier 4 | Real-world | `test_workflow_restaurant_opening_inventory_setup` |
| **W-02** | Multi-Supplier Delivery Invoice Processing | Supplier delivery with mix of goods | Tier 4 | Real-world | `test_workflow_supplier_delivery_invoice_processing` |

---

## 3. Test Architecture & Runner Instructions

### 3.1 Backend Test Architecture
- **Framework**: `pytest` (v9.0+) with `pytest-asyncio` (v1.4+).
- **HTTP Client**: `httpx.AsyncClient` utilizing `ASGITransport(app=app)`.
- **Database Engine**: `sqlite+aiosqlite` in-memory database with shared cache (`mode=memory&cache=shared&uri=true`) and PostgreSQL compatibility hooks (compiling `JSONB` to `JSON`, attaching `public` schema in SQLite).
- **Multi-Tenancy & Auth Simulation**:
  - Each test sets up an isolated `Tenant`, administrative `User`, and `Role` assigned required PBAC permissions (`menu:create`, `menu:manage`, `menu:view`, `inventory:create`, `inventory:manage`, `inventory:view`).
  - Access tokens are generated with `user_svc.create_access_token` and passed via `Authorization: Bearer <token>` headers.
- **Location of Test Suite**:
  - `backend/tests/test_e2e_requirements.py`: Comprehensive 4-tier E2E test suite covering all functional, boundary, cross-feature, and workflow requirements.

### 3.2 Frontend Test Architecture
- **Framework**: `flutter_test`.
- **Scope**: Widget tests and BLoC unit tests verifying single `LoadMenu` dispatch, isolated row rerenders via `ValueNotifier`, and keyboard traversal.
- **Location**: `frontend/test/`

### 3.3 Test Runner Instructions

#### Running Backend Tests (Windows PowerShell)
```powershell
# Navigate to backend directory
cd d:\Kreso_Flow\backend

# Run the complete test suite
.\.venv\Scripts\python -m pytest tests/ -v

# Run only the E2E requirements suite
.\.venv\Scripts\python -m pytest tests/test_e2e_requirements.py -v

# Run a specific tier (e.g., Tier 1)
.\.venv\Scripts\python -m pytest tests/test_e2e_requirements.py -k "TestTier1" -v

# Run with full traceback upon failure
.\.venv\Scripts\python -m pytest tests/test_e2e_requirements.py --tb=short
```

#### Running Frontend Tests (Windows PowerShell)
```powershell
# Navigate to frontend directory
cd d:\Kreso_Flow\frontend

# Run Flutter tests
flutter test
```

---

## 4. Acceptance Criteria Verification Gate

Before any release or milestone completion is accepted:
1. **100% Pass Rate**: All tests in `tests/test_e2e_requirements.py` and existing regression tests must exit with code `0`.
2. **PBAC Coverage**: Every newly created endpoint must be covered by tests asserting that unauthorized requests return `401`/`403`.
3. **No Phantom Stock**: Verification that creating catalog items never increments stock balances or inserts `StockTransaction` entries.
4. **Code Quality**: Zero linter errors (`ruff` / `flake8` / `flutter analyze`).

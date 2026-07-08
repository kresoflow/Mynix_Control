# Codebase Audit Exploration Handoff Report

## 1. Observation
Below is the direct evidence gathered from auditing both backend and frontend codebases:

### 1.1 API & Serialization Issues
*   **Omission of fields in `list_ingredients` API:**
    *   **File:** `backend/app/inventory/services/ingredient_service.py` (lines 44-54)
    *   **Snippet:**
        ```python
        IngredientRead(
            id=i.Ingredient.id,
            name=i.Ingredient.name,
            unit=i.Ingredient.unit,
            current_stock=i.Ingredient.current_stock,
            min_stock_alert=i.Ingredient.min_stock_alert,
            cost_per_unit=i.Ingredient.cost_per_unit,
            category_id=i.Ingredient.category_id,
            category_name=i.name,
            is_low_stock=i.Ingredient.current_stock <= i.Ingredient.min_stock_alert,
        )
        ```
    *   **Issue:** Omit `sort_order` and `attributes` fields from the model constructor, resulting in silent data loss (they default to `0` and `None` in responses).

*   **Omission of fields in `list_menu_items` API:**
    *   **File:** `backend/app/inventory/services/menu_service.py` (lines 125-138)
    *   **Snippet:**
        ```python
        MenuItemRead(
            id=m.id,
            name=m.name,
            short_name=m.short_name,
            tags=m.tags,
            category_id=m.category_id,
            category_name=m.category.name if m.category else None,
            retail_product_id=m.retail_product_id,
            price=m.price,
            is_available=m.is_available,
            description=m.description,
            type=m.type,
            attributes=m.attributes,
        )
        ```
    *   **Issue:** Omit `sort_order` parameter when constructing `MenuItemRead`.

*   **PIN Login Parameter Type Mismatch:**
    *   **File:** `frontend/lib/features/auth/repository/auth_repository.dart` (lines 31-38)
    *   **Snippet:**
        ```dart
        Future<String?> loginByPin(String tenantId, String pinCode) async {
          try {
            final response = await _dio.post(
              '/auth/pin',
              data: {
                'tenant_id': tenantId,
                'pin_code': pinCode,
              },
            );
        ```
    *   **File:** `backend/app/users/models.py` (lines 172-176)
    *   **Snippet:**
        ```python
        class PinLoginRequest(SQLModel):
            """Quick PIN login for booth workers."""
            pin_code: str
            tenant_id: int
        ```
    *   **Issue:** Frontend sends `tenant_id` as a `String`, but backend Pydantic model validation expects an `int`, causing an HTTP 422 validation error.

### 1.2 Environment & Security Configuration Issues
*   **Non-existent directory path in `init_db()`:**
    *   **File:** `backend/app/database.py` (lines 48-49)
    *   **Snippet:**
        ```python
        def run_alembic():
            os.system("cd D:\\Mynix_Control\\SCafe && .\\.venv\\Scripts\\alembic upgrade head")
        ```
    *   **Issue:** Hardcoded path references `SCafe` directory which does not exist, causing migration command execution to fail.

*   **PBAC Permissions Misalignment (Lockouts):**
    *   **File:** `backend/app/inventory/routers/document_router.py` (lines 19, 26, 78, 86)
    *   **Snippet:**
        ```python
        @supplier_router.get("/", ..., dependencies=[Depends(require_permission("inventory:read"))])
        ...
        @supplier_router.post("/", ..., dependencies=[Depends(require_permission("inventory:write"))])
        ```
    *   **File:** `backend/app/kitchen/routers/kds_router.py` (lines 48-50)
    *   **Snippet:**
        ```python
        @router.post("/{order_id}/ready", dependencies=[Depends(require_permission("kitchen:manage"))])
        ```
    *   **File:** `backend/app/users/seed.py` (lines 35-39)
    *   **Snippet:**
        ```python
        # Kitchen
        ("kitchen:view", "View kitchen order screen"),
        # Inventory
        ("inventory:manage", "Add/edit ingredients, recipes, receive stock"),
        ("inventory:view", "View stock levels and menu items"),
        ```
    *   **Issue:** The routers enforce permissions `"inventory:read"`, `"inventory:write"`, and `"kitchen:manage"`. However, the seed only populates `"inventory:view"`, `"inventory:manage"`, and `"kitchen:view"`. Non-superuser roles like `cook` are locked out of marking orders as ready, and all non-superuser roles are locked out of inventory document management.

*   **Committed Default Credentials & fallbacks:**
    *   **File:** `backend/app/config.py` (lines 23-24, 30)
    *   **Snippet:**
        ```python
        database_url: str = "postgresql+asyncpg://mynix:mynix_secret@127.0.0.1:5444/mynix_control"
        secret_key: str = "CHANGE-ME-IN-PRODUCTION-USE-LONG-RANDOM-STRING"
        ```
    *   **Issue:** Sensitive credentials and signature key fallbacks are checked into the codebase.

*   **Missing security headers / HTTPS enforcement:**
    *   **File:** `backend/app/main.py`
    *   **Issue:** No security header middleware (e.g. `X-Frame-Options`, `Content-Security-Policy`, `HSTS`) or HTTPS redirection is configured.

### 1.3 Database Script Isolation Issues
*   **Missing search_path scope in alteration scripts:**
    *   **Files:** `backend/alter_db_postgres.py` (line 9), `backend/alter_db_postgres_order.py` (line 9), `backend/alter_db_postgres_attributes.py` (lines 13, 16)
    *   **Snippets:**
        ```python
        await conn.execute(text("ALTER TABLE menu_items ADD COLUMN type VARCHAR DEFAULT 'dish'"))
        ```
    *   **Issue:** Scripts run raw SQL on tables like `menu_items` and `ingredients` without schema qualification or setting `search_path`. Because these tables only exist in tenant-specific schemas (e.g., `tenant_1.menu_items`), they fail in the default `public` schema with `relation "menu_items" does not exist`.

*   **Obsolete SQLite script:**
    *   **File:** `backend/alter_db.py` (line 3)
    *   **Snippet:**
        ```python
        conn = sqlite3.connect('app.db')
        ```
    *   **Issue:** Attempts to alter database using `sqlite3` on a non-existent `app.db` file, whereas the app runs on PostgreSQL.

*   **Broken sys.path in `alter_db_postgres_attributes.py`:**
    *   **File:** `backend/alter_db_postgres_attributes.py` (line 5)
    *   **Snippet:**
        ```python
        sys.path.append('D:\\Mynix_Control\\SCafe')
        ```
    *   **Issue:** References non-existent `SCafe` directory, causing import errors for `app.config`.

### 1.4 Code Quality & Leftovers
*   **Unused Hardware module:**
    *   **Path:** `backend/app/hardware/`
    *   **Issue:** The hardware module (with `printer.py`) is completely unused and never imported.
*   **Ad-Hoc scripts cluttering workspace root:**
    *   **Path:** `D:\Mynix_Control\`
    *   **Issue:** Leftover utility scripts (`smart_restore*.py`, `recover_*.py`, etc.) clutter the root directory.
*   **Leftover frontend root scripts:**
    *   **Path:** `frontend/replace_currency.py` and `frontend/replace_icons.py`.

---

## 2. Logic Chain
1. **API Alignment:** By inspecting `ingredient_service.py` and `menu_service.py` side-by-side with model schemas `IngredientRead` and `MenuItemRead`, we noticed that several parameters (like `sort_order` and `attributes`) are not being supplied during Pydantic object instantiation. This causes Python to serialize the default values (`0` or `None`) instead of the actual DB records, resulting in silent data loss.
2. **Dio Repository vs FastAPI Router Integration:** Comparing `auth_repository.dart` PIN login function signature with backend `PinLoginRequest` model, it is clear that `tenantId` is typed as `String` in Dart and serialized as a string in JSON, but the Pydantic model enforces `tenant_id` as `int`. Hence, any PIN login request will fail Pydantic type validation on the backend (returning HTTP 422).
3. **Database Migration Initialization:** Reading `app/database.py` shows that `init_db()` calls `os.system` using `cd D:\Mynix_Control\SCafe`. Because `SCafe` is a non-existent folder on the system, the `cd` command fails, preventing the subsequent `.venv\Scripts\alembic upgrade head` from being executed in the correct context, thus breaking migration execution on startup.
4. **PBAC Permision Constraints:** In `document_router.py` and `kds_router.py`, permissions `"inventory:read"`, `"inventory:write"`, and `"kitchen:manage"` are requested. However, in `seed.py`, these values are not present in the list of seeded permission records. Since these permissions are not seeded, they cannot be assigned to roles, causing a lockout for all non-superuser accounts who try to access these endpoints.
5. **Database Alteration Failures:** Because Mynix Control employs PostgreSQL schema-scoped isolation for multi-tenancy, any raw SQL script targeting tenant tables like `menu_items` must either set the session's `search_path` to the target tenant schema or prefix the tables. Alteration scripts like `alter_db_postgres.py` fail to do so, executing raw SQL in `public` schema where tenant tables do not exist.

---

## 3. Caveats
*   We did not run the test suites due to the user prompt permission timeout, but static codebase analysis was sufficient to identify these explicit mismatch and pathing errors.
*   We assume that the `SCafe` path is a legacy leftover from a previous folder name in development.

---

## 4. Conclusion
The Mynix Control codebase has several integration discrepancies:
1. **API Contracts:** Omitted fields in Pydantic serializers on the backend lead to silent data loss, and type mismatches in the PIN login endpoint prevent successful quick login.
2. **Security & Permissions (PBAC):** Missing permissions in the seeding scripts block cashiers and cooks from managing KDS order states and inventory documents.
3. **Database Setup:** Hardcoded legacy paths (`SCafe`) and raw SQL scripts executed without schema search-paths break automatic migrations and alter scripts.
4. **Dead Code:** Unused modules (`hardware`) and ad-hoc recovery utilities clutter both the root and frontend directories.

---

## 5. Verification Method
### 5.1 Automatic Testing Verification
*   **Run Backend Tests:** Run `pytest` from the `backend` directory:
    ```powershell
    cd D:\Mynix_Control\backend
    .\.venv\Scripts\pytest
    ```
    *Invalidation Condition:* The tests will verify if endpoints respond correctly, but won't detect the schema lockout unless test roles are seeded similarly to `seed.py`.

### 5.2 Manual Code Verification
1.  **Check `init_db` Pathing:** Inspect `D:\Mynix_Control\backend\app\database.py` line 49. Check if the path `D:\Mynix_Control\SCafe` exists.
2.  **Verify DB Schema Lockouts:** Log in as a user with `cook` role, and perform `POST /api/v1/kitchen/kds/{order_id}/ready`. It will return `403 Forbidden` due to missing `kitchen:manage` permission.
3.  **Verify Alter Scripts Failure:** Run `python backend/alter_db_postgres.py`. It will throw a `psycopg2.errors.UndefinedTable: relation "menu_items" does not exist` error.

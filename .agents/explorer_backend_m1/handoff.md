# Handoff Report — Backend Codebase Audit Exploration

## Observation

Below are the direct observations of architectural violations, bugs, and inconsistencies found in the codebase of `D:\Mynix_Control\backend\app\`.

### 1. Separation of Concerns Violation (SQL Execution in Router)
* **File Path**: `D:\Mynix_Control\backend\app\inventory\routers\document_router.py`
* **Observation**: Direct database session operations and exception handling are performed within the router endpoints rather than delegating to services.
* **Code Reference (Lines 32-35, 44-53, 62-74)**:
  ```python
  # Line 32-35
  supplier = Supplier(**supplier_in.model_dump())
  session.add(supplier)
  await session.flush()
  return supplier

  # Line 44-53
  supplier = await session.get(Supplier, supplier_id)
  ...
  update_data = supplier_in.model_dump(exclude_unset=True)
  for key, value in update_data.items():
      setattr(supplier, key, value)
  session.add(supplier)
  await session.flush()

  # Line 62-74
  supplier = await session.get(Supplier, supplier_id)
  ...
  try:
      await session.delete(supplier)
      await session.flush()
  except IntegrityError:
      await session.rollback()
      raise HTTPException(status_code=400, detail="...")
  ```

### 2. PBAC (Permission-Based Access Control) Mismatches and Security Vulnerabilities
* **File Path**: `D:\Mynix_Control\backend\app\pos\routers\pos_menu_router.py`
  * **Observation**: Line 11 requires `pos:menu_view` permission:
    ```python
    dependencies=[Depends(require_permission("pos:menu_view"))]
    ```
    However, `pos:menu_view` is **not** seeded in `D:\Mynix_Control\backend\app\users\seed.py` (which only contains `menu:view` and `menu:manage` on lines 46-47). No default role can access this endpoint.
* **File Path**: `D:\Mynix_Control\backend\app\inventory\routers\document_router.py`
  * **Observation**: Lines 19, 26, 37, 56, 78, 86, 94, 102 require `inventory:read` and `inventory:write` permissions:
    ```python
    dependencies=[Depends(require_permission("inventory:read"))]
    dependencies=[Depends(require_permission("inventory:write"))]
    ```
    However, `inventory:read` and `inventory:write` are **not** seeded in `D:\Mynix_Control\backend\app\users\seed.py` (which only contains `inventory:manage` and `inventory:view` on lines 38-39). Normal staff roles cannot access these endpoints.
* **File Path**: `D:\Mynix_Control\backend\app\kitchen\routers\kds_router.py`
  * **Observation**: Line 50 requires `kitchen:manage` permission:
    ```python
    dependencies=[Depends(require_permission("kitchen:manage"))]
    ```
    However, `kitchen:manage` is **not** seeded in `D:\Mynix_Control\backend\app\users\seed.py` (which only has `kitchen:view` on line 36). The default `cook` role only has `kitchen:view` and `orders:update_status`.
* **File Path**: `D:\Mynix_Control\backend\app\pos\ws.py`
  * **Observation**: Line 60 WebSocket route has **no** authorization wrapper:
    ```python
    @router.websocket("/ws/kitchen/{tenant_id}")
    async def kitchen_websocket(websocket: WebSocket, tenant_id: int):
    ```
    There is no dependency checking JWT token or permissions (`kitchen:view`), allowing any unauthenticated client to listen to order events for any tenant.

### 3. Critical DB Relationship Mutation Bug
* **File Path**: `D:\Mynix_Control\backend\app\kitchen\services\kds_service.py`
* **Observation**: In `get_active_orders()`, the database-tracked relationship collection is mutated in-place:
  ```python
  # Line 28-29
  # We override the items list to only include dishes
  order.items = dish_items
  ```
  Because the session auto-commits at the end of the request via the `get_tenant_session` dependency, SQLAlchemy attempts to persist this deletion of items (e.g. retail items) in the database, causing database corruption (deleting retail items from orders) or throwing an `IntegrityError` (since `order_id` in `order_items` is non-nullable).

### 4. Functional Bugs: Hardcoded Paths and Missing Session Flushes
* **File Path**: `D:\Mynix_Control\backend\app\database.py`
  * **Observation**: Line 49 hardcodes a non-existent folder:
    ```python
    os.system("cd D:\\Mynix_Control\\SCafe && .\\.venv\\Scripts\\alembic upgrade head")
    ```
    The folder in the workspace is `backend/` instead of `SCafe/`.
* **File Path**: `D:\Mynix_Control\backend\app\inventory\services\stock_service.py`
  * **Observation**: `receive_stock()` (line 115) does **not** call `await session.flush()` before returning the `txn` object:
    ```python
    session.add(txn)
    return txn
    ```
    This causes `txn.id` to be returned as `None` in the HTTP response of `/ingredients/receive`.
* **File Path**: `D:\Mynix_Control\backend\app\pos\services\shift_service.py`
  * **Observation**: `record_expense()` (line 103) does **not** call `await session.flush()` before returning `txn`, causing `transaction_id: null` to be returned in the HTTP response of `/cash/expense`.

### 5. Non-Optimal SQL & Logic Errors in Analytics Dashboard
* **File Path**: `D:\Mynix_Control\backend\app\analytics\services\dashboard_service.py`
  * **Observation**: Line 81 hardcodes the low stock threshold to `< 5`, completely ignoring the user-configured `min_stock_alert` in `RetailProduct`:
    ```python
    stock_query = select(RetailProduct).where(RetailProduct.current_stock < 5)
    ```
    It also completely omits `Ingredient` low-stock warnings.
  * **Observation**: In `recipe_service.py` `calc_food_cost` (line 86), the code assumes `recipe.ingredient` is always non-null:
    ```python
    total_cost += recipe.ingredient.cost_per_unit * recipe.quantity_required
    ```
    If an ingredient was deleted and orphans remain, this will crash with an `AttributeError`.

### 6. Model Multi-Tenancy Inconsistency
* **File Paths**: `D:\Mynix_Control\backend\app\inventory\models\recipe_models.py` (Line 9), `D:\Mynix_Control\backend\app\pos\models.py` (Line 107)
  * **Observation**: `Recipe` and `OrderItem` inherit from `SQLModel` directly instead of `TenantModel`. While schema isolation prevents cross-contamination, they fail the project rule: *"All domain entities inherit from TenantModel to enforce multi-tenancy"*, and lack `created_at`/`updated_at` audit fields.

### 7. Testing Architecture Flaw
* **File Path**: `D:\Mynix_Control\backend\tests\conftest.py`
  * **Observation**: The testing config only overrides `get_session`. It does **not** override `get_tenant_session`. Running any tests against tenant-scoped routes will trigger the real PostgreSQL session manager and crash on SQLite due to schema-unsupported queries.

---

## Logic Chain

1. **Separation of Concerns**: Global Rule 1.3 states that routers must only contain HTTP mapping and dependencies, while services contain business logic and SQL. Because `document_router.py` does direct database sessions and writes (`session.add`, `session.delete`), it directly violates the separation of concerns.
2. **PBAC Mismatches**: An endpoint protected by `require_permission(X)` checks user permissions. If permission `X` is not seeded in `PERMISSIONS` in `seed.py`, no user/role can ever be assigned that permission code. Consequently, endpoints requiring unseeded codes (`pos:menu_view`, `inventory:read`, `inventory:write`, `kitchen:manage`) will always return `403 Forbidden` for standard users (like cashiers and cooks).
3. **KDS Mutation Bug**: The active database session tracks entity state. Mutating `order.items` collection in `get_active_orders` tells SQLAlchemy that the items no longer in the list should be detached/deleted. On request completion, the session commits, executing database updates that drop or delete the other order items, corrupting order data.
4. **Missing Flushes**: Auto-increment IDs are set by PostgreSQL when a row is inserted. SQLAlchemy buffers inserts until a `flush()` or `commit()`. Because `receive_stock()` and `record_expense()` return the model without calling `session.flush()`, the ID attribute remains `None` when the router tries to serialize it, sending `null` to the client.
5. **Hardcoded Dashboard Thresholds**: `RetailProduct` and `Ingredient` have a dynamic, customizable `min_stock_alert` field. Hardcoding `< 5` in `dashboard_service.py` prevents managers from configuring alert thresholds properly.

---

## Caveats

* **Production DB Migration**: The alembic migration state was not ran because the execution permission timed out. However, the hardcoded path `D:\Mynix_Control\SCafe` was statically matched against the actual workspace name `Mynix_Control/backend`, proving it will fail to navigate.
* **WebSocket authentication implementation**: Implementing WebSocket authentication usually requires extracting tokens from headers or query parameters. The exact approach should be aligned with the frontend authentication method.

---

## Conclusion

The FastAPI backend codebase is highly modular and complies with line limits (all files under 250 lines). However, there are major bugs and security vulnerabilities, including:
1. Direct collection mutation in KDS service causing database corruption.
2. Mismatch between used router permissions and seeded permissions blocking cashier/cook APIs.
3. Unauthenticated WebSocket endpoint exposing all order data.
4. Separation of concerns violation in `document_router.py`.
5. Missing flushes resulting in empty transaction IDs.
6. Incorrect directory path for DB migration initialization.

---

## Recommended Fixes

### Fix 1: Separation of Concerns in `document_router.py`
Move the DB logic from `document_router.py` into a new service `app.inventory.services.document_service.py` (or a dedicated `supplier_service.py`).
* **Router Change**:
  ```python
  # Before
  @supplier_router.post("/", response_model=SupplierRead, ...
  async def create_supplier(supplier_in: SupplierCreate, session: TenantSession, user: CurrentUser):
      supplier = Supplier(**supplier_in.model_dump())
      session.add(supplier)
      await session.flush()
      return supplier

  # After
  @supplier_router.post("/", response_model=SupplierRead, ...
  async def create_supplier(supplier_in: SupplierCreate, session: TenantSession, user: CurrentUser):
      return await document_service.create_supplier(session, supplier_in)
  ```

### Fix 2: Resolve PBAC Permission Mismatches
* In `pos_menu_router.py`, change permission to `"menu:view"`:
  ```python
  @router.get("/menu/", dependencies=[Depends(require_permission("menu:view"))])
  ```
* In `document_router.py`, map `inventory:read` to `"inventory:view"`, and `inventory:write` to `"inventory:manage"`:
  ```python
  # For GET requests:
  dependencies=[Depends(require_permission("inventory:view"))]
  # For POST/PUT/DELETE requests:
  dependencies=[Depends(require_permission("inventory:manage"))]
  ```
* In `kds_router.py`, change `kitchen:manage` to `"orders:update_status"`:
  ```python
  @router.post("/{order_id}/ready", dependencies=[Depends(require_permission("orders:update_status"))])
  ```

### Fix 3: Secure the Kitchen WebSocket
* In `pos/ws.py`, validate the JWT token on connection:
  ```python
  # Proposed check
  @router.websocket("/ws/kitchen/{tenant_id}")
  async def kitchen_websocket(websocket: WebSocket, tenant_id: int, token: Optional[str] = Query(None)):
      # Decode token, verify user tenant_id == tenant_id, and user has kitchen:view permission
      ...
  ```

### Fix 4: Fix KDS Order Items Mutation
In `kitchen/services/kds_service.py`, do NOT reassign `order.items`. Construct a response DTO or a clean dict list:
* **Before**:
  ```python
  for order in orders:
      dish_items = [item for item in order.items if item.item_type == "dish"]
      if dish_items:
          order.items = dish_items  # <-- Mutates DB collection!
          filtered_orders.append(order)
  ```
* **After**:
  ```python
  # Return a dictionary or DTO rather than mutating tracked order.items
  for order in orders:
      dish_items = [item for item in order.items if item.item_type == "dish"]
      if dish_items:
          # Convert to dict or schema, leaving DB collection unmodified
          order_dict = order.model_dump()
          order_dict["items"] = [item.model_dump() for item in dish_items]
          filtered_orders.append(order_dict)
  ```
  *(Note: Update the router signature to expect dicts/DTOs instead of ORM objects)*

### Fix 5: Fix Hardcoded Migration Path
In `database.py` line 49, change path:
* **Before**:
  ```python
  os.system("cd D:\\Mynix_Control\\SCafe && .\\.venv\\Scripts\\alembic upgrade head")
  ```
* **After**:
  ```python
  os.system("cd D:\\Mynix_Control\\backend && .\\.venv\\Scripts\\alembic upgrade head")
  ```

### Fix 6: Add Missing Flushes in Stock/Shift Services
* In `stock_service.py` `receive_stock()`:
  ```python
  session.add(txn)
  await session.flush()  # <-- ADD THIS
  return txn
  ```
* In `shift_service.py` `record_expense()`:
  ```python
  session.add(txn)
  await session.flush()  # <-- ADD THIS
  return txn
  ```

---

## Verification Method

1. **Verify Alembic Command Path**:
   * Inspect `database.py:49` and verify the directory is set to `backend`.
2. **Verify PBAC endpoints**:
   * Run the FastAPI server and perform requests with token payloads belonging to a "cook" or "cashier" role. Verify that requesting `/api/v1/menu/` and `/api/v1/documents/` do not return 403 Forbidden under the corrected permissions.
3. **Verify WebSocket Security**:
   * Attempt to open a WebSocket connection to `ws://localhost:8000/ws/kitchen/1` without a query token and verify that it rejects the connection.
4. **Verify order item retention (KDS Bug)**:
   * Create an order with 1 dish and 1 retail item.
   * Hit `/api/v1/kitchen/kds/active`.
   * Inspect the database table `order_items` and verify that the retail item is still linked to the order and not deleted.

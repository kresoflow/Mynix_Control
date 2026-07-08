# Task: Update Code Quality Audit Report with Reviewer Corrections

## Objective
Apply critical corrections to `D:\Mynix_Control\code_quality_audit.md` based on review feedback from Reviewer 1 and Reviewer 2.

## Required Corrections
1. **Finding 1 (KDS ORM Mutation Fix)**:
   - Change the recommended code fix. Instead of changing the service return type to `List[dict]` and returning raw dictionaries, keep the typed approach.
   - The service `get_active_orders` should return `List[Order]` and query/filter orders without mutating `order.items`.
   - The router `api_get_active_orders` should filter the list of order items `for oi in o.items if oi.item_type == "dish"` during JSON serialization mapping.
2. **Finding 2 (WebSocket Auth Import Fix)**:
   - In the proposed Python WebSocket code, replace the non-existent import `from app.auth.services import verify_token` with direct JWT decoding using `jose.jwt` and settings. Use the settings properties: `settings.secret_key` and `settings.jwt_algorithm`.
3. **Finding 9 (ConnectKitchen Parameter Fix)**:
   - In the proposed Dart code inside `initState()`, fetch the `tenantId` from `authState` and pass it as a parameter when creating `ConnectKitchen`:
     `context.read<KitchenBloc>().add(ConnectKitchen(authState.tenantId));`
4. **Finding 13 (PBAC Cross-Reference Fix)**:
   - Change the text "(см. фикс для Находки 6)" to reference Finding 2 / Fix 2.
5. **Section 3 (Dead Code Removal)**:
   - Remove `bulk_add_modal.dart` from the dead/unused files list. It is actively imported and used.

## Output File
Overwrites/modifies `D:\Mynix_Control\code_quality_audit.md` directly.
Ensure the resulting markdown is valid. Once done, report back with your `handoff.md` inside your working directory `D:\Mynix_Control\.agents\worker_update_report`.

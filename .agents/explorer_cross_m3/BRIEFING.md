# BRIEFING — 2026-07-02T17:11:31Z

## Mission
Perform cross-cutting codebase audit of Mynix Control backend and frontend for configuration, API contracts, database scripts, and code quality.

## 🔒 My Identity
- Archetype: Teamwork explorer
- Roles: Read-only investigation, Codebase Audit
- Working directory: D:\Mynix_Control\.agents\explorer_cross_m3
- Original parent: 11dbf383-208c-4242-86b8-ceb7ae0255c7
- Milestone: Cross-Cutting Audit

## 🔒 Key Constraints
- Read-only investigation — do NOT implement
- CODE_ONLY network mode: no external web/service access, no curl/wget/lynx.
- Write only to your own folder: D:\Mynix_Control\.agents\explorer_cross_m3

## Current Parent
- Conversation ID: 11dbf383-208c-4242-86b8-ceb7ae0255c7
- Updated: 2026-07-02T17:11:31Z

## Investigation State
- **Explored paths**:
  - `backend/app/main.py`, `backend/app/config.py`, `backend/app/database.py`, `backend/app/base_model.py`
  - `backend/app/inventory/routers/*.py`, `backend/app/inventory/services/*.py`, `backend/app/inventory/models/*.py`
  - `backend/app/pos/routers/*.py`, `backend/app/pos/services/*.py`, `backend/app/pos/models.py`
  - `backend/app/kitchen/routers/*.py`, `backend/app/users/router.py`, `backend/app/users/models.py`, `backend/app/users/seed.py`
  - `frontend/lib/features/inventory/repository/inventory_repository.dart`
  - `frontend/lib/features/pos/repository/*.dart`
  - `frontend/lib/features/kitchen/repository/kitchen_repository.dart`
  - `frontend/lib/features/analytics/repository/analytics_repository.dart`
  - `frontend/lib/features/auth/repository/auth_repository.dart`
  - `backend/alter_db_*.py`, `backend/drop_db.py`, `backend/fix_db.py`, `backend/seed_documents.py`
- **Key findings**:
  - Data loss bugs in `list_ingredients` and `list_menu_items` APIs where `sort_order` and `attributes` are omitted during Pydantic schema instantiation.
  - Parameter type mismatch in `loginByPin` (Dio sends `String` while FastAPI expects `int`).
  - Critical hardcoded path in `init_db()` referencing non-existent directory `SCafe`.
  - Hardcoded database connections in multiple database scripts.
  - Permissions mismatch: document router requires `inventory:read`/`inventory:write` but seed only defines `inventory:view`/`inventory:manage`. Kitchen router requires `kitchen:manage` but seed only defines `kitchen:view`.
  - Raw SQL in DB alteration scripts failing on schema-based multi-tenancy due to missing `search_path` qualification.
  - Dead code in `backend/app/hardware` and root/frontend backup/cleanup scripts.
- **Unexplored areas**: None.

## Key Decisions Made
- Audited the entire backend and frontend integration layer.
- Documented findings with exact files and line numbers.

## Artifact Index
- D:\Mynix_Control\.agents\explorer_cross_m3\ORIGINAL_REQUEST.md — Original request logs

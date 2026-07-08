# Codebase Context: Mynix Control

## Overview
- Workspace URI: `d:\Mynix_Control`
- Tech Stack: FastAPI (Backend), Flutter (Frontend), PostgreSQL (Database)

## Architecture Guidelines (from AGENTS.md & user_global)
- Backend:
  - Multi-tenancy: Never add `tenant_id` column. PostgreSQL schemas are used instead. Use `get_tenant_session` dependency.
  - PBAC: Every endpoint in `router.py` must use `require_permission('domain:action')`.
  - Separation of Concerns: `router.py` does HTTP mapping/Pydantic schemas/dependencies. `services.py` contains business logic and executes SQL queries.
  - Line Limit: 250-300 lines limit per file for routers and services.
  - SQLModel/SQLAlchemy: Asyncpg driver. Execute queries via `session.exec()`.
- Frontend:
  - Macro-architecture: Feature-Driven Architecture (`lib/features/<feature_name>`).
  - State Management: No `StatefulWidget` for business logic; use `BLoC` + `Equatable`.
  - Networking: No direct HTTP requests from UI/BLoC; use Repository (`Dio`) injected via `RepositoryProvider`.
  - Micro-architecture: Line limit 200-250 lines per file. Complex build methods must be decomposed into widgets.

## Key Target Areas for Audit
- Backend: Files under `routers/` and `services/`.
- Frontend: BLoC files, feature layouts, widgets under `lib/features/`.

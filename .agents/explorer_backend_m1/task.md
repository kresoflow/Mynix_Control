# Task: Backend Code Quality Audit Exploration

## Objective
Analyze the Mynix Control FastAPI backend codebase to find architectural violations, functional bugs, logic errors, and non-optimal SQL queries.

## Scope
- D:\Mynix_Control\backend\app\
- Compare code against the global rules in `D:\Mynix_Control\AGENTS.md` and user_global rules.

## Requirements
1. **Layer Division**: Check routers (routers/) vs services (services/) separation. Look for business logic or SQL execution in routers.
2. **Multi-Tenancy**: Check for any `tenant_id` column usage in SQLModel/SQLAlchemy models. Check if `get_tenant_session` is used properly.
3. **PBAC**: Check if every router endpoint is protected by `require_permission('domain:action')`.
4. **SQL performance & Logic**: Identify non-optimal SQL queries, missing async calls, or bugs in backend services.
5. **Line Limits**: Identify any router/service files exceeding 250-300 lines limit.

## Outputs
Write `handoff.md` inside your working directory with a detailed findings list including file paths, line numbers, issue descriptions, and recommended fixes.

# Task: Draft Code Quality Audit Report

## Objective
Combine the backend, frontend, and cross-cutting audit findings into a single, comprehensive `code_quality_audit.md` report at `D:\Mynix_Control\code_quality_audit.md`.

## Source Materials
- Backend Findings: `D:\Mynix_Control\.agents\explorer_backend_m1\handoff.md`
- Frontend Findings: `D:\Mynix_Control\.agents\explorer_frontend_m2\handoff.md`
- Cross-Cutting Findings: `D:\Mynix_Control\.agents\explorer_cross_m3\handoff.md`

## Report Requirements
1. **Critical Highlights**: Clearly distinguish critical issues, such as:
   - Crashes (e.g. JSON parse format exceptions, null casts, orphan recipe food cost calculation).
   - Global project rules violations (e.g. 200-250 line limit in UI, direct repo instantiations, BLoC rules, SQL execution in router, multi-tenancy columns or missing `TenantModel` inheritance).
   - Data corruption (e.g. KDS relationship mutation).
   - Security flaws (unauthenticated WebSocket).
2. **Details for Each Finding**:
   - File Path (absolute path)
   - Line Numbers (if applicable)
   - Severity (Critical, Major, Minor)
   - Detailed Description of the issue
   - Code snippet showing the problem (optional but helpful)
   - Concrete Recommended Fix with exact code proposal.
3. **Language**: The report should be written in Russian (as requested in the initial user request: "Цель — выявить логические ошибки, проблемы со стабильностью и нарушения архитектурных стандартов проекта.") or English, but since the user prompt is in Russian and the request says "Предоставить сводный отчет (`code_quality_audit.md`) со списком...", writing the report in Russian or bilingual is highly preferred. Let's make sure the report is written in Russian to perfectly match the user's expectations.

## Output File
Write the report directly to `D:\Mynix_Control\code_quality_audit.md`.
Ensure the format is clean markdown with no parser errors.
Once written, report back with your `handoff.md` inside your working directory `D:\Mynix_Control\.agents\worker_draft_report`.

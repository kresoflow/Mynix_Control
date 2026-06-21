# Project: AI Studio Organizational Audit for Mynix Control POS

## Architecture & Context
- **Mynix Control POS:** A B2B SaaS POS system built with FastAPI (backend) and Flutter (frontend).
- **Core backend traits:** Multi-tenancy via PostgreSQL schema isolation (no `tenant_id` columns), PBAC authorization (e.g. `domain:action`), routing separate from service layer logic, async SQLAlchemy/SQLModel.
- **Core frontend traits:** Feature-Driven Architecture, state management via BLoC + Equatable, Repository layer via Dio, strict file line limit of 200-250 lines (aggressive decomposition).
- **Proposed Roster:** Product Manager, UI/UX Designer, Flutter Senior, FastAPI Senior, DB Architect, QA Lead, Security Auditor.
- **Constraints:** Lean Startup principles (avoid enterprise bloat, ensure quick MVP release).

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| 1 | Exploration & Audit Analysis | Evaluate the 7-agent roster against codebase requirements and Lean Startup principles; formulate optimization rationale. | None | DONE |
| 2 | Deliverables Generation | Write the audit report (`team_audit_report.md` in Russian) and subagent definitions (`ai_studio_config.json`) to `~/teamwork_projects/ai_studio_audit`. | M1 | DONE |
| 3 | Quality Assurance & Review | Run validation checks on JSON syntax and schema, audit the report for depth and Russian language correctness, verify compliance with `AGENTS.md` and system rules. | M2 | DONE |

## Deliverable Contracts
### `team_audit_report.md`
- Written entirely in Russian.
- Explicitly states final team size and details/justifies all role additions, deletions, or merges.
- Includes detailed definitions of roles, including responsibilities and alignment with Mynix Control core rules (e.g., PostgreSQL schema multi-tenancy, Flutter file size limits).

### `ai_studio_config.json`
- Structurally valid JSON file.
- Contains an array of agent definitions.
- Each agent definition has: `name`, `description`, and `system_prompt` (in the style of `define_subagent` configuration format).

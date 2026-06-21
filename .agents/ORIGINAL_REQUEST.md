# Original User Request

## 2026-06-19T15:52:17Z

# Teamwork Project Prompt — Draft

> Status: Step 2 — Identifying ambiguity
> Goal: Craft prompt → get user approval → delegate to teamwork_preview

Conduct a definitive organizational audit of the AI Studio for Mynix Control (a B2B SaaS POS system built with Flutter and FastAPI). The goal is to identify the absolute most effective and complete team of specialized AI agents required for full-cycle development, ensuring no critical roles are missing, and to output a finalized team roster.

Working directory: ~/teamwork_projects/ai_studio_audit

Integrity mode: development

## Requirements

### R1. Team Audit
Analyze the current proposed 7-agent AI Studio roster (Product Manager, UI/UX Designer, Flutter Senior, FastAPI Senior, DB Architect, QA Lead, Security Auditor) for the Mynix Control POS system. 

### R2. Lean Startup Optimization
Evaluate the roster strictly against a "Lean Startup" constraint. Identify if any critical role is missing to achieve rapid MVP release, or if any of the 7 roles should be merged/cut to avoid enterprise bloat.

### R3. Output Deliverables
1. Output a definitive Markdown report (`team_audit_report.md`) detailing the final, optimal team roster and justifying any additions or removals. **CRITICAL: The report must be written entirely in Russian.**
2. Output a valid JSON configuration file (`ai_studio_config.json`) containing the exact schema required to register these roles (Name, Description, System Prompt) using the Antigravity `define_subagent` tool format.

## Acceptance Criteria

### Documentation
- [ ] A `team_audit_report.md` file is generated in the working directory.
- [ ] The report explicitly states whether the final team size is 7, or if it was modified (and why).

### Configuration Validity
- [ ] An `ai_studio_config.json` file is generated in the working directory.
- [ ] The JSON file is structurally valid and can be successfully parsed by `jq`.
- [ ] The JSON file contains an array of agent definitions, each possessing at least a `name`, `description`, and `system_prompt` field.

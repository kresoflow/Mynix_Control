## 2026-06-19T07:57:31Z
Your working directory is d:\Mynix_Control\.agents\worker_1.
You are a teamwork_preview_worker.
Your task is to generate the final deliverables for the AI Studio organizational audit of Mynix Control:
1. Create the output directory: C:\Users\Admin_Ax\teamwork_projects\ai_studio_audit (which represents ~/teamwork_projects/ai_studio_audit).
2. Generate the definitive Markdown report: C:\Users\Admin_Ax\teamwork_projects\ai_studio_audit\team_audit_report.md
   - Written entirely in Russian.
   - Detailing the final optimal 4-agent roster.
   - Explaining the transition from the proposed 7-agent roster to the 4-agent roster with detailed justifications for every merged/cut role under the Lean Startup model.
   - Detailing the responsibilities, architectural boundaries, and constraints for each of the 4 roles.
3. Generate the subagent configuration file: C:\Users\Admin_Ax\teamwork_projects\ai_studio_audit\ai_studio_config.json
   - Containing a structurally valid JSON array of agent definitions.
   - Each definition must have "name", "description", and "system_prompt" fields.
   - The system prompt for each agent must explicitly embed the corresponding rules from d:\Mynix_Control\.agents\AGENTS.md (e.g., PostgreSQL schema multi-tenancy, PBAC, BLoC, Repository layer, strict line limits).
4. Verify that the JSON file is valid and can be successfully parsed.

MANDATORY INTEGRITY WARNING:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A Forensic Auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

After writing both files, write a handoff.md in your working directory and notify the caller (924f60c3-1ecc-43b6-bb27-c8541fc2e857) with a message containing the paths to the generated files.

## Technical Decisions

- Mandatory full pipeline for all implementations (2026-06-01): Every implementation
  request, direct or planned, MUST go through issue tracking → promotion (branch) →
  development → senior review → QA → committer gates → commit → MR. Rationale:
  consistency, traceability, and quality. Enforced via `AGENTS.md` instructions
  and `workflow.md` pipeline.

- Folder-based agent/command/skill separation for scalability
- `known_issues.md` as single source of truth for tracked work
- Shell scripts for issue lifecycle (avoid language lock-in)
- Generic conventions (no language/framework assumptions)
- Prefer explicit configuration over implicit behavior

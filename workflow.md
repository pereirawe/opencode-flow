## Discovery to Issue Flow

The discovery flow transforms raw ideas into tracked, typed issues with
acceptance criteria, business rules, and test definitions. Each agent asks
context-based questions to progressively refine the proposal.

### Mandatory Rule

**Every new feature (`feat` type) MUST go through the full discovery pipeline
before development starts.** Issues promoted without documented business rules
will be blocked by the Committer. Missing business rules discovered during
review are not bugs — they are incomplete specs and must be refined back
through discovery.

### Discovery Pipeline

1. **PO** registers a prioritization proposal in the **project's**
   `.opencode/prioritization.md`. If the project doesn't have this
   file yet, create it. The global `~/.config/opencode/prioritization.md`
   is ONLY for opencode's own improvements — never write project proposals there.
   Include business value, target, rationale, proposed issue type, and known
   business rules.
2. **CTO** reviews architectural alignment, defines technical vision, and
   identifies strategic constraints. Define whether the base branch aligns
   with the project's branch strategy.
3. **Tech Lead** refines with technical detail: feasibility, effort, risks,
   dependencies, non-functional requirements, task breakdown, and validates
   business rules against the technical model. Defines the **base branch**
   and **senior reviewer profiles**.
4. **PO** creates user story with acceptance criteria and documented business
   rules — every business rule must be explicit, not implicit. Records
   `- Base branch:` and `- Reviewers:` in the issue entry.
5. **QA** reviews story for testability, edge cases, and quality criteria —
   verifies that business rules are testable. Validates that reviewer profiles
   cover all affected domains.
6. **PM** validates dependencies, assigns to sprint, asks the user if they want
   to create the remote issue now (`scripts/create_issue.sh <id>` if confirmed),
   and promotes to `known_issues.md` with status `backlog` or `ready`. If the
   user declines remote creation, the field stays as `-` — it will be
   auto-created during promotion to `in-progress`.

### Agent Discovery Questions

Each agent must ask context-based questions during discovery. The PO must
drive the conversation around **business rules** specifically.

- **CTO**: Quais princípios arquiteturais são afetados? Existem trade-offs
  conhecidos? Como isso se alinha com a visão técnica de longo prazo?
- **PO**: Quem é o usuário final? Qual o valor de negócio? Qual a urgência?
  Quais critérios definem sucesso? **Quais são as regras de negócio
  específicas? Quais condições, limites e exceções existem?**
- **Tech Lead**: Quais camadas são afetadas? Quais dependências existem?
  Quais requisitos não-funcionais? Qual o esforço estimado? **As regras de
  negócio estão completas e consistentes com o modelo técnico? Qual a branch
  base? Quais perfis de revisores?**
- **QA**: Quais cenários de teste são necessários? Quais edge cases existem?
  Como validamos os critérios de aceite? **Como testamos cada regra de
  negócio isoladamente? Os perfis de revisores cobrem todos os domínios?**

## Development Workflow

### Mandatory Rule

**Every implementation request — regardless of how it's asked — MUST follow the
full pipeline.** This is enforced at the instruction level via `AGENTS.md`.
Any direct implementation without pipeline is a violation.

### Continuous Execution

**After promotion, steps 6–11 (development → senior review → QA → corrections →
committer gate → MR creation) execute automatically without user confirmation.**
No agent asks for permission between steps — each agent reads the issue status
in `known_issues.md`, performs its function, updates the status, and the next
agent in the pipeline continues. **The Developer must never pause between
implementation and senior review** — after running tests and self-review, the
developer updates status to `in-review` and proceeds immediately without asking
the user.

**Only two scenarios trigger interaction with the user:**
1. **Incomplete refinement**: business rules are missing or ambiguous in the
   issue — the agent flags the gap in `known_issues.md` and continues with
   what is available, rather than blocking. The issue remains in progress
   and the gap is documented for the next discovery cycle.
2. **Blocking error**: the issue has no `Base branch:`, no `Remote:` (for feat),
   or no reviewer profiles defined — these are structural gaps that prevent
   promotion entirely and must be resolved during discovery.

**After MR publication**: the pipeline pauses. The Close Requester does not
poll or check — it only acts when explicitly triggered by a merge notification.
The user merges the MR manually.

### Agent Pipeline

1. **CTO** — define technical vision and guidelines
2. **Product Owner** — define priorities, create user stories, register
    prioritization proposals in `.opencode/prioritization.md`
    (project-level) or `~/.config/opencode/prioritization.md`
   (global fallback). **The global file is ONLY for opencode's own improvements —
   never write project proposals there.**
3. **Tech Lead** — refine stories with technical detail, feasibility analysis,
   effort estimation, and task breakdown
4. **Quality Analyst (pre-development)** — ensure stories are testable and meet
   quality standards, validate business rules are testable
5. **Project Manager** — coordinate team, assign stories, track progress.
   **During promotion, PM reads `Base branch:` and `Reviewers:` from the issue
   entry in `known_issues.md`, auto-creates Remote if missing via
   `scripts/create_issue.sh <id>`, then runs `promote.sh <id>` to checkout+pull
   the base branch and create the feature branch. No user questions — all data
   was set during discovery.**
   **When QA sends an issue back from `in-qa` to `in-progress`, the PM
   re-invokes the Developer agent to implement corrections, then notifies
   Senior Reviewers to re-review.**
6. **Developer** — implement features, write automated tests, run tests, keep
   `known_issues.md` in sync. Verify the feature branch is based on the correct
   base branch before starting implementation. If business rules are missing or
   unclear, flag the gap as a new issue in `known_issues.md` and proceed with
   what is defined — do not block. **After implementation, update status to
   `in-review` and proceed to senior review without asking the user.**
7. **Senior Reviewers** — review code using the count stored in `- Reviewers:`
    in the issue entry (set during discovery), verify acceptance criteria,
   confirm tests were written and pass, identify issues
8. **Quality Analyst (post-review)** — verify quality after senior review,
   check that all identified issues were addressed and quality standards are met
9. **Developer** — implement all corrections from senior review and QA (loop
   with QA until approved). Re-invoked by PM when status returns to
   `in-progress` from `in-qa`.
10. **Committer** — verify pipeline gates: senior review completed, QA passed,
    business rules documented (for `feat` types), tests passing. Sets status to
    `in-publish` on approval. Reports findings without blocking — if a gate
    fails, document what failed and let the pipeline continue to the next cycle.
11. **Publish Requester** — create merge/pull request after Committer gate passes.
    Does not re-validate gates — trusts Committer signal (`Status: in-publish`).
    Does not ask for confirmation — creates the MR automatically.
12. **Close Requester** — does not poll or check automatically. Only acts when
    explicitly triggered by a merge notification. After MR/PR is merged, closes
    the remote issue on GitHub/GitLab, updates `known_issues.md` status to
    `resolved`, and archives to `resolved_issues.md` via `close_issue.sh`.

> **Documentation** and **Test Automation** are ongoing activities that run in
> parallel across all pipeline phases, not sequential gates.

> `known_issues.md` is the single source of truth — every agent must keep it in sync.
> **Business rules must be documented in every `feat` issue before promotion.**
> Missing business rules found during review = incomplete spec, not a bug.

### Issue Lifecycle

1. PO proposal registered in `.opencode/prioritization.md`
   (project-level) or `~/.config/opencode/prioritization.md`
   (global fallback). **The global file is ONLY for opencode's own improvements
   — never write project proposals there.**
2. Item captured in `known_issues.md` with status `backlog`
3. Refined and approved, QA pre-development review → `ready`
4. PM promotes the issue: auto-creates Remote if missing via
   `scripts/create_issue.sh <id>`, reads `Base branch:` and `Reviewers:` from
   the issue entry, checkouts+pulls the base branch, creates feature branch
   `issue-<id>-<slug>`. Status → `in-progress`.
5. Promotion blocks if `Remote:` is empty or `error:*` after auto-creation.
   Remote was optionally created during discovery (PM asks user); if declined,
   promotion auto-creates silently.
6. Development on branch — Senior review feedback addressed while staying
   `in-progress` → `in-progress`
7. Senior review completed, all issues resolved → `in-review`
8. QA verification:
   - Corrections needed → `in-qa` → `in-progress` (back to development)
   - Approved → `in-qa`
9. Committer gate passed → `in-publish`
10. MR/PR created → `in-publish`
11. MR/PR approved and merged → `in-publish` (PR merged but issue not yet closed)
12. Close Requester closes remote issue and archives → `resolved`

> **Steps 6–11 run automatically without user confirmation after promotion.**
> Step 12 only triggers on merge notification — no polling.

### Branch Naming

Pattern: `issue-<id>-<slug>`

Branches are created from the `Base branch:` field in the issue entry
(defined during discovery) by `promote.sh`.

### Definition of Done

- Base branch correctly chosen and feature branch created from it
- Tests written and passing (run before senior review)
- Acceptance criteria met (verified by Senior Reviewers)
- Business rules documented and implemented correctly
- QA verified after senior review
- Committer gate passed before MR creation
- `known_issues.md` reflects current status at every step
- MR approved and merged
- Remote issue closed

### Pre-commit

- Run tests for the project language
- Warn if `known_issues.md` not updated

### Pull/Merge Request

Must include:
- Tests passing
- Issue reference
- Updated docs
- QA verification confirmed

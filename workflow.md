## Discovery to Issue Flow

The discovery flow transforms raw ideas into tracked, typed issues with
acceptance criteria, business rules, and test definitions. Each agent asks
context-based questions to progressively refine the proposal.

### Mandatory Rule

**Every new feature (`feat` type) MUST go through the full discovery pipeline
before development starts.** Issues promoted without documented business rules
or test standards (`Tests:`) will be blocked by the Committer. Missing business
rules or test scenarios discovered during review are not bugs — they are
incomplete specs and must be refined back through discovery.

### `Tests:` — mandatory test standards (captured during discovery)

`Tests:` is MANDATORY in every new issue entry and MUST be captured during the
discovery phase — never added ad-hoc during development. The value is a list of
`scenario → outcome` lines that define the expected test behavior before any
code is written.

- For `doc`/`chore` types, the literal `- Tests: -` is permitted (no test
  surface).
- For `feat`/`bug` types, at least one `scenario → outcome` line is REQUIRED
  and the value may NEVER be `-`.
- Scenario depth is a FLOOR with no upper bound, by severity: `critical`/`high`
  → ≥3 `scenario → outcome` lines; `medium` → ≥2; `low` → ≥1. If `- Severity:`
  is missing at QA validation time, the medium floor (≥2) applies.
- Enforcement is **verified by QA pre-development review (Phase 5) and senior
  reviewers** — NOT enforced by scripts.
- Missing or insufficient `Tests:` found during senior review or post-review
  QA = `incomplete-spec` (discovery gap), NOT a bug — the issue returns to
  discovery refinement to capture the missing scenarios.
- Applies to ALL new issues going forward; existing in-flight issues are not
  retroactively rewritten.

> Follow-up (not part of any gate): an optional `promote.sh`/lint gate could
> enforce `Tests:` mechanically in the future.

### Discovery Pipeline

The discovery pipeline branches by `- Type:` (BR 1, 12, 13):

- **`bug`** → **lean track** (≤3 phases): PO triage → QA pre-development → PM
  promotion. CTO and Tech Lead are OPTIONAL and invoked ONLY on escalation.
  See "Bug Discovery Pipeline (lean track)" below.
- **`feat`** → the full 6-phase flow below, preserved unchanged.

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
   rules — every business rule must be explicit, not implicit. Drives `Tests:`
   capture (`scenario → outcome` lines) alongside business rules. Records
   `- Base branch:` and `- Reviewers:` in the issue entry.
5. **QA** reviews story for testability, edge cases, and quality criteria —
   verifies that business rules are testable. Validates the `Tests:` field:
   applies the severity floor (≥3 critical/high, ≥2 medium, ≥1 low; medium
   floor when `- Severity:` is missing) and tags `incomplete-spec` when
   `Tests:` is missing or insufficient. Validates that reviewer profiles
   cover all affected domains.
6. **PM** validates dependencies, assigns to sprint, asks the user if they want
   to create the remote issue now (`scripts/create_issue.sh <id>` if confirmed),
   and promotes to `known_issues.md` with status `backlog` or `ready`. If the
   user declines remote creation, the field stays as `-` — it will be
   auto-created during promotion to `in-progress`.

### Bug Discovery Pipeline (lean track)

Bugs are triaged through a lean, token-efficient track (≤3 agent invocations
vs 6 for the full flow — BR 4) that still enforces the quality gates:

1. **PO triage** (primary escalation decider): loads the `bug-triage` skill
   on-demand, scores the bug (Severity + Impact + Frequency + Risk), derives
   `- Priority:` from the score matrix (guard rule applies; the matrix and
   worked examples live ONLY in `skills/development/bug-triage/SKILL.md` —
   single source of truth, BR 11), decides escalation (five triggers: no root
   cause / no reproduction, multi-layer or cross-cutting fix, business-rule
   ambiguity, security involvement, touches architecture/standards — BR 6),
   registers `- Flow: lean`, defines `- Base branch:` and `- Reviewers:`
   (BR 7), and documents business rules when applicable — the literal
   `- Business rules: none` when the bug has none (BR 5).
2. **QA pre-development** (secondary escalation decider): validates the
   `Tests:` severity floor (critical/high ≥3, medium ≥2, low ≥1), accepts the
   literal `- Business rules: none`, REJECTS `-` (placeholder) as
   `incomplete-spec`, validates the derived `- Priority:` against the matrix,
   and may escalate (restart from the CTO) when a trigger surfaces.
3. **PM promotion** (non-interactive): reads `- Base branch:` and
   `- Reviewers:` from the entry; `- Flow:`/`- Priority:` are informative and
   NEVER prompt or block (BR 14).

Escalated bugs MUST restart from the CTO (CTO → Tech Lead → PO#2 → QA → PM)
and MUST set `- Flow: escalated` (BR 6, 10).

### Loop Profiles (bugs and issues do NOT share a flow)

Discovery selects ONE loop from `- Type:` + `- Severity:`. Bugs trade depth
for **speed** but keep a **higher quality bar**; feats keep full depth. Every
loop ends by writing a canonical entry via `scripts/append-issue.sh` and
validating with `scripts/issue-lint.sh --strict` — the QA pre-development agent
is replaced by that lint. PM/remote creation is deferred to promotion.

| Loop | Trigger | Discovery agents | Delivery reviewers | Quality bar |
|------|---------|-----------------|--------------------|-------------|
| `feat-full` | `feat` | PO (rules+`Tests:`) → TL (branch/reviewers) | from TL | full |
| `bug-expedite` | `bug` + `critical`/`high` | PO triage only (lean) | 2 (incl `security` if applicable) | high |
| `bug-lean` | `bug` + `low`/`medium` | PO triage only (lean) | 1 | normal |
| `chore` | `doc`/`chore` | none (script) | 1 | light |

- **Expedite** (critical/high bugs) is the fastest path to code yet mandates 2
  reviewers and `security` when relevant — speed without dropping the bar.
- **Lean** (low/medium bugs) is the minimal path: one PO triage pass, one
  reviewer, lint-strict.

### Aging policy (progressive prioritization)

A medium-priority bug persisting N days in `ready` (N = 7 by default,
configurable — a documented policy value, not a script) MUST be raised to
`- Priority: high` by the PO during triage/backlog review, computed from the
existing `- Ready:`/`- Opened:` timestamps (BR 8). This is a PROCESS rule —
no new scripts; future mechanization is explicitly out of scope. Critical/high
bugs rank above non-critical feats in the backlog.

### Coordination note (#25/#74)

Issues #25 and #74 also touch this shared `workflow.md`. Neither is
in-progress at the time of the differentiated bug-discovery change (#208);
merge-order coordination is required but non-blocking.

### Agent Discovery Questions

Each agent must ask context-based questions during discovery. The PO must
drive the conversation around **business rules** specifically.

- **CTO**: Which architectural principles are affected? Are there known
  trade-offs? How does this align with the long-term technical vision?
- **PO**: Who is the end user? What is the business value? What is the urgency?
  Which criteria define success? **What are the specific business rules? What
  conditions, limits, and exceptions exist?**
- **Tech Lead**: Which layers are affected? Which dependencies exist? Which
  non-functional requirements apply? What is the estimated effort? **Are the
  business rules complete and consistent with the technical model? What is the
  base branch? Which reviewer profiles apply?**
- **QA**: Which test scenarios are needed? Which edge cases exist? How do we
  validate the acceptance criteria? **How do we test each business rule in
  isolation? Do the reviewer profiles cover all domains? Are the `Tests:`
  scenarios testable and do they meet the severity floor?**

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

**Exception — `/ocf:develop-full` (end-to-end) and `/ocf:develop` (up to MR)**:
Both commands drive the pipeline **directly via scripts** — there is no
`delivery` orchestrator agent and no `develop-router` agent in the critical
path. The engine is: `promote.sh` → `preflight.sh` → `detect-lang.sh` picks the
dev agent → developer implements + tests → **senior reviewers run in parallel**
(one `Task` per profile, issued in a single message) → `committer-check.sh` +
`issue-lint.sh --strict` gate → `create-pr.sh` builds the MR →
`merge-and-close.sh` (develop-full only: auto-merge + return to base + archive).
Agents appear only where judgment is needed (developer, reviewers); everything
mechanical is scripted, which is faster and cheaper.

- `/ocf:develop-full`: end-to-end — after the MR, it **auto-merges**, checks out
  the updated base branch, and closes/archives the issue, then sends ONE
  Telegram notification.
- `/ocf:develop`: manual-merge variant — runs the same engine UP TO MR creation
  and STOPS. The MR is left OPEN; the issue stays `in-publish`. Closing/archiving
  is delegated to `ocf:check-pr` / the Close Requester after the user merges
  manually.

The `delivery` agent and `develop-router` are **legacy** (manual-merge
`/ocf:delivery` path only). Loop differentiation (bug vs feat, expedite vs lean)
is defined in § Loop Profiles above and selected during discovery.

### Remote Entry Point: `aibot-watcher` (issue #39)

The `aibot-watcher` systemd timer (`aibot-watcher.timer`, `OnCalendar=*:0/2`)
feeds the continuous pipeline from remote issue comments:

1. A `@aibot:develop` comment on a **locally tracked** issue (`Remote: #<id>`
   in the workspace `known_issues.md`) in an **allowlisted** repo
   (`~/.config/opencode/aibot-repos.json`) triggers the equivalent of
   `/ocf:develop-full <id>`: promote → develop → senior review → QA → corrections →
   committer gate → MR → **auto-merge** → local checkout of the updated base
   branch → remote issue close + archive → final notification.
2. The trigger runs via `opencode run --attach <web-url> --auto --dir <workspace>
--command "ocf:develop-full"` on the existing web server, serialized per repo
   with `flock -n` (parallel across repos).
3. Result messages (success with MR link / already-in-progress /
   already-resolved / not-tracked-locally / cannot-develop) are posted to the
   remote issue by the `development/aibot` subagent via `ocf:aibot-notify`,
   following `standards/aibot-messages.md` — one message per trigger.
4. Security boundary (validated by the security reviewer as a gate):
   repo allowlist (`aibot-repos.json`) + locally-tracked-issue gate +
   pinned qualified model + the global bash deny list (~21 destructive
   patterns: rm -rf, force-push, reset --hard, clean -f, branch -D, mkfs, dd,
   curl|sh, chmod -R 777, chown -R, shutdown/reboot) binding the main/command
   session and every agent WITHOUT its own bash config (`developer`, `devs/*`)
    - agent-level granular bash (`aibot`, `develop-router`: catch-all deny +
      scoped allows + explicit destructive-git denies after `git *: allow`) +
      EDIT denies on security-critical files (opencode.json, aibot-repos.json,
      aibot-watcher.sh, state/**, ~/.ssh/**) ordered so the deny is the LAST
      matching rule (findLast) and therefore wins under `--auto`; `aibot` also
      denies reads of `~/.ssh/**` and `state/**`.

**No-merge-polling boundary**: the watcher itself polls ONLY issue comments.
It never polls merge/PR status. `/ocf:develop-full` (the command the watcher
triggers) performs the merge once review and QA approve, then closes the
remote issue and archives locally as part of its own end-to-end flow —
bounded polling for the merge it initiated is confined to that command, never
to the watcher. The Close Requester and `ocf:check-pr` remain the paths for
closing issues merged through `ocf:delivery` (step 12) or merged manually
after an `ocf:develop` run.

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
6. **Developer** — implement features, write automated tests, run tests via
   `scripts/test-runner.sh` (cache-aware — fresh cache is reused, no cache runs
   and populates), keep `known_issues.md` in sync. Verify the feature branch is
   based on the correct base branch before starting implementation. If business
   rules are missing or unclear, flag the gap as a new issue in `known_issues.md`
   and proceed with what is defined — do not block. **After implementation,
   update status to `in-review` and proceed to senior review without asking the
   user.**
7. **Senior Reviewers** — review code using the count stored in `- Reviewers:`
   in the issue entry (set during discovery), verify acceptance criteria,
   confirm tests were written and pass (via `test-runner --check` — fresh cache
   suffices; only re-run when stale or for a domain-specific test), identify issues.
   The `security` reviewer profile is delegated to the OWASP specialist agent
   (`development/security-owasp`), which refuses approval when critical/high
   vulnerabilities are found (evidence + remediation in
   `.opencode/reviews/security-<target>-<timestamp>.md`).
8. **Quality Analyst (post-review)** — verify quality after senior review,
   check that all identified issues were addressed and quality standards are met
   (confirm tests via `test-runner --check`; do not re-run an unchanged suite)
9. **Developer** — implement all corrections from senior review and QA (loop
   with QA until approved). Re-invoked by PM when status returns to
   `in-progress` from `in-qa`.
10. **Committer** — verify pipeline gates: senior review completed, QA passed,
    business rules documented (for `feat` types), tests passing (satisfied by a
    fresh `test-runner --check` cache or a recent successful run — never re-run
    an unchanged suite). For issues with the `security` reviewer profile, the
    security gate applies: security review approved with no unresolved
    critical/high vulnerabilities — otherwise `in-publish` is NOT set and the
    issue routes back through the review loop (refusal → QA → developer fixes →
    re-review). Sets status to `in-publish` on approval. Reports
    findings without blocking — if a gate fails, document what failed and let
    the pipeline continue to the next cycle.
11. **Publish Requester** — create merge/pull request after Committer gate passes.
    Does not re-validate gates — trusts Committer signal (`Status: in-publish`).
    Does not ask for confirmation — creates the MR automatically.
12. **Close Requester** — does not poll or check automatically. Only acts when
    explicitly triggered by a merge notification. After MR/PR is merged, closes
    the remote issue on GitHub/GitLab, updates `known_issues.md` status to
    `resolved`, and archives to `resolved_issues.md` via `close_issue.sh`.

### Orchestrator Agents

Two meta-agents orchestrate the pipeline phases:

**Discovery Agent** (`agents/development/discovery.md`):

- Orchestrates phases 1-6: PO -> CTO -> Tech Lead -> PO -> QA -> PM
- Transforms raw ideas into tracked issues with complete business rules
- Ensures all required fields (Base branch, Reviewers, Remote) are populated
- Output: issue in `known_issues.md` with status `ready`

**Delivery Agent** (`agents/development/delivery.md`):

- Orchestrates phases 6-12: PM -> Developer -> Senior Review -> QA -> Committer -> Publish -> Close
- Executes automatically without user confirmation after promotion
- Handles the complete lifecycle from feature branch to merged MR
- Post-merge: triggers Close Requester to archive the issue

Use `ocf:discovery` to start the discovery pipeline and `ocf:delivery` to execute the delivery pipeline.

### Career Sector (resume optimization)

Outside the issue pipeline, the `career` sector provides a personal
resume-optimization flow (issue #60):

- `/ocf:cv-hub <candidate-dir>` — build the candidate hub (`hub.json` +
  `README.md`) from a CV PDF (required), official LinkedIn export (Download My
  Data — never scraping), and optional extras. Output lives in
  `~/career/<candidate-name>/`.
- `/ocf:cv-optimize <candidate-dir>` — analyze the candidate profile
  (post-hub): profile score, target job profiles, CLT/PJ salary ranges
  (`[INFERRED]`), context gaps, and a prioritized improvement plan in
  `profile-analysis.md`. Never fabricates; never modifies `hub.json`.
- `/ocf:cv-tailor <candidate-dir> <job>` — analyze a job (multi-portal), gap
  analysis vs `hub.json`, and generate a job-tailored resume PDF (HTML → PDF,
  Chrome headless, fallback LibreOffice) in the job's language. Never
  fabricates content; inferences are resolved with the candidate
  (`inferences.md`) and never appear as `[INFERRED]` in the final HTML/PDF
  (gate: `scripts/cv/check-inferred.sh`).
- **Design standard** — every generated resume MUST follow
  `standards/cv-design.md` (ATS-friendly, A4 print with 12–15mm margins, sober
  grayscale-safe style, page-count by seniority), starting from the reference
  template `skills/career/cv-pdf/templates/resume.html` (never CSS from
  scratch); cv-tailor verifies conformity against the standard's checklist
  before producing the PDF.

Backed by `agents/career/*`, `skills/career/*`, and `scripts/cv/*`.

### Design Pipeline (UI)

Outside the issue pipeline, the `design` sector provides the Adorable
pipeline: `/ocf:build-ui` (greenfield 4-pass: art-director → ui-architect →
ui-implementer → ui-critic) and `/ocf:audit-ui` (audit/refactor:
ui-auditor → ui-refactor-planner, optional build chain). See
`standards/design-pipeline.md` and `agents/design/README.md`.

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

> **Lifecycle timestamps (issue #57/#81):** `- Opened:`, `- Ready:` and
> `- Started:` are stamped directly by the pipeline scripts on the status
> transitions above (`create_issue.sh` stamps `Opened` on remote creation
> success; `promote.sh` stamps `Ready` on backlog→ready and `Started` on
> ready→in-progress, backfilling `Opened` set-if-absent during promotion mode
> 2). `scripts/transition.sh` stamps `- In review:`, `- In QA:` and
> `- In publish:` on the delivery stage transitions (in-progress→in-review→
> in-qa→in-publish) — it is the single status-transition entrypoint the
> delivery agents must call instead of editing `known_issues.md` directly. At
> close time `close_issue.sh` stamps `- Resolved:` (= close date) and computes
> `- Durations:` into the archive (per-stage: backlog/waiting/dev/review/qa/
> publish/total, UTC-anchored parse, DST-robust; `dev` = Started→In review,
> falling back to Started→Resolved for legacy entries without per-stage fields).
> All stamping is set-if-absent and idempotent; it is done by the scripts, NOT
> via commit-trailer parsing (issue #24). See `standards/issues.md` for the
> full field contract.

### Branch Naming

Pattern: `issue-<id>-<slug>`

Branches are created from the `Base branch:` field in the issue entry
(defined during discovery) by `promote.sh`.

### Definition of Done

- Base branch correctly chosen and feature branch created from it
- Tests written and passing (run via `scripts/test-runner.sh` before senior
  review; cache-aware — never re-run an unchanged suite)
- Acceptance criteria met (verified by Senior Reviewers)
- Business rules documented and implemented correctly
- QA verified after senior review
- Committer gate passed before MR creation
- `known_issues.md` reflects current status at every step
- MR approved and merged
- Remote issue closed

### Pre-commit

- Run tests via `scripts/test-runner.sh` (cache-aware fingerprint — identical
  code is never re-tested; delegates environment bootstrap and runner
  detection)
- Warn if `known_issues.md` not updated

### Pull/Merge Request

Must include:

- Tests passing
- Issue reference
- Updated docs
- QA verification confirmed

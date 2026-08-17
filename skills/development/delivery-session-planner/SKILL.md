---
name: delivery-session-planner
description: Plan and generate delivery-session prompts that batch refined (ready) issues into sequential/parallel opencode sessions for any pipeline-tracked repo. Use when the user wants to accelerate delivery, batch-develop multiple known_issues, create a delivery prompt, split work across sessions to save tokens, or order issues by effort and git-conflict safety.
---

# Delivery Session Planner

Response language: user's input language → `.opencode/locale` (project → global) → EN.

Creates session prompts to deliver the `ready` issues from `known_issues.md`
in batches, prioritizing the easiest/fastest, parallelizing when safe and
splitting the work into **several small sessions** (not one giant session) to
save context/tokens.

## Input

- The project (default: current workspace) — the `known_issues.md` lives in
  `<project>/.opencode/known_issues.md`.
- User priority rules (e.g. "backend only", "docs only", "max Xh per
  session"). If not given, use the defaults below.

## Step 1 — Collect eligible issues

1. Read `known_issues.md` and list every issue with `- Status: ready`.
2. For each one, extract from the record:
   - `ID`, `Type`, `Severity`
   - `Location:` (real paths — used to detect git conflicts)
   - `Dependencies:` / sequencing notes
   - Estimated effort in the `Suggested fix:` (pattern `~Nh`, `~N-Mh`, or a
     breakdown like `schema ~4h; APIs ~6h`)
   - `Reviewers:`, `Tests:` (confirm the issue is refined)
3. **Exclude** `backlog` issues (unless explicitly refined and `ready`),
   `in-publish`/`resolved`/`in-progress` and `incomplete-spec`.

## Step 2 — Classify by effort

| Range | Label | Example |
|-------|--------|---------|
| ≤ 2h | `quick` | 1h chore/docs |
| 3–8h | `small` | isolated frontend feature, 6h doc |
| 9–15h | `medium` | backend with 1 complex endpoint |
| 16h+ | `large` | schema migration, gateway integration |

Order each range by increasing effort.

## Step 3 — Detect git conflicts (critical)

Rules that determine what can NOT run in parallel:

1. **Same files in `Location:`** → never parallel (e.g. two issues editing
   `business-form.tsx` or `messages/*.json`). Sequence them.
2. **`prisma/schema.prisma` / migrations** → never parallel; migrations must
   be sequential (e.g. `#88` 1st migration → `#89` 2nd).
3. **`src/middleware.ts`** → auth contention point (e.g. `#89` and `#90`
   both edit it) → never parallel.
4. **`next.config.js`, `vercel.json`, `package.json`** → global points;
   parallelize only when the changes are in distinct, non-overlapping blocks.
5. **Data/schema dependency** (issue B "depends on #A's merge") → B runs
   after A is delivered.
6. **Crons** (vercel.json) → if two issues add crons they may coexist but
   require consolidation; document it as a merge prerequisite.

Mark each pair (A,B) as `PARALLEL-OK` or `CONFLICT` with the reason.

## Step 4 — Group into phases and sessions

**Phase 1 — Quick wins** (fast + small, independent):
- Parallelizable among themselves if `PARALLEL-OK`.
- Each can be **its own session** (short prompt, autonomous execution).

**Phase 2 — Large ones** (medium + large):
- Sequence by dependency and file conflict.
- One `large` issue alone per session (do not mix with other large ones in
  the same session).

**Session size rule (token economy):**
- **1 session = 1 issue**, unless 2+ issues are `quick`/`small` **and**
  `PARALLEL-OK` and together ≤ ~8h → then they can go in the same session in
  sequence.
- Never put a `large` issue + another `large` issue in the same session.
- If the user wants real parallelism: generate **N separate prompts** (one
  per session/issue) instead of one giant prompt.
- Goal: each session with self-contained context (the prompt embeds the issue
  record) so it does not depend on shared global context.

## Step 5 — Generate the prompts

For each session, create a file in `<project>/docs/delivery-prompts/`:
`delivery-<YYYYMMDD>-session-<n>.md` (or whatever pattern the project uses).
The prompt MUST contain:

1. **Role**: "You run the delivery pipeline (promote → develop →
   senior review → QA → committer gate → MR) for issue(s) X".
2. **Command**: `/ocf:delivery <id>` or `ocf:develop <id>` — continuous
   pipeline, no pause between phases.
3. **Embedded record**: copy the issue block from `known_issues.md`
   (Location, Business rules, AC, Tests, Reviewers, Base branch) so the
   session is self-contained.
4. **Delivery instructions**:
   - `Remote: -` → auto-created at promotion; do not ask.
   - Stop when the MR is created (`Status: in-publish`, `PR: #n`); do NOT run
     the Close Requester.
   - Order of the issues within the session (if >1).
   - Known conflicts with other parallel sessions (e.g. "do not touch
     middleware.ts — another session is editing it").
5. **Parallelism note**: if other sessions are running in parallel, list the
   files this session must NOT touch.

## Final output

- List of generated sessions: per session → issues, effort range, files
  touched, conflicts avoided.
- Recommended execution order (Phase 1 parallel first, Phase 2 sequential
  after).
- Context-economy estimate: `N small sessions vs 1 giant one`.
- If the user asks, also save a `README` in the prompts folder listing all
  sessions and their status (pending/in progress/completed).

## Quality reminder

- Always justify `PARALLEL-OK` vs `CONFLICT` with real file paths (never
  just "no").
- Effort comes from the issue's `Suggested fix:`/breakdown — never invent.
- `incomplete-spec` issues do not enter the batch.
- At the end, suggest a `telegram-notifier` notification summarizing the
  sessions created.

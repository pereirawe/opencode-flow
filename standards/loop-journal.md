# Loop Error Journal

Every discovery and delivery loop records its errors in a **structured journal**
so that failures become tracked work instead of dying in ad-hoc logs. At the end
of each loop the `development/loop-error-reviewer` agent reads the journal and
files canonical `bug` issues in the correct tracker (opencode global or the
target project). See `workflow.md` § Loop Error Review and issue #244.

## Journal file

- Location: `<workspace>/.opencode/loop-journal/` (git-ignored).
- One file per loop: `loop-<loop>-<id>.jsonl` (one JSON object per line).
- Overrides: `OCF_LOOP_JOURNAL_DIR` (directory) or `--journal <file>` (exact
  file) for callers that run outside the workspace cwd.
- Written only by `scripts/loop-journal.sh` (`append`); never hand-edited in
  normal operation.

## Event schema

One JSON object per line, keys in stable order:

| key | type | meaning |
|-----|------|---------|
| `ts` | string | UTC ISO-8601 timestamp (`2026-10-09T14:03:00Z`) |
| `loop` | string | loop label: `discovery`, `develop`, `develop-full`, `aibot-develop`, `batch` |
| `id` | string | issue id processed by the loop (or `batch`) |
| `phase` | string | pipeline phase where it failed (e.g. `discovery`, `review`, `merge`) |
| `severity` | string | `low` \| `medium` \| `high` \| `critical` |
| `scope` | string | `global`, `project`, or empty (let the router classify) |
| `location` | string | `file:line` or logical location of the failure |
| `command` | string | command that was running |
| `exit_code` | string | exit code, if any |
| `message` | string | human-readable error description |

Example:

```json
{"ts":"2026-10-09T14:03:00Z","loop":"develop","id":"244","phase":"committer","severity":"high","scope":"global","location":"scripts/committer-check.sh:88","command":"scripts/committer-check.sh 244","exit_code":"2","message":"committer gate FAIL: tests missing"}
```

## Usage

```bash
# record an event
scripts/loop-journal.sh append --loop develop --id 244 --phase review \
  --severity high --location "scripts/example.sh:10" --command "scripts/example.sh" \
  --exit-code 1 --message "unexpected failure"

# inspect
scripts/loop-journal.sh list --loop develop --id 244            # JSONL
scripts/loop-journal.sh list --loop develop --id 244 --format md # table
scripts/loop-journal.sh path --loop develop --id 244             # file path
scripts/loop-journal.sh clear --loop develop --id 244            # truncate
```

## Triage & routing

`scripts/loop-error-triage.sh` turns journals into a plan and (optionally) into
issues:

```bash
scripts/loop-error-triage.sh --plan --loop develop     # digest + proposals TSV
scripts/loop-error-triage.sh --apply --loop develop    # file the bugs
scripts/loop-error-triage.sh --apply --from <proposals.tsv>   # agent-reviewed plan
```

The reviewer agent runs `--plan`, edits the proposals TSV (drop noise, fix
scope/severity, merge duplicates), then runs `--apply --from`. Errors below
`--min-severity` (default `medium`) are ignored. An error already represented in
the target tracker (same `Location`) is reported as `already filed` and skipped
— the pass is idempotent.

### Global vs project rubric

Classify by **where the fix belongs**, i.e. the file that must change:

- **global** → `~/.config/opencode/known_issues.md`: opencode config/tooling —
  `scripts/`, `agents/`, `commands/`, `skills/`, `standards/`, `workflow.md`,
  `AGENTS.md`, `opencode.json`, `Makefile`.
- **project** → `<workspace>/.opencode/known_issues.md` (fallback
  `<workspace>/known_issues.md`): the workspace where the loop ran (its code,
  config, tests, project-level skills/docs).

The router auto-classifies: an absolute path under the opencode config tree is
always `global`; bare relative config paths (`scripts/...`) are global only when
the loop itself ran inside the config repo — inside a target project those same
paths are `project` code. When uncertain, the reviewer agent decides.

## Rules

- **Non-blocking:** the review never changes the reviewed issue's status and
  never fails the loop if it errors. It is best-effort.
- **No fabrication:** only errors present in a journal become issues.
- **Idempotent:** re-running `--apply` creates no duplicates (dedup by
  `Location`).
- **Single notification:** the top-level command owns the one Telegram message;
  the reviewer agent never notifies.

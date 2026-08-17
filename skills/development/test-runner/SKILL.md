---
name: test-runner
description: Single test entry point with a result cache (fingerprint) for development agents. Use when you need to validate tests (check/run/status), consume a fresh cache without re-executing, or run the suite for your own use when there is no cache. Never invoke ad hoc test commands (go test, pytest, npm test) — use this runner.
---

# Test Runner

Response language: user's input language → `.opencode/locale` (project → global) → EN.

Single test entry point for development agents. Eliminates repeated
executions of the same suite with identical output along the pipeline and
standardizes environment diagnostics.

## Protocol

```bash
scripts/test-runner.sh --check    # fresh cache? exit 0 + report path; otherwise exit 3
scripts/test-runner.sh --run      # runs the suite (or reuses a fresh cache), prints summary + exit code
scripts/test-runner.sh --status   # readable runner/cache/fingerprint state
```

Additional args after `--` are passed to the test command
(e.g. `test-runner.sh --run -- -run TestFoo`).

## Rules for the agent

1. **Always use the runner** — never `go test`, `pytest`, `npm test` ad hoc.
2. **Fresh passing cache → reuse it.** `--check` with exit 0 means the code
   has not changed since the last run **and** the suite passed: use the
   cached report, do not re-run.
3. **No valid cache → run for your own use.** `--check` exit 3 is not a
   block: run `--run` and use the result for your validation.
4. **Cache never blocks.** If the script fails for any reason, run the tests
   directly and proceed with the result.
5. **Domain-specific spot tests** (e.g. one specific test you want to check)
   are free — use `--run -- <filter>`. Filtered runs NEVER touch the shared
   cache: they actually execute and do not affect the "suite passed" signal
   that check/committer/pre_commit consume.
6. **Exit codes** of `--run`: `0` = suite passed; `1` = suite failed; `2` =
   cannot run (no runner/suite) — treat `2` as "no tests", not as a failure.
   The full report is in `.opencode/test-cache/<branch>-<runner>.log`.
7. **`--check`** exits 0 only when there is a fresh cache AND the last run
   passed (`exit_code=0`). A fresh cache from a failed suite → exit 3.

## Where the cache lives

```
.opencode/test-cache/<branch>-<runner>.result   # fingerprint + exit_code + timestamp
.opencode/test-cache/<branch>-<runner>.log      # full output of the last run
```

The `.opencode/test-cache/` directory is gitignored. The fingerprint is derived
from the git HEAD + changed code/test files — any minimal change invalidates
the cache and forces re-execution.

## Fallback

Without a git repo, the runner uses a content-based fingerprint (still
functional). Without a detected runner, the runner diagnoses clearly and the
agent should run the project tests directly, reporting the result for its own
use.

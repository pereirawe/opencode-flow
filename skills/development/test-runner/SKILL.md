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
scripts/test-runner.sh --check    # fresh cache? exit 0 + report path; otherwise exit 3;
                                  # exit 0 (no-op) when there is no test surface (issue #239)
scripts/test-runner.sh --run      # runs the suite (or reuses a fresh cache), prints summary + exit code;
                                  # exit 0 (no-op) when there is no test surface (issue #239)
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
   cannot run (runner detected but the test tool is missing, e.g. pytest not
   installed) — treat `2` as "no tests", not as a failure. **No test surface**
   (no runner detected, or `package.json` without a `test` script) is a
   **no-op**: `--run` and `--check` both exit `0` with a
   `no test surface` message — nothing to run, never a gate failure (issue
   #239). The full report is in `.opencode/test-cache/<branch>-<runner>.log`.
7. **`--check`** exits 0 only when there is a fresh cache AND the last run
   passed (`exit_code=0`), or when there is no test surface (no-op, issue
   #239). A fresh cache from a failed suite → exit 3.
8. **Report the environment version.** Every test report MUST include a
   `Version:` field sourced from `--status` (or the `.result` metadata), so
   later pipeline stages never re-ask which version ran the suite.

## Versioned test environment (issue #210)

The runner verifies the runtime against `.opencode/env-manifest.md`:

- **Pins**: `.nvmrc` / `.node-version` pin Node (e.g. `22`); the supported
  **ranges** live in the manifest strict section (`node: >=20 <23`,
  `python: >=3.10 <4`, `test-runner: >=1.0`).
- **Warnings** (`[test-env] WARNING:` on stderr) are emitted in `--status`
  and `--run` — **never in `--check`** (`--check` stderr stays empty even
  desynced). They are actionable: current version + expected range + install
  hint.
- **Warning-only**: environment checks never change exit codes `0/1/2/3`;
  `--status` always exits 0. A missing `node`/`python3` or a missing/malformed
  manifest produces an informative warning, never a failure. The no-test-surface
  no-op (exit 0, issue #239) is the ONLY exit-code change from the environment/
  detection layer.
- **Sync guard**: `.nvmrc` ↔ `.node-version` ↔ manifest pin mismatches emit a
  consistency warning (pin must satisfy `pin ⊆ range`).
- **Drift**: cached `.result` versions ≠ current environment → drift warning
  in `--status`, non-blocking.
- `.nvmrc`, `.node-version` and `.opencode/env-manifest.md` are **excluded
  from the fingerprint** — environment metadata edits never invalidate the
  cache.

See `standards/test-env.md` (localized `standards/{pt,es}/test-env.md`) for the
full protocol.

## Where the cache lives

```
.opencode/test-cache/<branch>-<runner>.result   # fingerprint + exit_code + timestamp + version metadata
.opencode/test-cache/<branch>-<runner>.log      # full output of the last run
```

The `.result` file records the versions actually used:

```text
fingerprint=...
exit_code=...
timestamp=...
output=...
node_version=v22.3.1
python_version=3.12.0
runner_version=1.0.0
```

The `.opencode/test-cache/` directory is gitignored. The fingerprint is derived
from the git HEAD + changed code/test files — any minimal change invalidates
the cache and forces re-execution.

## Fallback

Without a git repo, the runner uses a content-based fingerprint (still
functional). Without a detected runner (no test surface), the runner no-ops
with a `no test surface` message and exit 0 (issue #239) — there is nothing to
run; the agent reports the no-op instead of a test result.

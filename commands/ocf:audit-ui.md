## /ocf:audit-ui

---
description: Orchestrate the audit/refactor pipeline for existing codebases (ui-auditor → ui-refactor-planner, optionally → build pipeline)
---

Audit an **existing** codebase and plan its UI refactor through two passes
that consume and produce structured JSON, with an optional third pass that
chains into the greenfield build pipeline (`/ocf:build-ui`) to implement the
refactor.

### Usage

```
/ocf:audit-ui [project-path] [session-id]
```

| Argument | Description |
|----------|-------------|
| `<project-path>` | Project to audit (default: current working directory) |
| `<session-id>` | Existing session id (`YYYY-MM-DDTHH-MM-SS`) — resumes the pipeline from the first missing stage |

### Examples

```
/ocf:audit-ui
/ocf:audit-ui /home/user/dev/my-app
/ocf:audit-ui /home/user/dev/my-app 2026-08-17T14-30-00
```

### Pipeline passes

| Pass | Agent | Input | Output |
|------|-------|-------|--------|
| 1 | `ui-auditor` | Project path | `<dir>/audit_report.json` |
| 2 | `ui-refactor-planner` | `<dir>/audit_report.json` (+ design spec) | `<dir>/refactor_plan.json` |
| 3 (optional) | `ui-architect` → `ui-implementer` → `ui-critic` | `refactor_plan.json` + `design_spec.json` | Production code + `<dir>/quality_report.json` |

1. **Pass 1 — `ui-auditor`**: detects the stack via bash (`REACT_VITE`,
   `NEXTJS_APP`, `VUE_VITE`, `PHP_BLADE`, `PHP_HTML`, `HTML_VANILLA`, etc.),
   scores dimensions 1–5, cites `file:line` for every issue, and records
   preserved patterns. Never writes or edits code.
2. **Pass 2 — `ui-refactor-planner`**: consumes `<dir>/audit_report.json`
   and, when available, the design spec
   (`.opencode/design-outputs/<session-id>/design_spec.json` from a prior
   `/ocf:build-ui` run) — produces `<dir>/refactor_plan.json`: a phased plan
   (Group A blockers, Group B inline, Group C opportunities). Never plans a
   big bang and never deletes before replacing.
3. **Optional Pass 3**: if the user also wants the refactored UI implemented,
   the command continues into the build pipeline (`ui-architect` →
   `ui-implementer` → `ui-critic`), reusing the same session id and output
   files — same conventions as `/ocf:build-ui`.

### Session and output conventions

A session id (UTC timestamp `YYYY-MM-DDTHH-MM-SS`) and an output directory
`.opencode/design-outputs/<session-id>/` are created at command start. All
stage outputs land in that directory. See `standards/design-pipeline.md` for
the full output conventions and session protocol.

### Failure handling

On ANY stage failure the command logs the failure, sends a Telegram
notification (via the `telegram-notifier` skill /
`scripts/telegram-notify.sh`), and **STOPS** — it does not continue to the
next stage.

### Resumption

Re-running the command with the same session id skips stages whose output
files already exist and continues from the first missing stage.

### Model

No model is hardcoded for any stage — subagents use the user's default model
(see issue #82).

### Response language

The command responds in the user's input language (locale rule, issue #73).

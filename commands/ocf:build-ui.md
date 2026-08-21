## /ocf:build-ui

---
description: Orchestrate the 4-pass greenfield design pipeline (art-director → ui-architect → ui-implementer → ui-critic) with deterministic output files
---

Turn a design brief into production UI through the **Adorable pipeline**: four
passes that each consume and produce structured JSON, chained end-to-end with
no ambiguous text between agents. The pipeline is greenfield-only — for
existing codebases use `/ocf:audit-ui`.

### Usage

```
/ocf:build-ui <brief|file-path|session-id>
```

The argument is a design brief — either inline text or a path to a file
containing the brief. When the argument matches a session id (UTC timestamp
format `YYYY-MM-DDTHH-MM-SS`, e.g. `2026-08-17T14-30-00`), the command treats
it as a **resumption session id** instead of a new brief.

| Argument | Description |
|----------|-------------|
| `<brief>` | Design brief as inline text (required if not resuming) |
| `<file-path>` | Path to a file containing the design brief (required if not resuming) |
| `<session-id>` | Existing session id (`YYYY-MM-DDTHH-MM-SS`) — resumes the pipeline from the first missing stage |

If no argument is provided, the command asks the user for a brief.

### Examples

```
/ocf:build-ui "A landing page for a boutique coffee roaster, warm and editorial"
/ocf:build-ui briefs/coffee-roaster.md
/ocf:build-ui 2026-08-17T14-30-00
```

### Pipeline passes

| Pass | Agent | Input | Output |
|------|-------|-------|--------|
| 1 | `design/art-director` | Design brief | `<dir>/design_spec.json` |
| 2 | `design/ui-architect` | `<dir>/design_spec.json` | `<dir>/component_tree.json` |
| 3 | `design/ui-implementer` | `<dir>/design_spec.json` + `<dir>/component_tree.json` + project root | Production code |
| 4 | `design/ui-critic` | Implemented code + `<dir>/design_spec.json` + `<dir>/component_tree.json` | `<dir>/quality_report.json` |

`<dir>` = `.opencode/design-outputs/<session-id>/`.

1. **Pass 1 — `design/art-director`**: produces the design spec JSON
   (`brief_analysis`, `rejected_defaults`, `directions_considered`,
   `selected_direction`, `design_spec`). Never writes code.
2. **Pass 2 — `design/ui-architect`**: produces the component tree JSON
   (`layout_regions`, `component_tree`, `components`, `interaction_map`,
   `build_order`). Never writes code.
3. **Pass 3 — `design/ui-implementer`**: writes production code in the project
   following the build order; it never skips defined states.
4. **Pass 4 — `design/ui-critic`**: quality gate — returns `APPROVED` or
   `ISSUES_FOUND` with component-specific findings. If `ISSUES_FOUND` with
   blocking items, the feedback is fed back to the `design/ui-implementer`
   (iterate, max 3 rounds). If still `ISSUES_FOUND` after 3 rounds, the
   command stops, logs the failure, sends a Telegram notification, and
   delivers with the remaining findings listed in the summary.

### Session and output conventions

A session id (UTC timestamp `YYYY-MM-DDTHH-MM-SS`) and an output directory
`.opencode/design-outputs/<session-id>/` are created at command start. All
stage outputs land in that directory. On resumption the existing session id
and its output directory are REUSED as-is — a new session id/directory is
created only on the first run, never on a resume run. See
`standards/design-pipeline.md` for the full output conventions and session
protocol.

### Failure handling

On ANY stage failure the command logs the failure, sends a Telegram
notification (via the `telegram-notifier` skill /
`scripts/telegram-notify.sh`), and **STOPS** — it does not continue to the
next stage.

### Resumption

Re-running the command with the same session id
(e.g. `/ocf:build-ui <session-id>`) REUSES the same session id and its output
directory — never creating a new one — and skips stages whose output files
already exist, continuing from the first missing stage.

### Model

No model is hardcoded for any stage — subagents use the user's default model
(see issue #82).

### Response language

The command responds in the user's input language (locale rule, issue #73).

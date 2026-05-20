# OpenCode Project Configuration

Generic, language-agnostic configuration for AI-assisted development workflow.
This config lives in `~/.config/opencode/` and is automatically loaded by OpenCode as the **global config**.

## Structure

| Path | Purpose |
|------|---------|
| `AGENTS.md` | Entrypoint instructions |
| `opencode.json` | OpenCode configuration |
| `workflow.md` | Development workflow pipeline |
| `known_issues.md` | Tracked work register |
| `architecture.md` | Technical vision and structural decisions |
| `conventions.md` | Development conventions and best practices |
| `decisions.md` | Architecture decision records |
| `agents/` | Subagent definitions (CTO, PO, Dev, Committer, etc.) |
| `commands/` | Slash command documentation |
| `skills/` | Reusable skills (issue-manager) |
| `scripts/` | Shell helpers for issue lifecycle |
| `standards/` | Development patterns (branching, commits, PR) |
| `.opencode/` | Project bootstrap template (copy to other projects) |
| `wip/` | Planning artifacts |
| `.vscode/` | Editor settings |
| `Makefile` | Convenience targets |

## Usage

```
make scan-issues
make review
make promote id=<n>
make close-issue id=<n>
make bootstrap target=<path>
```

## Bootstrap a New Project

```
make bootstrap target=../my-project
```

This copies `.opencode/` template into the target project root.
See `.opencode/README.md` for details.

See individual directories for details.

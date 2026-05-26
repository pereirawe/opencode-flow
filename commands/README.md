# Slash Commands

These commands are available in the assistant. Each file documents a slash command's behavior.

| Command | Purpose |
|---------|---------|
| `ocf:init` | Initialize `.opencode/` project config with repo context |
| `ocf:scan-issues` | Deep codebase analysis; detect and register new issues |
| `ocf:review-branch` | Full PR/MR-style code review |
| `ocf:plan-feature` | Feature breakdown with risk assessment |
| `ocf:promote <id>` | Promote backlog item to open + create remote issue |
| `ocf:commit` | Create structured commit with `Status:` trailers |
| `ocf:sync-issues` | Sync known_issues with remote issue tracker |
| `ocf:archive-issue <id>` | Archive resolved issue to compact format |
| `ocf:maintain` | Full maintenance of known_issues.md |
| `ocf:backup` | Create intelligent timestamped backup excluding junk |

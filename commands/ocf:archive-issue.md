## /ocf:archive-issue <id>

---
description: Move a resolved issue to the resolved archive
---

Archive a resolved issue from `known_issues.md` to `resolved_issues.md` in compact format.

The working directory (`$PWD`) determines the target project.

### Flow

1. Issue must be `Status: resolved` (use `ocf:close-issue` first or edit status)
2. Script extracts compact fields: title, type, reported-by, remote, severity, summary
3. Entry is removed from `known_issues.md`
4. Entry is prepended to `resolved_issues.md` (newest first)
5. See `standards/resolved-issue.md` for the archive format

### Usage

```
/ocf:archive-issue 5
```

### Direct invocation

```bash
$SCRIPTS_DIR/close_issue.sh <id>
```

The `close_issue.sh` script handles both closing and archiving in one step.

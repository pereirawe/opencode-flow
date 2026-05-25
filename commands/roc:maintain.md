## /roc:maintain

---
description: Maintain known_issues.md — sync, archive, clean
---

Full maintenance of the tracker file `known_issues.md`.

### Flow

1. **Run `maintain.sh`** — detects remote states, reports stale issues
2. **Archive stale resolved issues** — for each remote-closed issue, run `close_issue.sh <id>`
3. **Reindex if needed** — renumber remaining issues in `known_issues.md`
4. **Report** — summarize what was archived, updated, and skipped

### Detailed steps

#### 1. Check remote states

```bash
$SCRIPTS_DIR/maintain.sh
```

Output:
- Issues with `Remote: #<id>` → checks if remote is open/closed
- Issues with `Remote: -` → local-only, skip
- Reports mismatches (local says `in-progress` but remote is closed)

#### 2. Archive resolved

For issues where remote is closed but local is still `in-progress`:

```bash
$SCRIPTS_DIR/close_issue.sh <id>
```

This:
- Closes remote issue (already closed, will no-op)
- Archives to `resolved_issues.md` in compact format
- Removes from `known_issues.md`

#### 3. Reindex

After removals, renumber issues sequentially:

```bash
awk '/^### [0-9]+\./{count++; sub(/^### [0-9]+/, \"### \" count)} 1' known_issues.md > tmp && mv tmp known_issues.md
```

#### 4. Report

Output a summary:
```
[maintain] Known issues: 4 active, 1 archived, 0 stale
```

### Automation notes

- `maintain.sh` is safe to run independently — it only reads remote state and reports, never modifies files
- Actual archiving requires the assistant to run `close_issue.sh` after reviewing the report
- `standards/prioritization.md` proposals should be checked separately for items ready to promote

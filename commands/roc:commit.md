## /roc:commit

---
description: Create a commit with automatic status flags
---

Create a structured commit with automatic status trailers that sync with
`known_issues.md` and remote issue trackers.

The working directory (`$PWD`) determines the target project.

### Format

```
<type>: <short description> (#<issue-id>)

<body (optional)>

Status: <in-progress | resolved>
```

### Trailer flags

| Trailer | Effect |
|---------|--------|
| `Status: in-progress` | Updates `known_issues.md` issue status to `in-progress` |
| `Status: resolved` | Updates `known_issues.md` to `resolved` + closes remote issue |
| `Remote: #<id>` | Sets the remote issue reference |

### Usage

```
/roc:commit
```

The assistant will:
1. Ask for the commit type, description, and issue ID
2. Detect the project's `known_issues.md`
3. Optionally detect remote context from `git remote` / AGENTS.md
4. Construct the commit with trailers
5. Run `git commit` with the proper message
6. Update `known_issues.md` status based on trailers

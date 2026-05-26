## /ocf:plan-feature

---
description: Feature planning with risk assessment
---

Break down a feature into steps and register planned work.

The working directory (`$PWD`) determines the target project. All paths are
relative to the project root, **not** to the global opencode config.

Responsibilities:
- Break down feature into steps
- Identify impacted layers
- Register risks and planned work in `$PWD/.opencode/known_issues.md` (project issue tracker)
- Add new entries with `Status: backlog` and the proper `Type`
- Follow the issue entry format from `standards/issues.md`

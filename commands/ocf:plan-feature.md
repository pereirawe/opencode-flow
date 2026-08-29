## /ocf:plan-feature

---
description: Alias of /ocf:discovery for feature planning — registers a planned feature as a linted, tracked issue
---

`/ocf:plan-feature` is now an alias of `/ocf:discovery`. Feature planning goes
through the same discovery loop (`feat-full`): PO captures business rules +
`Tests:`, TL sets branch + reviewers, and the issue is written canonically and
linted before it reaches delivery.

Use:

```
/ocf:plan-feature "Add CSV export to reports"
```

which is equivalent to:

```
/ocf:discovery "Add CSV export to reports"
```

The working directory (`$PWD`) determines the target project. All paths are
relative to the project root. After planning, deliver with
`/ocf:develop-full <id>`.

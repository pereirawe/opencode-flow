---
description: Author a rigorous technical specification for a project. Delegates to the business-ops/spec-writer agent, which bootstraps the workspace, runs structured discovery, invokes C-level experts as needed, and produces docs/specs/<slug>/tech-spec.md with an embedded company logo.
agent: business-ops/spec-writer
---

## /ocf:tech-spec

Create or refine a technical specification.

Usage:

```
/ocf:tech-spec <slug> [initial scope description]
```

Examples:

```
/ocf:tech-spec dia-educacao-2026
/ocf:tech-spec loyalty-program "B2C loyalty program with points and tiers"
```

## What happens

1. The `business-ops/spec-writer` agent bootstraps
   `docs/specs/<slug>/` via `scripts/spec-init.sh`, copying the company
   logo from `docs/assets/` or `~/.config/opencode/assets/`.
2. It runs structured discovery across the 12 spec dimensions defined in
   the `tech-spec` skill, asking the user targeted questions in batches.
3. It invokes C-level agents (`cto`, `cmo`, `cfo`, `coo`) in parallel when
   the domain requires senior judgment, and records every consultation in
   the spec's Sign-off section.
4. It drafts the spec following the canonical structure, runs the quality
   checklist, and asks for explicit user sign-off before saving.
5. Output: `docs/specs/<slug>/tech-spec.md`.

## Next step

After approval:

```
/ocf:proposal <slug>
```

to generate the commercial proposal from the approved spec.

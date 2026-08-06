## /ocf:import-skill <git-url|owner/repo>

---
description: Import external skills as git clones via skill-vendor.sh
---

Import an external skill (or a repo containing several skills) using the
**vendor clone strategy** — the upstream repo is cloned into
`~/.config/opencode/vendor/` and loaded in-place via `skills.paths`, so it can
be updated with `git pull` and never diverges from upstream. Skills are never
copied into `skills/`.

### Flow

1. Ask the user for the source: a git URL (`https://github.com/owner/repo`)
   or `owner/repo` shorthand.
2. If the repo contains multiple skills and the user only wants specific ones,
   ask which folders to check out as sparse paths (e.g.
   `skills/taste-skill skills/redesign-skill skills/minimalist-skill`).
3. Run `scripts/skill-vendor.sh add <url> [--sparse <paths...>]`, which:
   - clones the repo into `~/.config/opencode/vendor/<name>`,
   - discovers every `SKILL.md` frontmatter `name` inside the clone,
   - registers each discovered skill as `allow` in `permission.skill`
     (atomic write to `opencode.json`).
4. Report the installed path and discovered skill names.
5. Remind the user to restart opencode for the skills to appear.

### Maintenance

```bash
scripts/skill-vendor.sh add <git-url|owner/repo> [--sparse <paths...>]
scripts/skill-vendor.sh update <name>   # git pull — no re-import
scripts/skill-vendor.sh list
scripts/skill-vendor.sh remove <name>   # also unregisters its skills
```

### Usage

```
/ocf:import-skill meodai/skill.color-expert
/ocf:import-skill Leonxlnx/taste-skill --sparse skills/taste-skill skills/redesign-skill skills/minimalist-skill
```

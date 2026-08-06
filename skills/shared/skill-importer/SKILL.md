---
name: skill-importer
description: Import external skills (GitHub/GitLab) into opencode as git clones. Clones the repo into ~/.config/opencode/vendor/ and registers each discovered skill in opencode.json — never copies SKILL.md files into skills/. Use when importing skills from a repository URL, owner/repo shorthand, or when asked to install a third-party skill.
compatibility: opencode
---

## What I do

Import an external skill (or a repo containing several skills) into opencode
using the **vendor clone strategy** — the upstream repo is cloned in-place and
loaded via `skills.paths`, so it can be updated with `git pull` and never
diverges from upstream.

## Why clone instead of copy

- Upstream content stays in its own git repo — update with `git pull`, no re-import.
- No divergence: the skill is always the upstream version, never a stale copy.
- Skills are loaded recursively via `skills.paths` (`**/SKILL.md` scan).
- Third-party content stays out of the config repo (vendor/ is gitignored).

## Workflow

1. **Ask the user** for the source: a git URL (`https://github.com/owner/repo`)
   or `owner/repo` shorthand. If they mention multiple repos, repeat per repo.
2. **Determine sparse paths** (optional): if the repo contains many skills and
   the user only wants specific ones, ask which folders (relative to the repo
   root) contain the desired skills, e.g. `skills/taste-skill
   skills/redesign-skill`.
3. **Run** `scripts/skill-vendor.sh add <url> [--sparse <paths...>]` to:
   - Clone the repo into `~/.config/opencode/vendor/<name>`
   - Discover every `SKILL.md` with a frontmatter `name` inside the clone
   - Register each discovered skill as `"<name>": "allow"` in
     `opencode.json` under `permission.skill` (atomic write)
4. **Report** the installed path, the discovered skill names, and tell the
   user to start a new session (or restart the opencode web service) for the
   skills to appear in `available_skills`.

## Helper script

```bash
# full clone (single-skill repos)
scripts/skill-vendor.sh add meodai/skill.color-expert

# sparse clone (multi-skill repos — only desired folders checked out)
scripts/skill-vendor.sh add Leonxlnx/taste-skill --sparse skills/taste-skill skills/redesign-skill skills/minimalist-skill

# refresh a vendored repo
scripts/skill-vendor.sh update taste-skill

# list vendored repos and their skills
scripts/skill-vendor.sh list

# remove a vendored repo (and unregister its skills)
scripts/skill-vendor.sh remove taste-skill
```

## Rules

- NEVER copy SKILL.md files into `skills/` — use the vendor clone strategy.
- Never modify vendored content in place; upstream changes arrive via `git pull`.
- Register skills via `skill-vendor.sh add` (which handles `permission.skill`).
- Keep `vendor/` out of the config repo (already in `.gitignore`).
- After any change, remind the user to restart opencode for skills to load.

# Formatting

Run the project's formatter before committing so the code/changelog always
enters the repository formatted, without per-project discipline or manual
configuration.

Issue: #246.

## `scripts/format.sh`

`scripts/format.sh` detects the project's formatter, runs it on the selected
files, and degrades gracefully when no formatter binary is installed.

```
scripts/format.sh [--staged | --all | --diff <range>] [--check]
```

| Flag | Meaning |
|------|---------|
| `--staged` | Format only staged files (`git diff --cached --diff-filter=ACMR`). Default. |
| `--all` | Format every tracked file (`git ls-files`). |
| `--diff <range>` | Format files changed in a git range, e.g. `main...HEAD`. |
| `--check` | Do not write; exit non-zero when formatting changes are needed. |

Exit codes: `0` success or graceful skip; `1` `--check` found pending changes;
`3` usage error.

## Detection

Detection is per file group; every group whose binary is available runs (and
whose project opt-in, for Prettier, is present). Groups without a formatter are
skipped (the script never installs anything).

| Group | Formatter | Files |
|-------|-----------|-------|
| Prettier | `npx --no-install prettier`, else `prettier` — **only when the project opts in** | `.js .jsx .ts .tsx .mjs .cjs .json .css .scss .less .md .markdown .yml .yaml .html .htm .vue .svelte` |
| Go | `gofmt` | `.go` |
| Shell | `shfmt` | `.sh .bash` |
| Python | `ruff format`, else `black` | `.py` |

Prettier runs only when the project configures it: a `.prettierrc*` file, a
`prettier.config.*` file, or a `prettier` key in `package.json` (the project's
`.prettierrc*`/`prettier.config.*` is honoured automatically). This avoids
reformatting non-Prettier projects just because a global `prettier` is on
`PATH`. Go, shell and Python groups run whenever their binary is available.

`node_modules/`, `vendor/`, `dist/`, `build/` and `.git/` are never formatted.
When nothing is formatted, `format.sh` exits `0` with a skip message — either
`[format] no supported formatter found for <mode> files — skipping` (no
formatter binary) or `[format] no eligible <mode> files for the available
formatter(s) — skipping` (a tool exists but no candidate files). Absence of a
formatter never blocks a commit.

## Wiring

- `scripts/pre_commit.sh` runs `format.sh --staged` **before** the test step and
  re-stages **only the files the formatter actually rewrote** that had no
  pre-existing unstaged changes (`git add -- <file>`), so formatting lands in
  the same commit without ever committing partially staged hunks by accident. A
  missing `format.sh` or formatter is non-blocking.
- `scripts/committer-check.sh` runs `format.sh --diff <base>...HEAD --check`
  (falling back to `--staged --check`) as a **non-blocking WARN**:
  `GATE: WARN — formatting changes pending` never flips the verdict to FAIL.

## Tests

`scripts/tests/test_format.sh` uses fake formatter shims on `PATH`, so it does
not require Prettier/gofmt/shfmt/ruff/black to be installed.

```bash
bash scripts/tests/test_format.sh
```

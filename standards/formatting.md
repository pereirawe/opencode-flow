# Formatting

Run the project's formatter before committing so the code/changelog always
enters the repository formatted, without per-project discipline or manual
configuration.

Issue: #246.

## `scripts/format.sh`

`scripts/format.sh` detects the project's formatter, runs it on the selected
files, and degrades gracefully when no formatter binary is installed.

```
scripts/format.sh [--staged | --all] [--check]
```

| Flag | Meaning |
|------|---------|
| `--staged` | Format only staged files (`git diff --cached --diff-filter=ACMR`). Default. |
| `--all` | Format every tracked file (`git ls-files`). |
| `--check` | Do not write; exit non-zero when formatting changes are needed. |

Exit codes: `0` success or graceful skip; `1` `--check` found pending changes;
`3` usage error.

## Detection

Detection is per file group; every group whose binary is available runs, and
groups without a formatter are skipped (the script never installs anything).

| Group | Formatter | Files |
|-------|-----------|-------|
| Prettier | `prettier`, else `npx --no-install prettier` | `.js .jsx .ts .tsx .mjs .cjs .json .css .scss .less .md .markdown .yml .yaml .html .htm .vue .svelte` |
| Go | `gofmt` | `.go` |
| Shell | `shfmt` | `.sh .bash` |
| Python | `ruff format`, else `black` | `.py` |

A project `.prettierrc*` / `prettier.config.*` is honoured automatically by
Prettier. `node_modules/`, `vendor/`, `dist/`, `build/` and `.git/` are never
formatted. If no supported formatter is found, `format.sh` prints
`[format] no supported formatter found for <mode> files — skipping` and exits
`0` — absence of a formatter never blocks a commit.

## Wiring

- `scripts/pre_commit.sh` runs `format.sh --staged` **before** the test step and
  re-stages the files it modified (`git add -- <file>`), so formatting lands in
  the same commit. A missing `format.sh` or formatter is non-blocking.
- `scripts/committer-check.sh` runs `format.sh --staged --check` as a
  **non-blocking WARN**: `GATE: WARN — formatting changes pending` never flips
  the verdict to FAIL.

## Tests

`scripts/tests/test_format.sh` uses fake formatter shims on `PATH`, so it does
not require Prettier/gofmt/shfmt/ruff/black to be installed.

```bash
bash scripts/tests/test_format.sh
```

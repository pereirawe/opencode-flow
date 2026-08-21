# Test Environment Standard (test-env)

Versioned, verified test environment for the pipeline: `.nvmrc`, `.node-version`
and `.opencode/env-manifest.md` pin and validate the Node/Python/test-runner
versions used to run the suite. Applies to every project that uses
`scripts/test-runner.sh` and to `scripts/init.sh` bootstrapping.

## Manifest format (`.opencode/env-manifest.md`)

The manifest is a **project instance, committed** file. It MUST contain a strict
machine-parseable section in addition to free prose with the bootstrap
procedure. The strict section is parsed by `scripts/test-runner.sh` — one
`key: range` per line, no indentation, no markdown markers:

```text
## Strict (machine-parseable)

node: >=20 <23
python: >=3.10 <4
test-runner: >=1.0
```

Supported keys: `node`, `python`, `test-runner`. ONLY the strict section is
parsed — prose lines that start with one of those keys (before the
`## Strict` header or after the next `##` heading) are ignored, so prose is
free-form. Inline `#` comments on range lines are stripped before validation
(e.g. `node: >=20 <23 # nvm 22`). Duplicate keys within the strict section
emit a warning and the LAST value wins.

## Range policy

- **Pins live in files**: `.nvmrc` and `.node-version` pin a concrete Node
  version (e.g. `22`) for nvm/fnm/mise compatibility.
- **Ranges live in the manifest**: the supported range (e.g. `>=20 <23`) is
  declared in the strict section.
- **Pin ⊆ range**: the `.nvmrc`/`.node-version` pin MUST satisfy the manifest
  `node` range; the sync guard verifies this.
- **Range syntax**: space-separated constraint tokens `>=X`, `>X`, `<=X`, `<X`,
  `=X` or a bare `X` (exact). `>=20 <23` means `20 <= v < 23`. Versions compare
  as `x.y.z` (missing parts default to 0).
- **Malformed range** (e.g. `node: >=20 <`): the parser degrades gracefully —
  actionable warning, validation skipped, never a crash.

## Sync guard

`scripts/test-runner.sh` compares, in `--status` and `--run`:

1. `.nvmrc` ↔ `.node-version` — both pin files MUST hold the same version
   (compared NORMALIZED: `22` and `22.0.0` are equal). An EMPTY pin file is
   itself a consistency warning (BR 1 requires a pinned version).
2. `.nvmrc`/`.node-version` pin ↔ manifest `node` range — pin MUST satisfy
   `pin ⊆ range`.

Any mismatch emits a **consistency warning** (`sync guard: ...`) to stderr. It
never changes the exit code and never blocks the run.

## Warning contract

- Warnings go to **stderr**, prefixed `[test-env] WARNING:`, and are
  **actionable**: current version + expected range + install hint.
- Emitted in **`--status` and `--run`** — NEVER in `--check` (`--check` keeps
  its stderr empty even with a desynced environment).
- **Warning-only policy**: exit codes `0/1/2/3` are never changed by the
  environment checks; `--status` always exits `0`.
- **Missing tool** (`node`/`python3` absent): informative warning, never error.
- **Missing/malformed manifest**: warning + validation skipped, exit intact.
- **Drift** (cached `.result` versions ≠ current environment): warning in
  `--status`, non-blocking.

## Version metadata

Every `.result` cache file records the versions actually used:

```text
node_version=v22.3.1
python_version=3.12.0
runner_version=1.0.0
```

Test reports MUST include a `Version:` field sourced from `--status` output or
the `.result` metadata, so later pipeline stages never re-ask which version ran
the suite.

## Fingerprint

`.nvmrc`, `.node-version` and `.opencode/env-manifest.md` are **excluded from
the fingerprint**: changing environment metadata never invalidates the result
cache — only code/test changes do.

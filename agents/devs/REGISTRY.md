# Dev Agent Registry

Source of truth for `/ocf:develop` language routing.

`develop-router` reads this file to decide which specialized `devs/*` agent
should implement an issue. If no entry matches, it must fall back to
`developer`.

## Matching Order

1. `Detect files`
2. `Detect extensions`
3. `Detect paths`

If multiple agents match, the strongest match wins.

## Agents

### `devs/golang`
- Agent file: `agents/devs/golang.md`
- Detect files: `go.mod`
- Detect extensions: `.go`
- Detect paths: `cmd/`, `internal/`
- Skills: `skills/go/*`
- Notes: Prefer this agent for Go modules and for issues whose `Location:` or nearby code is predominantly Go.

### `devs/python`
- Agent file: `agents/devs/python.md`
- Detect files: `pyproject.toml`, `requirements.txt`, `setup.py`, `setup.cfg`
- Detect extensions: `.py`, `.pyi`
- Detect paths: `src/`, `app/`, `tests/`
- Skills: `skills/python/*`
- Notes: Prefer this agent for Python packages, scripts, APIs, CLIs, test suites, and issues whose `Location:` or nearby code is predominantly Python.

## Adding A New Language

1. Create `agents/devs/<language>.md`
2. Add a new `###` entry under `## Agents`
3. Fill in `Agent file`, `Detect files`, `Detect extensions`, and `Detect paths`
4. Add language skills under `skills/<language>/` when applicable
5. Restart OpenCode

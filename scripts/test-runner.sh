#!/usr/bin/env bash
# test-runner.sh — single test entrypoint for development agents.
#
# Detects the project's test runner, bootstraps the environment, computes a
# change fingerprint, and caches results in .opencode/test-cache/ so identical
# code is never re-tested across the pipeline (developer → senior review → QA
# → committer).
#
# Modes:
#   --check            exit 0 + report path when a fresh cache exists; exit 3 otherwise
#   --run              run the suite (or reuse a fresh cache), print summary + exit code
#   --status           human-readable state of the cache and fingerprint
#
# The cache is an optimization, never a blocker: when there is no valid cache
# the agent must run tests directly and use the result for its own purpose.
#
# Extra args after a `--` separator are appended to the test command
# (e.g. `test-runner.sh --run -- -run TestFoo` for Go).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
PROJECT_ROOT="$(pwd -P)"

CACHE_DIR=".opencode/test-cache"
EXCLUDE_RE='(^|/)(node_modules|\.venv|venv|vendor|dist|build|target|\.pytest_cache|__pycache__|\.next|coverage|\.opencode/test-cache|\.git)(/|$)'

usage() {
  echo "Usage: test-runner.sh --check|--run|--status [-- <test-args>]"
  echo ""
  echo "  --check   exit 0 + report path when a fresh cache exists; exit 3 otherwise"
  echo "  --run     run the suite (or reuse a fresh cache), print summary + exit code"
  echo "  --status  show cache/fingerprint state"
  echo ""
  echo "Example: test-runner.sh --run -- -run TestFoo"
  exit 1
}

MODE="${1:-}"
[[ "$MODE" == "--check" || "$MODE" == "--run" || "$MODE" == "--status" ]] || usage
shift || true

EXTRA_ARGS=()
if [[ "${1:-}" == "--" ]]; then
  shift || true
  EXTRA_ARGS=("$@")
fi

log() { printf '[test-runner] %s\n' "$*"; }
log_err() { printf '[test-runner] %s\n' "$*" >&2; }

# --- runner detection -------------------------------------------------------

detect_runner() {
  if [[ -f go.mod ]] && command -v go >/dev/null 2>&1; then
    echo "go"
  elif [[ -f Cargo.toml ]] && command -v cargo >/dev/null 2>&1; then
    echo "cargo"
  elif [[ -f package.json ]]; then
    if has_npm_test_script; then
      echo "npm"
    else
      echo "__npm-no-test__"
    fi
  elif [[ -f pyproject.toml ]] || [[ -f setup.py ]] || [[ -f setup.cfg ]] || [[ -f requirements.txt ]]; then
    if command -v poetry >/dev/null 2>&1 && [[ -f pyproject.toml ]]; then
      echo "poetry"
    else
      echo "pytest"
    fi
  else
    echo ""
  fi
}

# has_npm_test_script — 0 when package.json defines a scripts.test entry.
# File-based so detection works even when npm is not installed.
has_npm_test_script() {
  if command -v python3 >/dev/null 2>&1; then
    python3 -c 'import json,sys
try:
    d=json.load(open("package.json"))
    sys.exit(0 if "test" in d.get("scripts", {}) else 1)
except Exception:
    sys.exit(1)'
  else
    grep -q '"test"[[:space:]]*:' package.json 2>/dev/null
  fi
}

build_command() {
  local runner="$1"
  case "$runner" in
    go)   echo "go test ./...";;
    cargo) echo "cargo test";;
    npm)  echo "npm test";;
    poetry) echo "poetry run pytest";;
    pytest)
      if [[ -x ".venv/bin/pytest" ]]; then
        echo ".venv/bin/pytest"
      elif [[ -x "venv/bin/pytest" ]]; then
        echo "venv/bin/pytest"
      elif command -v python3 >/dev/null 2>&1 && python3 -c "import pytest" >/dev/null 2>&1; then
        echo "python3 -m pytest"
      elif command -v pytest >/dev/null 2>&1; then
        echo "pytest"
      else
        echo "__missing__"
      fi
      ;;
  esac
}

# --- environment bootstrap / diagnostics ------------------------------------

bootstrap_env() {
  local runner="$1"
  case "$runner" in
    npm)
      if [[ ! -d node_modules ]]; then
        log "WARNING: node_modules not found — run 'npm install' before tests."
      fi
      ;;
    pytest|poetry)
      if [[ ! -x ".venv/bin/pytest" && ! -x "venv/bin/pytest" ]] && \
         ! (command -v python3 >/dev/null 2>&1 && python3 -c "import pytest" >/dev/null 2>&1) && \
         ! command -v pytest >/dev/null 2>&1; then
        log "WARNING: pytest not found — create/activate a venv ('python3 -m venv .venv && .venv/bin/pip install -e .[dev]') or install pytest."
      fi
      ;;
  esac
}

# --- fingerprint ------------------------------------------------------------

# List changed paths (tracked modified/deleted/staged + untracked), NUL-delimited
# so paths with spaces/special chars are handled exactly (`-z` disables C-quoting).
changed_paths() {
  {
    git diff --name-only -z
    git diff --cached --name-only -z
    git ls-files --others --exclude-standard -z
  } 2>/dev/null
}

compute_fingerprint() {
  local buf=""
  if git rev-parse --git-dir >/dev/null 2>&1; then
    buf+="HEAD:$(git rev-parse HEAD 2>/dev/null || echo unknown)\n"
    local f df
    while IFS= read -r -d '' f; do
      [[ -z "$f" ]] && continue
      [[ "$f" =~ $EXCLUDE_RE ]] && continue
      # Path name is always included so deletions/renames change the fingerprint
      buf+="path:$f\n"
      if [[ -f "$f" ]]; then
        buf+="$f:$(sha256sum "$f" 2>/dev/null | cut -d' ' -f1)\n"
      elif [[ -d "$f" ]]; then
        while IFS= read -r -d '' df; do
          [[ "$df" =~ $EXCLUDE_RE ]] && continue
          [[ -f "$df" ]] && buf+="$df:$(sha256sum "$df" 2>/dev/null | cut -d' ' -f1)\n"
        done < <(find "$f" -type f -print0 2>/dev/null || true)
      fi
    done < <(changed_paths)
  else
    local f
    while IFS= read -r f; do
      [[ "$f" =~ $EXCLUDE_RE ]] && continue
      [[ -f "$f" ]] && buf+="$f:$(sha256sum "$f" 2>/dev/null | cut -d' ' -f1)\n"
    done < <(find . -type f 2>/dev/null | sed 's#^\./##' | sort || true)
  fi
  printf '%b' "$buf" | sha256sum | cut -d' ' -f1
}

branch_name() {
  git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "nogit"
}

is_git_repo() {
  git rev-parse --git-dir >/dev/null 2>&1
}

# --- cache helpers ----------------------------------------------------------

cache_path() { printf '%s/%s-%s.result' "$CACHE_DIR" "$(branch_name)" "$1"; }
log_path()   { printf '%s/%s-%s.log'   "$CACHE_DIR" "$(branch_name)" "$1"; }

write_cache() {
  local runner="$1" fp="$2" code="$3" out="$4"
  mkdir -p "$CACHE_DIR"
  cat > "$(cache_path "$runner")" <<EOF
fingerprint=$fp
exit_code=$code
timestamp=$(date +%s)
output=$(basename "$out")
EOF
}

read_cache() {
  # prints "0" when no valid cache, "1" when cache matches the fingerprint
  local runner="$1" fp="$2"
  local file
  file="$(cache_path "$runner")"
  [[ -f "$file" ]] || { echo 0; return; }
  if [[ "$(awk -F= '/^fingerprint=/{print $2}' "$file" 2>/dev/null)" == "$fp" ]]; then
    echo 1
  else
    echo 0
  fi
}

cache_exit_code() {
  local runner="$1"
  local file
  file="$(cache_path "$runner")"
  [[ -f "$file" ]] || { echo 255; return; }
  awk -F= '/^exit_code=/{print $2}' "$file" 2>/dev/null || echo 255
}

# --- modes -------------------------------------------------------------------

runner_name() {
  local r
  r="$(detect_runner)"
  if [[ "$r" == "__npm-no-test__" ]]; then
    log_err "package.json found but no 'test' script defined — nothing to run (exit 3)"
    return 1
  fi
  printf '%s' "$r"
}

cmd_check() {
  local runner
  runner="$(runner_name)" || exit 3
  if [[ -z "$runner" ]]; then
    log "no test runner detected (no go.mod/Cargo.toml/package.json/pyproject.toml/requirements.txt)"
    exit 3
  fi
  local fp
  fp="$(compute_fingerprint)"
  if [[ "$(read_cache "$runner" "$fp")" == "1" && "$(cache_exit_code "$runner")" == "0" ]]; then
    log "cache fresh and passing: $(cache_path "$runner")"
    printf '%s\n' "$(cache_path "$runner")"
    exit 0
  fi
  log "no fresh passing cache (exit 3)"
  exit 3
}

cmd_run() {
  local runner
  runner="$(runner_name)" || { log "fallback: run the project's tests directly and use the result."; exit 2; }
  if [[ -z "$runner" ]]; then
    log "no test runner detected (no go.mod/Cargo.toml/package.json/pyproject.toml/requirements.txt)"
    log "fallback: run the project's tests directly and use the result."
    exit 2
  fi

  local cmd
  cmd="$(build_command "$runner")"
  if [[ "$cmd" == "__missing__" ]]; then
    log "ERROR: pytest not available. Create a venv ('python3 -m venv .venv && .venv/bin/pip install -e \".[dev]\"') or install pytest."
    log "fallback: run the project's tests directly and use the result."
    exit 2
  fi

  bootstrap_env "$runner"

  local code=0
  local outfile=""
  local filtered=0
  [[ ${#EXTRA_ARGS[@]} -gt 0 ]] && filtered=1

  log "running: $cmd ${EXTRA_ARGS[*]:-}"

  # Filtered (domain-specific) runs never touch the shared cache — they are
  # for the agent's own verification and would otherwise poison the "suite
  # passed" signal that check/committer/pre_commit rely on.
  if [[ "$filtered" == "1" ]]; then
    mkdir -p "$CACHE_DIR"
    outfile="$(log_path "$runner")"
    $cmd "${EXTRA_ARGS[@]}" >"$outfile" 2>&1 || code=$?
    printf 'test-runner: %s (exit %s) — full output: %s\n' "$([ "$code" -eq 0 ] && echo PASS || echo FAIL)" "$code" "$outfile"
    exit "$code"
  fi

  local fp
  fp="$(compute_fingerprint)"

  if [[ "$(read_cache "$runner" "$fp")" == "1" ]]; then
    local cached_code cached_out
    cached_code="$(cache_exit_code "$runner")"
    cached_out="$(awk -F= '/^output=/{print $2}' "$(cache_path "$runner")" 2>/dev/null || true)"
    log "reusing cached result (fingerprint unchanged) — exit $cached_code, log: $CACHE_DIR/$cached_out"
    printf 'test-runner: cached (exit %s) — full output: %s\n' "$cached_code" "$CACHE_DIR/$cached_out"
    exit "$cached_code"
  fi

  mkdir -p "$CACHE_DIR"
  outfile="$(log_path "$runner")"
  $cmd >"$outfile" 2>&1 || code=$?

  write_cache "$runner" "$fp" "$code" "$outfile"

  log "exit $code — summary:"
  awk 'NR==1{first=$0} {last=$0} END{print "first: " first; print "last: " last}' "$outfile" 2>/dev/null || true
  printf 'test-runner: %s (exit %s) — full output: %s\n' "$([ "$code" -eq 0 ] && echo PASS || echo FAIL)" "$code" "$outfile"
  exit "$code"
}

cmd_status() {
  local runner
  runner="$(detect_runner)"
  [[ "$runner" == "__npm-no-test__" ]] && runner="(npm: no test script)"
  local fp
  fp="$(compute_fingerprint)"
  local branch
  branch="$(branch_name)"

  echo "test-runner status"
  echo "  runner:       ${runner:-none detected}"
  echo "  branch:       $branch"
  if is_git_repo; then
    echo "  git repo:     yes"
  else
    echo "  git repo:     no (content fingerprint)"
  fi
  echo "  fingerprint:  $fp"
  if [[ -n "$runner" && -f "$(cache_path "$runner")" ]]; then
    echo "  cache:        $(cache_path "$runner")"
    echo "  cached exit:  $(awk -F= '/^exit_code=/{print $2}' "$(cache_path "$runner")" 2>/dev/null || echo -)"
    echo "  cached log:   $CACHE_DIR/$(awk -F= '/^output=/{print $2}' "$(cache_path "$runner")" 2>/dev/null || true)"
    if [[ "$(read_cache "$runner" "$fp")" == "1" ]]; then
      echo "  freshness:    fresh (matches current fingerprint)"
    else
      echo "  freshness:    stale (code changed since last run)"
    fi
  else
    echo "  cache:        none"
  fi
  exit 0
}

case "$MODE" in
  --check)  cmd_check ;;
  --run)    cmd_run ;;
  --status) cmd_status ;;
esac

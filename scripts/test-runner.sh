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

# Pure-bash path derivation — no external `dirname` dependency (issue #210 F3).
# Fails loudly (set -e aborts) when BASH_SOURCE has no directory component.
SCRIPT_SRC="${BASH_SOURCE[0]:-$0}"
SCRIPT_DIR="$(cd "${SCRIPT_SRC%/*}" && pwd)"
PROJECT_ROOT="$(pwd -P)"

CACHE_DIR=".opencode/test-cache"
EXCLUDE_RE='(^|/)(node_modules|\.venv|venv|vendor|dist|build|target|\.pytest_cache|__pycache__|\.next|coverage|\.opencode/test-cache|\.git)(/|$)'

# --- versioned test environment (issue #210) ---
# The runtime versions are advisory: they are detected and compared against the
# ranges declared in .opencode/env-manifest.md, emitting non-blocking warnings
# only (exit codes 0/1/2/3 are never changed by the environment checks).
TEST_RUNNER_VERSION="1.0.0"
ENV_MANIFEST_FILE=".opencode/env-manifest.md"
ENV_NODE_VERSION=""    # detected `node --version`, normalized (e.g. v22.3.1); empty when absent
ENV_PYTHON_VERSION=""  # detected `python3 --version`, normalized (e.g. 3.12.0); empty when absent
MANIFEST_NODE_RANGE=""     # e.g. ">=20 <23"
MANIFEST_PYTHON_RANGE=""   # e.g. ">=3.10 <4"
MANIFEST_RUNNER_RANGE=""   # e.g. ">=1.0"
MANIFEST_DUPLICATE_KEYS="" # keys seen more than once in the strict section (F5)

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

# Paths excluded from the fingerprint: heavy/generated dirs (EXCLUDE_RE) plus the
# versioned test-environment files (.nvmrc / .node-version / env-manifest).
# Environment metadata changes must never invalidate the result cache — only code
# and test changes do (issue #210, BR 4 / AC 6).
is_fingerprint_excluded() {
  local f="$1"
  [[ "$f" =~ $EXCLUDE_RE ]] && return 0
  [[ "$f" == ".nvmrc" || "$f" == ".node-version" || "$f" == ".opencode/env-manifest.md" ]] && return 0
  return 1
}

compute_fingerprint() {
  local buf=""
  if git rev-parse --git-dir >/dev/null 2>&1; then
    buf+="HEAD:$(git rev-parse HEAD 2>/dev/null || echo unknown)\n"
    local f df
    while IFS= read -r -d '' f; do
      [[ -z "$f" ]] && continue
      is_fingerprint_excluded "$f" && continue
      # Path name is always included so deletions/renames change the fingerprint
      buf+="path:$f\n"
      if [[ -f "$f" ]]; then
        buf+="$f:$(sha256sum "$f" 2>/dev/null | cut -d' ' -f1)\n"
      elif [[ -d "$f" ]]; then
        while IFS= read -r -d '' df; do
          is_fingerprint_excluded "$df" && continue
          [[ -f "$df" ]] && buf+="$df:$(sha256sum "$df" 2>/dev/null | cut -d' ' -f1)\n"
        done < <(find "$f" -type f -print0 2>/dev/null || true)
      fi
    done < <(changed_paths)
  else
    local f
    while IFS= read -r f; do
      is_fingerprint_excluded "$f" && continue
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

# --- versioned test environment (issue #210) ----------------------------------
# All functions in this section are warning-only: they never change the exit
# code contract (0/1/2/3) and never block execution (BR 5). Warnings go to
# stderr in --status and --run; --check is kept pure (empty stderr, BR 4 / AC 3).

env_warn() { printf '[test-env] WARNING: %s\n' "$*" >&2; }

# normalize_version <v> — "v22" / "22" / "22.3" / "22.3.1-rc1" → "22.3.1"
normalize_version() {
  local v="$1" parts
  v="${v#v}"
  v="${v%%[[:space:]]}"
  v="${v%%-*}"
  IFS='.' read -r -a parts <<< "$v"
  printf '%s.%s.%s' "${parts[0]:-0}" "${parts[1]:-0}" "${parts[2]:-0}"
}

# version_cmp <a> <b> — echoes 1 (a>b), -1 (a<b), 0 (a==b)
version_cmp() {
  local a="$1" b="$2" ia ib i na nb
  IFS='.' read -r -a ia <<< "$a"
  IFS='.' read -r -a ib <<< "$b"
  for i in 0 1 2; do
    na="${ia[$i]:-0}"; nb="${ib[$i]:-0}"
    na="${na%%[!0-9]*}"; nb="${nb%%[!0-9]*}"
    na="${na:-0}"; nb="${nb:-0}"
    if (( 10#$na > 10#$nb )); then echo 1; return; fi
    if (( 10#$na < 10#$nb )); then echo -1; return; fi
  done
  echo 0
}

# valid_range_syntax <range> — accepts tokens like >=X, >X, <=X, <X, =X or bare X.
valid_range_syntax() {
  local range="$1" tok num
  for tok in $range; do
    case "$tok" in
      '>='*|'>'*|'<='*|'<'*|'='*) ;;
      *) [[ "$tok" =~ ^[0-9]+(\.[0-9]+)*$ ]] || return 1 ;;
    esac
    num="${tok#>=}"; num="${num#>}"; num="${num#<=}"; num="${num#<}"; num="${num#=}"
    [[ "$num" =~ ^[0-9]+(\.[0-9]+)*$ ]] || return 1
  done
  return 0
}

# range_matches <version> <range> — 0 = in range, 1 = out of range, 2 = malformed token.
range_matches() {
  local ver="$1" range="$2" tok op num cmp
  for tok in $range; do
    case "$tok" in
      '>='*) op='>='; num="${tok#>=}";;
      '>'*)  op='>';  num="${tok#>}";;
      '<='*) op='<='; num="${tok#<=}";;
      '<'*)  op='<';  num="${tok#<}";;
      '='*)  op='=';  num="${tok#=}";;
      *)     if [[ "$tok" =~ ^[0-9]+(\.[0-9]+)*$ ]]; then op='='; num="$tok"; else return 2; fi ;;
    esac
    cmp="$(version_cmp "$ver" "$(normalize_version "$num")")"
    case "$op" in
      '>=') [[ "$cmp" == "1" || "$cmp" == "0" ]] || return 1 ;;
      '>')  [[ "$cmp" == "1" ]] || return 1 ;;
      '<=') [[ "$cmp" == "-1" || "$cmp" == "0" ]] || return 1 ;;
      '<')  [[ "$cmp" == "-1" ]] || return 1 ;;
      '=')  [[ "$cmp" == "0" ]] || return 1 ;;
    esac
  done
  return 0
}

# detect_versions — sets ENV_NODE_VERSION / ENV_PYTHON_VERSION. Absent tools are
# informational (BR 10), never an error.
detect_versions() {
  if command -v node >/dev/null 2>&1; then
    local raw
    raw="$(node --version 2>/dev/null || true)"
    [[ -n "$raw" ]] && ENV_NODE_VERSION="v$(normalize_version "$raw")"
  fi
  if command -v python3 >/dev/null 2>&1; then
    local raw
    raw="$(python3 --version 2>/dev/null || true)"
    raw="${raw#Python }"; raw="${raw#python }"
    [[ -n "$raw" ]] && ENV_PYTHON_VERSION="$(normalize_version "$raw")"
  fi
}

# load_manifest — parses ONLY the STRICT machine-parseable section of
# .opencode/env-manifest.md (issue #210 F4): lines after the
# `## Strict (machine-parseable)` heading count, and the section ends at the
# next `##` heading. Prose lines that look like keys (before or after the
# strict section) are ignored. Inline `#` comments on range lines are stripped
# (QA-3). Duplicate keys within the strict section are collected in
# MANIFEST_DUPLICATE_KEYS (F5, last value wins + warning).
# Returns 0 = parsed OK, 1 = missing/empty, 2 = malformed.
load_manifest() {
  local file="$PROJECT_ROOT/$ENV_MANIFEST_FILE"
  MANIFEST_NODE_RANGE=""; MANIFEST_PYTHON_RANGE=""; MANIFEST_RUNNER_RANGE=""
  MANIFEST_DUPLICATE_KEYS=""
  [[ -f "$file" ]] || return 1
  local line key val bad=0 in_strict=0 saw_strict=0 seen=""
  while IFS= read -r line; do
    if [[ "$line" == "## Strict"* ]]; then
      saw_strict=1; in_strict=1
      continue
    fi
    if [[ "$in_strict" == "1" && "$line" == "##"* ]]; then
      in_strict=0   # the next `##` heading ends the strict section
      continue
    fi
    [[ "$in_strict" == "1" ]] || continue
    [[ "$line" =~ ^(node|python|test-runner):[[:space:]]*([^[:space:]].*)$ ]] || continue
    key="${BASH_REMATCH[1]}"; val="${BASH_REMATCH[2]}"
    val="${val%%#*}"                            # strip inline comment (QA-3)
    val="${val%"${val##*[![:space:]]}"}"        # trim trailing whitespace (pure bash)
    if [[ "$seen" == *" $key "* ]]; then
      MANIFEST_DUPLICATE_KEYS+="${MANIFEST_DUPLICATE_KEYS:+, }$key"
    else
      seen+=" $key "
    fi
    case "$key" in
      node)        MANIFEST_NODE_RANGE="$val" ;;
      python)      MANIFEST_PYTHON_RANGE="$val" ;;
      test-runner) MANIFEST_RUNNER_RANGE="$val" ;;
    esac
  done < "$file"
  if [[ "$saw_strict" == "0" ]]; then
    return 1   # no strict section at all — treated the same as missing (F4)
  fi
  if [[ -z "$MANIFEST_NODE_RANGE" && -z "$MANIFEST_PYTHON_RANGE" && -z "$MANIFEST_RUNNER_RANGE" ]]; then
    return 1
  fi
  for key in node python test-runner; do
    local val=""
    case "$key" in
      node) val="$MANIFEST_NODE_RANGE" ;;
      python) val="$MANIFEST_PYTHON_RANGE" ;;
      test-runner) val="$MANIFEST_RUNNER_RANGE" ;;
    esac
    if [[ -n "$val" ]] && ! valid_range_syntax "$val"; then
      bad=1
    fi
  done
  [[ "$bad" == "1" ]] && return 2
  return 0
}

# check_sync_guard — .nvmrc ↔ .node-version ↔ manifest pin consistency (BR 6 / AC 7).
check_sync_guard() {
  local pin_nvmrc="" pin_nodever=""
  if [[ -f "$PROJECT_ROOT/.nvmrc" ]]; then
    pin_nvmrc="$(tr -d '[:space:]' < "$PROJECT_ROOT/.nvmrc")"
    if [[ -z "$pin_nvmrc" ]]; then
      env_warn "sync guard: .nvmrc exists but is empty — BR 1 requires a pinned Node version (e.g. 22)."
    fi
  fi
  if [[ -f "$PROJECT_ROOT/.node-version" ]]; then
    pin_nodever="$(tr -d '[:space:]' < "$PROJECT_ROOT/.node-version")"
    if [[ -z "$pin_nodever" ]]; then
      env_warn "sync guard: .node-version exists but is empty — BR 1 requires a pinned Node version (e.g. 22)."
    fi
  fi
  # Compare NORMALIZED pins: `.nvmrc`=22 and `.node-version`=22.0.0 are
  # semantically identical and must not warn (issue #210 F6).
  if [[ -n "$pin_nvmrc" && -n "$pin_nodever" ]] && \
     [[ "$(normalize_version "$pin_nvmrc")" != "$(normalize_version "$pin_nodever")" ]]; then
    env_warn "sync guard: .nvmrc ($pin_nvmrc) and .node-version ($pin_nodever) disagree — pin them to the same Node version (e.g. 22)."
  fi
  # Pin ⊆ range only makes sense against a syntactically valid manifest range.
  if [[ -n "$MANIFEST_NODE_RANGE" ]] && valid_range_syntax "$MANIFEST_NODE_RANGE"; then
    local f pin
    for f in .nvmrc .node-version; do
      pin=""
      [[ -f "$PROJECT_ROOT/$f" ]] && pin="$(tr -d '[:space:]' < "$PROJECT_ROOT/$f")"
      if [[ -n "$pin" ]] && ! range_matches "$(normalize_version "$pin")" "$MANIFEST_NODE_RANGE"; then
        env_warn "sync guard: $f pin $pin is outside the manifest node range ($MANIFEST_NODE_RANGE) — pin must satisfy pin ⊆ range (BR 1)."
      fi
    done
  fi
}

# check_env_drift — cached .result versions vs current environment (BR 11 / AC 10).
check_env_drift() {
  local runner="$1" file
  file="$(cache_path "$runner")"
  [[ -f "$file" ]] || return 0
  local cached_node cached_py
  cached_node="$(awk -F= '/^node_version=/{print $2}' "$file" 2>/dev/null || true)"
  cached_py="$(awk -F= '/^python_version=/{print $2}' "$file" 2>/dev/null || true)"
  if [[ -n "$cached_node" && -n "$ENV_NODE_VERSION" && "$cached_node" != "$ENV_NODE_VERSION" ]]; then
    env_warn "drift: the cached result was produced with node $cached_node, current node is $ENV_NODE_VERSION — cached results may be stale."
  fi
  if [[ -n "$cached_py" && -n "$ENV_PYTHON_VERSION" && "$cached_py" != "$ENV_PYTHON_VERSION" ]]; then
    env_warn "drift: the cached result was produced with python $cached_py, current python is $ENV_PYTHON_VERSION — cached results may be stale."
  fi
}

# emit_env_warnings — full environment diagnostic. Warning-only (BR 5): called
# from --status and --run, NEVER from --check (AC 3 keeps --check stderr empty).
emit_env_warnings() {
  detect_versions

  if [[ -z "$ENV_NODE_VERSION" ]]; then
    env_warn "node not found in PATH — skipping Node version validation (install Node 22, e.g. via nvm: 'nvm install 22 && nvm use')."
  fi
  if [[ -z "$ENV_PYTHON_VERSION" ]]; then
    env_warn "python3 not found in PATH — skipping Python version validation."
  fi

  local mrc=0
  load_manifest || mrc=$?
  if [[ -n "$MANIFEST_DUPLICATE_KEYS" ]]; then
    env_warn "duplicate range key(s) in the strict section of $ENV_MANIFEST_FILE: $MANIFEST_DUPLICATE_KEYS — the last value wins; remove the duplicates (possible typo)."
  fi
  if [[ $mrc -eq 1 ]]; then
    if [[ -f "$PROJECT_ROOT/$ENV_MANIFEST_FILE" ]]; then
      env_warn "$ENV_MANIFEST_FILE has no parseable strict section — range validation skipped; add lines like 'node: >=20 <23' (see standards/test-env.md)."
    else
      env_warn "no $ENV_MANIFEST_FILE found — range validation skipped (create it per standards/test-env.md; strict section: 'node: >=20 <23', 'python: >=3.10 <4', 'test-runner: >=1.0')."
    fi
  elif [[ $mrc -eq 2 ]]; then
    env_warn "malformed range(s) in $ENV_MANIFEST_FILE — range validation skipped; fix the strict section (expected syntax like 'node: >=20 <23')."
  fi

  if [[ $mrc -eq 0 ]]; then
    if [[ -n "$ENV_NODE_VERSION" && -n "$MANIFEST_NODE_RANGE" ]]; then
      range_matches "$(normalize_version "$ENV_NODE_VERSION")" "$MANIFEST_NODE_RANGE" \
        || env_warn "node $ENV_NODE_VERSION is outside the manifest range ($MANIFEST_NODE_RANGE) — expected e.g. Node 22 (nvm: 'nvm install 22 && nvm use')."
    fi
    if [[ -n "$ENV_PYTHON_VERSION" && -n "$MANIFEST_PYTHON_RANGE" ]]; then
      range_matches "$ENV_PYTHON_VERSION" "$MANIFEST_PYTHON_RANGE" \
        || env_warn "python $ENV_PYTHON_VERSION is outside the manifest range ($MANIFEST_PYTHON_RANGE) — expected e.g. Python 3.11/3.12 (python3 -m venv .venv)."
    fi
    if [[ -n "$MANIFEST_RUNNER_RANGE" ]]; then
      range_matches "$TEST_RUNNER_VERSION" "$MANIFEST_RUNNER_RANGE" \
        || env_warn "test-runner $TEST_RUNNER_VERSION is outside the manifest range ($MANIFEST_RUNNER_RANGE) — update scripts/test-runner.sh."
    fi
  fi

  check_sync_guard
}

# --- cache helpers ----------------------------------------------------------

cache_path() { printf '%s/%s-%s.result' "$CACHE_DIR" "$(branch_name)" "$1"; }
log_path()   { printf '%s/%s-%s.log'   "$CACHE_DIR" "$(branch_name)" "$1"; }

write_cache() {
  local runner="$1" fp="$2" code="$3" out="$4"
  local path tmp
  path="$(cache_path "$runner")"
  tmp="$path.tmp"
  mkdir -p "$CACHE_DIR"
  cat > "$tmp" <<EOF
fingerprint=$fp
exit_code=$code
timestamp=$(date +%s)
output=$(basename "$out")
node_version=${ENV_NODE_VERSION:-}
python_version=${ENV_PYTHON_VERSION:-}
runner_version=$TEST_RUNNER_VERSION
EOF
  # Atomic publish (issue #210 F1): a partially-written .result (e.g. truncated
  # between fingerprint= and exit_code=) must never be observable by readers.
  mv -f "$tmp" "$path"
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

  # Environment verification (issue #210): warning-only, never blocks (BR 5).
  emit_env_warnings

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
    outfile="$(printf '%s/%s-%s-filtered.log' "$CACHE_DIR" "$(branch_name)" "$runner")"
    $cmd "${EXTRA_ARGS[@]}" >"$outfile" 2>&1 || code=$?
    printf 'test-runner: %s (exit %s) — full output: %s\n' "$([ "$code" -eq 0 ] && echo PASS || echo FAIL)" "$code" "$outfile"
    exit "$code"
  fi

  local fp
  fp="$(compute_fingerprint)"

  if [[ "$(read_cache "$runner" "$fp")" == "1" ]]; then
    local cached_code cached_out
    cached_code="$(cache_exit_code "$runner")"
    if [[ "$cached_code" =~ ^[0-9]+$ ]]; then
      cached_out="$(awk -F= '/^output=/{print $2}' "$(cache_path "$runner")" 2>/dev/null || true)"
      log "reusing cached result (fingerprint unchanged) — exit $cached_code, log: $CACHE_DIR/$cached_out"
      printf 'test-runner: cached (exit %s) — full output: %s\n' "$cached_code" "$CACHE_DIR/$cached_out"
      exit "$cached_code"
    fi
    # The cache is an optimization, never a blocker (issue #210 F1): a .result
    # truncated/corrupted between fingerprint= and exit_code= must fall through
    # to a real re-run instead of `exit ""` (which would fake rc=2 "cannot run").
    log_err "WARNING: cached .result has no valid exit_code — ignoring the cache and re-running the suite"
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
  local raw_runner="$runner"
  [[ "$runner" == "__npm-no-test__" ]] && runner="(npm: no test script)"
  local fp
  fp="$(compute_fingerprint)"
  local branch
  branch="$(branch_name)"

  # Environment verification (issue #210): warnings + metadata, always exit 0.
  emit_env_warnings
  check_env_drift "$raw_runner"

  echo "test-runner status"
  echo "  runner:       ${runner:-none detected}"
  echo "  branch:       $branch"
  if is_git_repo; then
    echo "  git repo:     yes"
  else
    echo "  git repo:     no (content fingerprint)"
  fi
  echo "  fingerprint:  $fp"
  echo "  node version:     ${ENV_NODE_VERSION:-not detected}"
  echo "  python version:   ${ENV_PYTHON_VERSION:-not detected}"
  echo "  runner version:   $TEST_RUNNER_VERSION"
  if [[ -n "$MANIFEST_NODE_RANGE" ]]; then
    echo "  manifest ranges:  node: $MANIFEST_NODE_RANGE, python: ${MANIFEST_PYTHON_RANGE:--}, test-runner: ${MANIFEST_RUNNER_RANGE:--}"
  fi
  if [[ -n "$raw_runner" && -f "$(cache_path "$raw_runner")" ]]; then
    echo "  cache:        $(cache_path "$raw_runner")"
    echo "  cached exit:  $(awk -F= '/^exit_code=/{print $2}' "$(cache_path "$raw_runner")" 2>/dev/null || echo -)"
    echo "  cached log:   $CACHE_DIR/$(awk -F= '/^output=/{print $2}' "$(cache_path "$raw_runner")" 2>/dev/null || true)"
    echo "  cached env:   node: $(awk -F= '/^node_version=/{print $2}' "$(cache_path "$raw_runner")" 2>/dev/null || echo -), python: $(awk -F= '/^python_version=/{print $2}' "$(cache_path "$raw_runner")" 2>/dev/null || echo -), runner: $(awk -F= '/^runner_version=/{print $2}' "$(cache_path "$raw_runner")" 2>/dev/null || echo -)"
    if [[ "$(read_cache "$raw_runner" "$fp")" == "1" ]]; then
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

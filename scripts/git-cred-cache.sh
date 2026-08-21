#!/usr/bin/env bash
# git-cred-cache.sh — per-project git credential cache (issue #209).
#
# Single access point for the per-project git credential cache living in
# <project>/.opencode/cache/git/ (gitignored via .opencode/.gitignore). It lets
# pipeline agents authenticate and commit under `--auto` without interactive
# prompts and without ever exposing secrets in outputs, logs, or fingerprints.
#
# Layout (SPLIT — never cross-served, BR 2):
#   .opencode/cache/git/credentials   git credential store format:
#                                     https://<user>:<token>@<host>
#   .opencode/cache/git/identity      name=<name> / email=<email>
#
# Security model (BR 3, BR 8):
#   - Cache dir 0700 and files 0600 applied on EVERY write (umask-independent).
#   - All reads/writes go through THIS script; opencode.json denies read/edit
#     of .opencode/cache/** for agents (access via script only).
#   - Fail-silent: missing/unreadable cache → no prompts (stdin is never read),
#     no secrets in error messages; --status is the diagnostic path.
#   - Symlink-safe: the project root is resolved with `pwd -P` and writes are
#     refused when .opencode/.opencode/cache/cache-dir is a symlink.
#   - Atomic writes (tmp + mv) and flock for concurrent safety.
#
# Subcommands (run from the project root):
#   --init                      configure local git store (absolute path) +
#                               credential.interactive never
#   --set [--host H] [--user U] [--token T] [--force]
#                               import credentials; primary input is the env
#                               (GITLAB_TOKEN / GH_TOKEN / GITHUB_TOKEN — empty
#                               is treated as absent). Idempotent: skips when the
#                               entry already exists; --force overwrites.
#   --get                       print stored credentials with tokens masked
#   --erase                     remove cached credentials + identity
#   --identity [--set [--name N] [--email E]]
#                               print (name=/email=) or store the commit identity
#   --status                    fully redacted cache state (diagnosis)

SCRIPT_SRC="${BASH_SOURCE[0]:-$0}"
SCRIPT_DIR="$(cd "${SCRIPT_SRC%/*}" && pwd)"
# shellcheck source=config.sh
source "$SCRIPT_DIR/config.sh"

# Cache location — resolved from the CWD (symlink-safe, BR 7 / test 3).
PROJECT_ROOT="$(pwd -P)"
CACHE_ROOT="$PROJECT_ROOT/.opencode/cache"
CACHE_DIR="$CACHE_ROOT/git"
CREDENTIALS_FILE="$CACHE_DIR/credentials"
IDENTITY_FILE="$CACHE_DIR/identity"
LOCK_FILE="$CACHE_DIR/.lock"

LOCK_FD=""

usage() {
  cat <<'EOF'
Usage: git-cred-cache.sh <subcommand> [options]

  --init
  --set [--host H] [--user U] [--token T] [--force]
  --get
  --erase
  --identity [--set [--name N] [--email E]]
  --status

Credentials are imported from GITLAB_TOKEN / GH_TOKEN / GITHUB_TOKEN env vars
(empty is treated as absent). Run from the project root; the cache lives in
.opencode/cache/git/ (gitignored). See scripts/README.md (issue #209).
EOF
}

# --- filesystem helpers -----------------------------------------------------

# ensure_cache_dir — create the cache dir with 0700. Refuses (fail-silent) when
# any path component is a symlink: writes must never escape the project.
ensure_cache_dir() {
  if [[ -L "$PROJECT_ROOT/.opencode" || -L "$CACHE_ROOT" || -L "$CACHE_DIR" ]]; then
    return 1
  fi
  mkdir -p "$CACHE_DIR" 2>/dev/null || return 1
  chmod 700 "$CACHE_DIR" 2>/dev/null || true
  chmod 700 "$CACHE_ROOT" 2>/dev/null || true
  return 0
}

# cache_lock / cache_unlock — exclusive flock on the cache dir. No-op when
# flock is unavailable (the atomic tmp+mv still guarantees a never-torn store).
cache_lock() {
  LOCK_FD=""
  if command -v flock >/dev/null 2>&1; then
    if mkdir -p "$CACHE_DIR" 2>/dev/null && exec 9>"$LOCK_FILE" 2>/dev/null; then
      if flock 9 2>/dev/null; then
        LOCK_FD=9
      fi
    fi
  fi
}

cache_unlock() {
  if [[ -n "$LOCK_FD" ]]; then
    flock -u "$LOCK_FD" 2>/dev/null || true
    LOCK_FD=""
  fi
}

# atomic_write_file <file> <content> — write with 0600 via tmp + mv.
atomic_write_file() {
  local target="$1" content="$2"
  local tmp
  tmp="$(mktemp "$CACHE_DIR/.tmp.XXXXXX" 2>/dev/null)" || return 1
  chmod 600 "$tmp" 2>/dev/null || true
  printf '%s' "$content" > "$tmp" 2>/dev/null || { rm -f "$tmp" 2>/dev/null; return 1; }
  mv -f "$tmp" "$target" 2>/dev/null || { rm -f "$tmp" 2>/dev/null; return 1; }
  chmod 600 "$target" 2>/dev/null || true
  chmod 700 "$CACHE_DIR" 2>/dev/null || true
  return 0
}

# --- subcommands ------------------------------------------------------------

# --init: configure the LOCAL git store pointing at the cache (absolute path)
# and disable interactive credential prompts. NEVER writes identity or secrets
# to .git/config (BR 7). Fail-silent outside a git repo.
cmd_init() {
  ensure_cache_dir || exit 0
  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    exit 0
  fi
  git config --local credential.helper "store --file=$CREDENTIALS_FILE" 2>/dev/null || true
  git config --local credential.interactive never 2>/dev/null || true
  exit 0
}

# write_entry <host> <user> <token> <force> — idempotent append/overwrite.
# An identical line → no-op; a different token for the same host+user → skip
# unless --force; atomic and flock-protected (BR 2, test 3/7).
write_entry() {
  local host="$1" user="$2" token="$3" force="$4"
  ensure_cache_dir || return 0
  [[ -n "$token" ]] || return 0

  local line="https://${user}:${token}@${host}"

  cache_lock
  local existing="" has_exact=0 has_other=0 l
  if [[ -f "$CREDENTIALS_FILE" ]]; then
    while IFS= read -r l; do
      [[ -n "$l" ]] || continue
      existing+="$l"$'\n'
      if [[ "$l" == "$line" ]]; then has_exact=1; fi
      if [[ "$l" == "https://${user}:"*"@${host}" && "$l" != "$line" ]]; then has_other=1; fi
    done < "$CREDENTIALS_FILE"
  fi

  if [[ "$has_exact" == "1" ]]; then
    cache_unlock
    return 0
  fi
  if [[ "$has_other" == "1" && "$force" != "1" ]]; then
    cache_unlock
    return 0
  fi

  local out=""
  if [[ -n "$existing" ]]; then
    while IFS= read -r l; do
      [[ -n "$l" ]] || continue
      if [[ "$l" == "https://${user}:"*"@${host}" && "$l" != "$line" ]]; then
        continue  # drop the stale entry for this host+user (force path)
      fi
      out+="$l"$'\n'
    done <<< "$existing"
  fi
  out+="$line"$'\n'
  atomic_write_file "$CREDENTIALS_FILE" "$out"
  cache_unlock
  return 0
}

# --set: auto-import from env (GITLAB_TOKEN/GH_TOKEN/GITHUB_TOKEN) or explicit
# --token/--host/--user flags. Empty env vars are treated as absent (BR 5).
cmd_set() {
  local host="" user="" token="" force=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --host) host="${2:-}"; shift 2 ;;
      --user) user="${2:-}"; shift 2 ;;
      --token) token="${2:-}"; shift 2 ;;
      --force) force=1; shift ;;
      *) shift ;;  # unknown args ignored silently
    esac
  done

  if [[ -n "$token" ]]; then
    # Explicit token — one entry (host/user default to GitHub convention).
    [[ -n "$host" ]] || host="github.com"
    [[ -n "$user" ]] || user="x-access-token"
    write_entry "$host" "$user" "$token" "$force"
  else
    if [[ -n "${GITLAB_TOKEN:-}" ]]; then
      write_entry "gitlab.com" "${GITLAB_USER:-oauth2}" "$GITLAB_TOKEN" "$force"
    fi
    if [[ -n "${GH_TOKEN:-}" ]]; then
      write_entry "github.com" "${GH_USER:-x-access-token}" "$GH_TOKEN" "$force"
    fi
    if [[ -n "${GITHUB_TOKEN:-}" ]]; then
      write_entry "github.com" "${GH_USER:-x-access-token}" "$GITHUB_TOKEN" "$force"
    fi
  fi
  exit 0
}

# --get: print stored credentials with tokens masked. Never emits identity
# fields (BR 2 / test 5). Fail-silent when absent/unreadable (BR 8).
cmd_get() {
  if [[ ! -f "$CREDENTIALS_FILE" || ! -r "$CREDENTIALS_FILE" ]]; then
    exit 0
  fi
  local line
  while IFS= read -r line; do
    [[ -n "$line" ]] || continue
    redact_secret "$line"
    printf '\n'
  done < "$CREDENTIALS_FILE"
  exit 0
}

# --erase: remove cached credentials + identity (no rm -rf, no symlink follow).
cmd_erase() {
  rm -f "$CREDENTIALS_FILE" "$IDENTITY_FILE" "$LOCK_FILE" 2>/dev/null || true
  rmdir "$CACHE_DIR" 2>/dev/null || true
  rmdir "$CACHE_ROOT" 2>/dev/null || true
  exit 0
}

# --identity: print (name=/email=) or store the commit identity. The print path
# emits REAL values (used to apply `git -c user.name= -c user.email=`), never
# credentials (test 5). The stored email is masked as <set> only in --status.
cmd_identity() {
  if [[ "${1:-}" == "--set" ]]; then
    shift || true
    ensure_cache_dir || exit 0
    local name="" email=""
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --name) name="${2:-}"; shift 2 ;;
        --email) email="${2:-}"; shift 2 ;;
        *) shift ;;
      esac
    done
    local content=""
    [[ -n "$name" ]] && content+="name=$name"$'\n'
    [[ -n "$email" ]] && content+="email=$email"$'\n'
    [[ -n "$content" ]] && atomic_write_file "$IDENTITY_FILE" "$content"
    exit 0
  fi

  if [[ ! -f "$IDENTITY_FILE" || ! -r "$IDENTITY_FILE" ]]; then
    exit 0
  fi
  local line
  while IFS= read -r line; do
    [[ -n "$line" ]] || continue
    printf '%s\n' "$line"
  done < "$IDENTITY_FILE"
  exit 0
}

# --status: fully redacted diagnostic (BR 6 / AC 3 — email shows as <set>).
cmd_status() {
  local dir_perm="" cred_state="absent" cred_perm="" ident_state="not set" helper="" interactive=""
  if [[ -d "$CACHE_DIR" ]]; then
    dir_perm="$(stat -c %a "$CACHE_DIR" 2>/dev/null || true)"
  fi
  if [[ -f "$CREDENTIALS_FILE" ]]; then
    if [[ -r "$CREDENTIALS_FILE" ]]; then
      cred_state="present"
      cred_perm="$(stat -c %a "$CREDENTIALS_FILE" 2>/dev/null || true)"
    else
      cred_state="unreadable"
    fi
  fi
  if [[ -f "$IDENTITY_FILE" ]]; then
    if [[ -r "$IDENTITY_FILE" ]]; then
      if grep -q '^email=' "$IDENTITY_FILE" 2>/dev/null; then
        ident_state="set (email <set>)"
      else
        ident_state="set"
      fi
    else
      ident_state="unreadable"
    fi
  fi
  helper="$(git config --local --get credential.helper 2>/dev/null || true)"
  interactive="$(git config --local --get credential.interactive 2>/dev/null || true)"
  [[ -n "$helper" ]] && helper="$(redact_secret "$helper")"

  printf 'cache dir:   %s\n' "${CACHE_DIR:-}"
  printf 'cache perm:  %s\n' "${dir_perm:--}"
  printf 'credentials: %s\n' "$cred_state"
  [[ -n "$cred_perm" ]] && printf 'cred perm:   %s\n' "$cred_perm"
  printf 'identity:    %s\n' "$ident_state"
  printf 'git helper:  %s\n' "${helper:-not configured}"
  printf 'git inter:   %s\n' "${interactive:-not configured}"
  exit 0
}

case "${1:-}" in
  --init)     cmd_init ;;
  --set)      shift; cmd_set "$@" ;;
  --get)      shift; cmd_get "$@" ;;
  --erase)    shift; cmd_erase "$@" ;;
  --identity) shift; cmd_identity "$@" ;;
  --status)   shift; cmd_status "$@" ;;
  *)          usage; exit 1 ;;
esac

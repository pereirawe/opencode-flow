# Shared configuration for opencode scripts.
# Source this file from any script to get absolute global paths.
#
# Usage:
#   source "$(dirname "$0")/config.sh"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="$(dirname "$SCRIPT_DIR")"
SCRIPTS_DIR="$CONFIG_DIR/scripts"

# Global issue tracker (opencode config-level issues)
ISSUES_FILE="$CONFIG_DIR/known_issues.md"

# Project-local issue tracker (project-specific issues)
# Detected from CWD — falls back to global if no .opencode/ found
if [ -f ".opencode/known_issues.md" ]; then
  PROJECT_ISSUES_FILE="$(pwd -P)/.opencode/known_issues.md"
  PROJECT_ISSUES_DIR="$(pwd -P)/.opencode"
else
  PROJECT_ISSUES_FILE="$ISSUES_FILE"
  PROJECT_ISSUES_DIR="$CONFIG_DIR"
fi

# Resolved issue archive — prefer project .opencode/ even when issues are global
if [ -d ".opencode" ]; then
  RESOLVED_FILE="$(pwd -P)/.opencode/resolved_issues.md"
else
  RESOLVED_FILE="$PROJECT_ISSUES_DIR/resolved_issues.md"
fi

# Reviewer count for branch/PR reviews (default: 1)
# Projects can override by setting REVIEWER_COUNT in their own config
REVIEWER_COUNT="${REVIEWER_COUNT:-1}"

# --- Jira Cloud sync (issue #48) -------------------------------------------
#
# Jira sync is ENABLED only when a valid configuration exists: base URL,
# project key, email, and API token are all present. The token is read
# EXCLUSIVELY from the environment (JIRA_API_TOKEN) — never from jira.json,
# never committed, never logged. Without valid config the sync is disabled and
# pipeline scripts behave exactly as before (zero Jira API calls).
#
# Config sources (per-field, env wins over file):
#   - `.opencode/jira.json` (project) — {baseUrl, email, projectKey,
#     statusMap?, authMode?}
#   - env vars: JIRA_BASE_URL, JIRA_PROJECT_KEY, JIRA_EMAIL, JIRA_AUTH_MODE,
#     JIRA_STATUS_MAP (JSON), JIRA_API_TOKEN (required, env only)
#
# Default status map (statusMap in jira.json overrides, else these):
#   backlog/ready → "To Do", in-progress → "In Progress", in-review →
#   "In Review", in-qa → "QA/Testing", in-publish → "Ready for Release",
#   resolved → "Done"
#
# Usage: jira_config_load && echo "enabled"; or check `sync-jira.sh config`.

# jira_config_load — resolve Jira config into globals
#   JIRA_BASE_URL, JIRA_PROJECT_KEY, JIRA_EMAIL, JIRA_AUTH_MODE, JIRA_STATUS_MAP
# Returns 0 when fully configured (token included), 1 otherwise.
jira_config_load() {
  # Capture env first — the function must NOT clobber caller-provided env vars
  local env_base="${JIRA_BASE_URL:-}" env_key="${JIRA_PROJECT_KEY:-}"
  local env_email="${JIRA_EMAIL:-}" env_auth="${JIRA_AUTH_MODE:-}" env_map="${JIRA_STATUS_MAP:-}"
  JIRA_BASE_URL=""
  JIRA_PROJECT_KEY=""
  JIRA_EMAIL=""
  JIRA_AUTH_MODE=""
  JIRA_STATUS_MAP=""
  local file_base="" file_key="" file_email="" file_auth="" file_status_map=""
  local file_base_b64="" file_key_b64="" file_email_b64="" file_auth_b64="" file_status_map_b64=""
  local cfg="${JIRA_CONFIG_FILE:-}"
  if [[ -z "$cfg" ]]; then
    for c in .opencode/jira.json "$CONFIG_DIR/.opencode/jira.json"; do
      if [[ -f "$c" ]]; then cfg="$c"; break; fi
    done
  fi
  if [[ -n "$cfg" && -f "$cfg" ]]; then
    if command -v python3 >/dev/null 2>&1; then
      # Values are base64-encoded so the eval-d `name=value` lines are always
      # single-word, quote-safe bash assignments (JSON strings with quotes,
      # spaces, or special chars survive verbatim).
      eval "$(JIRA_CFG="$cfg" python3 -c '
import json, os, sys, base64
try:
    d = json.load(open(os.environ["JIRA_CFG"]))
except Exception:
    sys.exit(0)
def b64(s):
    return base64.b64encode(s.encode("utf-8")).decode("ascii")
out = []
for k, envk in (("baseUrl", "file_base"), ("email", "file_email"),
                ("projectKey", "file_key"), ("authMode", "file_auth")):
    v = d.get(k, "")
    if isinstance(v, str) and v:
        out.append("%s_b64=%s" % (envk, b64(v)))
m = d.get("statusMap")
if isinstance(m, dict) and m:
    out.append("file_status_map_b64=%s" % b64(json.dumps(m)))
print("; ".join(out))')" 2>/dev/null || true
      file_base="$([[ -n "$file_base_b64" ]] && printf '%s' "$file_base_b64" | base64 -d 2>/dev/null || true)"
      file_email="$([[ -n "$file_email_b64" ]] && printf '%s' "$file_email_b64" | base64 -d 2>/dev/null || true)"
      file_key="$([[ -n "$file_key_b64" ]] && printf '%s' "$file_key_b64" | base64 -d 2>/dev/null || true)"
      file_auth="$([[ -n "$file_auth_b64" ]] && printf '%s' "$file_auth_b64" | base64 -d 2>/dev/null || true)"
      file_status_map="$([[ -n "$file_status_map_b64" ]] && printf '%s' "$file_status_map_b64" | base64 -d 2>/dev/null || true)"
    else
      # No python3: flat scalar fallback (statusMap not loaded — defaults apply)
      file_base="$(sed -n 's/.*"baseUrl"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$cfg" | head -1)"
      file_email="$(sed -n 's/.*"email"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$cfg" | head -1)"
      file_key="$(sed -n 's/.*"projectKey"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$cfg" | head -1)"
    fi
  fi
  # env wins over file (per-field); token is env-only (BR 1)
  JIRA_BASE_URL="${env_base:-$file_base}"
  JIRA_PROJECT_KEY="${env_key:-$file_key}"
  JIRA_EMAIL="${env_email:-$file_email}"
  JIRA_AUTH_MODE="${env_auth:-$file_auth}"
  JIRA_AUTH_MODE="${JIRA_AUTH_MODE:-basic}"
  JIRA_STATUS_MAP="${env_map:-$file_status_map}"
  [[ -n "$JIRA_BASE_URL" && -n "$JIRA_PROJECT_KEY" && -n "$JIRA_EMAIL" && -n "${JIRA_API_TOKEN:-}" ]]
}

# --- Secret redaction (issue #209, BR 3) -----------------------------------
#
# redact_secret <text> — masks credential-like patterns so secrets never reach
# outputs, logs, or fingerprints. Centralized helper: every script that can
# touch secrets MUST route its user-facing output through this function.
# Idempotent — safe to apply to already-masked text.
#
# Masked patterns:
#   - URL userinfo:  https://user:secret@host  →  https://user:****@host
#   - Known token env assignments: GITLAB_TOKEN=secret → GITLAB_TOKEN=****
#   - Generic secret-ish key=value / key:value (TOKEN/PASSWORD/SECRET/API_KEY),
#     case-insensitive
#
# Rule order matters: the generic rule runs FIRST so its value terminator
# (which stops at `@`) never swallows an already-masked `****@host` — the URL
# userinfo rule runs LAST and restores the canonical `user:****@host` form with
# the host preserved. The generic value also stops at whitespace so a spaced
# value (`TOKEN: glpat-abc`) is fully consumed with no leaked remainder.
redact_secret() {
  local s="$1"
  [[ -n "$s" ]] || return 0
  # Generic secret-ish assignments, case-insensitive (bare keys like PASSWORD/
  # TOKEN/SECRET anywhere in the text, or prefixed like DB_PASSWORD / API_KEY —
  # the prefix must end in `_`/`-` so the keyword alternation can match itself).
  # The value stops at whitespace, `=`, `:`, or `@` — so `TOKEN: glpat-abc`
  # masks fully (no ` glpat-abc` leak) and `x-access-token:ghp_123@github.com`
  # keeps `@github.com` for the URL rule below.
  s="$(printf '%s' "$s" | sed -E 's#\b([A-Za-z0-9_]*[_-])?(TOKEN|PASSWORD|PASSWD|SECRET|API[_-]?KEY)[=:][[:space:]]*[^[:space:]=:@]*#\1\2=****#gi')"
  # Known token environment variables (also covers export KEY=... prefix)
  s="$(printf '%s' "$s" | sed -E 's#((GITLAB_TOKEN|GITLAB_ACCESS_TOKEN|GH_TOKEN|GITHUB_TOKEN|CI_JOB_TOKEN|JIRA_API_TOKEN))=[^[:space:]]*#\1=****#g')"
  # URL userinfo LAST (git credential store lines, basic-auth URLs, ...).
  # Accepts `:` or `=` separators (the generic rule rewrites
  # `x-access-token:ghp_123@github.com` to `x-access-token=****@github.com`
  # first; this rule normalizes it back to `x-access-token:****@github.com`).
  # The token class is a greedy non-whitespace run that may itself contain `/`
  # (e.g. https://user:tok/en@host.com) AND `@` — it anchors to the LAST `@`
  # before the host, so `https://user:tok@en@host.com` masks the whole token
  # (`tok@en`) instead of leaking `en@` as part of the "host" (security F4).
  # The host is captured separately (`[^/[:space:]]+`) so a path after the
  # host (`/repo.git`) is preserved, never swallowed.
  s="$(printf '%s' "$s" | sed -E 's#(://[^:/@[:space:]]+)[=:][^[:space:]]*@([^/[:space:]]+)#\1:****@\2#g')"
  printf '%s' "$s"
}

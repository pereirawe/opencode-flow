#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/config.sh"

# Usage: issue-lint.sh <local_issue_id> [--strict]
#
# Mechanical validation of an issue entry — replaces the QA pre-development
# discovery agent (which only re-checked these rules) with a cheap, uniform
# check. Enforces the schema from standards/issues.md:
#   - Type / Status valid
#   - feat requires Business rules (non-empty, not the "-"/none placeholder)
#   - Tests: severity floor (critical/high >=3, medium >=2, low >=1; missing
#     severity => medium floor >=2); doc/chore may be "-"
#   - Reviewers: "<n> (profiles)" with >=1 profile
#   - Base branch present (required before promotion to in-progress)
#
# --strict: also warns on missing Remote at ready (used by the Committer gate).
# Exit 0 = PASS (no blocking findings), 2 = FAIL (blocking findings).

ID=${1:-}
STRICT=0
[[ "${2:-}" == "--strict" ]] && STRICT=1
if [[ -z "$ID" ]]; then echo "Usage: issue-lint.sh <id> [--strict]"; exit 3; fi

FILE="$PROJECT_ISSUES_FILE"
if [[ ! -f "$FILE" ]]; then echo "known_issues.md not found"; exit 3; fi

SECTION=$(awk -v id="$ID" '
  $0 ~ "^### " id "\\." {found=1}
  found { if ($0 ~ /^### [0-9]+\./ && $0 !~ "^### " id "\\.") exit; print }
' "$FILE")
if [[ -z "$SECTION" ]]; then echo "lint: FAIL — issue $ID not found"; exit 2; fi

field() { # <fieldname>
  printf '%s\n' "$SECTION" | awk -v f="$1" '
    $0 ~ "^- " f ":" {cap=1; sub("^- " f ": ?","",$0); print; next}
    cap && /^- [A-Za-z]/ {cap=0}
    cap {print}
  '
}
val() { field "$1" | head -1 | sed 's/^[[:space:]]*//'; }

TYPE=$(val "Type")
STATUS=$(val "Status")
SEVERITY=$(val "Severity")
BASE=$(val "Base branch")
REMOTE=$(val "Remote")
BUS=$(val "Business rules")
REVIEWERS=$(val "Reviewers")
TESTS_BLOCK=$(field "Tests")
TESTS_COUNT=$(printf '%s\n' "$TESTS_BLOCK" | sed '/^$/d' | grep -cE '.' || true)

FAIL=0
note() { echo "lint: $1"; }
fail() { echo "lint: FAIL — $1"; FAIL=1; }

[[ "$TYPE" =~ ^(bug|feat|doc|chore)$ ]] || fail "Type '$TYPE' invalid (bug|feat|doc|chore)"
[[ "$STATUS" =~ ^(backlog|ready|open|in-progress|in-review|in-qa|in-publish|resolved)$ ]] \
  || fail "Status '$STATUS' invalid"

if [[ "$TYPE" == "feat" ]]; then
  if [[ -z "$BUS" || "$BUS" == "-" || "$BUS" == "none" ]]; then
    fail "feat requires Business rules (got '${BUS:-empty}')"
  fi
fi

# Tests floor
if [[ "$TYPE" == "doc" || "$TYPE" == "chore" ]]; then
  :
elif [[ -z "$TESTS_BLOCK" || "$TESTS_COUNT" -eq 0 ]]; then
  fail "Tests: required for $TYPE (>=1 scenario)"
else
  FLOOR=2
  case "$SEVERITY" in
    critical|high) FLOOR=3 ;;
    medium) FLOOR=2 ;;
    low) FLOOR=1 ;;
    *) FLOOR=2 ;;  # missing severity => medium floor
  esac
  if [[ "$TESTS_COUNT" -lt "$FLOOR" ]]; then
    fail "Tests: $TYPE/$SEVERITY needs >=$FLOOR scenarios, found $TESTS_COUNT"
  fi
fi

# Reviewers format
if [[ -z "$REVIEWERS" || "$REVIEWERS" == "-" ]]; then
  fail "Reviewers: required (e.g. '1 (backend)')"
elif ! printf '%s' "$REVIEWERS" | grep -qE '^[0-9]+[[:space:]]*\(.+\)'; then
  fail "Reviewers: bad format '$REVIEWERS' (expect '<n> (profiles)')"
fi

# Base branch (needed before in-progress)
if [[ -z "$BASE" || "$BASE" == "-" ]]; then
  if [[ "$STATUS" == "in-progress" || "$STATUS" == "in-review" || "$STATUS" == "in-qa" || "$STATUS" == "in-publish" ]]; then
    fail "Base branch: missing but required at status '$STATUS'"
  else
    note "WARN: Base branch not set yet (will be required at promotion)"
  fi
fi

if [[ "$STRICT" == "1" && ( -z "$REMOTE" || "$REMOTE" == "-" ) ]]; then
  note "WARN: Remote missing at ready (auto-created during promotion)"
fi

if [[ "$FAIL" -eq 0 ]]; then
  echo "lint: PASS — issue $ID conforms to schema"
  exit 0
else
  exit 2
fi

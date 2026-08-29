#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/config.sh"

# Usage: append-issue.sh [flags]
#
# Appends a CANONICAL issue entry to the project/local known_issues.md using the
# exact schema from standards/issues.md. Removes PO/PM format variance — the
# discovery flow produces fields, this script writes them. Multiline values
# (tests, acceptance, business rules, description, impact) accept "\n" escapes.
#
# Flags:
#   --id <n>            issue id (auto if omitted = max+1)
#   --title <t>         required
#   --type <t>          bug|feat|doc|chore
#   --severity <s>      critical|high|medium|low
#   --priority <p>      low|medium|high|critical
#   --base <b>          base branch (default: detected later)
#   --reviewers <r>     "1 (backend)" etc.
#   --location <l>      file:line
#   --description <d>   (accepts \n)
#   --impact <i>        (accepts \n)
#   --business-rules <b> (accepts \n)
#   --acceptance <a>    (accepts \n)
#   --tests <t>         scenario lines (accepts \n)
#   --flow <f>          lean|escalated (bugs only)
#   --report <r>        reporter (default: model)
#   --status <s>        default backlog
#   --no-lint           skip the post-append lint

decode() { printf '%s' "${1:-}" | sed 's/\\n/\n/g'; }

ID=""
TITLE=""; TYPE="feat"; SEVERITY="medium"; PRIORITY="medium"
BASE="-"; REVIEWERS="1 (backend)"; LOCATION="-"
DESCRIPTION=""; IMPACT=""; BUS="-"; ACCEPTANCE=""; TESTS="-"
FLOW=""; REPORT="model"; STATUS="backlog"; LINT=1

while [[ $# -gt 0 ]]; do
  case "$1" in
    --id) ID="$2"; shift 2 ;;
    --title) TITLE="$2"; shift 2 ;;
    --type) TYPE="$2"; shift 2 ;;
    --severity) SEVERITY="$2"; shift 2 ;;
    --priority) PRIORITY="$2"; shift 2 ;;
    --base) BASE="$2"; shift 2 ;;
    --reviewers) REVIEWERS="$2"; shift 2 ;;
    --location) LOCATION="$2"; shift 2 ;;
    --description) DESCRIPTION="$2"; shift 2 ;;
    --impact) IMPACT="$2"; shift 2 ;;
    --business-rules) BUS="$2"; shift 2 ;;
    --acceptance) ACCEPTANCE="$2"; shift 2 ;;
    --tests) TESTS="$2"; shift 2 ;;
    --flow) FLOW="$2"; shift 2 ;;
    --report) REPORT="$2"; shift 2 ;;
    --status) STATUS="$2"; shift 2 ;;
    --no-lint) LINT=0; shift ;;
    *) echo "Unknown flag: $1"; exit 3 ;;
  esac
done

if [[ -z "$TITLE" ]]; then echo "append-issue: --title required"; exit 3; fi
FILE="$PROJECT_ISSUES_FILE"
if [[ ! -f "$FILE" ]]; then echo "known_issues.md not found"; exit 3; fi

if [[ -z "$ID" ]]; then
  ID=$(awk '/^### [0-9]+\./ {n=$2} END {print n+1}' "$FILE")
fi

FLOW_LINE=""
if [[ -n "$FLOW" && "$FLOW" != "-" ]]; then
  FLOW_LINE=$'\n'"- Flow: $FLOW"
fi

{
  echo ""
  echo "### $ID. $(decode "$TITLE")"
  echo "- Status: $STATUS"
  echo "- Type: $TYPE"
  echo "- Severity: $SEVERITY"
  echo "- Priority: $PRIORITY"
  printf '%s\n' "$FLOW_LINE"
  echo "- Report: $REPORT"
  echo "- Base branch: $BASE"
  echo "- Reviewers: $REVIEWERS"
  echo "- Remote: -"
  echo "- Jira: -"
  echo "- PR: -"
  echo "- Location: $LOCATION"
  echo "- Description: $(decode "$DESCRIPTION")"
  echo "- Impact: $(decode "$IMPACT")"
  echo "- Business rules: $(decode "$BUS")"
  echo "- Acceptance criteria: $(decode "$ACCEPTANCE")"
  echo "- Tests: $(decode "$TESTS")"
  echo "- Suggested fix: -"
} >> "$FILE"

echo "[append] issue $ID appended (status=$STATUS)"

if [[ "$LINT" -eq 1 ]]; then
  "$SCRIPTS_DIR/issue-lint.sh" "$ID" || true
fi

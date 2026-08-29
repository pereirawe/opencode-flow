#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/config.sh"

# Usage: committer-check.sh <local_issue_id>
#
# Mechanical gate verification for the Committer stage. Performs the objective
# checks (test cache, business-rules presence, security review report, status
# precondition) and prints a structured verdict. The committer AGENT then only
# applies judgment on the verdict instead of re-scanning files — saving tokens.
#
# Exit code: 0 = all hard gates pass (safe to set in-publish);
#            2 = a hard gate failed (do NOT set in-publish);
#            3 = usage/parse error.

ID=${1:-}
if [[ -z "$ID" ]]; then
  echo "Usage: committer-check.sh <id>"
  exit 3
fi

FILE="$PROJECT_ISSUES_FILE"
if [[ ! -f "$FILE" ]]; then
  echo "known_issues.md not found"
  exit 3
fi

SECTION=$(awk -v id="$ID" '
  $0 ~ "^### " id "\\." {found=1}
  found {
    if ($0 ~ /^### [0-9]+\./ && $0 !~ "^### " id "\\.") exit
    print
  }
' "$FILE")
if [[ -z "$SECTION" ]]; then
  echo "GATE: FAIL — issue $ID not found"
  exit 2
fi

STATUS=$(printf '%s\n' "$SECTION" | awk -F': ' '/^- Status:/ {print $2; exit}')
TYPE=$(printf '%s\n' "$SECTION" | awk -F': ' '/^- Type:/ {print $2; exit}')
REVIEWERS=$(printf '%s\n' "$SECTION" | awk -F': ' '/^- Reviewers:/ {print $2; exit}')
BUSRULES=$(printf '%s\n' "$SECTION" | awk -F': ' '/^- Business rules:/ {print $2; exit}')

echo "=== Committer gate check: #$ID ==="
echo "Status: ${STATUS:-(unknown)}"

FAIL=0

if [[ "$STATUS" != "in-review" && "$STATUS" != "in-qa" ]]; then
  echo "GATE: FAIL — status '$STATUS' (expected in-review/in-qa before publish)"
  FAIL=1
fi

echo -n "Tests cache: "
if "$SCRIPTS_DIR/test-runner.sh" --check >/dev/null 2>&1; then
  echo "PASS (fresh cache)"
else
  echo "MISSING — run test-runner --run before publish"
  FAIL=1
fi

if [[ "$TYPE" == "feat" ]]; then
  if [[ -z "$BUSRULES" || "$BUSRULES" == "-" ]]; then
    echo "GATE: WARN — feat without Business rules (committer may block)"
  else
    echo "Business rules: present"
  fi
fi

if printf '%s' "$REVIEWERS" | grep -qi 'security'; then
  REPORT=$(ls -1 "$PROJECT_ISSUES_DIR"/reviews/security-*.md 2>/dev/null | head -1 || true)
  if [[ -z "$REPORT" ]]; then
    echo "GATE: FAIL — security reviewer profile set but no report found"
    FAIL=1
  elif grep -qi 'refuse\|unresolved critical\|unresolved high' "$REPORT"; then
    echo "GATE: FAIL — security report refuses approval (unresolved critical/high)"
    FAIL=1
  else
    echo "Security review: report present and approved ($REPORT)"
  fi
fi

if [[ "$FAIL" -eq 0 ]]; then
  echo "VERDICT: PASS — safe to transition -> in-publish"
  exit 0
else
  echo "VERDICT: FAIL — do NOT set in-publish; route back through review loop"
  exit 2
fi

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

# security_report_blocks <report> — returns 0 (ok) when the security report
# approves, 1 (block) when it refuses approval. The verdict is read from the
# LAST verdict anchor (`## Verdict` section or `**Verdict:**` header) with a
# bounded window, so quoted/archived earlier REFUSED rounds inside a final
# APPROVED report are never mistaken for the current verdict.
security_report_blocks() {
  local report="$1" anchor text
  anchor=$(awk '
    /^#+[[:space:]]*Verdict/ {l=NR}
    /\*\*Verdict\*\*/ {l=NR}
    END{print l+0}
  ' "$report")
  if [[ "$anchor" -gt 0 ]]; then
    text=$(awk -v s="$anchor" 'NR>=s{print; if (NR>s && /^#{1,3}[[:space:]]/){exit}}' "$report")
  else
    text=$(cat "$report")
  fi
  text=$(printf '%s' "$text" | sed -E \
    's/no unresolved (critical|high)[^.]*\.//gi; s/(does ?not|do ?not|doesn.?t|not) block ?approval[^.]*\./DOES_NOT_BLOCK_APPROVAL./gi')
  if printf '%s' "$text" | grep -qiE \
    'refus|request ?[-_ ]?changes|changes requested|denied|block ?approval|not approved|does+ ?not ?pass|gate does not|minimum required fixes|unresolved (critical|high)'; then
    return 0
  fi
  # Only explicit approval clears the gate; an unverifiable report is treated
  # as blocking (never assume approval from silence).
  printf '%s' "$text" | grep -qiE 'APPROVED|APPROVE|PASS|SATISFIED' && return 1
  return 0
}

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
  # Prefer issue-scoped reports, most recent by mtime (handles -recheck/-rereview
  # superseding the original verdict). No broad legacy fallback: that was the
  # #222 false-GATE-FAIL (report of another issue picked via `ls | head -1`).
  REPORT=""
  for pattern in "security-issue-${ID}-" "security-${ID}-"; do
    REPORT=$(ls -1t "$PROJECT_ISSUES_DIR"/reviews/${pattern}*.md 2>/dev/null | head -1 || true)
    [[ -n "$REPORT" ]] && break
  done
  if [[ -z "$REPORT" ]]; then
    echo "GATE: FAIL — security reviewer profile set but no issue-scoped report found (expected reviews/security-issue-${ID}-*.md)"
    FAIL=1
  elif security_report_blocks "$REPORT"; then
    echo "GATE: FAIL — security report refuses approval ($REPORT)"
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

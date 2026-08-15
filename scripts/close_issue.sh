#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/config.sh"

# Usage: $SCRIPTS_DIR/close_issue.sh <local_issue_id>

ID=${1:-}
if [[ -z "$ID" ]]; then
  echo "Usage: close_issue.sh <id>"
  exit 1
fi

FILE="$PROJECT_ISSUES_FILE"
if [[ ! -f "$FILE" ]]; then
  echo "known_issues.md not found"
  exit 1
fi

SECTION=$(awk -v id="$ID" '
  /^### Status/ {exit}
  $0 ~ "^### " id "\\." {found=1}
  found {
    if ($0 ~ /^### [0-9]+\./ && $0 !~ "^### " id "\\.") {
      exit
    }
    print
  }
' "$FILE")

if [[ -z "$SECTION" ]]; then
  echo "Issue $ID not found"
  exit 1
fi

STATUS=$(printf '%s\n' "$SECTION" | awk -F': ' '/^- Status:/ {print $2; exit}')
REMOTE_REF=$(printf '%s\n' "$SECTION" | awk -F': ' '/^- Remote:/ {print $2; exit}')
REMOTE_ID=${REMOTE_REF#\#}
PR_REF=$(printf '%s\n' "$SECTION" | awk -F': ' '/^- PR:/ {print $2; exit}')
PR_ID=${PR_REF#\#}
REMOTE_URL=$(git config --get remote.origin.url)

if [[ "$STATUS" != "in-publish" && "$STATUS" != "resolved" ]]; then
  echo "Issue $ID cannot be closed from status '$STATUS'"
  echo "Only in-publish and resolved statuses are accepted"
  exit 1
fi

SHOULD_CLOSE_REMOTE=true

if [[ -n "$REMOTE_ID" && "$REMOTE_ID" != "-" ]]; then
  # For resolved: check if remote is already closed
  if [[ "$STATUS" == "resolved" ]]; then
    if [[ "$REMOTE_URL" == *"github.com"* ]]; then
      REMOTE_STATE=$(gh issue view "$REMOTE_ID" --json state --jq '.state' 2>/dev/null || echo "UNKNOWN")
      if [[ "$REMOTE_STATE" == "CLOSED" ]]; then
        echo "[remote] Issue #$REMOTE_ID is already closed — skipping remote close"
        SHOULD_CLOSE_REMOTE=false
      fi
    fi
  fi

  # For in-publish: verify PR is merged before closing
  if [[ "$STATUS" == "in-publish" && -n "$PR_ID" && "$PR_ID" != "-" ]]; then
    if [[ "$REMOTE_URL" == *"github.com"* ]]; then
      PR_STATE=$(gh pr view "$PR_ID" --json state --jq '.state' 2>/dev/null || echo "UNKNOWN")
      if [[ "$PR_STATE" != "MERGED" ]]; then
        echo "[pr] PR #$PR_ID not merged yet (state: $PR_STATE). Skipping remote close."
        SHOULD_CLOSE_REMOTE=false
      fi
    fi
  fi

  # Confirm with user before closing remote
  if $SHOULD_CLOSE_REMOTE; then
    read -r -p "Fechar issue #$REMOTE_ID no remote? (s/N) " CONFIRM || true
    if [[ "$CONFIRM" != "s" && "$CONFIRM" != "S" ]]; then
      echo "[remote] User cancelled — skipping remote close"
      SHOULD_CLOSE_REMOTE=false
    fi
  fi

  if $SHOULD_CLOSE_REMOTE; then
    if [[ "$REMOTE_URL" == *"github.com"* ]]; then
      gh issue close "$REMOTE_ID" || echo "[remote] Warning: failed to close issue #$REMOTE_ID"
    elif [[ "$REMOTE_URL" == *"gitlab"* ]]; then
      glab issue close "$REMOTE_ID" || echo "[remote] Warning: failed to close issue #$REMOTE_ID"
    fi
  fi
fi

# Jira Cloud sync (issue #48): at close time the card is moved to the terminal
# state (resolved → Done/Closed) for BOTH accepted statuses — the real pipeline
# closes in-publish entries right after the PR merge and archives without ever
# passing through resolved, so --terminal forces the resolved mapping (reviewer
# finding). Runs before archiving (entry still present). Non-blocking (BR 8).
if [[ "$STATUS" == "in-publish" || "$STATUS" == "resolved" ]] \
   && "$SCRIPTS_DIR/sync-jira.sh" config >/dev/null 2>&1; then
  "$SCRIPTS_DIR/sync-jira.sh" transition "$FILE" "$ID" --terminal \
    || echo "[jira] Warning: Jira transition failed for issue $ID (non-blocking)"
fi

# Extract fields for archive
TITLE=$(printf '%s\n' "$SECTION" | sed -n '1s/^### [0-9]*\. //p')
TYPE=$(printf '%s\n' "$SECTION" | awk -F': ' '/^- Type:/ {print $2; exit}')
SEVERITY=$(printf '%s\n' "$SECTION" | awk -F': ' '/^- Severity:/ {print $2; exit}')
REPORTED_BY=$(printf '%s\n' "$SECTION" | awk -F': ' '/^- Report:/ {print $2; exit}')
REVIEWERS=$(printf '%s\n' "$SECTION" | awk -F': ' '/^- Reviewers:/ {print $2; exit}')
# Strip profiles, keep only count for archive (BR11)
REVIEWER_COUNT=$(printf '%s\n' "$REVIEWERS" | grep -o '^[0-9]*' || echo "1")
DESC=$(printf '%s\n' "$SECTION" | awk -F': ' '/^- Description:/ {print $2; exit}')
SUGGESTED=$(printf '%s\n' "$SECTION" | awk -F': ' '/^- Suggested fix:/ {print $2; exit}')
# Lifecycle timestamps (issue #57). Missing fields are tolerated (`-` allowed).
OPENED_DATE=$(printf '%s\n' "$SECTION" | awk -F': ' '/^- Opened:/ {print $2; exit}')
READY_DATE=$(printf '%s\n' "$SECTION" | awk -F': ' '/^- Ready:/ {print $2; exit}')
STARTED_DATE=$(printf '%s\n' "$SECTION" | awk -F': ' '/^- Started:/ {print $2; exit}')
RESOLVED_DATE=$(date +%Y-%m-%d)
SUMMARY="${DESC:-no description}${SUGGESTED:+ — ${SUGGESTED}}"

# days_between <start|-> <end|-> — prints "<N>d" or "-"
# Duration math is UTC-anchored (TZ=UTC date -d "$d" +%s), which is DST-robust
# (BR 4): naive local-epoch /86400 day counting fails the spring-forward DST
# scenario (23-hour day → integer division floors to 0 days).
# Guards (BR 5/BR 10): start > end renders `-` BEFORE division; missing dates
# render `-`; differences are floored at 0 (non-negative); diff == 0 → "0d".
days_between() {
  local s="$1" e="$2"
  if [[ -z "$s" || -z "$e" || "$s" == "-" || "$e" == "-" ]]; then
    echo "-"; return
  fi
  local se ee
  se=$(TZ=UTC date -d "$s" +%s 2>/dev/null || echo "")
  ee=$(TZ=UTC date -d "$e" +%s 2>/dev/null || echo "")
  if [[ -z "$se" || -z "$ee" ]]; then
    echo "-"; return
  fi
  if (( ee < se )); then
    echo "-"; return
  fi
  local diff=$(( (ee - se) / 86400 ))
  if (( diff < 0 )); then diff=0; fi
  echo "${diff}d"
}

# Compute per-stage durations (BR 12): backlog (Opened→Ready), waiting
# (Ready→Started), dev (Started→Resolved), total (Opened→Resolved, relative to
# the close date — BR 6). When ALL dates are missing, output the literal
# `- Durations: -` (BR 5).
BACKLOG_D=$(days_between "$OPENED_DATE" "$READY_DATE")
WAITING_D=$(days_between "$READY_DATE" "$STARTED_DATE")
DEV_D=$(days_between "$STARTED_DATE" "$RESOLVED_DATE")
TOTAL_D=$(days_between "$OPENED_DATE" "$RESOLVED_DATE")
if [[ "$BACKLOG_D$WAITING_D$DEV_D$TOTAL_D" == "----" ]]; then
  DURATIONS_VAL="-"
else
  DURATIONS_VAL="backlog=$BACKLOG_D waiting=$WAITING_D dev=$DEV_D total=$TOTAL_D"
fi

# Ensure resolved archive exists (rewrite block below always writes the header)
if [[ ! -f "$RESOLVED_FILE" ]]; then
  : > "$RESOLVED_FILE"
fi

# Prepend to resolved archive (newest first), always rewriting the header.
# Clean stale temp files from previous failed runs, then create a fresh one
# in the target directory (same filesystem) for an atomic rename.
rm -f "$(dirname "$RESOLVED_FILE")"/.resolved.*
TMP_ARCHIVE=$(mktemp "$(dirname "$RESOLVED_FILE")/.resolved.XXXXXX")
trap 'rm -f "$TMP_ARCHIVE"' EXIT
printf '# Resolved Issues\n' > "$TMP_ARCHIVE"
printf '\n' >> "$TMP_ARCHIVE"
printf 'Issues resolved from `known_issues.md`. See `standards/resolved-issue.md` for format.\n' >> "$TMP_ARCHIVE"
printf '\n' >> "$TMP_ARCHIVE"
printf '### %s. %s\n' "$ID" "$TITLE" >> "$TMP_ARCHIVE"
printf -- '- Resolved: %s\n' "$RESOLVED_DATE" >> "$TMP_ARCHIVE"
printf -- '- Durations: %s\n' "$DURATIONS_VAL" >> "$TMP_ARCHIVE"
printf -- '- Severity: %s\n' "${SEVERITY:-medium}" >> "$TMP_ARCHIVE"
printf -- '- Type: %s\n' "${TYPE:-chore}" >> "$TMP_ARCHIVE"
printf -- '- Report: %s\n' "${REPORTED_BY:-unknown}" >> "$TMP_ARCHIVE"
printf -- '- Reviewers: %s\n' "${REVIEWER_COUNT:-1}" >> "$TMP_ARCHIVE"
printf -- '- Remote: %s\n' "${REMOTE_REF:--}" >> "$TMP_ARCHIVE"
printf -- '- Summary: %s\n' "$SUMMARY" >> "$TMP_ARCHIVE"
printf '\n' >> "$TMP_ARCHIVE"
# Append existing entries in full — skip only the canonical 4-line header;
# keep every entry, even corrupted ones (no data is ever truncated).
awk '
  NR <= 4 && ($0 == "# Resolved Issues" || $0 == "" ||
               $0 ~ /^Issues resolved from `known_issues\.md`/) { next }
  { print }
' "$RESOLVED_FILE" >> "$TMP_ARCHIVE"
mv "$TMP_ARCHIVE" "$RESOLVED_FILE"
echo "[archive] Appended to $RESOLVED_FILE"

# Remove entry from known_issues.md
awk -v id="$ID" '
BEGIN{skip=0}
$0 ~ "^### " id "\\." {skip=1; next}
skip == 1 && $0 ~ /^### [0-9]+\./ {skip=0}
skip == 0 {print}
' "$FILE" > "$FILE.tmp" && mv "$FILE.tmp" "$FILE"

echo "[issue] closed $ID, archived to resolved_issues.md"

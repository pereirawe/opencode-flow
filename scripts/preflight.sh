#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/config.sh"

# Usage: preflight.sh <local_issue_id>
#
# Cheap mechanical warm-up for an issue BEFORE it is developed. Produces a
# structured notes file (.opencode/preflight/issue-<id>.md) so the Developer
# agent can skip re-exploration and start implementing sooner — shortening the
# development cycle (see develop-full "warm next issue" step).
#
# Purely mechanical: inventories files by the issue Location, lists candidate
# test files, and surfaces obvious gaps (missing business rules / location).
# No judgment, no code — just a head start.

ID=${1:-}
if [[ -z "$ID" ]]; then
  echo "Usage: preflight.sh <id>"
  exit 1
fi

FILE="$PROJECT_ISSUES_FILE"
if [[ ! -f "$FILE" ]]; then
  echo "known_issues.md not found"
  exit 1
fi

SECTION=$(awk -v id="$ID" '
  $0 ~ "^### " id "\\." {found=1}
  found {
    if ($0 ~ /^### [0-9]+\./ && $0 !~ "^### " id "\\.") exit
    print
  }
' "$FILE")
if [[ -z "$SECTION" ]]; then
  echo "Issue $ID not found"
  exit 1
fi

REPO_ROOT="$(dirname "$PROJECT_ISSUES_DIR")"
OUT_DIR="$PROJECT_ISSUES_DIR/preflight"
mkdir -p "$OUT_DIR"
OUT="$OUT_DIR/issue-$ID.md"

TITLE=$(printf '%s\n' "$SECTION" | sed -n '1s/^### [0-9]*\. //p')
TYPE=$(printf '%s\n' "$SECTION" | awk -F': ' '/^- Type:/ {print $2; exit}')
LOCATION=$(printf '%s\n' "$SECTION" | awk -F': ' '/^- Location:/ {print $2; exit}')
STATUS=$(printf '%s\n' "$SECTION" | awk -F': ' '/^- Status:/ {print $2; exit}')
BUSRULES=$(printf '%s\n' "$SECTION" | awk -F': ' '/^- Business rules:/ {print $2; exit}')
ACCEPT=$(printf '%s\n' "$SECTION" | awk -F': ' '/^- Acceptance criteria:/ {print $2; exit}')

FILES=()
TESTS=()
if [[ -n "$LOCATION" && "$LOCATION" != "-" ]]; then
  if [[ -d "$REPO_ROOT/$LOCATION" ]]; then
    mapfile -t FILES < <(git -C "$REPO_ROOT" ls-files -- "$LOCATION" 2>/dev/null | head -60)
    mapfile -t TESTS < <(git -C "$REPO_ROOT" ls-files -- "$LOCATION" 2>/dev/null | grep -iE '(test|spec)' | head -30)
  elif [[ -f "$REPO_ROOT/$LOCATION" ]]; then
    FILES=("$LOCATION")
    DIR=$(dirname "$LOCATION")
    mapfile -t TESTS < <(git -C "$REPO_ROOT" ls-files -- "$DIR" 2>/dev/null | grep -iE '(test|spec)' | head -30)
  else
    mapfile -t FILES < <(git -C "$REPO_ROOT" ls-files 2>/dev/null | grep -F "$LOCATION" | head -60)
    mapfile -t TESTS < <(git -C "$REPO_ROOT" ls-files 2>/dev/null | grep -iE '(test|spec)' | grep -F "$LOCATION" | head -30)
  fi
fi

{
  echo "# Preflight: #$ID — $TITLE"
  echo
  echo "- Type: ${TYPE:--}"
  echo "- Status: ${STATUS:--}"
  echo "- Location: ${LOCATION:-(none)}"
  echo "- Generated: $(date +%Y-%m-%d) (mechanical, no judgment)"
  echo
  echo "## File inventory (by Location)"
  if [[ ${#FILES[@]} -gt 0 ]]; then
    for f in "${FILES[@]}"; do echo "- $f"; done
  else
    echo "- (no files matched Location — verify path or broaden search)"
  fi
  echo
  echo "## Candidate test files"
  if [[ ${#TESTS[@]} -gt 0 ]]; then
    for t in "${TESTS[@]}"; do echo "- $t"; done
  else
    echo "- (none detected near Location)"
  fi
  echo
  echo "## Mechanical gap flags"
  if [[ "$TYPE" == "feat" && ( -z "$BUSRULES" || "$BUSRULES" == "-" ) ]]; then
    echo "- WARNING: feat issue without Business rules — Committer will block."
  fi
  if [[ -z "$LOCATION" || "$LOCATION" == "-" ]]; then
    echo "- WARNING: no Location set — Developer must discover target files."
  fi
  if [[ -z "$ACCEPT" || "$ACCEPT" == "-" ]]; then
    echo "- NOTE: no Acceptance criteria recorded."
  fi
  echo
  echo "## Developer handoff"
  echo "Consume this file to skip re-exploration: read the file inventory above,"
  echo "locate the implementation entry point, and draft the change + tests."
} > "$OUT"

echo "[preflight] wrote $OUT (${#FILES[@]} files, ${#TESTS[@]} tests)"

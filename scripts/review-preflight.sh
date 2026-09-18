#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/config.sh"

# Usage: review-preflight.sh <issue-id> <profile>
#
# Scoped context injection for parallel senior reviewers. Produces a
# profile-filtered notes file (.opencode/preflight/review-<id>-<profile>.md)
# so each reviewer can skip broad re-exploration and focus on the files that
# match its domain — shortening the review phase (see develop-full "parallel
# senior review" step).
#
# Purely mechanical: extracts the issue section from known_issues.md, lists
# the diff against the issue's Base branch, and filters the changed files by
# the profile's globs. No judgment, no code — just a scoped head start.
#
# Exit codes: 0 success, 2 usage/error.

# Profile -> file-globs mapping (business rule 4). Canonical constant.
declare -A PROFILE_GLOBS=(
  [backend]='**/*.go **/*.py **/*.rb **/handlers/** **/controllers/**'
  [frontend]='**/*.tsx **/*.jsx **/*.vue **/*.css **/*.scss'
  [data]='**/*.sql migrations/** schemas/**'
  [security]='auth/** middleware/** **/security/** .env* Dockerfile'
  [runtime]='Dockerfile* docker-compose* .github/workflows/** deploy/** k8s/**'
  [devops]='.github/** ci/** scripts/** Makefile'
  [performance]='**/*.go **/*.py **/*.tsx cache/** perf/**'
  [ux-ui]='**/*.tsx **/*.jsx **/*.html **/*.css'
  [qa]='**/*_test.* tests/** spec/**'
  [mobile]='**/*.swift **/*.kt android/** ios/**'
  [auth]='auth/** **/auth/** middleware/**'
)

usage() {
  echo "Usage: review-preflight.sh <issue-id> <profile>" >&2
  echo "Profiles: ${!PROFILE_GLOBS[*]}" >&2
}

# glob_to_regex <glob> — converts a ** glob into an anchored ERE.
# **/ matches zero or more directory prefixes; ** matches across directories.
glob_to_regex() {
  local g="$1" out
  out=$(printf '%s' "$g" | sed -E 's/[]^$.+(){}|\\[]/\\&/g')
  out=$(printf '%s' "$out" | sed 's|\*\*/|@STARSTAR@|g')
  out=$(printf '%s' "$out" | sed 's|\*\*|@DOTSTAR@|g')
  out=$(printf '%s' "$out" | sed 's|\*|[^/]*|g')
  out=$(printf '%s' "$out" | sed 's|?|[^/]|g')
  out=$(printf '%s' "$out" | sed 's#@STARSTAR@#(^|.*/)#g; s#@DOTSTAR@#.*#g')
  printf '^%s$' "$out"
}

ID=${1:-}
PROFILE=${2:-}
if [[ -z "$ID" || -z "$PROFILE" ]]; then
  usage
  exit 2
fi
if [[ -z "${PROFILE_GLOBS[$PROFILE]+x}" ]]; then
  echo "Error: invalid profile '$PROFILE'" >&2
  usage
  exit 2
fi

# Resolve the issue source: project file first, global fallback (the opencode
# repo itself tracks config-level issues in the global file).
FILE="$PROJECT_ISSUES_FILE"
if [[ ! -f "$FILE" && -f "$ISSUES_FILE" ]]; then
  FILE="$ISSUES_FILE"
fi
if [[ ! -f "$FILE" ]]; then
  echo "Error: known_issues.md not found (looked at $PROJECT_ISSUES_FILE and $ISSUES_FILE)" >&2
  exit 2
fi

SECTION=$(awk -v id="$ID" '
  $0 ~ "^### " id "\\." {found=1}
  found {
    if ($0 ~ /^### [0-9]+\./ && $0 !~ "^### " id "\\.") exit
    print
  }
' "$FILE")
if [[ -z "$SECTION" && "$FILE" != "$ISSUES_FILE" && -f "$ISSUES_FILE" ]]; then
  FILE="$ISSUES_FILE"
  SECTION=$(awk -v id="$ID" '
    $0 ~ "^### " id "\\." {found=1}
    found {
      if ($0 ~ /^### [0-9]+\./ && $0 !~ "^### " id "\\.") exit
      print
    }
  ' "$FILE")
fi
if [[ -z "$SECTION" ]]; then
  echo "Error: issue $ID not found in known_issues.md" >&2
  exit 2
fi

TITLE=$(printf '%s\n' "$SECTION" | sed -n '1s/^### [0-9]*\. //p')
TYPE=$(printf '%s\n' "$SECTION" | awk -F': ' '/^- Type:/ {print $2; exit}')
SEVERITY=$(printf '%s\n' "$SECTION" | awk -F': ' '/^- Severity:/ {print $2; exit}')
PRIORITY=$(printf '%s\n' "$SECTION" | awk -F': ' '/^- Priority:/ {print $2; exit}')
BASE_BRANCH=$(printf '%s\n' "$SECTION" | awk -F': ' '/^- Base branch:/ {print $2; exit}')
BASE_BRANCH=${BASE_BRANCH:-main}
[[ "$BASE_BRANCH" == "-" ]] && BASE_BRANCH="main"

# Multi-line block extraction: from the field line until the next "- " field.
BUSRULES=$(printf '%s\n' "$SECTION" | awk '
  /^- Business rules:/ {found=1; sub(/^- Business rules:[[:space:]]*/, ""); print; next}
  found && /^- / {exit}
  found {print}
')
ACCEPT=$(printf '%s\n' "$SECTION" | awk '
  /^- Acceptance criteria:/ {found=1; sub(/^- Acceptance criteria:[[:space:]]*/, ""); print; next}
  found && /^- / {exit}
  found {print}
')
TESTS=$(printf '%s\n' "$SECTION" | awk '
  /^- Tests:/ {found=1; sub(/^- Tests:[[:space:]]*/, ""); print; next}
  found && /^- / {exit}
  found {print}
')

# Diff against the issue's Base branch (read-only git commands only).
DIFF_STAT=""
DIFF_FILES=""
if git rev-parse --is-inside-work-tree >/dev/null 2>&1 && \
   git rev-parse --verify "$BASE_BRANCH" >/dev/null 2>&1; then
  DIFF_STAT=$(git diff --stat "$BASE_BRANCH...HEAD" 2>/dev/null || true)
  DIFF_FILES=$(git diff --name-only "$BASE_BRANCH...HEAD" 2>/dev/null || true)
else
  DIFF_STAT="(not a git repo or base branch '$BASE_BRANCH' not found)"
fi

# Filter the diff paths by the profile's globs.
REGEX=""
for g in ${PROFILE_GLOBS[$PROFILE]}; do
  r=$(glob_to_regex "$g")
  if [[ -n "$REGEX" ]]; then REGEX+="|"; fi
  REGEX+="$r"
done
MATCHED=()
if [[ -n "$DIFF_FILES" ]]; then
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    if printf '%s\n' "$f" | grep -Eq "$REGEX"; then
      MATCHED+=("$f")
    fi
  done <<< "$DIFF_FILES"
fi

# Test-cache status: report the --check exit code as text, never re-run tests.
TEST_CACHE_LINE="Test cache: check unavailable"
if [[ -x "$SCRIPTS_DIR/test-runner.sh" ]]; then
  set +e
  "$SCRIPTS_DIR/test-runner.sh" --check >/dev/null 2>&1
  rc=$?
  set -e
  if [[ $rc -eq 0 ]]; then
    TEST_CACHE_LINE="Test cache: fresh (PASS)"
  elif [[ $rc -eq 3 ]]; then
    TEST_CACHE_LINE="Test cache: stale/absent (exit 3)"
  else
    TEST_CACHE_LINE="Test cache: check exit $rc"
  fi
fi

OUT_DIR=".opencode/preflight"
mkdir -p "$OUT_DIR"
OUT="$OUT_DIR/review-$ID-$PROFILE.md"

{
  echo "# Review preflight: #$ID — $TITLE"
  echo
  echo "- Type: ${TYPE:--}"
  echo "- Severity: ${SEVERITY:--}"
  echo "- Priority: ${PRIORITY:--}"
  echo "- Profile: $PROFILE"
  echo "- Generated: $(date +%Y-%m-%d) (mechanical, no judgment)"
  echo
  echo "## Business rules"
  if [[ -n "$BUSRULES" && "$BUSRULES" != "-" ]]; then
    printf '%s\n' "$BUSRULES"
  else
    echo "- (none documented)"
  fi
  echo
  echo "## Acceptance criteria"
  if [[ -n "$ACCEPT" && "$ACCEPT" != "-" ]]; then
    printf '%s\n' "$ACCEPT"
  else
    echo "- (none documented)"
  fi
  echo
  echo "## Tests"
  if [[ -n "$TESTS" && "$TESTS" != "-" ]]; then
    printf '%s\n' "$TESTS"
  else
    echo "- (none documented)"
  fi
  echo
  echo "## Diff (against $BASE_BRANCH)"
  if [[ -n "$DIFF_STAT" ]]; then
    printf '%s\n' "$DIFF_STAT"
  else
    echo "(no diff)"
  fi
  echo
  echo "## Files affected (filtered: $PROFILE)"
  if [[ ${#MATCHED[@]} -gt 0 ]]; then
    for f in "${MATCHED[@]}"; do echo "- $f"; done
  else
    echo "TRIVIAL: no files matching profile $PROFILE in this diff — reviewer may approve without deep read."
  fi
  echo
  echo "$TEST_CACHE_LINE"
} > "$OUT"

echo "[review-preflight] wrote $OUT (${#MATCHED[@]} files matched profile $PROFILE)"
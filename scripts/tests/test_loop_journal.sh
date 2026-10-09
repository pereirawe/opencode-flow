#!/usr/bin/env bash
# test_loop_journal.sh — regression test for issue #244: scripts/loop-journal.sh
# (structured per-loop error journal, JSONL append/list/clear).
#
# Coverage:
#   t01 — append writes one JSON object per line with all fields (round-trip)
#   t02 — message escaping: a double quote and a backslash survive list --format jsonl
#   t03 — list --format md renders a human table with the key values
#   t04 — path echoes the resolved journal file (honors --journal)
#   t05 — clear truncates the journal
#   t06 — invalid --severity is rejected (exit 3)
#   t07 — bash -n: loop-journal.sh parses
#
# Self-contained: mktemp + trap.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/lib.sh"
t_begin "test_loop_journal"

JOURNAL="$HERE/../loop-journal.sh"
[[ -f "$JOURNAL" ]] || { t_fail "loop-journal.sh not found at $JOURNAL"; t_finish; exit 1; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
J="$TMP/loop-develop-244.jsonl"
OUT="$TMP/out"

# t01 — full append round-trip
bash "$JOURNAL" append --journal "$J" --loop develop --id 244 --phase review \
  --severity high --scope global --location "scripts/foo.sh:10" \
  --command "scripts/foo.sh 244" --exit-code 2 --message "boom global" >"$OUT" 2>&1
assert_eq "0" "$?" "t01a append exits 0"
bash "$JOURNAL" list --journal "$J" --format jsonl >"$OUT" 2>&1
assert_eq "1" "$(wc -l < "$OUT" | tr -d ' ')" "t01b one JSON line written"
for f in '"loop":"develop"' '"id":"244"' '"phase":"review"' '"severity":"high"' '"scope":"global"' '"exit_code":"2"' '"message":"boom global"'; do
  assert_contains "$OUT" "$f" "t01c round-trip $f"
done

# t02 — escaping: quote + backslash + newline survive
bash "$JOURNAL" append --journal "$J" --loop develop --id 244 --phase review \
  --severity low --scope project --location 'src/a b.py:1' \
  --message 'quote " and back\slash' >>"$OUT" 2>&1
bash "$JOURNAL" list --journal "$J" --format jsonl >"$OUT" 2>&1
assert_contains "$OUT" '\" and back\\slash' "t02 escaped quote+backslash round-trip"
assert_eq "2" "$(wc -l < "$OUT" | tr -d ' ')" "t02b two lines after second append"

# t03 — markdown table
bash "$JOURNAL" list --journal "$J" --format md >"$OUT" 2>&1
assert_contains "$OUT" "develop#244" "t03a md header has loop label"
assert_contains "$OUT" "scripts/foo.sh:10" "t03b md shows location"
assert_contains "$OUT" "global" "t03c md shows scope"

# t04 — path
bash "$JOURNAL" path --journal "$J" >"$OUT" 2>&1
assert_eq "$J" "$(cat "$OUT")" "t04 path echoes resolved file"

# t05 — clear
bash "$JOURNAL" clear --journal "$J" >"$OUT" 2>&1
bash "$JOURNAL" list --journal "$J" >"$OUT" 2>&1
assert_eq "0" "$(wc -l < "$OUT" | tr -d ' ')" "t05 clear truncates journal"

# t06 — invalid severity rejected
bash "$JOURNAL" append --journal "$J" --severity nope --message x >"$OUT" 2>&1
assert_eq "3" "$?" "t06 invalid severity exits 3"

# t08 — control chars (ANSI ESC) are stripped so JSONL stays valid
bash "$JOURNAL" append --journal "$J" --message "$(printf 'ansi \033[31mred\033[0m')" >"$OUT" 2>&1
bash "$JOURNAL" list --journal "$J" --format jsonl >"$OUT" 2>&1
if grep -q $'\033' "$OUT"; then t_fail "t08 ANSI ESC leaked into JSONL"; else t_ok "t08 control chars stripped"; fi

# t07 — syntax
bash -n "$JOURNAL" 2>/dev/null
assert_eq "0" "$?" "t07 loop-journal.sh bash -n"

t_finish

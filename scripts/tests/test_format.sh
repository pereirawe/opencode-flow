#!/usr/bin/env bash
# Tests for scripts/format.sh and its integration with scripts/pre_commit.sh.
# Uses fake formatter shims on PATH so the suite does not depend on prettier,
# gofmt, shfmt, ruff or black being installed.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/lib.sh"
t_begin "test_format"

FORMAT="$HERE/../format.sh"
PRE_COMMIT="$HERE/../pre_commit.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

BASH_BIN="$(command -v bash)"
GIT_BIN="$(command -v git)"
GREP_BIN="$(command -v grep)"

# --- fake gofmt shim --------------------------------------------------------
BIN="$TMP/bin"
mkdir -p "$BIN"
cat > "$BIN/gofmt" <<'SHIM'
#!/usr/bin/env bash
# Minimal fake gofmt: -w appends a marker; -l lists files lacking it.
mode=""; files=()
for a in "$@"; do
  case "$a" in
    -w) mode=w ;;
    -l) mode=l ;;
    *) files+=("$a") ;;
  esac
done
if [ "$mode" = "w" ]; then
  for f in "${files[@]}"; do
    grep -q 'FORMATTED' "$f" || printf '\n// FORMATTED\n' >> "$f"
  done
elif [ "$mode" = "l" ]; then
  for f in "${files[@]}"; do
    grep -q 'FORMATTED' "$f" || printf '%s\n' "$f"
  done
fi
SHIM
chmod +x "$BIN/gofmt"

# --- minimal PATH without any formatter -------------------------------------
MIN="$TMP/minbin"
mkdir -p "$MIN"
ln -s "$GIT_BIN" "$MIN/git"
ln -s "$GREP_BIN" "$MIN/grep"

mk_repo() {
  local d="$1"
  mkdir -p "$d"
  git -C "$d" init -q
  git -C "$d" config user.email test@example.com
  git -C "$d" config user.name test
  printf 'package main\nfunc main(){println("x")}\n' > "$d/main.go"
  git -C "$d" add main.go
}

# --- t01: write mode formats staged files --------------------------------
D="$TMP/d1"
mk_repo "$D"
( cd "$D" && PATH="$BIN:$PATH" "$BASH_BIN" "$FORMAT" --staged ) >"$TMP/out01" 2>&1
rc=$?
assert_eq 0 "$rc" "format --staged (write) exits 0"
assert_contains "$D/main.go" "FORMATTED" "format --staged rewrote the file"

# --- t02: --check pending, clean after write -----------------------------
D="$TMP/d2"
mk_repo "$D"
( cd "$D" && PATH="$BIN:$PATH" "$BASH_BIN" "$FORMAT" --staged --check ) >"$TMP/out02" 2>&1
rc=$?
assert_eq 1 "$rc" "format --check reports pending changes"
( cd "$D" && PATH="$BIN:$PATH" "$BASH_BIN" "$FORMAT" --staged ) >/dev/null 2>&1
( cd "$D" && PATH="$BIN:$PATH" "$BASH_BIN" "$FORMAT" --staged --check ) >/dev/null 2>&1
rc=$?
assert_eq 0 "$rc" "format --check clean after write"

# --- t03: no formatter -> graceful skip ----------------------------------
D="$TMP/d3"
mk_repo "$D"
( cd "$D" && PATH="$MIN" "$BASH_BIN" "$FORMAT" --staged ) >"$TMP/out03" 2>&1
rc=$?
assert_eq 0 "$rc" "no formatter exits 0"
assert_contains "$TMP/out03" "no supported formatter found" "no formatter prints skip message"

# --- t04: pre_commit runs formatter and re-stages ------------------------
D="$TMP/d4"
mk_repo "$D"
( cd "$D" && PATH="$BIN:$PATH" "$BASH_BIN" "$PRE_COMMIT" ) >"$TMP/out04" 2>&1
rc=$?
assert_eq 0 "$rc" "pre_commit exits 0"
if git -C "$D" show :main.go 2>/dev/null | grep -q FORMATTED; then
  t_ok "pre_commit re-staged the formatted file"
else
  t_fail "pre_commit re-staged the formatted file"
fi

# --- t05: unknown flag -> usage exit 3 -----------------------------------
rc=0
"$BASH_BIN" "$FORMAT" --bogus >/dev/null 2>&1 || rc=$?
assert_eq 3 "$rc" "unknown flag exits 3"

# --- t06: syntax of all touched scripts ----------------------------------
for f in "$FORMAT" "$PRE_COMMIT"; do
  if "$BASH_BIN" -n "$f" 2>/dev/null; then
    t_ok "bash -n $(basename "$f")"
  else
    t_fail "bash -n $(basename "$f")"
  fi
done

# --- t07: node_modules is never formatted --------------------------------
D="$TMP/d7"
mk_repo "$D"
mkdir -p "$D/node_modules"
printf 'package main\nfunc other(){}\n' > "$D/node_modules/x.go"
git -C "$D" add node_modules/x.go
( cd "$D" && PATH="$BIN:$PATH" "$BASH_BIN" "$FORMAT" --staged ) >/dev/null 2>&1
assert_contains "$D/main.go" "FORMATTED" "t07 formats tracked staged file"
if grep -q FORMATTED "$D/node_modules/x.go"; then
  t_fail "t07 leaves node_modules untouched"
else
  t_ok "t07 leaves node_modules untouched"
fi

# --- t08: --all formats tracked files ------------------------------------
D="$TMP/d8"
mk_repo "$D"
git -C "$D" commit -qm init
printf 'package main\nfunc a(){}\n' > "$D/other.go"
git -C "$D" add other.go
( cd "$D" && PATH="$BIN:$PATH" "$BASH_BIN" "$FORMAT" --all ) >/dev/null 2>&1
rc=$?
assert_eq 0 "$rc" "t08 --all exits 0"
assert_contains "$D/main.go" "FORMATTED" "t08 --all formats tracked file"

# --- fake prettier shim ---------------------------------------------------
BIN2="$TMP/bin2"
mkdir -p "$BIN2"
cat > "$BIN2/prettier" <<'SHIM'
#!/usr/bin/env bash
mode=""; files=()
for a in "$@"; do
  case "$a" in
    --write) mode=w ;;
    --check) mode=c ;;
    *) files+=("$a") ;;
  esac
done
if [ "$mode" = "w" ]; then
  for f in "${files[@]}"; do grep -q 'PRETTIERED' "$f" || printf '\n// PRETTIERED\n' >> "$f"; done
elif [ "$mode" = "c" ]; then
  rc=0
  for f in "${files[@]}"; do grep -q 'PRETTIERED' "$f" || rc=1; done
  exit $rc
fi
SHIM
chmod +x "$BIN2/prettier"

# --- t09: Prettier only runs when the project configures it --------------
D="$TMP/d9"
mkdir -p "$D"; git -C "$D" init -q
git -C "$D" config user.email test@example.com; git -C "$D" config user.name test
printf '{}\n' > "$D/.prettierrc"
printf 'const x = 1\n' > "$D/a.js"
git -C "$D" add .prettierrc a.js
( cd "$D" && PATH="$BIN2:$PATH" "$BASH_BIN" "$FORMAT" --staged ) >/dev/null 2>&1
assert_contains "$D/a.js" "PRETTIERED" "t09 runs prettier when configured"

D="$TMP/d9b"
mkdir -p "$D"; git -C "$D" init -q
git -C "$D" config user.email test@example.com; git -C "$D" config user.name test
printf 'const x = 1\n' > "$D/a.js"
git -C "$D" add a.js
( cd "$D" && PATH="$BIN2:$PATH" "$BASH_BIN" "$FORMAT" --staged ) >/dev/null 2>&1
if grep -q PRETTIERED "$D/a.js"; then
  t_fail "t09 skips prettier without project config"
else
  t_ok "t09 skips prettier without project config"
fi

# --- t10: --diff formats the files in a git range ------------------------
D="$TMP/d10"
mk_repo "$D"
git -C "$D" commit -qm c1
printf 'package main\nfunc b(){}\n' > "$D/b.go"
git -C "$D" add b.go
git -C "$D" commit -qm c2
( cd "$D" && PATH="$BIN:$PATH" "$BASH_BIN" "$FORMAT" --diff HEAD~1...HEAD ) >/dev/null 2>&1
assert_contains "$D/b.go" "FORMATTED" "t10 --diff formats changed files"

# --- t11: partially staged changes are never committed by the formatter --
D="$TMP/d11"
mk_repo "$D"
printf '// unstaged edit\n' >> "$D/main.go"
( cd "$D" && PATH="$BIN:$PATH" "$BASH_BIN" "$PRE_COMMIT" ) >/dev/null 2>&1
if git -C "$D" show :main.go 2>/dev/null | grep -q 'unstaged edit'; then
  t_fail "t11 keeps partially staged changes out of the index"
else
  t_ok "t11 keeps partially staged changes out of the index"
fi

t_finish

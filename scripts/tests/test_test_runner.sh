#!/usr/bin/env bash
# test_test_runner.sh — unit tests for scripts/test-runner.sh.
# Covers: check válido/inválido, run popula cache, re-run não re-executa,
# fingerprint muda com edição, fallback sem git, diagnóstico de ambiente.
# Uses a mock runner (go) in PATH with an invocation counter.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/lib.sh"
t_begin "test_test_runner"

SCRIPT="$HERE/../test-runner.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# --- mock runner infrastructure ---
MOCK_BIN="$TMP/bin"
MOCK_LOG="$TMP/mock-invocations.log"
MOCK_EXIT_FILE="$TMP/mock-exit"
export MOCK_LOG MOCK_EXIT_FILE
mkdir -p "$MOCK_BIN"
echo "0" > "$MOCK_EXIT_FILE"

cat > "$MOCK_BIN/go" <<'EOF'
#!/usr/bin/env bash
echo "go called: $*" >> "$MOCK_LOG"
cat "$MOCK_EXIT_FILE" > /dev/null
exit "$(cat "$MOCK_EXIT_FILE")"
EOF
chmod +x "$MOCK_BIN/go"

# make_repo <dir> — creates a tiny git repo with go.mod (Go runner detected)
make_repo() {
  local dir="$1"
  mkdir -p "$dir"
  printf 'module test\n' > "$dir/go.mod"
  printf 'package main\n' > "$dir/main.go"
  git -C "$dir" init -q
  git -C "$dir" -c user.name=t -c user.email=t@t add -A
  git -C "$dir" -c user.name=t -c user.email=t@t commit -qm init
}

invocations() {
  [[ -f "$MOCK_LOG" ]] && wc -l < "$MOCK_LOG" || echo 0
}

reset_mock() {
  : > "$MOCK_LOG"
  echo "0" > "$MOCK_EXIT_FILE"
}

# --- 1. --check antes de qualquer run → exit 3 ---
repo="$TMP/proj"
make_repo "$repo"
reset_mock
(
  cd "$repo"
  PATH="$MOCK_BIN:$PATH" bash "$SCRIPT" --check >/dev/null 2>&1
  echo $?
) > "$TMP/check1.rc"
assert_eq "3" "$(cat "$TMP/check1.rc")" "--check sem cache válido sai com exit 3"

# --- 2. --run grava cache com fingerprint e exit code corretos ---
reset_mock
(
  cd "$repo"
  PATH="$MOCK_BIN:$PATH" bash "$SCRIPT" --run >/dev/null 2>&1
  echo $?
) > "$TMP/run1.rc"
assert_eq "0" "$(cat "$TMP/run1.rc")" "--run exit 0 quando suite passa"
assert_eq "1" "$(invocations)" "--run invocou o runner exatamente 1x"
branch="$(git -C "$repo" rev-parse --abbrev-ref HEAD)"
assert_eq "1" "$([[ -f "$repo/.opencode/test-cache/$branch-go.result" ]] && echo 1 || echo 0)" "cache .result criado"
assert_contains "$repo/.opencode/test-cache/$branch-go.result" "exit_code=0" "cache registra exit_code"
assert_contains "$repo/.opencode/test-cache/$branch-go.result" "fingerprint=" "cache registra fingerprint"

# --- 3. re-run com mesma fingerprint → NÃO re-executa (usa cache) ---
reset_mock
(
  cd "$repo"
  PATH="$MOCK_BIN:$PATH" bash "$SCRIPT" --run >/dev/null 2>&1
  echo $?
) > "$TMP/run2.rc"
assert_eq "0" "$(cat "$TMP/run2.rc")" "re-run exit 0 (vem do cache)"
assert_eq "0" "$(invocations)" "re-run NÃO invoca o runner de novo (contador 0)"
out=$(cd "$repo" && PATH="$MOCK_BIN:$PATH" bash "$SCRIPT" --run 2>&1 || true)
assert_contains <(printf '%s' "$out") "reusing cached result" "re-run reporta uso de cache"

# --- 4. tocar arquivo de teste → fingerprint muda → re-executa ---
reset_mock
printf 'package main\n\nvar x = 1\n' > "$repo/main.go"
(
  cd "$repo"
  PATH="$MOCK_BIN:$PATH" bash "$SCRIPT" --run >/dev/null 2>&1
  echo $?
) > "$TMP/run3.rc"
assert_eq "0" "$(cat "$TMP/run3.rc")" "run após mudança exit 0"
assert_eq "1" "$(invocations)" "mudança mínima re-executa o runner"

# --- 5. --check depois de run válido → exit 0 + caminho do relatório ---
out=$(cd "$repo" && PATH="$MOCK_BIN:$PATH" bash "$SCRIPT" --check 2>&1 || true)
assert_contains <(printf '%s' "$out") ".opencode/test-cache/$branch-go.result" "--check imprime o caminho do relatório"
rc=$(cd "$repo" && PATH="$MOCK_BIN:$PATH" bash "$SCRIPT" --check >/dev/null 2>&1; echo $?)
assert_eq "0" "$rc" "--check com cache válido sai exit 0"

# --- 6. falha do runner é propagada e cacheada ---
reset_mock
echo "1" > "$MOCK_EXIT_FILE"
printf 'package main\n\nvar x = 2\n' > "$repo/main.go"
rc=$(cd "$repo" && PATH="$MOCK_BIN:$PATH" bash "$SCRIPT" --run >/dev/null 2>&1; echo $?)
assert_eq "1" "$rc" "--run propaga exit code de falha do runner"
assert_contains "$repo/.opencode/test-cache/$branch-go.result" "exit_code=1" "cache registra exit_code de falha"

# --- 7. --status sem git → diagnostica sem quebrar ---
nogit="$TMP/nogit"
mkdir -p "$nogit"
printf 'def test_x():\n    assert True\n' > "$nogit/test_x.py"
out=$(cd "$nogit" && bash "$SCRIPT" --status 2>&1 || true)
assert_contains <(printf '%s' "$out") "test-runner status" "--status funciona sem git"
assert_contains <(printf '%s' "$out") "git repo:     no" "--status diagnostica ausência de git"

# --- 8. --run sem git não quebra (fingerprint por conteúdo) ---
# Força detecção de runner Python fake mesmo sem git
cat > "$MOCK_BIN/pytest" <<'EOF'
#!/usr/bin/env bash
echo "pytest called: $*" >> "$MOCK_LOG"
exit 0
EOF
chmod +x "$MOCK_BIN/pytest"
printf '[project]\nname = "x"\nversion = "0.1.0"\n' > "$nogit/pyproject.toml"
printf 'def test_y():\n    assert True\n' > "$nogit/test_y.py"
rc=$(cd "$nogit" && PATH="$MOCK_BIN:$PATH" bash "$SCRIPT" --run >/dev/null 2>&1; echo $?)
assert_eq "0" "$rc" "--run sem git exit 0 (fallback por conteúdo)"
assert_contains <(cd "$nogit" && PATH="$MOCK_BIN:$PATH" bash "$SCRIPT" --status 2>&1) "git repo:     no" "--status sem git continua coerente"

# --- 9. diagnóstico de ambiente: runner ausente ---
empty="$TMP/empty"
mkdir -p "$empty"
out=$(cd "$empty" && bash "$SCRIPT" --run 2>&1 || true)
assert_contains <(printf '%s' "$out") "no test runner detected" "runner ausente produz diagnóstico claro"
rc=$(cd "$empty" && bash "$SCRIPT" --run >/dev/null 2>&1; echo $?)
assert_eq "2" "$rc" "--run sem runner exit 2 (cannot run, não falha de teste)"
rc=$(cd "$empty" && bash "$SCRIPT" --check >/dev/null 2>&1; echo $?)
assert_eq "3" "$rc" "--check sem runner exit 3"

# --- 10. package.json sem script test → diagnosticado, não falha silencioso ---
noproj="$TMP/nopkgtest"
mkdir -p "$noproj"
printf '{"dependencies":{}}\n' > "$noproj/package.json"
out=$(cd "$noproj" && PATH="$MOCK_BIN:$PATH" bash "$SCRIPT" --run 2>&1 || true)
assert_contains <(printf '%s' "$out") "no 'test' script" "package.json sem test script é diagnosticado"

# --- 11. filtro (--run -- <args>) NÃO toca o cache compartilhado (B1) ---
reset_mock
# garante um cache completo FRESCO e PASSANDO primeiro (invalida o de falha do teste 6)
echo "0" > "$MOCK_EXIT_FILE"
printf 'package main\n\nvar x = 11\n' > "$repo/main.go"
( cd "$repo" && PATH="$MOCK_BIN:$PATH" bash "$SCRIPT" --run >/dev/null 2>&1 )
fp_full="$(awk -F= '/^fingerprint=/{print $2}' "$repo/.opencode/test-cache/$branch-go.result")"
# run filtrado — deve executar de verdade e NÃO sobrescrever o cache
reset_mock
rc=$(cd "$repo" && PATH="$MOCK_BIN:$PATH" bash "$SCRIPT" --run -- -run TestFoo >/dev/null 2>&1; echo $?)
assert_eq "0" "$rc" "--run com filtro exit 0"
assert_eq "1" "$(invocations)" "run filtrado executa o runner (não usa cache)"
fp_after="$(awk -F= '/^fingerprint=/{print $2}' "$repo/.opencode/test-cache/$branch-go.result")"
assert_eq "$fp_full" "$fp_after" "run filtrado NÃO sobrescreve o cache compartilhado (B1)"
rc=$(cd "$repo" && PATH="$MOCK_BIN:$PATH" bash "$SCRIPT" --check >/dev/null 2>&1; echo $?)
assert_eq "0" "$rc" "--check continua válido após run filtrado"

# --- 12. deleção de arquivo invalida o fingerprint (B2) ---
reset_mock
printf 'package main\n\nvar x = 3\n' > "$repo/extra.go"
( cd "$repo" && PATH="$MOCK_BIN:$PATH" bash "$SCRIPT" --run >/dev/null 2>&1 )
fp_before="$(awk -F= '/^fingerprint=/{print $2}' "$repo/.opencode/test-cache/$branch-go.result")"
rm "$repo/extra.go"
reset_mock
( cd "$repo" && PATH="$MOCK_BIN:$PATH" bash "$SCRIPT" --run >/dev/null 2>&1 )
assert_eq "1" "$(invocations)" "deleção de arquivo re-executa o runner (B2)"
fp_after="$(awk -F= '/^fingerprint=/{print $2}' "$repo/.opencode/test-cache/$branch-go.result")"
if [[ "$fp_before" != "$fp_after" ]]; then
  t_ok "deleção muda o fingerprint (B2)"
else
  t_fail "deleção NÃO mudou o fingerprint (B2)"
fi

# --- 13. cache fresco de suite FALHADA não satisfaz --check (B4) ---
reset_mock
echo "1" > "$MOCK_EXIT_FILE"
printf 'package main\n\nvar x = 4\n' > "$repo/main.go"
( cd "$repo" && PATH="$MOCK_BIN:$PATH" bash "$SCRIPT" --run >/dev/null 2>&1 )
rc=$(cd "$repo" && PATH="$MOCK_BIN:$PATH" bash "$SCRIPT" --check >/dev/null 2>&1; echo $?)
assert_eq "3" "$rc" "--check com cache fresco PORÉM falho sai exit 3 (B4)"

# --- 14. caminho com espaços invalida o fingerprint (B3) ---
reset_mock
echo "0" > "$MOCK_EXIT_FILE"
printf 'package main\n\nvar x = 5\n' > "$repo/main.go"
( cd "$repo" && PATH="$MOCK_BIN:$PATH" bash "$SCRIPT" --run >/dev/null 2>&1 )
fp_space="$(awk -F= '/^fingerprint=/{print $2}' "$repo/.opencode/test-cache/$branch-go.result")"
mkdir -p "$repo/dir with space"
printf 'package main\n\nvar y = 1\n' > "$repo/dir with space/extra_test.go"
reset_mock
( cd "$repo" && PATH="$MOCK_BIN:$PATH" bash "$SCRIPT" --run >/dev/null 2>&1 )
assert_eq "1" "$(invocations)" "arquivo com espaço re-executa o runner (B3)"
fp_after="$(awk -F= '/^fingerprint=/{print $2}' "$repo/.opencode/test-cache/$branch-go.result")"
if [[ "$fp_space" != "$fp_after" ]]; then
  t_ok "arquivo com espaço muda o fingerprint (B3)"
else
  t_fail "arquivo com espaço NÃO mudou o fingerprint (B3)"
fi
rm -rf "$repo/dir with space"
reset_mock
( cd "$repo" && PATH="$MOCK_BIN:$PATH" bash "$SCRIPT" --run >/dev/null 2>&1 )
assert_eq "1" "$(invocations)" "deleção de arquivo com espaço re-executa (B3)"

# --- 15. run filtrado usa log separado, não sobrescreve o da suite (improvement) ---
reset_mock
echo "0" > "$MOCK_EXIT_FILE"
printf 'package main\n\nvar x = 6\n' > "$repo/main.go"
( cd "$repo" && PATH="$MOCK_BIN:$PATH" bash "$SCRIPT" --run >/dev/null 2>&1 )
full_log="$repo/.opencode/test-cache/$branch-go.log"
if [[ -f "$full_log" ]]; then
  t_ok "log da suite existe antes do run filtrado"
else
  t_fail "log da suite não existe antes do run filtrado"
fi
( cd "$repo" && PATH="$MOCK_BIN:$PATH" bash "$SCRIPT" --run -- -run TestFoo >/dev/null 2>&1 )
if [[ -f "$repo/.opencode/test-cache/$branch-go-filtered.log" ]]; then
  t_ok "run filtrado cria log separado (-filtered.log)"
else
  t_fail "run filtrado NÃO criou log separado"
fi

t_finish

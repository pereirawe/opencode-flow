#!/usr/bin/env bash
# test_language.sh — language-conformance gate for the opencode config (issue #73).
#
# Scans the operational artifacts (agents/, commands/, native skills/, scripts/,
# root docs, standards EN originals) for Portuguese instruction prose and flags
# violating files. Detection is heuristic, not a bare grep:
#
#   * Portuguese accented characters (á à â ã é ê í ó ô õ ú ü ç) co-occurring
#     with at least one PT stopword, OR
#   * at least 4 distinct PT stopwords/domain words in the file.
#
# Exemptions (never scanned): standards/pt/**, standards/es/**, vendor/**,
# resolved_issues.md, standards/aibot-messages.md (PT-BR domain contract, #39),
# scripts/cv/migrate-schema.py + scripts/tests/test_cv.sh (career migration:
# legacy PT hub.json keys are domain constants, BR 3), and git history.
# known_issues.md and prioritization.md are scanned in diff-only mode (only
# lines added since HEAD) so historical PT entries stay exempt.
#
# Usage:
#   bash scripts/tests/test_language.sh                    # self-tests (run_all)
#   bash scripts/tests/test_language.sh --mode=advisory    # report, exit 0
#   bash scripts/tests/test_language.sh --mode=blocking    # report, exit 1 on hits
#   bash scripts/tests/test_language.sh --mode=blocking --diff
#
# Mode is explicit, never magic: advisory emits the authoritative inventory for
# QA review; blocking enforces the gate. The default invocation (no flags, used
# by run_all.sh) runs the self-test suite.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
CONFIG_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# PT-specific accented characters. Includes á/é/í/ó/ú (English loanwords such as
# "café" / "résumé" carry these too, but they never co-occur with a strong PT
# word in legitimate EN prose — see AC 3).
PT_ACCENTS_RE='[áàâãäéèêëíìîïóòôõöúùûüç]'

# STRONG discriminators: PT content words / stopwords that are NOT valid English
# words. A file is flagged when it contains >= 3 distinct strong words, or when
# it contains an accent co-occurring with >= 1 strong word.
PT_STRONG="
não nao são sao estão estao isto isso essa esse essas estes estas este mesma
mesmo todo toda todos todas nosso nossa uma uns umas sem que por para sob
sobre entre contra desde depois antes agora ainda sempre nunca enquanto quando
onde quem como também tambem então entao muito muita muitos muitas pouco pouca
poucos poucas apenas quase bem ser pode podem deve devem devia precisava precisa
precisam fazer feito foi foram será sera já ja pela pelo pelas pelos tudo nada
algo alguém alguem nós nos regras regra fluxo sistema trabalho comando agente
instruções instrucoes desenvolvimento projeto usuário usuario usuários usuarios
questão questao cenário cenario resultado piso severidade critérios criterios
impacto objetivo tarefa revisão revisao correção correcao implementação
implementacao processo validação validacao versão versao exemplo configuração
configuracao ambiente sugestão sugestao diretrizes atenção atencao aviso
restrição restricao conforme entregue entrega mudanças mudancas funcionalidade
requisito prazo recurso recursos impedimento pendência pendencia conhecimento
desempenho infraestrutura provedor falha falhas teste testes cobertura critério
criterio aceite aceites integração integracao mensagem mensagens notificação
notificacao título titulo conteúdo conteudo arquivo arquivos diretório diretorio
pasta pastas caminho nome nomes valor valores campo campos linha linhas coluna
colunas erro erros retorno retornos saída saida entrada entradas resultado
resultados informar informa informe gerar gera gere gerado gerada alterar altere
alteração alteracao criar crie criado adicionar adicione remover remova atualizar
atualize atualização atualizacao validar valide validado executar executado
configurar configurado
"

# WEAK words: short PT function words that can legitimately appear in English
# text (URLs ".com", "no", "as", "in") — never flag on their own.
PT_WEAK="
a o os as e em ao aos na nas no nos um com de do da das dos se é eh vai ja
mas mais nem
"

# lowercase <text> — lowercases and strips inline code spans
lowercase() {
  printf '%s' "${1:-}" | sed -e 's/`[^`]*`//g' -e 's/.*/\L&/'
}

# Pre-compiled regexes (single pass per file instead of one grep per word)
_build_re() {
  printf '%s\n' $1 | tr '\n' '|' | sed 's/|$//'
}
PT_STRONG_RE="\\b($(_build_re "$PT_STRONG"))\\b"
PT_WEAK_RE="\\b($(_build_re "$PT_WEAK"))\\b"

# count_distinct <text> <regex> — number of distinct words from the regex present
count_distinct() {
  local text="$1" regex="$2"
  if [[ -z "$regex" ]]; then
    echo 0
    return
  fi
  printf '%s' "$text" | grep -oE "$regex" 2>/dev/null | sort -u | wc -l
}

# has_accent <text> — 1 when a PT accented char is present
has_accent() {
  if printf '%s' "${1:-}" | grep -qE "$PT_ACCENTS_RE"; then
    echo 1
  else
    echo 0
  fi
}

# scan_text <text> — echo 1 when the text violates, 0 otherwise
scan_text() {
  local norm strong weak accent
  norm="$(lowercase "$1")"
  strong="$(count_distinct "$norm" "$PT_STRONG_RE")"
  weak="$(count_distinct "$norm" "$PT_WEAK_RE")"
  accent="$(has_accent "$norm")"
  if [[ "$strong" -ge 3 ]] || { [[ "$accent" -eq 1 ]] && [[ "$strong" -ge 1 ]]; }; then
    echo 1
  else
    echo 0
  fi
}

# strip_code <file> — echoes prose (fenced blocks removed; code comment lines kept;
# SKILL.md frontmatter descriptions strip quoted trigger-keyword appendices per
# BR 11 — bilingual keyword retention). For .sh/.py files, heredoc bodies
# (`<<TOKEN` ... `TOKEN`) are fixture data and are skipped.
strip_code() {
  local f="$1" line in_code=0 trimmed base heredoc_token=""
  base="$(basename "$f")"
  while IFS= read -r line; do
    if [[ "$base" != SKILL.md ]]; then
      if [[ -n "$heredoc_token" ]]; then
        # skip until the heredoc delimiter line
        [[ "$line" == "$heredoc_token" ]] && heredoc_token=""
        continue
      fi
      if [[ "$line" == *'<<'* ]]; then
        heredoc_token="$(printf '%s\n' "$line" | sed -nE "s/.*<<[[:space:]]*-?[[:space:]]*['\\\"]?([A-Za-z_]+)['\\\"]?.*/\\1/p")"
        [[ -n "$heredoc_token" ]] && continue
      fi
    fi
    if [[ "$line" =~ ^[[:space:]]*\`\`\` ]]; then
      in_code=$((1 - in_code))
      continue
    fi
    if [[ "$in_code" -eq 1 ]]; then
      trimmed="${line#"${line%%[![:space:]]*}"}"
      if [[ "$trimmed" == \#* || "$trimmed" == //* || "$trimmed" == '--'* || "$trimmed" == ';'* || "$trimmed" == "'"* ]]; then
        printf '%s\n' "$line"
      fi
      continue
    fi
    if [[ "$base" == SKILL.md && "$line" =~ ^description: ]]; then
      # strip double-quoted spans (trigger-keyword appendix) from descriptions
      printf '%s\n' "$line" | sed -E 's/"[^"]*"//g'
      continue
    fi
    printf '%s\n' "$line"
  done < "$f"
}

# scan_file <file> — echo 1 when the file violates, 0 otherwise
scan_file() {
  local content
  content="$(strip_code "$1")"
  scan_text "$content"
}

# ---------------------------------------------------------------------------
# File discovery
# ---------------------------------------------------------------------------

# diff_lines <file> — echoes only the added lines since HEAD (diff-only mode)
diff_lines() {
  local f="$1" rel
  rel="${f#"$CONFIG_DIR"/}"
  git -C "$CONFIG_DIR" diff HEAD -- "$rel" 2>/dev/null | grep '^+' | grep -v '^+++'
}

# collect_files — echoes the in-scope file list (relative to CONFIG_DIR)
collect_files() {
  ( cd "$CONFIG_DIR" && \
    find agents commands scripts standards -type f \
      \( -name '*.md' -o -name '*.sh' -o -name '*.py' -o -name '*.service' \
         -o -name '*.timer' -o -name '*.conf' -o -name '*.json' \) \
      -not -path 'standards/pt/*' \
      -not -path 'standards/es/*' \
      -not -name 'aibot-messages.md' \
      -not -name 'opencode.json' \
      -not -name 'test_language.sh' \
      -not -path 'scripts/cv/migrate-schema.py' \
      -not -path 'scripts/tests/test_cv.sh' \
      -print \
    && find skills -type f -name 'SKILL.md' -print \
    && ls AGENTS.md workflow.md conventions.md decisions.md architecture.md 2>/dev/null ) | sort -u
}

# ---------------------------------------------------------------------------
# Gate runner
# ---------------------------------------------------------------------------

run_gate() {
  local mode="$1" diff_only="$2"
  local violations=0 scanned=0 f full text
  while IFS= read -r f; do
    full="$CONFIG_DIR/$f"
    if [[ "$diff_only" == "1" ]]; then
      if [[ "$f" != known_issues.md && "$f" != prioritization.md ]]; then
        continue
      fi
      text="$(diff_lines "$full")"
      [[ -n "$text" ]] || continue
      scanned=$((scanned + 1))
      if [[ "$(scan_text "$text")" == "1" ]]; then
        echo "[PT] $f (added lines)"
        violations=$((violations + 1))
      fi
    else
      if [[ "$f" == known_issues.md || "$f" == prioritization.md ]]; then
        continue
      fi
      scanned=$((scanned + 1))
      if [[ "$(scan_file "$full")" == "1" ]]; then
        echo "[PT] $f"
        violations=$((violations + 1))
      fi
    fi
  done < <( { collect_files; printf '%s\n' known_issues.md prioritization.md; } | sort -u )

  if [[ "$mode" == "advisory" ]]; then
    echo "advisory: scanned $scanned file(s), $violations PT violation(s) — inventory above"
    return 0
  fi
  echo "blocking: scanned $scanned file(s), $violations PT violation(s)"
  [[ "$violations" -eq 0 ]]
}

# ---------------------------------------------------------------------------
# Self-test suite (default invocation — run_all.sh)
# ---------------------------------------------------------------------------

source "$SCRIPT_DIR/lib.sh"

run_self_tests() {
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT

  t_begin "test_language.sh"

  # Fixture 1 — accented PT prose in an agent prompt -> flagged
  local f1="$tmp/agents/x/agent1.md"
  mkdir -p "$tmp/agents/x"
  printf '%s\n' "# Agent" "Instruções de desenvolvimento para o agente." > "$f1"
  assert_eq "1" "$(scan_file "$f1")" "accented PT prose flagged"

  # Fixture 2 — accent-free PT prose -> flagged via stopword heuristic
  local f2="$tmp/agents/x/agent2.md"
  printf '%s\n' "# Agent" "Regras do fluxo de cada sistema sobre o trabalho." > "$f2"
  assert_eq "1" "$(scan_file "$f2")" "accent-free PT prose flagged via stopwords"

  # Fixture 3 — legit EN prose with café/naïve accents -> not flagged
  local f3="$tmp/agents/x/agent3.md"
  printf '%s\n' "# Agent" "The café menu is simple, the approach is naïve but effective." > "$f3"
  assert_eq "0" "$(scan_file "$f3")" "legit EN prose with accents not flagged"

  # Fixture 4 — PT content under exempted paths -> gate reports 0 violations
  local ex="$tmp/exempt"
  mkdir -p "$ex/standards/pt" "$ex/standards/es" "$ex/vendor/x" "$ex/agents/x" "$ex/skills/x"
  printf '%s\n' "Rastreamento de issues com regras de negócio." > "$ex/standards/pt/issues.md"
  printf '%s\n' "Seguimiento de issues con reglas de negocio." > "$ex/standards/es/issues.md"
  printf '%s\n' "Já existe um desenvolvimento em andamento para esta issue." > "$ex/standards/aibot-messages.md"
  printf '%s\n' "Histórico arquivado com regras antigas." > "$ex/resolved_issues.md"
  printf '%s\n' "Skill de terceiros em português." > "$ex/vendor/x/SKILL.md"
  printf '%s\n' "# Agent" "Development instructions for the agent." > "$ex/agents/x/agent.md"
  printf '%s\n' "---" "description: Development skill." "---" > "$ex/skills/x/SKILL.md"
  bash "$SCRIPT_DIR/test_language.sh" --mode=blocking --dir="$ex" > "$tmp/exempt_report.txt" 2>&1
  assert_eq "0" "$?" "exempted paths honored (blocking exits 0)"
  assert_not_contains "$tmp/exempt_report.txt" "[PT]" "no PT violations reported for exempted paths"

  # Fixture 5 — PT word inside fenced code block / inline backtick -> not flagged;
  # PT comment line inside a code block -> flagged
  local f6="$tmp/agents/x/agent6.md"
  printf '%s\n' "# Agent" "Run the tool with" '`comando`.' \
    '```bash' "echo 'sem PT'" '```' > "$f6"
  assert_eq "0" "$(scan_file "$f6")" "PT word in code block/backtick not flagged"
  local f7="$tmp/agents/x/agent7.md"
  printf '%s\n' "# Agent" '```bash' "# regras de negócio do sistema" "run" '```' > "$f7"
  assert_eq "1" "$(scan_file "$f7")" "PT comment line inside code block flagged"

  # Fixture 6 — mode transition: advisory exit 0 + report; blocking exit 1
  local gate_out advisory_rc blocking_rc report
  gate_out="$(bash "$SCRIPT_DIR/test_language.sh" --mode=advisory --dir="$tmp" 2>&1)"
  advisory_rc=$?
  assert_eq "0" "$advisory_rc" "advisory mode exits 0"
  printf '%s' "$gate_out" > "$tmp/report.txt"
  assert_contains "$tmp/report.txt" "advisory:" "advisory report generated"
  gate_out="$(bash "$SCRIPT_DIR/test_language.sh" --mode=blocking --dir="$tmp" 2>&1)"
  blocking_rc=$?
  assert_eq "1" "$blocking_rc" "blocking mode exits 1 with violations"
  printf '%s' "$gate_out" > "$tmp/report2.txt"
  assert_contains "$tmp/report2.txt" "blocking:" "blocking report generated"

  # Fixture 7 — clean repo scan (blocking) exits 0
  local clean="$tmp/clean"
  mkdir -p "$clean/agents/x"
  printf '%s\n' "# Agent" "Development instructions for the agent." > "$clean/agents/x/agent.md"
  bash "$SCRIPT_DIR/test_language.sh" --mode=blocking --dir="$clean" >/dev/null 2>&1
  assert_eq "0" "$?" "clean tree blocking scan exits 0"

  t_finish
}

# ---------------------------------------------------------------------------
# Entry point (only when executed directly, not when sourced)
# ---------------------------------------------------------------------------

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  MODE=""
  DIFF_ONLY=0
  SCAN_DIR=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --mode=advisory) MODE="advisory" ;;
      --mode=blocking) MODE="blocking" ;;
      --diff) DIFF_ONLY=1 ;;
      --dir=*) SCAN_DIR="${1#--dir=}" ;;
      *) echo "unknown arg: $1" >&2; exit 2 ;;
    esac
    shift
  done

  if [[ -n "$MODE" ]]; then
    if [[ -n "$SCAN_DIR" ]]; then
      CONFIG_DIR="$SCAN_DIR"
    fi
    run_gate "$MODE" "$DIFF_ONLY"
    exit $?
  fi

  run_self_tests
fi

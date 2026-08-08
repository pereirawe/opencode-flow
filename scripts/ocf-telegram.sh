#!/usr/bin/env bash
# ocf-telegram.sh — Executa um comando e notifica via Telegram ao finalizar
# Uso: ocf-telegram.sh <comando...>
#
# Exemplo:
#   ocf-telegram.sh opencode run --command "ocf:develop 42" --auto

set -euo pipefail

if [[ $# -eq 0 ]]; then
    echo "Uso: ocf-telegram.sh <comando...>" >&2
    echo "  Executa o comando e envia notificação Telegram ao finalizar." >&2
    exit 1
fi

NOTIFY_SCRIPT="$HOME/.config/opencode/scripts/telegram-notify.sh"
START_TIME=$(date +%s)
CMD="$*"

# Contexto do projeto
PROJECT=$(basename "$(git rev-parse --show-toplevel 2>/dev/null || echo '?')")
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo '?')

echo "🚀 Executando: $CMD"
echo "   Projeto: $PROJECT | Branch: $BRANCH"
echo "---"

# Executa o comando capturando saída
OUTPUT_FILE=$(mktemp)
set +e
eval "$CMD" > "$OUTPUT_FILE" 2>&1
EXIT_CODE=$?
set -e

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
DURATION_STR=$(printf '%dm%ds' $((DURATION/60)) $((DURATION%60)))

# Últimas linhas da saída (se houver erro, mostra mais)
if [[ $EXIT_CODE -eq 0 ]]; then
    TAIL_LINES=$(tail -5 "$OUTPUT_FILE" 2>/dev/null || true)
    STATUS_ICON="✅"
    STATUS_TEXT="concluído com sucesso"
else
    TAIL_LINES=$(tail -15 "$OUTPUT_FILE" 2>/dev/null || true)
    STATUS_ICON="❌"
    STATUS_TEXT="falhou (exit $EXIT_CODE)"
fi

# Build notification message
MSG="${STATUS_ICON} Comando ${STATUS_TEXT}
⏱ Duração: ${DURATION_STR}
📂 Projeto: ${PROJECT}
🌿 Branch: ${BRANCH}
💻 <code>${CMD}</code>"

if [[ -n "$TAIL_LINES" ]]; then
    MSG="${MSG}"$'\n\n'"<pre>${TAIL_LINES}</pre>"
fi

# Envia notificação (silenciosa — não quebra se falhar)
if [[ -x "$NOTIFY_SCRIPT" ]]; then
    "$NOTIFY_SCRIPT" --title "${STATUS_ICON} Comando finalizado (${DURATION_STR})" "$MSG" 2>/dev/null || true
fi

rm -f "$OUTPUT_FILE"

# Repassa o exit code original
exit $EXIT_CODE

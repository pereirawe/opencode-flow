---
name: telegram-notifier
description: Envia notificações para o Telegram via Bot API quando um comando opencode termina ou quando um agente precisa de resposta do usuário. Use ao finalizar tarefas longas, reportar resultados, ou pedir input do usuário quando ele pode estar longe do terminal.
---

# Telegram Notifier

Envia notificações para o Telegram usando o Bot API.
O script está em `$HOME/.config/opencode/scripts/telegram-notify.sh`.

## Configuração

As credenciais são carregadas de (ordem de prioridade):
1. `./.opencode/telegram.env` (projeto atual)
2. `~/.config/opencode/.opencode/telegram.env` (global)
3. Variáveis de ambiente `TELEGRAM_BOT_TOKEN` / `TELEGRAM_CHAT_ID`

## Quando usar

**SEMPRE que uma dessas situações ocorrer:**

1. **Ao terminar um comando/tarefa** — notifique o resultado (sucesso ou falha).
2. **Quando precisar de resposta do usuário** — se o usuário não estiver visivelmente ativo no terminal, envie a pergunta pelo Telegram e aguarde.
3. **Ao encontrar um bloqueio** — regra de negócio ausente, conflito, falha.
4. **Ao completar um milestone** — pipeline concluído, MR criada, deploy feito.

## Como enviar notificações

### Mensagem simples (via argumento)

```bash
$HOME/.config/opencode/scripts/telegram-notify.sh "Desenvolvimento da issue #42 concluído. MR: https://github.com/..."
```

### Mensagem com título

```bash
$HOME/.config/opencode/scripts/telegram-notify.sh --title "⚠️ Ação Necessária" \
  "A issue #28 precisa de revisão de negócio. O campo 'desconto máximo' não está definido."
```

### Mensagem via stdin (para textos longos)

```bash
cat <<EOF | $HOME/.config/opencode/scripts/telegram-notify.sh --title "📋 Relatório de Revisão"
Revisão concluída:
- 2 issues críticas encontradas
- 5 warnings
- Cobertura de testes: 87%
EOF
```

### Modo Markdown

```bash
$HOME/.config/opencode/scripts/telegram-notify.sh --parse-mode markdown \
  "*Review concluída*\n\n✅ Testes: passando\n🔒 Segurança: ok"
```

## Template de mensagens

Use sempre este padrão:

```
Contexto: <projeto>/<branch>
<corpo da mensagem>

Ação: <o que o usuário precisa fazer, se aplicável>
```

Exemplo:

```
Contexto: setup-tecnologia/issue-28-close-issue
Implementação concluída. MR criada:
https://github.com/pereirawe/setup-tecnologia/pull/15

Ação: Revisar e aprovar a MR.
```

⚠️ **Não pergunte ao usuário se ele quer receber notificação** — apenas envie. Se as credenciais não estiverem configuradas, o script falhará com uma mensagem clara e você continua normalmente.

# Mensagens de Telegram — Formato padrão para notificações de agentes

Formato padronizado para as notificações de Telegram enviadas pelos agentes
através da skill `telegram-notifier`. Cada mensagem identifica o projeto de
origem e segue uma template específica por categoria.

## Regras gerais

1. **Sempre incluir o contexto do projeto** — a primeira linha DEVE ser
   `🔹 [NOME-DO-PROJETO]` para que o usuário saiba de qual workspace vem a
   notificação.
2. **Uma notificação por evento** — cada conclusão de tarefa, falha, pergunta ou
   milestone gera exatamente uma mensagem.
3. **Máximo 300 caracteres** — notificações mobile; coloque a info chave no
   início.
4. **Sempre incluir linha de ação quando precisar de interação** — prefixada
   com `→`.
5. **Usar o flag `--parse-mode html`** para negrito, links e código.
6. **Nunca pedir permissão para enviar** — apenas envie a notificação.
7. **Detectar o nome do projeto** a partir do nome do repositório git
   (`basename "$(git rev-parse --show-toplevel)"` ou fallback para o último
   componente do diretório atual).

## Categorias

| Chave | Emoji | Uso |
|-------|-------|-----|
| `done` | ✅ | Tarefa/comando concluído com sucesso |
| `fail` | ❌ | Tarefa/comando falhou com erro |
| `question` | 💬 | Agente precisa de resposta do usuário |
| `blocked` | 🚫 | Agente não pode prosseguir (falta info, permissões) |
| `milestone` | 🏁 | Fase do pipeline ou release alcançada |
| `alert` | ⚠️ | Aviso não-bloqueante / alerta |
| `progress` | ⏳ | Atualização de tarefa longa em andamento |

## Templates por chave

### `done` — tarefa concluída com sucesso

```
🔹 [PROJETO]
✅ <o que foi concluído>

<resultado ou link, 1 linha>
```

Exemplo:
```
🔹 [opencode-flow]
✅ Pipeline concluído — issue #42

MR: https://github.com/pereirawe/opencode-flow/pull/34
```

### `fail` — tarefa falhou com erro

```
🔹 [PROJETO]
❌ <o que falhou>

<causa do erro, 1 linha>

→ <ação corretiva>
```

Exemplo:
```
🔹 [setup-tecnologia]
❌ Suite de testes falhou — 3/47 testes

pytest core/tests/test_auth.py - 2 assertion errors

→ Revisar falhas e re-executar desenvolvimento
```

### `question` — agente precisa de input do usuário

```
🔹 [PROJETO]
💬 <contexto>

<a pergunta>

→ Responder aqui ou no terminal
```

Exemplo:
```
🔹 [opencode-flow]
💬 Selecionar quantidade de revisores para issue #28

Quantos Senior Reviewers devem revisar esta branch?

→ Responder com um número (1–5)
```

### `blocked` — agente bloqueado

```
🔹 [PROJETO]
🚫 Bloqueado — <bloqueador>

<por que não pode prosseguir, 1 linha>

→ <o que precisa acontecer>
```

Exemplo:
```
🔹 [my-app]
🚫 Bloqueado — regras de negócio ausentes

Issue #15 (feat) não tem campo `Business rules:`.

→ Adicionar regras de negócio em known_issues.md ou refinar via discovery
```

### `milestone` — milestone do pipeline alcançado

```
🔹 [PROJETO]
🏁 <descrição do milestone>

<link ou detalhe chave>
```

Exemplo:
```
🔹 [opencode-flow]
🏁 Versão 1.8.0 publicada

https://github.com/pereirawe/opencode-flow/releases/tag/v1.8.0
```

### `alert` — aviso não-bloqueante

```
🔹 [PROJETO]
⚠️ <mensagem de aviso>
```

Exemplo:
```
🔹 [my-app]
⚠️ PR #12 aberto há 5 dias — faça merge ou feche
```

### `progress` — atualização de tarefa longa

```
🔹 [PROJETO]
⏳ <o que está acontecendo> (passo X/Y)
```

Exemplo:
```
🔹 [opencode-flow]
⏳ Scan profundo em andamento (passo 2/3 — analisando arquivos Go)
```

## Invocação do script

O script respeita o emoji de categoria como parte do `--title`, e o cabeçalho
do projeto + corpo como mensagem:

```bash
SCRIPT="$HOME/.config/opencode/scripts/telegram-notify.sh"

# done
"$SCRIPT" --title "✅ Pipeline concluído" "🔹 [meu-projeto]\n\nMR: https://github.com/..."

# fail
"$SCRIPT" --title "❌ Testes falharam" "🔹 [meu-projeto]\n\n→ Revisar falhas e re-executar"

# question
"$SCRIPT" --title "💬 Input necessário" "🔹 [meu-projeto]\n\nQual branch para issue #42?\n\n→ Responder aqui"
```

Para mensagens multi-linha, usar stdin:

```bash
printf "🔹 [meu-projeto]\n\n✅ Feature implementada\nBranch: issue-42-login\nMR: %s" "$MR_URL" | \
  "$SCRIPT" --title "✅ Concluído"
```

## Chat ID por projeto (configuração multi-repo)

Ao trabalhar com múltiplos projetos, usar o arquivo `.opencode/telegram.env`
específico de cada projeto. O script carrega as credenciais do projeto antes
das globais:

```
<projeto>/
├── .opencode/
│   └── telegram.env    ← carregado primeiro (específico do projeto)
```

Se todos os projetos devem notificar o mesmo chat, manter apenas o arquivo
global em `~/.config/opencode/.opencode/telegram.env`.

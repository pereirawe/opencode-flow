# Aibot Messages — PT-BR (exempt from language standardization)

NOTE: This file is intentionally written in PT-BR as it defines the standardized Portuguese messages for the Aibot agent (issue #39). It is exempt from the language-conformance gate.

# Aibot Messages — Padrão de mensagens do agente aibot

Padrão uniforme para as mensagens que o agente `development/aibot` posta em
issues remotas (GitHub/GitLab) durante o ciclo do `aibot-watcher` (issue #39).

## Regras gerais

1. **Uma mensagem por trigger** — cada evento (comentário `@aibot:develop`
   processado) gera exatamente UMA mensagem, escolhida pela chave da mensagem.
2. **Idioma**: PT-BR, tom objetivo e cordial (o aibot é um assistente de dev —
   sem gírias ou ansiedade de leigo).
3. **Provider**: GitHub → `gh issue comment <remote-id> --body-file -` (ou
   `--body`); GitLab → `glab issue comment <remote-id> --message ...`.
4. **Placeholders**:
   - `{issue_id}` — id remoto da issue comentada
   - `{mr_link}` — URL da MR/PR criada (obtida via `gh pr view <n> --json url`
     ou `glab mr view <n> --json web_url`, com fallback construído do remote)
5. O aibot NUNCA posta outra coisa na issue além da mensagem padrão
   correspondente à chave.

## Templates por chave

### `success` — desenvolvimento concluído, MR pronta

```
Desenvolvimento concluído ✅

A issue #{issue_id} foi desenvolvida e a MR está pronta para revisão e merge:
{mr_link}

— aibot
```

### `already-in-progress` — já existe desenvolvimento em andamento

```
Já existe um desenvolvimento em andamento para esta issue 🚧

Novo disparo ignorado para evitar execução concorrente. Acompanhe a MR
existente para revisão e merge.

— aibot
```

### `already-resolved` — issue já resolvida

```
Esta issue já foi resolvida ✔️

Nenhuma ação necessária.

— aibot
```

### `not-tracked` — issue não rastreada localmente

```
Esta issue não está rastreada localmente neste workspace ❌

O pipeline não pode ser iniciado. Registre a issue no `known_issues.md` do
workspace com `Remote: #{issue_id}` e tente novamente.

— aibot
```

### `cannot-develop` — bloqueio no desenvolvimento

```
Não foi possível desenvolver esta issue automaticamente ⚠️

A tarefa deve ser revisada (ex.: regras de negócio ausentes ou ambíguas,
conflito de branch, falha de modelo). Nenhuma MR foi criada.

— aibot
```

## Chaves aceitas pelo `ocf:aibot-notify`

| Chave | Uso |
|-------|-----|
| `success` | BR 8 — issue atingiu `in-publish` com `PR: #n` |
| `already-in-progress` | BR 5 — status `in-progress`/`in-review`/`in-qa`/`in-publish` |
| `already-resolved` | BR 5 — status `resolved` |
| `not-tracked` | BR 4 — sem entrada local com `Remote:` correspondente |
| `cannot-develop` | BR 9 — falha/bloqueio no develop, sem MR |

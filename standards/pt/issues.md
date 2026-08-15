# Rastreamento de Issues

Rastreamento em dois níveis:
- **Global**: `~/.config/opencode/known_issues.md` — issues de config do opencode
- **Projeto**: `<projeto>/.opencode/known_issues.md` — issues específicas do projeto

## Formato de Entrada

```markdown
### <id>. <título>
- Status: backlog | ready | open | in-progress | in-review | in-qa | in-publish | resolved
- Opened: <YYYY-MM-DD> | -
- Ready: <YYYY-MM-DD> | -
- Started: <YYYY-MM-DD> | -
- Type: bug | feat | doc | chore
- Severity: critical | high | medium | low
- Report: <nome-usuário> | <nome-modelo>
- Base branch: <default-branch> | <branch-name>
- Reviewers: <número> (<perfil1>, <perfil2>)
- Remote: - | #<id-remoto>
- Jira: - | <KEY-N>
- PR: - | #<pr-number>
- Location: <caminho-arquivo>:<linhas>
- Description: <descrição breve>
- Impact: <o que ou quem é afetado>
- Business rules: <regras de negócio, restrições e regras de domínio>
- Acceptance criteria: <o que deve ser verdade para a issue ser considerada completa>
- Tests: <cenário → resultado, definidos durante o discovery>
- Suggested fix: <abordagem ou próximo passo>
```

`Jira:` é opcional (default `-`) — a chave da issue no Jira Cloud (ex.:
`DEV-123`) para o card espelhado a partir desta issue quando o sync do Jira
está habilitado (issue #48). É separado de `Remote:` (que continua exclusivo
do provider git GitHub/GitLab). Preenchido por `scripts/sync-jira.sh` (via
hooks em `create_issue.sh`/`promote.sh`/`close_issue.sh` ou o comando
`ocf:sync-jira`); o sync é não-bloqueante e o `Status:` local sempre vence o
Jira.

### Timestamps (Opened / Ready / Started / Resolved + Durations)

Timestamps de ciclo de vida por issue são armazenados como campos da entrada
em `known_issues.md` (`- Opened:`, `- Ready:`, `- Started:`, nessa ordem após
`- Status:`) e calculados/armazenados no arquivo de resolvidas no fechamento
(`- Resolved:` e `- Durations:`). São gravados diretamente pelos scripts do
pipeline — nunca via parsing de trailers de commit (issue #24).

| Campo | Gravado por | Quando |
|-------|-------------|--------|
| `- Opened:` | `scripts/create_issue.sh` | ao criar a issue remota com sucesso (set-if-absent). `scripts/promote.sh` faz backfill set-if-absent no modo 2 (ready → in-progress) com a data atual — aproximação documentada quando a issue remota foi criada antes do recurso de timestamps (BR 3). |
| `- Ready:` | `scripts/promote.sh` | ao transicionar backlog → ready (set-if-absent) |
| `- Started:` | `scripts/promote.sh` | ao transicionar ready → in-progress (set-if-absent) |
| `- Resolved:` | `scripts/close_issue.sh` | no fechamento (= data do fechamento / hoje) |
| `- Durations:` | `scripts/close_issue.sh` | no fechamento, na entrada do arquivo de resolvidas — diferença em dias entre os timestamps, com parse ancorado em UTC (`TZ=UTC date -d "$d" +%s`, robusto a DST) |

Componentes de `Durations`: `backlog` (Opened→Ready), `waiting`
(Ready→Started), `dev` (Started→Resolved), `total` (Opened→Resolved, relativo
à data de fechamento). Guards: um componente renderiza `-` quando uma data
está ausente ou start > end (guardado ANTES da divisão); `0d` quando a
diferença é zero; valores são limitados a 0 (não-negativos); quando TODAS as
datas estão ausentes, o campo inteiro renderiza o literal `- Durations: -`.

A gravação é idempotente (set-if-absent): re-executar um script nunca duplica
nem sobrescreve timestamps existentes, e `close_issue.sh` nunca adiciona
entrada duplicada no arquivo de resolvidas. Timestamps aplicam-se apenas a
issues novas — entradas existentes nunca são reescritas retroativamente.

### `Tests:` — padrão obrigatório de testes

`Tests:` é OBRIGATÓRIO em toda issue nova, capturado durante o discovery (QA
pré-desenvolvimento, Fase 5) como linhas `cenário → resultado` — nunca
adicionado ad-hoc durante o desenvolvimento. Desenvolvedores escrevem testes
contra esses cenários documentados em vez de inventá-los em tempo de execução.

- Para tipos `doc`/`chore`, o literal `- Tests: -` é permitido (sem superfície
  de teste).
- Para tipos `feat`/`bug`, pelo menos uma linha `cenário → resultado` é
  OBRIGATÓRIA e o valor pode NUNCA ser `-`.
- A profundidade de cenários é um PISO sem limite superior, por severidade:
  `critical`/`high` → ≥3 linhas `cenário → resultado`; `medium` → ≥2; `low`
  → ≥1. Se `- Severity:` estiver ausente no momento da validação do QA, o piso
  médio (≥2) se aplica.
- A aplicação é **verificada pela revisão pré-desenvolvimento do QA (Fase 5)
  e pelos senior reviewers** — NÃO aplicada por scripts.
- `Tests:` ausente ou insuficiente encontrado durante senior review ou QA
  pós-revisão = `incomplete-spec` (lacuna de discovery), NÃO um bug — a issue
  retorna ao refinamento do discovery para capturar os cenários ausentes.
- Aplica-se a TODAS as issues novas; issues existentes em andamento não são
  reescritas retroativamente.

> Follow-up (não faz parte de nenhum gate): um gate opcional de
> `promote.sh`/lint poderia aplicar `Tests:` mecanicamente no futuro.

## Ciclo de Vida

```
backlog -> ready -> open -> in-progress -> in-review -> in-qa -> in-publish -> resolved
```

| Status | Significado |
|--------|-------------|
| `backlog` | Capturado, ainda não refinado |
| `ready` | Claro, aprovado, testável — pronto para execução |
| `open` | Selecionado, aguardando criação remota |
| `in-progress` | Issue remota existe, trabalho iniciado |
| `in-review` | Senior review concluído, aguardando QA |
| `in-qa` | QA verificando pós-review (pode voltar para `in-progress`) |
| `in-publish` | Committer aprovou, MR criado, aguardando merge |
| `resolved` | MR aprovado e mesclado (movido para arquivo) |

## Known Issues

Single source of truth for tracked work in this project.

### Format

```markdown
### <id>. <title>
- Status: backlog | ready | open | in-progress | in-review | in-qa | in-publish | resolved
- Opened: <YYYY-MM-DD> | -
- Ready: <YYYY-MM-DD> | -
- Started: <YYYY-MM-DD> | -
- Type: bug | feat | doc | chore
- Severity: critical | high | medium | low
- Report: <user-name> | <model-name>
- Base branch: <default-branch> | <branch-name>
- Reviewers: <number> (<profile1>, <profile2>)
- Remote: - | #<remote-id>
- Jira: - | <KEY-N>
- PR: - | #<pr-number>
- Location: <file-path>:<line-numbers>
- Description: <brief>
- Impact: <what or who is affected>
- Business rules: <specific business logic, constraints, and domain rules>
- Acceptance criteria: <what must be true for the issue to be complete>
- Tests: <scenario → outcome lines, defined during discovery>
- Suggested fix: <approach or next step>
```

`Business rules:` is required for `feat` type issues.
`Tests:` is MANDATORY for every new issue, captured during discovery as
`scenario → outcome` lines. For `doc`/`chore` types the literal `- Tests: -`
is permitted (no test surface). For `feat`/`bug` types at least one
`scenario → outcome` line is REQUIRED and the value may NEVER be `-`. Severity
floor: `critical`/`high` → ≥3 lines, `medium` → ≥2, `low` → ≥1; if `Severity`
is missing, the medium floor (≥2) applies. Enforcement is verified by QA
pre-development review (Phase 5) and senior reviewers — NOT enforced by
scripts. Missing or insufficient `Tests:` = `incomplete-spec` (discovery gap),
not a bug.
`Base branch:` is set during discovery (usually `main`/`master`).
`Reviewers:` stores count and profiles (set during discovery, e.g. `1 (backend)`).
`Remote:` is populated at the end of discovery (PM asks user, creates if confirmed).
Auto-created by `ocf:promote` or `ocf:develop` if still missing.
`Jira:` is optional (default `-`) — the Jira Cloud card key (e.g. `DEV-123`)
mirrored from this issue when the Jira sync is enabled (issue #48), separate
from `Remote:`. Populated by `scripts/sync-jira.sh` (hooks in
create_issue.sh/promote.sh/close_issue.sh or the `ocf:sync-jira` command);
non-blocking, local `Status:` always wins.
`Opened:`/`Ready:`/`Started:` lifecycle timestamps are stamped by the pipeline
scripts (create_issue.sh on remote creation success; promote.sh on backlog→ready
and ready→in-progress; close_issue.sh stamps `Resolved:` and computes
`Durations:` into the archive). Set-if-absent, idempotent, new issues only.
See `standards/issues.md` for the full contract.

### 20. Agente Anderson — feedback de usuário leigo nas MRs
- Status: resolved
- Type: feat
- Severity: medium
- Report: PO
- Base branch: main
- Reviewers: 2 (qa, ux-ui)
- Remote: #20
- PR: -
- Location: agents/development/anderson.md, opencode.json, workflow.md
- Description: Criar agente "Anderson" — usuário leigo, ansioso, paulistano e puxa-saco — que comenta automaticamente em PT-BR nas MRs após o publish-requester, simulando feedback do cliente final.
- Impact: Fecha o gap de validação do ponto de vista do usuário final no pipeline. Força PRs a serem escritas de forma clara para não-técnicos.
- Business rules: all 12 implemented
- Suggested fix: Implemented

### 23. Instruções contraditórias para contagem de revisores entre command doc e opencode.json
- Status: in-publish
- Type: bug
- Severity: high
- Report: opencode
- Base branch: main
- Reviewers: 1
- Remote: #22
- PR: #23
- Location: commands/ocf:review-branch.md vs opencode.json:28
- Description: commands/ocf:review-branch.md diz "Ask user for reviewer count (default 1)", enquanto opencode.json (fonte da verdade) diz "Read from `- Reviewers:` field; if absent or empty, default to 1 — do NOT ask the user."
- Impact: Agentes recebem instruções conflitantes. Pode resultar em perguntas indesejadas ao usuário ou revisores não atribuídos.
- Suggested fix: Alinhar commands/ocf:review-branch.md com opencode.json — remover "Ask user" e usar leitura do campo na issue.

### 24. `pre_commit.sh` não sincroniza trailers de status com `known_issues.md`
- Status: backlog
- Type: bug
- Severity: high
- Report: opencode
- Base branch: main
- Reviewers: 1
- Remote: -
- PR: -
- Location: scripts/pre_commit.sh:36-61, standards/commits.md
- Description: standards/commits.md documenta que trailers (Status:, Closes) sincronizam automaticamente com known_issues.md via pre_commit.sh, mas o script apenas detecta e loga os trailers — nunca modifica o arquivo de issues.
- Impact: Sincronização automática documentada não existe. Usuários/agentes precisam atualizar known_issues.md manualmente após cada commit.
- Suggested fix: Implementar atualização real de status em known_issues.md no pre_commit.sh, ou remover a alegação da documentação.

### 25. Status `open` no ciclo de vida é inatingível — nunca setado por scripts
- Status: backlog
- Type: bug
- Severity: medium
- Report: opencode
- Base branch: main
- Reviewers: 1
- Remote: -
- PR: -
- Location: scripts/promote.sh, scripts/create_issue.sh, workflow.md, standards/issues.md
- Description: O ciclo de vida documentado é backlog→ready→open→in-progress, mas promote.sh transiciona backlog→ready e ready→in-progress sem nunca passar por open. create_issue.sh mantém status como ready. Nenhum script ou agente seta Status: open.
- Impact: Estado open é inatingível. Código que referencia Status: open (maintain.sh, pre_commit.sh) é dead logic. Diagrama de lifecycle é enganoso.
- Suggested fix: Remover open do ciclo de vida ou fazer create_issue.sh transicionar ready→open ao criar remote com sucesso.

### 27. `opencode.json` referencia `/temp/*` em vez de `/tmp/*`
- Status: backlog
- Type: bug
- Severity: low
- Report: opencode
- Base branch: main
- Reviewers: 1
- Remote: -
- PR: -
- Location: opencode.json:89
- Description: Linha 89 tem `"/temp/*": "allow"` — o diretório temporário padrão no Linux é `/tmp/`, não `/temp/`. Provável typo.
- Impact: Se um agente precisar escrever em `/tmp/`, a permissão será negada.
- Suggested fix: Alterar `"/temp/*"` para `"/tmp/*"`.

### 28. `close_issue.sh` fecha issue remota sem verificar merge do PR para status não-`in-publish`
- Status: in-progress
- Type: bug
- Severity: medium
- Report: opencode
- Base branch: main
- Reviewers: 1 (devops)
- Remote: -
- PR: -
- Location: scripts/close_issue.sh:42-65
- Description: O script aceita status ready, open, in-progress, resolved e executa `gh issue close` sem verificar se o PR foi merged. Apenas in-publish tem verificação de merge.
- Impact: Fechamento acidental de issues remotas ainda em desenvolvimento. Sem proteção ou confirmação.
- Business rules:
  1. close_issue.sh DEVE aceitar apenas status `in-publish` e `resolved`.
  2. Para qualquer outro status, DEVE abortar com erro e não modificar known_issues.md nem resolved_issues.md.
  3. Para status `in-publish`, DEVE manter a verificação existente de merge do PR antes de fechar remote.
  4. Para status `resolved`, DEVE verificar se a issue remota já está fechada antes de tentar fechar.
  5. DEVE exibir confirmação ao usuário antes de fechar a issue remota: `"Fechar issue #<id> no remote? (s/N)"`.
  6. Se o usuário recusar, DEVE pular o fechamento remoto mas continuar o arquivamento local.
  7. O fechamento remoto NÃO DEVE travar o arquivamento local em caso de falha.
- Acceptance criteria:
  1. Script aceita apenas status `in-publish` e `resolved` para fechar remote.
  2. Status `ready`, `open`, `in-progress`, `backlog`, `in-review`, `in-qa` abortam com erro.
  3. Status `resolved` verifica se remote já está fechado antes de tentar fechar.
  4. Status `in-publish` verifica merge do PR (lógica existente preservada).
  5. Usuário é confirmado antes de fechar remote.
  6. Se usuário recusar, arquivamento local continua.
  7. Falha no fechamento remoto não interrompe arquivamento.
- Suggested fix: Restringir close_issue.sh a aceitar apenas status in-publish e resolved. Adicionar verificação de estado remoto para resolved. Adicionar confirmação do usuário.

### 29. IDs duplicados de issue em `resolved_issues.md`
- Status: backlog
- Type: bug
- Severity: medium
- Report: opencode
- Base branch: main
- Reviewers: 1
- Remote: -
- PR: -
- Location: resolved_issues.md:17-25, resolved_issues.md:44-51
- Description: Duas entradas em resolved_issues.md têm o mesmo ID `### 7.` — uma para "Melhorar ocf:init" e outra para "Workflow de revisão externa". close_issue.sh nunca verifica duplicatas antes de append.
- Impact: IDs não únicos no arquivo de resolução. Confusão ao referenciar issues resolvidas por ID.
- Suggested fix: Verificar se o ID já existe em resolved_issues.md antes de fazer append; alertar ou usar sufixo.

### 30. Código morto: sentinelas awk `/^### Status/ {exit}` nas scripts de issue
- Status: backlog
- Type: chore
- Severity: low
- Report: opencode
- Base branch: main
- Reviewers: 1
- Remote: -
- PR: -
- Location: scripts/promote.sh:25, scripts/create_issue.sh:21, scripts/close_issue.sh:20
- Description: As scripts usam `awk '/^### Status/ {exit}'` como sentinela de terminação, mas known_issues.md não tem linha começando com `### Status` — apenas `### Format`. O padrão nunca é triggerado.
- Impact: Código morto. Sem impacto em runtime pois a lógica de boundary é tratada por outros patterns.
- Suggested fix: Remover as linhas `/^### Status/ {exit}` ou substituir por pattern que efetivamente case (ex: `/^### [A-Z]/`).

### 31. `import_claude_skill.sh` escreve `opencode.json` sem validação atômica
- Status: backlog
- Type: bug
- Severity: medium
- Report: opencode
- Base branch: main
- Reviewers: 1
- Remote: -
- PR: -
- Location: scripts/import_claude_skill.sh:30-42
- Description: O script lê e escreve opencode.json com json.dump sem validação, sem write atômico, sem preservar formatação original, e com `2>/dev/null` suprimindo erros.
- Impact: Se a escrita for interrompida, a configuração do opencode pode ser corrompida.
- Suggested fix: Usar write atômico (temp file + rename). Validar JSON antes de escrever. Preservar indentação original. Remover supressão de erro.

### 32. Scripts shell sem cobertura de testes automatizados
- Status: backlog
- Type: chore
- Severity: medium
- Report: opencode
- Base branch: main
- Reviewers: 1
- Remote: -
- PR: -
- Location: scripts/*.sh (12 scripts, 0 testes)
- Description: 12 scripts shell sem nenhum teste automatizado. Eles contêm lógica awk complexa, paths de erro e edge cases que seriam pegos por testes.
- Impact: Bugs em scripts passam despercebidos. Propenso a regressões. A infraestrutura do pipeline é a parte menos testada do sistema.
- Suggested fix: Criar scripts/tests/ com BATS ou shellcheck. Adicionar target `make test-scripts`. Adicionar ao CI.

### 33. `promote.sh` ignora silenciosamente falhas de `git fetch`
- Status: backlog
- Type: bug
- Severity: medium
- Report: opencode
- Base branch: main
- Reviewers: 1
- Remote: -
- PR: -
- Location: scripts/promote.sh:162
- Description: `git fetch origin "$BASE_BRANCH" 2>/dev/null || git fetch origin 2>/dev/null || true` — erros de rede, autenticação ou remote inexistente são completamente suprimidos sem warning.
- Impact: Desenvolvedores podem trabalhar em branch stale sem saber que o remote está inacessível. Possíveis conflitos de merge depois.
- Suggested fix: Logar warning quando fetch falhar. Substituir `2>/dev/null` por `2>&1` para visibilidade.

### 34. `known_issues.md` global carregado como instrução para todos os projetos
- Status: backlog
- Type: chore
- Severity: low
- Report: opencode
- Base branch: main
- Reviewers: 1
- Remote: -
- PR: -
- Location: opencode.json:6
- Description: `opencode.json` inclui `~/.config/opencode/known_issues.md` no array `instructions`. Como a config é herdada por todos os projetos, as issues do opencode são injetadas no contexto de qualquer projeto que use esta config global.
- Impact: Poluição de contexto do agente — issues do opencode (como "Agente Anderson") aparecem em sessões de outros projetos.
- Suggested fix: Mover known_issues.md para fora de instructions, usando AGENTS.md para referenciá-lo apenas quando trabalhando no próprio opencode.

### 35. `sync_github_issues.sh`: detecção de estado de issue GitLab frágil e sem fechamento automático
- Status: backlog
- Type: bug
- Severity: low
- Report: opencode
- Base branch: main
- Reviewers: 1
- Remote: -
- PR: -
- Location: scripts/sync_github_issues.sh:92-93
- Description: Detecção de estado no GitLab usa `glab issue view | head -5 | grep -i state` — frágil e dependente de formatação. Além disso, o branch GitLab nunca chama `SHOULD_CLOSE=true` para status resolved (linhas 91-94 faltam a lógica de fechamento).
- Impact: Issues GitLab em status resolved nunca são fechadas automaticamente pelo sync. Detecção quebra com mudanças de versão do glab.
- Suggested fix: Usar `glab issue view --json state --jq '.state'` se suportado. Adicionar lógica de close para GitLab resolved.

### 36. `scan_issues.sh` usa globs hardcoded que não cobrem diretórios do projeto
- Status: in-publish
- Type: chore
- Severity: low
- Report: opencode
- Base branch: main
- Reviewers: 1
- Remote: -
- PR: #49
- Location: scripts/scan_issues.sh:10-11
- Description: O script escaneia apenas `./src ./cmd ./internal ./*.go ./*.py ./*.js ./*.ts ./*.rs`. Projetos com layouts diferentes (monorepo, app/, lib/, scripts/) são ignorados.
- Impact: scan-issues pode reportar "no issues" quando há issues em diretórios não listados. Scripts shell em scripts/ nunca são escaneados.
- Suggested fix: Incluir scripts/ nos targets. Adicionar suporte a config `.opencode/scan-patterns` ou escanear a raiz com .gitignore-aware tool.

### 37. Delegar `ocf:develop` para router e agentes Go/Python
- Status: in-progress
- Type: feat
- Severity: medium
- Report: opencode
- Base branch: main
- Reviewers: 1 (docs, runtime)
- Remote: -
- PR: -
- Location: commands/ocf:develop.md, opencode.json, agents/development/develop-router.md, agents/development/devs/golang.md, agents/development/devs/python.md, skills/development/go/*, skills/development/python/*
- Description: Atualizar `ocf:develop` para invocar `develop-router` e registrar agentes especializados para Go e Python com skills dedicadas.
- Impact: O fluxo de desenvolvimento passa a rotear automaticamente para o agente mais específico, em vez de cair sempre no `developer` genérico, melhorando a qualidade idiomática em projetos Go e Python.
- Business rules:
  1. `/ocf:develop` deve invocar `develop-router` em vez de chamar `developer` diretamente.
  2. `develop-router` deve escolher `development/devs/golang` quando o contexto indicar Go.
  3. `develop-router` deve escolher `development/devs/python` quando o contexto indicar Python.
  4. O registro de agentes deve incluir `development/devs/golang` com `go.mod`, `.go`, `cmd/`, `internal/`.
  5. O registro de agentes deve incluir `development/devs/python` com `pyproject.toml`, `requirements.txt`, `setup.py`, `setup.cfg`, `.py`, `.pyi`, `src/`, `app/`, `tests/`.
  6. O agente Python deve se apoiar apenas nas fontes fornecidas para PEP 20, PEP 8, PEP 257, typing, dataclasses, excecoes e Google Python Style Guide.
  7. As skills Go e Python devem estar disponiveis para revisao e implementacao idiomatica quando necessarias.
  8. O ecossistema Python pode incluir skill especializada para Flask quando o desafio principal for desenho de API HTTP e nao sintaxe da linguagem.
- Suggested fix: Adicionar o router, registrar os agentes especializados e atualizar o comando/config para usar o novo fluxo.

### 38. Criar agentes orquestradores Discovery e Delivery
- Status: resolved
- Type: feat
- Severity: medium
- Report: william_pereira
- Base branch: main
- Reviewers: 1 (docs, runtime)
- Remote: -
- PR: -
- Location: agents/development/discovery.md, agents/development/delivery.md, agents/README.md, agents/development/README.md, opencode.json, workflow.md
- Description: Criar dois meta-agentes que orquestram as fases do pipeline: Discovery (fases 1-6: PO -> CTO -> Tech Lead -> PO -> QA -> PM) e Delivery (fases 6-12: PM -> Developer -> Review -> QA -> Committer -> Publish -> Close). Registrar comandos `ocf:discovery` e `ocf:delivery` no opencode.json.
- Impact: Simplifica o uso do pipeline — usuários podem invocar um único comando para executar todas as fases de discovery ou delivery, em vez de invocar cada agente individualmente.
- Business rules:
  1. Discovery agent DEVE orquestrar fases 1-6 sequencialmente (PO -> CTO -> Tech Lead -> PO -> QA -> PM)
  2. Delivery agent DEVE orquestrar fases 6-12 sequencialmente (PM -> Developer -> Review -> QA -> Committer -> Publish -> Close)
  3. Após promoção (fase 6), fases 7-11 DEVEM executar automaticamente sem confirmação do usuário
  4. Fase 12 (Close Requester) DEVE pausar após criação da MR — apenas dispara quando MR é merged
  5. Comandos `ocf:discovery` e `ocf:delivery` DEVEM ser registrados no opencode.json
  6. agents/README.md e agents/development/README.md DEVEM listar os novos agentes orquestradores
  7. workflow.md DEVE documentar os agentes orquestradores
- Suggested fix: Criar agents/development/discovery.md e agents/development/delivery.md com instruções completas de orquestração. Atualizar READMEs e workflow.md. Registrar comandos no opencode.json.

### 40. AIBot nativo em GitHub Actions / GitLab CI com imagem Docker do opencode config
- Status: in-progress
- Type: feat
- Severity: critical
- Report: PO
- Base branch: main
- Reviewers: 2 (devops, security)
- Remote: #32
- PR: -
- Location: .github/workflows/aibot-develop.yml, Dockerfile, scripts/build-opencode-image.sh, scripts/run-ci-workflow.sh, opencode.json, workflow.md, scripts/README.md
- Description: Executar o pipeline de desenvolvimento completo em CI remoto (GitHub Actions / GitLab CI) ao detectar `@aibot:develop` em comentário de issue. O workflow usa uma **imagem Docker pre-built** do opencode config (`ghcr.io/pereirawe/opencode-flow:latest` + tag semver) que inclui opencode binary + config completa (agents, skills, commands, scripts, deny rules). O workflow roda `opencode run --command "ocf:develop" <id> --auto` em **modo headless** (sem `--attach`) no runner CI, cria a MR e o aibot comenta o link. Paralelismo massivo: cada repo/issue corre no próprio runner, sem consumir recursos locais.
- Impact: Libera a máquina local; escala horizontalmente com runners GitHub/GitLab; isola cada run; paridade local/CI via imagem imutável. O watcher local (issue 39) vira fallback.
- Business rules:
  1. O trigger DEVE ser APENAS comentário em issue (não PR) contendo `@aibot:develop` como palavra standalone; outros comentários são ignorados.
  2. O repo DEVE estar em allowlist: a imagem contém `aibot-repos.json` (ou o secret/variável `AIBOT_ALLOWLIST` define os repos autorizados). Repo fora da allowlist → recusa com mensagem padrão.
  3. A issue comentada DEVE estar rastreada localmente no workspace: `known_issues.md` com `Remote:` igual ao id remoto. Senão → mensagem padrão "não rastreada localmente", sem pipeline.
  4. O workflow DEVE executar o pipeline completo em modo headless: promote → develop → senior review → QA → correções → committer gate → MR.
  5. Ao terminar com sucesso, o aibot DEVE comentar na issue com o link da MR e que está pronta para revisão/merge.
  6. Se houver bloqueio (regra de negócio ausente/ambígua, conflito, falha de modelo), o aibot DEVE comentar "não foi possível desenvolver, tarefa deve ser revisada" — sem criar MR.
  7. Mensagens DEVM seguir `standards/aibot-messages.md` (uma mensagem por trigger).
  8. NÃO DEVE haver execução concorrente para a mesma issue: lock a nível de issue no CI (ex: `actions/locker` ou mutex por repo+issue) → segundo trigger é ignorado com mensagem padrão.
  9. Múltiplos repos/issues DEVEM rodar em paralelo (runners separados, workspaces/branches isolados `issue-<id>-<slug>`).
  10. NÃO DEVE pollear merge/PR status — fechamento de issue após merge permanece exclusivo do `ocf:check-pr`/close-requester (no-merge-polling boundary).
  11. Secrets: `OPENCODE_API_KEY`, `GH_TOKEN`/`GL_TOKEN`, `AIBOT_ALLOWLIST` em GitHub Actions secrets / GitLab CI variables.
  12. **Imagem Docker**: build automático em push a `main` que toque `.config/opencode/**` (ou `~/.config/opencode/**`); publicada em `ghcr.io/pereirawe/opencode-flow:latest` + tag semver (`vX.Y.Z`); build idempotente e reprodutível.
  13. **Modo headless**: o trigger DEVE ser `opencode run --command "ocf:develop" <local-id> --auto` (sem `--attach`). Se opencode exigir web server, o workflow usa self-hosted runner com acesso a `http://host.docker.internal:4096` — validar em spike antes da implementação.
  14. O workflow DEVE ser idempotente e tolerante a re-runs (re-executar não duplica MR nem pipeline).
  15. O aibot NÃO DEVE auto-disparar (exclusão de autor do comentário).
  16. `workflow.md` DEVE documentar o entry point CI nativo e a fronteira de no-merge-polling.
- Acceptance criteria:
  1. `Dockerfile` + `scripts/build-opencode-image.sh` produzem imagem `ghcr.io/pereirawe/opencode-flow:latest` com opencode binary + config completa; `docker run ghcr.io/pereirawe/opencode-flow opencode --version` funciona.
  2. Build da imagem é idempotente (rodar 2x não quebra) e dispara em push a `main` tocando a config.
  3. Workflow `.github/workflows/aibot-develop.yml` instalado e válido (`actionlint`/parse OK).
  4. Postar `@aibot:develop` em issue rastreada em repo allowlisted → pipeline completo até `in-publish`; MR criada com `PR: #n`; aibot comenta sucesso com link da MR.
  5. Postar `@aibot:develop` em issue não rastreada → aibot posta "não rastreada localmente"; sem mudança de status/branch/MR.
  6. Postar em issue já `in-progress`/`in-publish` → "já em andamento"; exatamente um run.
  7. Dois comentários na mesma issue no mesmo run → apenas um run de develop.
  8. Issues em repos diferentes no mesmo tick → runs paralelos isolados.
  9. Comentário sem o token é ignorado (sem pipeline, sem mensagem).
  10. Caminho de falha (ex: `feat` sem `Business rules:`) → "não foi possível desenvolver"; sem MR.
  11. Comentário em PR não dispara; apenas issue comments.
  12. Comentário do aibot nunca dispara (self-trigger prevention).
  13. Re-run do workflow não re-dispara (idempotência: 1 run prova).
  14. `workflow.md` documenta o entry point CI nativo e a fronteira de no-merge-polling.
  15. Matriz de provider: GitHub Actions + GitLab CI → handling correto em cada.
  16. Security review: com `--auto`, um edit/bash fora do allowlist é negado (deny rules presentes e provadas na imagem; boundary documentado sem superestimar).
  17. Imagem usa opencode versionado (sem drift): `opencode --version` na imagem == versão esperada.
  18. Segredo `OPENCODE_API_KEY`/`GH_TOKEN` não vaza em logs (redação verificada).
- Suggested fix: Criar `Dockerfile` + `scripts/build-opencode-image.sh` (build GHCR + tag semver), `.github/workflows/aibot-develop.yml` (trigger issue_comment → filter `@aibot:develop` → allowlist/tracker gates → `opencode run` headless → MR + notify), validar modo headless em spike, documentar em `workflow.md` e `scripts/README.md`. O watcher local (issue 39) permanece como fallback.
- Notes (implementação — revisores validarem):
  1. **Spike (BR 13) — RESULTADO: headless OK**. Executado em 2026-08-03 com opencode 1.18.7 (binário local em `~/.opencode/bin/opencode`): `opencode run --command "ocf:scan-issues" --auto --dir /home/william_pereira/.config/opencode` SEM `--attach` — o opencode iniciou uma sessão local própria (`message=command session.id=... command=ocf:scan-issues`), resolveu o comando, avaliou permissões (`evaluated permission=read ... action=allow`) e iniciou o stream (`providerID=opencode-go modelID=deepseek-v4-flash`). NÃO exigiu web server nem `--attach`; o `--attach` só é necessário para conectar a um servidor JÁ em execução. O run foi encerrado pelo timeout do spike (30–45s) durante a varredura de arquivos — não por erro de modo headless. Conclusão: o workflow CI pode rodar `opencode run --command "ocf:develop" <id> --auto` dentro do container Docker sem `--attach` e sem self-hosted runner. O modelo deve ser fornecido via `--model` + `OPENCODE_API_KEY` (o provider padrão do opencode é `opencode-go`; o fallback ollama local não existe no runner).
  2. O pipeline headless no CI precisa resolver o CWD quirk (issue 39): o runner roda no workspace do repo alvo com `.opencode/known_issues.md` real (projetos padrão) — repos sem tracker real caem em `cannot-develop` (mesma limitação do watcher local).
  3. A imagem Docker carrega a config global (`~/.config/opencode/`); o workspace do repo alvo é montado via `-v` ou checkout no runner. Secrets via env do workflow.
  4. Issues #41 (nginx) e #39 (watcher local) permanecem independentes; esta issue pode coexistir (watcher como fallback) ou, após validação, o CI nativo torna-se o caminho primário.
  5. **Dependência do issue #39 (não merged)**: `aibot-repos.json`, `standards/aibot-messages.md` e as deny rules de `opencode.json` só existem na branch do issue #39 (PR #31, in-review, NÃO merged em main). O issue #40 portou cópias IDÊNTICAS desses artefatos nesta branch (mesmo blob → merge limpo quando #39 land): `aibot-repos.json` (allowlist), `standards/aibot-messages.md` (templates de mensagem) e o bloco `permission.bash/edit` (deny rules — exigidas pelo AC 16 na imagem). O comando `ocf:aibot-notify` (issue #39) NÃO foi portado: o CI posta mensagens nativamente via `gh`/`glab` usando os templates do `standards/aibot-messages.md`, evitando duplicar o diff de #39 no opencode.json. Se revisores preferirem o `ocf:aibot-notify` no CI, é follow-up.
  6. **Decisão de design — recusa de allowlist**: BR 2 pede "recusa com mensagem padrão" para repo fora da allowlist; o arquivo `standards/aibot-messages.md` portado (idêntico ao de #39) não tem chave `not-allowlisted`. A mensagem de recusa ficou INLINE no `run-ci-workflow.sh` (mesmo tom/formato PT-BR) para não divergir do arquivo de #39. Se os revisores quiserem, mover para o padrão no follow-up.
  7. **Lock por issue**: BR 8/AC 6/AC 7 — implementado via `concurrency` do GitHub Actions por issue (`group: aibot-develop-${{ github.event.issue.number }}`) + re-check de status dentro do script. Dois comentários na mesma issue → o segundo run serializa e o status gate posta `already-in-progress`/`already-resolved`.
  8. **Testes**: `scripts/tests/test_run_ci_workflow.sh` (bash puro, sem BATS) cobre as gates do `run-ci-workflow.sh` (autor/token/allowlist/tracker/status/headless argv) com mocks de `opencode`/`gh` via PATH; `bash -n` em todos os scripts; `actionlint` ausente na máquina — validação do YAML feita com parser do Ruby/`docker` fallback (AC 3 verificado estaticamente; exige runner para validação real do GitHub Actions). `docker build` executado (AC 1) se o daemon estiver disponível.
  9. **GitLab CI (AC 15)**: este repo é GitHub-only (origin github.com). O `.github/workflows/aibot-develop.yml` cobre GitHub Actions; o mesmo `scripts/run-ci-workflow.sh` é provider-agnostic (detecta github/gitlab do remote) e pode ser invocado de um `.gitlab-ci.yml` equivalente — documentado no `scripts/README.md` (seção "GitLab CI"). Matriz de provider coberta no script; o workflow YAML GitLab não foi criado por ausência de repo GitLab no allowlist (flag incompleto se o PO quiser).
 - Suggested fix (alternativo): Se o spike do modo headless falhar, avaliar self-hosted GitHub runner na mesma VM do opencode web, com `--attach http://127.0.0.1:4096` — mantém paralelismo sem exigir suporte headless do opencode. SPIKE PASSED — alternativa NÃO necessária.

### 68. Interview preparation kit — ocf:cv-interview-prep
- Status: backlog
- Type: feat
- Severity: high
- Report: william_pereira
- Base branch: main
- Reviewers: 1 (docs)
- Remote: -
- PR: -
- Location: agents/career/cv-interview-prep.md (NEW), skills/career/cv-interview-prep/SKILL.md (NEW), commands/ocf:cv-interview-prep.md (NEW), opencode.json
- Description: Create command `ocf:cv-interview-prep <candidate-dir> <job>`, agent `career/cv-interview-prep`, and skill `cv-interview-prep`. Given the candidate hub and a job description, generate: (1) likely interview questions for the role (behavioral + technical), (2) suggested STAR-format answers mapped to real experience from the hub, (3) questions the candidate should ask the interviewer, (4) technical topics to review based on the job's required skills. Output as `preparacao-entrevista.md` in the user's communication language. NEVER fabricate experience — STAR answers must reference real hub entries.
- Impact: Bridges the gap between "having a good resume" and "performing well in the interview". The hub already contains the raw material for STAR answers — high commercial value.
- Business rules:
  1. Command `ocf:cv-interview-prep <candidate-dir> <job>` MUST generate a structured interview preparation kit.
  2. The kit MUST include: likely questions (behavioral + technical), STAR answers mapped to hub experience, questions to ask the interviewer, and technical topics to review.
  3. STAR answers MUST reference real achievements from the hub — NEVER fabricate experience.
  4. Questions MUST be role-appropriate (derived from the job's requirements/seniority).
  5. Output: `~/carreira/<candidato>/preparacao-entrevista.md` in the user's communication language.
  6. No [INFERIDO] in the output (actionable prep file, not internal analysis).
  7. The agent MUST validate hub.json before generating.
  8. If a question cannot be answered from the hub (gap), the kit MUST flag it as a preparation gap to review.
  9. The agent MUST be registered in opencode.json (permission, skill allow) with `temperature: 0.2` and edit restricted to `~/carreira/**`.
  10. The skill MUST be registered in `permission.skill` in opencode.json.
  11. The report MUST follow standards/cv-analysis.md (#65) structure.
- Acceptance criteria:
  1. `agents/career/cv-interview-prep.md` exists with valid frontmatter.
  2. `skills/career/cv-interview-prep/SKILL.md` exists with valid frontmatter.
  3. `commands/ocf:cv-interview-prep.md` exists with usage instructions.
  4. `opencode.json` registers the command and skill.
  5. Kit includes behavioral + technical questions, STAR answers, questions to ask, and technical topics.
  6. STAR answers reference real hub entries.
  7. Gaps are flagged as preparation gaps.
  8. Output in user's communication language.
  9. No [INFERIDO] in the output.
  10. Report follows standards/cv-analysis.md structure.
  11. Agent permissions restrict edit to `~/carreira/**`.
  12. `make test-scripts` passes with new test cases.
- Suggested fix: Create agent, skill, command; register in opencode.json. Execute after #64 and #65. Origem: Proposal 2026-08-14-7 em prioritization.md.

### 69. ATS compatibility scoring of generated resume — ocf:cv-ats-score
- Status: backlog
- Type: feat
- Severity: medium
- Report: william_pereira
- Base branch: main
- Reviewers: 1 (qa)
- Remote: -
- PR: -
- Location: agents/career/cv-ats-score.md (NEW), skills/career/cv-ats-score/SKILL.md (NEW), commands/ocf:cv-ats-score.md (NEW), opencode.json
- Description: Create command `ocf:cv-ats-score <candidate-dir> <job-slug>`, agent `career/cv-ats-score`, skill `cv-ats-score`. Given a generated resume PDF (from cv-tailor) and the original job description, extract text from the PDF (pdftotext), analyze keyword density vs the job's requirements, detect ATS red flags (tables, images, multi-column, missing standard sections), and produce a score (0-100) + actionable recommendations. Output as `ats-score.md` in the job's slug directory.
- Impact: Closes the loop — generate, measure, optimize. Without it, the candidate has no feedback on whether the tailored resume actually matches the job's ATS keywords.
- Business rules:
  1. Command `ocf:cv-ats-score <candidate-dir> <job-slug>` MUST analyze the generated resume PDF against the original job description.
  2. Analysis MUST extract text from the PDF via `pdftotext` (best-effort — if pdftotext unavailable, report limitation).
  3. Analysis MUST cover: keyword density (job keywords found in resume vs total), ATS red flags (tables, images as text, multi-column layouts, missing standard sections — contact, experience, education, skills), and section detection score.
  4. Score MUST be 0-100 with breakdown: keyword_match (40%), section_completeness (30%), format_compliance (30%).
  5. Output: `~/carreira/<candidato>/curriculos/<slug>/ats-score.md` in the user's communication language.
  6. The agent MUST be registered in opencode.json with bash allow for `pdftotext*`, `python3*`, `ls*`, `grep*`.
  7. The skill MUST be registered in `permission.skill` in opencode.json.
  8. The agent MUST NOT modify any files (read-only + report) — edit restricted to `~/carreira/**`.
  9. Recommendations MUST be actionable and specific (e.g., "Add 'Kubernetes' to the skills section — it appears 5x in the job but 0x in your resume").
  10. The report MUST follow standards/cv-analysis.md (#65) structure.
- Acceptance criteria:
  1. `agents/career/cv-ats-score.md` exists with valid frontmatter.
  2. `skills/career/cv-ats-score/SKILL.md` exists with valid frontmatter.
  3. `commands/ocf:cv-ats-score.md` exists with usage instructions.
  4. `opencode.json` registers the command and skill.
  5. Score is 0-100 with breakdown (keyword_match 40%, section_completeness 30%, format_compliance 30%).
  6. ATS red flags detected (tables, images, multi-column, missing sections).
  7. Recommendations are actionable and specific.
  8. Output in user's communication language.
  9. Report follows standards/cv-analysis.md structure.
  10. Agent is read-only (no file modification besides the report).
  11. `make test-scripts` passes with new test cases.
- Suggested fix: Create agent, skill, command; register in opencode.json; use pdftotext for text extraction; compute score and recommendations. Execute after #64, #62, and #65. Origem: Proposal 2026-08-14-8 em prioritization.md.

### 70. Hub update flow — incremental edits to existing hub.json
- Status: backlog
- Type: feat
- Severity: high
- Report: william_pereira
- Base branch: main
- Reviewers: 2 (runtime, docs)
- Remote: -
- PR: -
- Location: commands/ocf:cv-hub-update.md (NEW) OR commands/ocf:cv-hub.md (--update flag), agents/career/cv-extractor.md, skills/career/cv-hub/SKILL.md, opencode.json
- Description: Create command `ocf:cv-hub-update <candidate-dir>`, enhancing the existing cv-hub flow to support incremental edits. The user provides new information (pasted text, new PDF, new file) and the agent updates the existing hub.json with the new entries (new experience, skill, certification, project) without recreating the entire hub. Alternatively, accept manual edits to hub.json and validate + regenerate README.md. Command can also be `ocf:cv-hub <dir> --update`.
- Impact: Today the only way to update the hub is to recreate it from scratch. Candidates frequently need to add a new experience, certification, or skill. An incremental update flow avoids re-processing the entire PDF/LinkedIn export.
- Business rules:
  1. Command `ocf:cv-hub-update <candidate-dir>` MUST update an existing hub.json with new entries without recreating the entire hub.
  2. The command MUST accept new information as: pasted text, new PDF (pdftotext), new file, or manual key-value edits.
  3. The agent MUST only ADD or UPDATE entries — it MUST NEVER delete existing entries without explicit confirmation.
  4. After updating, the agent MUST re-validate with `python3 $SCRIPTS_DIR/cv/validate.py` and regenerate `README.md` from the updated hub.
  5. If hub.json does not exist, the command MUST tell the user to run `ocf:cv-hub` first.
  6. Duplicates MUST be detected and merged (same company+title+start_date in experience, same name in skills/certifications/projects).
  7. The agent MUST preserve existing [INFERIDO] markers on entries that had them.
  8. The agent MUST be registered in opencode.json with edit allow for `~/carreira/**` including `hub.json` (unlike cv-optimizer which denies hub.json edits).
  9. The skill MUST extend (not replace) the existing cv-hub skill with update-mode instructions.
  10. A diff/summary of changes MUST be reported to the user after the update.
- Acceptance criteria:
  1. `ocf:cv-hub-update <candidate-dir>` updates an existing hub.json without recreating it.
  2. New entries (experience, skill, certification, project) are added correctly.
  3. Existing entries are preserved (no data loss).
  4. Duplicates are detected and merged.
  5. [INFERIDO] markers on existing entries are preserved.
  6. After update, validate.py passes and README.md is regenerated.
  7. If hub.json does not exist, user is told to run ocf:cv-hub first.
  8. A diff/summary of changes is reported.
  9. Agent permissions allow hub.json edits (unlike cv-optimizer).
  10. `make test-scripts` passes with new test cases.
- Suggested fix: Extend cv-hub skill/agent with update mode; create command (separate or --update flag); register in opencode.json with hub.json edit permission. Execute after #64 (English schema). Origem: Proposal 2026-08-14-9 em prioritization.md.

### 71. Keyword density and match percentage in gap analysis
- Status: backlog
- Type: feat
- Severity: medium
- Report: william_pereira
- Base branch: main
- Reviewers: 1 (qa)
- Remote: -
- PR: -
- Location: skills/career/cv-tailor/SKILL.md, agents/career/cv-tailor.md, commands/ocf:cv-tailor.md, standards/cv-analysis.md
- Description: Enhance the cv-tailor gap analysis to include: (1) match percentage (requirements met / total requirements × 100), (2) keyword density map showing each job keyword and its count in the resume, (3) a coverage summary by section showing which resume sections contain the most job keywords. These metrics complement the ATS score (#69) and give the candidate actionable insight at the gap analysis stage.
- Impact: A qualitative atendido/parcial/not_met classification is useful but not actionable enough. Quantifying the match gives the candidate a clear metric to optimize and compare across jobs.
- Business rules:
  1. The gap analysis in cv-tailor MUST include a match percentage (met / total × 100).
  2. The gap analysis MUST include a keyword density map: each job keyword → count in the generated resume.
  3. The gap analysis MUST include a coverage summary by section (which resume sections contain the most job keywords).
  4. The match percentage MUST use weighted scoring: mandatory requirements weigh 2x, desirable 1x.
  5. The keyword density MUST be computed on the final resume text (extracted from index.html or the PDF).
  6. The gap analysis report MUST follow standards/cv-analysis.md (#65) table format.
  7. The metrics MUST be computed in the cv-tailor skill/agent, not as a separate command (enhance existing, not new agent).
  8. No new agent or command — this is an enhancement to cv-tailor.
- Acceptance criteria:
  1. Gap analysis includes match percentage (weighted: mandatory 2x, desirable 1x).
  2. Gap analysis includes keyword density map (keyword → count in resume).
  3. Gap analysis includes coverage summary by section.
  4. Metrics computed on the final resume text (index.html or PDF).
  5. Gap analysis report follows standards/cv-analysis.md table format.
  6. No new agent or command created.
  7. `make test-scripts` passes with new test cases.
- Suggested fix: Enhance cv-tailor skill/agent with keyword density and match percentage logic; update gap-analysis.md format in standards/cv-analysis.md. Execute after #64 and #65. Origem: Proposal 2026-08-14-10 em prioritization.md.

### 72. Technical corrections — validate.py, schema.json, agents/README, templates, curl security
- Status: backlog
- Type: chore
- Severity: medium
- Report: william_pereira
- Base branch: main
- Reviewers: 1 (runtime)
- Remote: -
- PR: -
- Location: scripts/cv/validate.py, scripts/cv/schema.json, agents/career/README.md (NEW), skills/career/cv-hub/SKILL.md, skills/career/cv-tailor/SKILL.md, agents/career/cv-tailor.md, commands/ocf:cv-tailor.md, opencode.json, scripts/tests/test_cv.sh
- Description: Bundle of technical corrections: (D1) validate.py should use schema.json via jsonschema library with fallback to hand-rolled validator; (D2) improve validation — formats (email, url), nested required fields, summary_i18n, cross-field consistency (start < end in experience, since <= current year); (D3) create agents/career/README.md listing the 3 agents, responsibilities, flow, and commands; (D4) define README.md template for hub output; (D5) restrict or remove curl -L in cv-tailor (replace with "paste text" requirement to eliminate SSRF via file:// redirects).
- Impact: Fixes latent bugs and structural gaps in the career sector infrastructure that reduce reliability and maintainability.
- Business rules:
  1. validate.py MUST use schema.json as the source of truth when jsonschema is available; fall back to the existing hand-rolled validator when jsonschema is not installed (zero dependency regression).
  2. validate.py MUST validate email format (basic regex), URL format (basic regex), summary_i18n keys (pt/en/es), and cross-field: experience.start < experience.end (when end != "atual"/"present").
  3. agents/career/README.md MUST exist and list: cv-extractor, cv-optimizer, cv-tailor (+ any new agents from #66/#67/#68/#69/#70), their responsibilities, the career flow, and the available commands.
  4. A README.md template MUST be defined (in the cv-hub skill or standards/) showing the canonical structure of the human-readable hub README: name + title, contact, summary, experience, education, skills, certifications, projects, languages, links.
  5. curl -L MUST be removed from cv-tailor agent permissions and skill instructions — replace with "ask user to paste job description text" (LinkedIn always blocks; other portals may have file:// redirects or SSRF vectors). The `curl -L*` bash permission in cv-tailor.md and the curl instructions in cv-tailor SKILL.md and command MUST be removed.
  6. No existing functionality MUST break — all changes must pass `make test-scripts`.
  7. test_cv.sh MUST be updated for any validation behavior changes.
- Acceptance criteria:
  1. validate.py uses schema.json via jsonschema when available; falls back to hand-rolled when not installed.
  2. validate.py validates email format, URL format, summary_i18n keys, and cross-field date consistency.
  3. agents/career/README.md exists and lists all career agents + commands.
  4. README.md template is defined in the cv-hub skill or standards.
  5. curl -L is removed from cv-tailor agent permissions and skill/command instructions.
  6. `make test-scripts` passes with updated test_cv.sh.
  7. No existing functionality breaks.
- Suggested fix: Refactor validate.py to use schema.json; add format/cross-field validation; create agents/career/README.md; define README.md template; remove curl -L from cv-tailor. Execute after #64 (English schema). Origem: Proposal 2026-08-14-11 em prioritization.md.

### 73. Standardize project language to English (prompts, skills, docs, scripts) with locale-aware responses
- Status: ready
- Type: feat
- Severity: high
- Report: william_pereira
- Base branch: main
- Reviewers: 2 (docs, qa)
- Remote: -
- PR: -
- Location: agents/** (PT prompts), commands/** (PT docs + opencode.json command templates), skills/**/SKILL.md native (PT frontmatter/body, excl. vendor/**), scripts/*.sh (PT comments/usage/messages), scripts/tests/test_*.sh (PT assertion messages), scripts/tests/test_language.sh (NEW), AGENTS.md, workflow.md, conventions.md, decisions.md, architecture.md, standards/*.md EN originals, standards/aibot-messages.md (exemption note only), standards/telegram-messages.md (EN original + move PT to standards/pt/), skills/shared/locale-loader/SKILL.md
- Description: Rewrite ALL remaining Portuguese-language artifacts to English: agent prompts, skill prompts (frontmatter + body), command docs and opencode.json command templates, scripts (comments, usage/help, errors), root docs (AGENTS.md, workflow.md, conventions.md, decisions.md, architecture.md), and standards/*.md English originals. Standards keep pt/es translations. Add the canonical response-language rule to AGENTS.md (input language → .opencode/locale project → global → EN) and per-agent one-line references; update locale-loader SKILL.md. Ship scripts/tests/test_language.sh as an advisory-then-blocking language-conformance gate (heuristic accent+stopword, auto-discovered by run_all.sh). standards/aibot-messages.md is exempted as a PT-BR domain contract (issue #39). Issue #64 lands first; career files are not re-rewritten.
- Impact: Every agent that reads these prompts (developer, reviewers, QA, committer, sector agents), every project that inherits the global config, and the maintainer — PT/EN mixing (~44 files) is eliminated; outputs remain localized for the user. No runtime behavior change; touching core prompts carries regression risk mitigated by the gate + QA pre-development + senior review.
- Business rules:
  1. English MUST be the operational language of: agent prompts (agents/**), skill prompts (skills/**/SKILL.md frontmatter + body), command docs and opencode.json command templates, scripts (scripts/** comments, usage, help, error messages, interactive prompts), root docs (AGENTS.md, workflow.md, conventions.md, decisions.md, architecture.md), and standards/*.md English originals.
  2. Rewrite is content-preserving (language only). Technical terms, command names, code identifiers, and domain constants ([INFERIDO], aibot message templates — BR 3) remain unchanged.
  3. standards/aibot-messages.md is a PT-BR domain constant (issue #39 spec — the message templates ARE the PT output contract, same precedent as [INFERIDO] in #64). Exempted from the gate and NOT rewritten; a one-line EN header may be added noting the exemption. The remote-issue-comment language exception (aibot posts PT-BR) is documented in the AGENTS.md canonical rule.
  4. Standards keep pt/es translations under standards/{locale}/; EN originals are the source of truth (locale-loader resolves per .opencode/locale).
  5. Response-language rule (canonical in AGENTS.md): every agent responds/produces user-facing output in the user's input language; fallback = .opencode/locale (project → global) → EN. Applies to chat, reports, Telegram, remote issue comments. Per-agent one-line references added to each rewritten prompt; locale-loader SKILL.md updated to match.
  6. New artifacts MUST be authored in English; user-facing new agents/skills carry the response rule; new standards ship pt/es translations.
  7. Gate (scripts/tests/test_language.sh, auto-discovered by run_all.sh): heuristic detection (accent chars + PT stopword co-occurrence with per-file thresholding), NOT grep-only. Covers agents/, commands/, skills/ (native, excl. vendor/), scripts/, root docs, and standards EN originals. Advisory on first run (produces authoritative file inventory) → QA-reviewed → blocking thereafter. Exemptions: standards/pt|es/**, vendor/**, domain constants (BR 3), git history/archive, historical entries.
  8. Historical content not retroactively rewritten (resolved_issues.md, git history, closed proposals); new/edited known_issues.md entries and new proposals authored in EN; mixed-language entries migrated opportunistically only (gate uses diff-only mode for known_issues.md — historical PT entries are exempt).
  9. vendor/** out of scope (ADR 2026-08-05).
  10. Scripts' static user-facing messages MUST be EN; interactive prompts MAY follow project locale but default to EN.
  11. Skill frontmatter description: EN canonical, preserving all current trigger keywords (bilingual keyword retention — PT trigger phrases preserved as keyword appendix since users trigger skills in PT; test-runner, telegram-notifier verified PT → converted with keyword parity); QA verifies no PT description is load-bearing for triggering.
  12. PT assertion messages in existing scripts/tests/test_*.sh are converted to EN — test-observability strings, not exemptions.
  13. Overlap with #64/career bundle: #64 lands first; career files standardized by #64/#62/#63/#65–72 are NOT re-rewritten; merge order = career bundle → this issue.
  14. Verification: make test-scripts passes; gate green; no behavior change (QA pre-development + senior review confirm).
- Acceptance criteria:
  1. All PT artifacts in agents/, commands/, native skills/**/SKILL.md, scripts/**, root docs (AGENTS.md, workflow.md, conventions.md, decisions.md, architecture.md), and standards/*.md EN originals are rewritten to English with no instruction/business-rule/behavior change (QA compares before/after for content parity).
  2. scripts/tests/test_language.sh exists and is auto-discovered by run_all.sh (matches existing test_*.sh glob); detection is heuristic (accented chars + PT stopword co-occurrence with per-file thresholding), not a bare grep.
  3. Gate covers agents/, commands/, native skills/ (excl. vendor/**), scripts/, root docs, and standards EN originals; the exemption set (standards/pt|es/**, vendor/**, aibot-messages.md, git history/archive, historical entries) is enforced without glob over-matching.
  4. Gate is advisory on its first run (emits authoritative file inventory for QA review) and blocking on all runs thereafter (explicit mode switch, not magic).
  5. AGENTS.md contains the canonical response-language rule (input language → .opencode/locale project → global → EN) with the aibot PT-BR exception documented; every rewritten agent/skill prompt carries a one-line reference.
  6. skills/shared/locale-loader/SKILL.md is updated to match the response-language rule; standards/pt/ and standards/es/ translations preserved; EN originals remain source of truth.
  7. standards/aibot-messages.md is NOT rewritten — PT-BR templates byte-identical except optional one-line EN exemption header; the gate does not flag it.
  8. Every skill frontmatter description converted to EN preserves all current trigger keywords (bilingual keyword appendix); QA confirms no PT description was load-bearing for skill triggering.
  9. PT assertion messages in existing scripts/tests/test_*.sh converted to EN; suites still pass.
  10. Scripts' static user-facing messages (usage/help/errors) are EN; interactive prompts default to EN and may follow project locale.
  11. standards/telegram-messages.md EN original created; PT content moved to standards/pt/telegram-messages.md (currently the EN-root file is PT-only — must be corrected).
  12. No career-bundle file standardized by #64/#62/#63/#65–#72 is re-rewritten (no duplicate diffs); merge order = career bundle first, then this issue.
  13. No behavior change: make test-scripts passes, gate green, command names (ocf:cv-hub, ocf:develop, etc.), code identifiers, and domain constants ([INFERIDO]) unchanged — confirmed by QA pre-development and senior review.
  14. New/edited known_issues.md entries and new prioritization.md proposals are authored in EN; resolved_issues.md, git history, and closed proposals untouched.
  15. vendor/** third-party skills untouched (ADR 2026-08-05 / issue #50).
- Tests:
  1. Gate fixture PT prose (accented: "Instruções de desenvolvimento") in an agent prompt → advisory mode flags the file in the report with exit 0; blocking mode exits ≠ 0 listing the file.
  2. Gate fixture accent-free PT prose ("Regras do fluxo de cada sistema sobre o trabalho") → flagged via stopword heuristic (stopword+threshold detection), not just accents.
  3. Gate fixture legit EN prose (with "café"/"naïve" accents and shared Romance tokens) → 0 violations in both modes (no false positives).
  4. PT content under standards/pt/**, standards/es/**, vendor/**, resolved_issues.md, and the exact aibot-messages.md file → gate reports 0 violations in both modes (exemptions honored, no glob over-matching).
  5. PT word inside a fenced code block / inline backtick in an EN doc → not flagged; PT comment line inside a code block → flagged per documented per-file rule.
  6. grep -r "idêntico\|DEVE\|Instruções" over scripts/tests/*.sh assertion messages → 0 PT assertion phrases (converted to EN); test_sync_regression.sh label spot-checked.
  7. skills/**/SKILL.md frontmatter descriptions scanned → 0 PT descriptions; PT trigger keywords retained where documented (assert_contains on preserved bilingual triggers).
  8. Root docs (AGENTS.md, workflow.md, conventions.md, decisions.md, architecture.md) + standards/*.md EN originals → gate scan reports 0 violations; standards/pt/** and standards/es/** parity files still exist (assert_contains).
  9. Content-preserving baseline: assert_contains of unchanged tokens (ocf:cv-hub, ocf:develop, ocf:cv-tailor, [INFERIDO], code identifiers) in sampled rewritten files.
  10. Canonical rule text: AGENTS.md + locale-loader contain the exact resolution order "input language → .opencode/locale → global → EN" with the aibot exception documented (assert_contains wording).
  11. Mode transition: same fixture run with --mode=advisory then --mode=blocking → advisory exit 0 + report generated; blocking exit 1 (assert exit codes + report content).
  12. make test-scripts regression: full suite including new test_language.sh → exit 0 (no breakage of existing tests).
  13. (manual QA) Session in PT input → response PT; EN input → response EN; ES .opencode/locale with EN input → response EN (input wins) — behavioral checklist for QA reviewer.
  14. (manual QA) Senior reviewer samples ≥5 rewritten files → semantics identical, only language changed (content-preservation spot-check per BR 2).
- Suggested fix: (1) write the gate FIRST (scripts/tests/test_language.sh — heuristic accents + PT stopwords, advisory mode emitting the authoritative PT-file inventory, exemptions per BR 3/7/8/9); (2) rewrite each artifact to EN content-preserving using the inventory; (3) add canonical response rule to AGENTS.md + update locale-loader SKILL.md; (4) convert skill description frontmatter to EN with bilingual trigger-keyword appendix; (5) create standards/telegram-messages.md EN original + move PT to standards/pt/; (6) convert PT assertion messages in existing test_*.sh; (7) run make test-scripts + QA pre-development confirmation. Effort ~16–24h. Execute AFTER #64 and the career bundle (#62/#63/#65–72). Origem: Proposal 2026-08-14-12 em prioritization.md.

### 74. Validate and run delivery sessions in isolated containers for effective parallelization
- Status: ready
- Type: feat
- Severity: high
- Report: william_pereira
- Base branch: main
- Reviewers: 2 (devops, security)
- Remote: -
- PR: -
- Location: scripts/run-parallel-delivery.sh (NEW orchestrator), scripts/tests/test_parallel_delivery.sh (NEW), .opencode/spikes/containerized-delivery.md (NEW), state/parallel-delivery/ (host lockfiles, NEW, gitignored), scripts/telegram-notify.sh (env-var verification/tests), scripts/test-runner.sh (cache seeding integration), workflow.md (entry-point + boundary docs), opencode.json (command registration if applicable), scripts/README.md, aibot-repos.json (consumed, unchanged), Dockerfile (reference only — #40 image base)
- Description: Spike-first. Prove that N=3 parallel containerized delivery sessions complete concurrently on one host with zero file-write/git conflicts and results identical to serial execution, documenting the outcome in .opencode/spikes/containerized-delivery.md with pass/fail criteria. Each session runs the full delivery pipeline (promote → develop → senior review → QA → corrections → committer gate → MR) inside its own container with a private working-tree snapshot (feature branch issue-<id>-<slug> on the base branch), reusing the #40 image ghcr.io/pereirawe/opencode-flow (semver-tagged). Orchestrator handles per-issue host-side flock locking (state/parallel-delivery/), parallelism cap AIBOT_MAX_PARALLEL (default 3), cache seeding, session result contract, working-tree-only sync-back to host known_issues.md, resource limits/cleanup, and orphan reaping. Security/allowlist/no-merge-polling boundaries from #39/#40 preserved. If the spike fails, fall back to host-side git worktree isolation or #39 flock serialization.
- Impact: The delivery pipeline's throughput bottleneck on the local machine — concurrent ocf:delivery/ocf:develop sessions collide today on one shared working tree. This unblocks N parallel deliveries (default 3) per host. Touches the core lifecycle (promote/develop/publish) and security boundaries — regression risk mitigated by spike-gating, idempotency requirements, and the #39/#40 gate semantics being reused. BLOCKED ON #40 landing on main + GHCR image publish (semver) — do not promote to in-progress until that lands.
- Business rules:
  1. Spike-first with explicit preconditions: Docker daemon availability; image obtainment (GHCR pull OR build from #40 branch with semver tag); model-API egress from containers; explicit API-level parallelism measurement (not just wall-clock — the model API is likely the real bottleneck). Outcome documented in .opencode/spikes/containerized-delivery.md (or ADR) with pass/fail criteria.
  2. Spike evaluates BOTH isolation candidates: (a) git worktree host-side worktrees (bind-mounted into containers or worktree-only) and (b) full volume-copy clone per session (isolated .git). Pass/fail includes git-metadata race analysis; if shared-.git races cannot be eliminated, full-clone wins.
  3. Isolation semantics: each session runs in its own container with a private working tree; feature branch issue-<id>-<slug> on top of base branch; all writes/git ops confined to the session.
  4. Per-issue lock MUST be host-side (flock on host lockfile under state/parallel-delivery/); snapshot spawn re-checks fresh host status inside the lock (TOCTOU guard). Different issues run in parallel up to AIBOT_MAX_PARALLEL (default 3, runtime-configurable), capped by host resources AND model-API concurrency. Lock scope per-issue, never global.
  5. Image reuse: base MUST be ghcr.io/pereirawe/opencode-flow:latest + semver tag, semver-tagged and rebuildable via the #40 pipeline; extensions layered and versioned.
  6. Config source decision: spike validates both bind-mount ~/.config/opencode (rw session workspace + read-only config) and immutable image config; when the image is stale vs local config, bind-mount wins.
  7. Cache seeding: each snapshot is seeded with a copy of host .opencode/test-cache/; sessions never share cache (each container its own copy). Seeded cache may be stale (base-branch fingerprint) — test-runner --check reports stale and falls back to --run (never blocks).
  8. No-merge-polling boundary preserved: sessions never poll merge/PR status; closing remote issues remains exclusive to ocf:check-pr/Close Requester.
  9. Security: deny rules (global bash deny list + edit denies on opencode.json, aibot-repos.json, state/**, ~/.ssh/**) bind via --auto with the packaged config; non-root containers; only session workspace (rw) + read-only config mounted; ~/.ssh, state/, and telegram.env are NEVER mounted (runtime env injection only).
  10. Allowlist: remote posting only for repos in aibot-repos.json; messages per standards/aibot-messages.md (one per trigger).
  11. Credentials/state injection: GH_TOKEN/GL_TOKEN/OPENCODE_API_KEY env-injected at runtime, never baked into the image.
  12. Session result contract: each session MUST emit a structured result (exit code + result file at a fixed container path: final issue status, PR number, or cannot-develop) consumed by sync-back.
  13. Sync-back is working-tree only: host workspace not modified by sessions; orchestrator (a) fetches the pushed branch, (b) updates host known_issues.md with the session's final status as an uncommitted diff — never commit/push to host main, per-entry replace only (session entry wins, authoritative), AND the host tracker file is flocked during sync-back writes (concurrent sync-backs must not interleave/corrupt the file); failures logged, never silent.
  14. Resource management: CPU/mem limits, hard timeout, cleanup-on-exit; orphaned containers reaped by the orchestrator (including reap at startup, not only at session end).
  15. Idempotency: re-running a session for the same issue MUST NOT duplicate branches, MRs, tracker entries, or remote comments.
  16. telegram-notify.sh env-var path: the env-var credential loading (TELEGRAM_BOT_TOKEN/TELEGRAM_CHAT_ID) already exists in the script — this issue VERIFIES it works with no telegram.env file mounted (container mode) and adds test coverage + credential redaction assertion. Implementation only if the verification finds a gap.
  17. Spike success criteria: N=3 parallel sessions on one host, zero file/git conflicts, no lost tracker updates, no duplicate MRs, wall-clock materially below 3× serial, identical end state to serial, resource peaks within configured limits.
  18. Fallback: spike failure → documented findings + recommendation (host-side git worktree isolation, or #39 flock serialization); NO production implementation without a passing spike or explicit user approval.
- Acceptance criteria:
  1. .opencode/spikes/containerized-delivery.md (or ADR) exists documenting the spike with explicit pass/fail criteria covering the four preconditions: Docker daemon availability, image obtainment (GHCR pull or #40-branch build with semver tag), model-API egress from containers, and API-level parallelism measurement (not just wall-clock).
  2. The spike evaluated BOTH isolation candidates — host-side git worktree worktrees AND full volume-copy clones with isolated .git — including a documented git-metadata race analysis; if shared-.git races cannot be eliminated, the full-clone candidate wins.
  3. Spike success at N=3 on one host demonstrated: zero file/git conflicts, no lost tracker updates, no duplicate MRs, wall-clock materially below 3× serial, end state identical to serial execution, resource peaks within configured limits.
  4. If the spike failed, findings + fallback recommendation (host-side git worktree isolation, or #39 flock serialization) documented and NO production implementation proceeds without a passing spike or explicit user approval.
  5. Orchestrator enforces per-issue host-side flock on lockfiles under state/parallel-delivery/ (never a global lock); snapshot spawn re-checks fresh host issue status inside the lock (TOCTOU guard); different issues run in parallel up to AIBOT_MAX_PARALLEL (default 3, runtime-configurable), capped by host resources and model-API concurrency.
  6. Each session runs in its own container with a private working tree; feature branch issue-<id>-<slug> created on top of base branch; all file writes and git operations confined to the session container, never overlapping other sessions.
  7. Container base is ghcr.io/pereirawe/opencode-flow pinned to a semver tag (not latest-only), rebuildable via the #40 pipeline; extensions layered and versioned.
  8. Spike documented the config-source decision between bind-mount ~/.config/opencode (rw session workspace + read-only config) and immutable image config; when the image is stale vs local config, bind-mount wins.
  9. Each session snapshot seeded with a copy of host .opencode/test-cache/; sessions never share a cache (each container its own copy); stale seeded cache falls back to --run (never blocks).
  10. Sessions never poll merge/PR status; closing remote issues remains exclusive to ocf:check-pr/Close Requester (no-merge-polling boundary preserved).
  11. Security boundary verified: global bash deny list and edit denies (opencode.json, aibot-repos.json, state/**, ~/.ssh/**) bind via --auto with the packaged config; containers run non-root; only session workspace (rw) + read-only config volume mounted; ~/.ssh, state/, and telegram.env never mounted.
  12. Remote posting allowed only for repos in the aibot-repos.json allowlist; others refused with the standard message; remote comments follow standards/aibot-messages.md (one message per trigger).
  13. GH_TOKEN/GL_TOKEN/OPENCODE_API_KEY injected as env vars at runtime, never baked into the image, never in logs (redaction verified).
  14. Each session emits a structured result contract — exit code + result file (fixed container path) containing final issue status, PR number, or cannot-develop — consumed by sync-back.
  15. Sync-back is working-tree only: host workspace never modified directly by sessions; orchestrator fetches the pushed branch and updates host known_issues.md with the session's final status as an uncommitted diff (never commits/pushes to host main), per-entry replace only (session entry authoritative), tracker file flocked during writes; failures logged, never silent.
  16. Resource management: each session container has CPU/memory limits, a hard timeout, cleanup-on-exit; orchestrator reaps orphaned containers (at startup and session end).
  17. Idempotency verified: re-running a session for the same issue produces no duplicate branches, MRs, tracker entries, or remote comments.
  18. scripts/telegram-notify.sh works with only TELEGRAM_BOT_TOKEN/TELEGRAM_CHAT_ID env vars (no telegram.env file mounted) — verified with a mock-curl test; existing file-based fallback retained; credentials redacted from logs.
  19. Dependency gate: the issue may promote on main only after #40 lands and the GHCR image is published (semver); until then it stays ready/backlog with the dependency documented.
- Tests:
  1. Two concurrent runs of run-parallel-delivery.sh for the SAME issue → exactly one proceeds; the other exits with the skip message; flock file created under state/parallel-delivery/ (mock opencode via PATH).
  2. TOCTOU: status flips to in-progress between lock acquisition and branch creation (mock known_issues.md mutation) → orchestrator re-reads status post-lock and skips.
  3. Idempotent re-run: completed issue (PR: #n present) run again → no duplicate MR creation, no duplicate tracker entry; reports already-in-progress; exactly one result consumed.
  4. AIBOT_MAX_PARALLEL=1 with 3 ready issues → sessions execute serially (mock invocation log: no overlap, count = 3).
  5. Sync-back per-entry: session result contract (fixed path, machine-parseable) contains only its own issue block → host known_issues.md updated for that entry only; all other entries byte-identical (diff limited to the one block).
  6. Concurrent sync-back: two session results flushed simultaneously → host tracker file flocked during write; file remains valid with both entries intact (no interleave/corruption).
  7. Container crash mid-run (mock kill) → orchestrator reaps the container, runs cleanup, marks session failed, host status → cannot-develop.
  8. Hard timeout exceeded (mock sleep) → orchestrator kills session, cleanup runs, failure logged.
  9. Credential redaction: session logs containing GH_TOKEN / OPENCODE_API_KEY / TELEGRAM_BOT_TOKEN literal values → persisted logs/errors contain no token values (assert_not_contains on output artifacts).
  10. Env-var credentials: telegram-notify.sh with only TELEGRAM_BOT_TOKEN/TELEGRAM_CHAT_ID env (mock curl via PATH) → sends notification; missing token → graceful error, exit ≠ 0, no crash.
  11. Mount restrictions: docker argv contains rw mount ONLY for the session workspace; no ~/.ssh, no state/, no telegram.env mounts; container runs non-root (mock docker asserts argv).
  12. Allowlist gating: repo not in aibot-repos.json → session refuses with standard message; allowlisted repo → proceeds (mock allowlist + message-count assert).
  13. Image ref: container launched from ghcr.io/pereirawe/opencode-flow:<semver> (assert image argv; no custom base).
  14. Cache seeding: host .opencode/test-cache seeded; stale fingerprint in container → mock test-runner --check reports stale → fallback to --run executes (never blocks).
  15. Missing docker binary/daemon → clear diagnostic message, exit ≠ 0, no partial state.
  16. make test-scripts regression: full suite including new test_parallel_delivery.sh → exit 0.
  17. (spike gate — manual/PM) Spike doc .opencode/spikes/containerized-delivery.md exists with N=3 pass criteria met, both isolation candidates evaluated, API-concurrency cap measured → verified before production implementation is promoted.
  18. (manual QA/integration) Real N=3 parallel run on host: zero file/git conflicts, no duplicate MRs, wall-clock materially < 3× serial, resource peaks within limits → recorded in spike doc.
- Suggested fix: (1) run the spike first: validate the four preconditions (Docker daemon, image obtainment via GHCR or #40-branch build, model-API egress, API-level parallelism measurement), evaluate both isolation candidates (host-side git worktree vs full volume-copy clone with isolated .git) including git-metadata race analysis, document pass/fail in .opencode/spikes/containerized-delivery.md; (2) on pass: implement the orchestrator script scripts/run-parallel-delivery.sh (per-issue host-side flock under state/parallel-delivery/ with TOCTOU re-check, AIBOT_MAX_PARALLEL runtime cap, snapshot spawn with cache seeding, CPU/mem/time limits, cleanup + orphan reap, session result contract, working-tree-only sync-back as uncommitted diff with tracker flock); (3) verify/extend scripts/telegram-notify.sh env-only credentials (likely verification + tests only — support already exists); (4) add scripts/tests/test_parallel_delivery.sh covering locking, idempotency, result contract, sync-back, and deny-rule/allowlist gating; (5) document in workflow.md + scripts/README.md. Effort ~28–36h, spike-gated. BLOCKED ON #40 landing on main + GHCR image publish (semver) — do not promote to in-progress until that lands. Origem: Proposal 2026-08-14-13 em prioritization.md.

### 75. standards/cv-analysis.md lacks a report-type section for linkedin-optimization.md
- Status: backlog
- Type: doc
- Severity: low
- Report: opencode
- Base branch: main
- Reviewers: 1 (docs)
- Remote: -
- PR: -
- Location: standards/cv-analysis.md (section 3), skills/career/cv-linkedin/SKILL.md
- Description: Issue #67 (ocf:cv-linkedin) introduced a new career-sector report type, `linkedin-optimization.md`, and the skill/agent/command correctly reference `standards/cv-analysis.md` for its structure. However, `standards/cv-analysis.md` §3 ("Report-type structures") only documents `analise-perfil.md` (§3.1), `gap-analysis.md` (§3.2) and `inferencias.md` (§3.3) — there is no §3.x entry defining the canonical structure of `linkedin-optimization.md` (H2 section order: Target role → Headline → About → Skills ranking → Featured). The implementation follows the standard's general rules (§1 language, §2 structure, §5 INFERIDO) and defines the section order inline in the skill, so the delivered contract is met; the standard itself is incomplete for future consistency.
- Impact: The report type's canonical structure lives in the skill instead of the shared standard; future report types (e.g. #68 interview prep, #69 ATS score) will not have a single canonical reference. Low severity — no functional impact on #67.
- Business rules:
  1. `standards/cv-analysis.md` DEVE document the `linkedin-optimization.md` report type structure in §3 (as §3.4 or a generic §3.x), matching the section order implemented in the cv-linkedin skill: Target role, Headline suggestions, About section draft, Skills ranking, Featured section.
  2. A DEVE explicitar que o relatório segue as regras gerais de §2 (H1 único, sem metadata header, conteúdo direto) e a convenção [INFERIDO] de §5.
  3. NÃO DEVE alterar o comportamento da skill cv-linkedin — documento de referência, não implementação.
- Acceptance criteria:
  1. `standards/cv-analysis.md` tem entrada §3.x documentando `linkedin-optimization.md` com a ordem de seções H2 da skill.
  2. A entrada referencia §2 (regras gerais) e §5 ([INFERIDO]).
  3. Nenhuma mudança funcional na skill/agente/comando cv-linkedin.
- Tests: -
- Suggested fix: Add a §3.4 entry to `standards/cv-analysis.md` documenting the `linkedin-optimization.md` report structure (H2 section order per the cv-linkedin skill), referencing §2 general rules and §5 [INFERIDO] convention. Can be done as part of the #65 standard maintenance or a standalone docs commit.

### 76. Mandatory `Tests:` field missing across career-bundle issues (#66-#72) — incomplete-spec discovery gap
- Status: backlog
- Opened: 2026-08-15
- Ready: -
- Started: -
- Type: chore
- Severity: medium
- Report: opencode
- Base branch: main
- Reviewers: 1 (qa)
- Remote: -
- PR: -
- Location: known_issues.md (issues #66, #67, #68, #69, #70, #71, #72), standards/issues.md, workflow.md
- Description: The `Tests:` field is MANDATORY for every new issue, captured during discovery as `scenario → outcome` lines (feat/high → ≥3 lines; feat/bug → never `-`). All career-bundle issues were created WITHOUT the field: #66 (closed 2026-08-15), #67 (in-review), and #68-#72 (backlog). The QA pre-development Phase 5 check was skipped for this bundle and the senior reviewers did not flag it. This is an incomplete-spec discovery gap, NOT a bug — no code was written against undocumented scenarios (developers wrote tests from the sector standards), but the issue entries fail the mandatory field contract.
- Impact: Issue entries do not comply with the mandatory `Tests:` standard; the enforcement chain (QA Phase 5 → senior review → post-review QA) did not catch the systematic gap. Without capture, the committer cannot verify the test floor, and future discovery cycles lack the per-issue scenario contract. #67 itself is otherwise fully verified (all 12 BRs/ACs, tests passing) — only the entry field is missing.
- Business rules:
  1. `Tests:` MUST be captured in issue #67 with ≥3 `scenario → outcome` lines (feat/high floor) before the committer gate finalizes `in-publish`.
  2. `Tests:` MUST be captured in issues #68-#72 before each is promoted to `in-progress` (feat/high → ≥3; feat/medium → ≥2), per their severities.
  3. Issue #66 is already archived — the gap is documented here for traceability, no retroactive rewrite.
  4. QA Phase 5 (pre-development) MUST re-verify the `Tests:` field on every future issue before `ready`.
- Acceptance criteria:
  1. Issue #67 entry has `- Tests:` with ≥3 `scenario → outcome` lines.
  2. Each of #68-#72 has `- Tests:` meeting its severity floor before promotion.
  3. QA pre-development re-checks `Tests:` on all new issues (no recurrence).
- Tests: -
- Suggested fix: Discovery refinement: capture the `Tests:` field for #67 (proposed lines in the QA post-review report of 2026-08-15) and for #68-#72 in their respective discovery cycles; enforce the field in QA Phase 5 going forward. Optionally add a mechanical lint gate in promote.sh (follow-up noted in standards/issues.md).

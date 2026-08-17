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

### 24. `pre_commit.sh` não sincroniza trailers de status com `known_issues.md`
- Status: backlog
- Type: bug
- Severity: high
- Report: opencode
- Base branch: main
- Reviewers: 1
- Remote: -
- PR: #93
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
- PR: #93
- Location: scripts/promote.sh, scripts/create_issue.sh, workflow.md, standards/issues.md
- Description: O ciclo de vida documentado é backlog→ready→open→in-progress, mas promote.sh transiciona backlog→ready e ready→in-progress sem nunca passar por open. create_issue.sh mantém status como ready. Nenhum script ou agente seta Status: open.
- Impact: Estado open é inatingível. Código que referencia Status: open (maintain.sh, pre_commit.sh) é dead logic. Diagrama de lifecycle é enganoso.
- Suggested fix: Remover open do ciclo de vida ou fazer create_issue.sh transicionar ready→open ao criar remote com sucesso.

### 28. `close_issue.sh` fecha issue remota sem verificar merge do PR para status não-`in-publish`
- Status: resolved
- Type: bug
- Severity: medium
- Report: opencode
- Base branch: main
- Reviewers: 1 (devops)
- Remote: -
- PR: #93
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
- PR: #93
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
- PR: #93
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
- PR: #93
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
- PR: #93
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
- PR: #93
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
- PR: #93
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
- PR: #93
- Location: scripts/sync_github_issues.sh:92-93
- Description: Detecção de estado no GitLab usa `glab issue view | head -5 | grep -i state` — frágil e dependente de formatação. Além disso, o branch GitLab nunca chama `SHOULD_CLOSE=true` para status resolved (linhas 91-94 faltam a lógica de fechamento).
- Impact: Issues GitLab em status resolved nunca são fechadas automaticamente pelo sync. Detecção quebra com mudanças de versão do glab.
- Suggested fix: Usar `glab issue view --json state --jq '.state'` se suportado. Adicionar lógica de close para GitLab resolved.

### 37. Delegar `ocf:develop` para router e agentes Go/Python
- Status: resolved
- Type: feat
- Severity: medium
- Report: opencode
- Base branch: main
- Reviewers: 1 (docs, runtime)
- Remote: -
- PR: #93
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

### 40. AIBot nativo em GitHub Actions / GitLab CI com imagem Docker do opencode config
- Status: in-review
- Type: feat
- Severity: critical
- Report: PO
- Base branch: main
- Reviewers: 2 (devops, security)
- Remote: #32
- PR: #93
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

### 74. Validate and run delivery sessions in isolated containers for effective parallelization
- Status: ready
- Type: feat
- Severity: high
- Report: william_pereira
- Base branch: main
- Reviewers: 2 (devops, security)
- Remote: -
- PR: #93
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
- PR: #93
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

### 77. cv-cover-letter ainda carrega o padrão curl -L (SSRF) — follow-up do #72 D5
- Status: backlog
- Opened: 2026-08-15
- Ready: -
- Started: -
- Type: bug
- Severity: medium
- Report: senior-reviewers/runtime
- Base branch: main
- Reviewers: 1 (security)
- Remote: -
- PR: #93
- Location: agents/career/cv-cover-letter.md:19,43, commands/ocf:cv-cover-letter.md:30, skills/career/cv-cover-letter/SKILL.md:30, opencode.json:139
- Description: O issue #72 (D5) removeu `curl -L` do cv-tailor (vetor SSRF via file:// redirects; LinkedIn sempre bloqueia). A mesma racionalidade se aplica ao cv-cover-letter, que ainda ensina/permite fetch de URL via `curl -L` no agente, skill, comando e template opencode.json. Encontrado na senior review do #72 (L1) e confirmado na re-review como follow-up obrigatório — fora do escopo do #72.
- Impact: Vetor SSRF e dependência de fetch de URL não confiável persistente no fluxo de carta de apresentação; inconsistência com o padrão do setor career estabelecido no #72.
- Business rules:
  1. `curl -L*` DEVE ser removido das permissões bash do agente cv-cover-letter (agents/career/cv-cover-letter.md:19).
  2. As instruções de fetch via URL com curl DEVM ser substituídas por "peça ao usuário para colar o texto da vaga" no agente, skill (skills/career/cv-cover-letter/SKILL.md:30) e comando (commands/ocf:cv-cover-letter.md:30).
  3. O template do comando ocf:cv-cover-letter em opencode.json (linha 139) DEVE ser atualizado para remover qualquer instrução de curl -L.
  4. A entrada de fonte da vaga DEVE aceitar texto colado, arquivo local ou export oficial — nunca fetch de URL com redirects.
- Acceptance criteria:
  1. `grep -rn "curl -L" agents/career/cv-cover-letter.md commands/ocf:cv-cover-letter.md skills/career/cv-cover-letter/SKILL.md opencode.json` → 0 ocorrências.
  2. O fluxo cv-cover-letter solicita texto da vaga colado pelo usuário em vez de fetch URL.
  3. `make test-scripts` passa com cobertura de teste atualizada (assert_not_contains curl nos quatro artefatos).
- Tests:
  1. Permissão bash do cv-cover-letter contém `curl -L` → gate falha e lista o artefato.
  2. Instrução "curl -L <url>" presente no SKILL/comando/template → gate falha com evidência.
  3. Texto da vaga colado pelo usuário → fluxo gera carta normalmente sem fetch de URL.
  4. `make test-scripts` com cv-cover-letter limpo → exit 0 (assert_not_contains curl em todos os artefatos).
- Suggested fix: Aplicar o mesmo tratamento do #72 D5 ao cv-cover-letter: remover permissão/instruções/template `curl -L` e exigir texto colado. Follow-up registrado na senior review do #72 (L1, não-bloqueante para o #72).

### 78. Design sector skills (foundation for Adorable pipeline)
- Status: backlog
- Type: feat
- Severity: high
- Report: william_pereira
- Base branch: main
- Reviewers: 2 (design, frontend)
- Remote: -
- PR: -
- Location: skills/design/reference-library/SKILL.md, skills/design/component-patterns/SKILL.md, skills/design/design-tokens/SKILL.md, skills/design/visual-hierarchy/SKILL.md
- Description: Create 4 skills under `skills/design/` that encode concrete, testable UI patterns for the Adorable pipeline. These skills are the foundation consumed by all 6 design agents — without them, agents produce generic UI.
- Impact: All 6 design agents (art-director, ui-architect, ui-implementer, ui-critic, ui-auditor, ui-refactor-planner) depend on these skills for pattern references, token systems, component anatomy, and visual hierarchy rules.
- Business rules:
  1. `skills/design/reference-library/SKILL.md` MUST exist with concrete UI patterns (Dashboard Card, Data Table, Nav Rail, Metric Display, Empty State, Command Palette) — each specifies exact CSS values, NOT descriptions.
  2. `skills/design/component-patterns/SKILL.md` MUST exist with anatomy per component type: primitive (Button, Badge, Icon, Avatar, Separator, Skeleton, Spinner) and composite (Card, DataTable, Form, Dropdown, Modal, Toast, CommandPalette).
  3. `skills/design/design-tokens/SKILL.md` MUST exist specifying: palette (5 functional layers + 2 accent + semantic), typography (2 families, scale xs–4xl), spacing (4pt base), radius philosophy, shadow tiers, motion durations.
  4. `skills/design/visual-hierarchy/SKILL.md` MUST exist with rules for: visual weight, contrast ratios (WCAG AA minimum), density modes, responsive patterns.
  5. All skills MUST have English frontmatter with bilingual trigger keywords (PT appendix per #73).
  6. Skills MUST be registered in `opencode.json` under `permission.skill`.
  7. Skills MUST NOT contain code — pattern references consumed by agents as system prompt context.
- Acceptance criteria:
  1. All 4 SKILL.md files exist under `skills/design/*/` with correct frontmatter.
  2. Each skill contains concrete, testable values (not philosophy or opinions).
  3. `opencode.json` registers all 4 skills.
  4. Skills follow `standards/cv-analysis.md` §2 structure rules.
- Tests:
  1. `ls skills/design/reference-library/SKILL.md skills/design/component-patterns/SKILL.md skills/design/design-tokens/SKILL.md skills/design/visual-hierarchy/SKILL.md` → all exist.
  2. `grep -c "MUST\|MUST NOT" skills/design/*/SKILL.md` → each skill has ≥10 MUST statements.
  3. `grep -c "background.*#\|border.*#\|radius.*px\|padding.*px" skills/design/reference-library/SKILL.md` → ≥10 concrete CSS values.
  4. `jq '.permission.skill' opencode.json` → all 4 skills registered.
  5. `grep -c "^#" skills/design/*/SKILL.md` → each skill has ≥3 H2 sections.
- Suggested fix: Create the 4 skills under `skills/design/` with concrete patterns (not philosophy), English frontmatter, bilingual trigger keywords, and register in opencode.json. Reference vendor taste-skill/minimalist-ui for pattern examples but create original content.

### 79. Greenfield pipeline agents (art-director, ui-architect, ui-implementer, ui-critic)
- Status: backlog
- Type: feat
- Severity: high
- Report: william_pereira
- Base branch: main
- Reviewers: 2 (design, frontend)
- Remote: -
- PR: -
- Location: agents/design/art-director.md, agents/design/ui-architect.md, agents/design/ui-implementer.md, agents/design/ui-critic.md
- Description: Create the core 4-pass Adorable pipeline: art-director (brief → design_spec.json), ui-architect (design_spec → component_tree.json), ui-implementer (JSONs → production code), ui-critic (quality gate). Each agent has a single responsibility and consumes/produces structured JSON.
- Impact: Replaces the single-pass `designer.md` with a pipeline that separates layout, architecture, implementation, and quality concerns — the key differentiator from generic AI UI.
- Business rules:
  1. `agents/design/art-director.md` — mode=subagent, edit=deny, bash=deny, temp=0.7. Process: deconstruct brief → audit defaults → 3 design directions → critique → design_spec.json.
  2. `agents/design/ui-architect.md` — mode=subagent, edit=deny, bash=deny, temp=0.2. Process: parse design_spec → layout regions → component tree → contracts → interaction map → build order.
  3. `agents/design/ui-implementer.md` — mode=subagent, edit=allow, bash=allow, temp=0.1. Process: parse JSONs → verify env → implement by build_order → verify checklist.
  4. `agents/design/ui-critic.md` — mode=subagent, edit=deny, bash=deny, temp=0.3. Process: receive code → evaluate checklist → pass/iterate.
  5. NO `model:` in frontmatter — user's default model. Prompt documents preference textually.
  6. All agents consume/produce structured JSON — no ambiguous text between agents.
  7. All agents include locale rule per #73.
  8. art-director rejects AI anti-patterns (cream+terracotta, Inter for everything, generic purple gradient, etc.).
  9. art-director generates 3 directions before selecting; defines signature element.
  10. ui-architect maps all 6 data states per async component; structural accessibility.
  11. ui-implementer implements every defined state — no skipping.
  12. ui-critic blocks delivery on any checklist failure — no partial approvals.
  13. Agents registered in `opencode.json` with correct permissions.
- Acceptance criteria:
  1. All 4 agent .md files exist under `agents/design/` with correct frontmatter.
  2. art-director produces valid JSON with brief_analysis, rejected_defaults, directions_considered, selected_direction, design_spec.
  3. ui-architect produces valid JSON with layout_regions, component_tree, components, interaction_map, build_order.
  4. ui-implementer reads JSONs and writes code files (not JSON).
  5. ui-critic returns APPROVED or ISSUES_FOUND with component-specific feedback.
  6. `opencode.json` registers all 4 agents with correct permissions.
- Tests:
  1. `ls agents/design/art-director.md agents/design/ui-architect.md agents/design/ui-implementer.md agents/design/ui-critic.md` → all exist.
  2. `grep "mode: subagent" agents/design/*.md` → all 4 agents are subagents.
  3. `grep "model:" agents/design/*.md` → 0 occurrences (no hardcoded model).
  4. `grep "edit: deny" agents/design/art-director.md agents/design/ui-architect.md agents/design/ui-critic.md` → all deny.
  5. `grep "edit: allow" agents/design/ui-implementer.md` → allow.
  6. `jq '.agents' opencode.json` → all 4 agents registered.
- Suggested fix: Create the 4 agents under `agents/design/` based on the drafts in `.opencode/adorable-proposal/` but rewritten in English, with no hardcoded model, and registered in opencode.json. Depends on #80 (skills) for pattern references.

### 80. Audit/Refactor agents (ui-auditor, ui-refactor-planner)
- Status: backlog
- Type: feat
- Severity: high
- Report: william_pereira
- Base branch: main
- Reviewers: 2 (devops, frontend)
- Remote: -
- PR: -
- Location: agents/design/ui-auditor.md, agents/design/ui-refactor-planner.md
- Description: Create 2 agents for existing codebase refactoring: ui-auditor (stack-agnostic diagnostic → audit_report.json) and ui-refactor-planner (diagnostic + design_spec → phased refactor_plan.json). Enables the pipeline to work on existing projects, not just greenfield.
- Impact: Extends the Adorable pipeline from new-project-only to any existing codebase. The auditor produces machine-readable diagnostics; the planner produces a migration plan that never breaks working functionality.
- Business rules:
  1. `agents/design/ui-auditor.md` — mode=subagent, edit=deny, bash=allow, temp=0.1. Detects stack via bash (REACT_VITE, NEXTJS_APP, VUE_VITE, PHP_BLADE, PHP_HTML, HTML_VANILLA, etc.).
  2. Auditor uses bash for detection only — never destructive (no rm, mv, write).
  3. Auditor assigns severity scores (1–5) per dimension: visual_consistency, component_structure, state_completeness, accessibility, responsiveness, performance_visual, maintainability.
  4. Auditor cites file and line for every issue; preserves what's good in `preserved_patterns`.
  5. `agents/design/ui-refactor-planner.md` — mode=subagent, edit=deny, bash=deny, temp=0.2. Consumes audit + design_spec → refactor_plan.json.
  6. Planner classifies: Group A (blockers), Group B (inline), Group C (opportunities).
  7. Planner never plans big bang; never deletes before replacing; adapts strategy to stack.
  8. Both output pure JSON; both include locale rule; both registered in opencode.json.
- Acceptance criteria:
  1. Both agent .md files exist under `agents/design/` with correct frontmatter.
  2. ui-auditor detects stack via bash and produces audit_report.json with scores, critical_issues, preserved_patterns.
  3. ui-refactor-planner produces refactor_plan.json with phases, component_decisions, token_mapping, dependency_map.
  4. `opencode.json` registers both agents.
- Tests:
  1. `ls agents/design/ui-auditor.md agents/design/ui-refactor-planner.md` → both exist.
  2. `grep "bash: allow" agents/design/ui-auditor.md` → allow.
  3. `grep "bash: deny" agents/design/ui-refactor-planner.md` → deny.
  4. `jq '.agents' opencode.json` → both agents registered.
- Suggested fix: Create the 2 agents under `agents/design/` based on the drafts in `.opencode/adorable-proposal/` but rewritten in English, with no hardcoded model. Depends on #80 (skills) for token/component references that the planner consumes.

### 81. /ocf:build-ui orchestration command + output file conventions
- Status: backlog
- Type: feat
- Severity: high
- Report: william_pereira
- Base branch: main
- Reviewers: 2 (design, docs)
- Remote: -
- PR: -
- Location: commands/ocf:build-ui.md, commands/ocf:audit-ui.md, standards/design-pipeline.md
- Description: Create 2 orchestration commands and define output file conventions. `/ocf:build-ui` orchestrates the 4-pass greenfield pipeline; `/ocf:audit-ui` orchestrates audit+refactor. Output conventions define deterministic file paths for pipeline artifacts, enabling resumption and multi-model flows.
- Impact: The entry point that makes the Adorable pipeline usable. Without commands, users must manually invoke each agent. Without conventions, output files are unnamed and undiscoverable.
- Business rules:
  1. `commands/ocf:build-ui.md` orchestrates: art-director → ui-architect → ui-implementer → ui-critic.
  2. `commands/ocf:audit-ui.md` orchestrates: ui-auditor → ui-refactor-planner (optional: → build pipeline).
  3. Commands pass JSON outputs between agents — each receives previous agent's output file path.
  4. Commands handle failure at any stage — log + Telegram notification, no continuation.
  5. Output directory: `.opencode/design-outputs/<session-id>/` (timestamp-based, e.g., `2026-08-17T14-30-00`).
  6. Output file names: `design_spec.json`, `component_tree.json`, `refactor_plan.json`, `audit_report.json`, `quality_report.json`.
  7. Commands registered in `opencode.json`.
  8. Commands accept brief (build-ui) or project path (audit-ui).
  9. Commands support resumption — re-run with same session-id skips completed stages.
  10. No hardcoded model in command template — user's default.
  11. Response-language rule: respond in user's input language.
  12. `standards/design-pipeline.md` documents output conventions, session management, pipeline stages.
- Acceptance criteria:
  1. `commands/ocf:build-ui.md` and `commands/ocf:audit-ui.md` exist.
  2. Commands pass JSON file paths between agents as context.
  3. `standards/design-pipeline.md` documents output file names, directory structure, session protocol.
  4. `opencode.json` registers both commands.
  5. `workflow.md` documents the design pipeline as an entry point.
- Tests:
  1. `ls commands/ocf:build-ui.md commands/ocf:audit-ui.md` → both exist.
  2. `grep -c "art-director\|ui-architect\|ui-implementer\|ui-critic" commands/ocf:build-ui.md` → ≥4 references.
  3. `grep -c "ui-auditor\|ui-refactor-planner" commands/ocf:audit-ui.md` → ≥2 references.
  4. `ls standards/design-pipeline.md` → exists.
  5. `grep "design-outputs" standards/design-pipeline.md` → output convention documented.
  6. `jq '.commands' opencode.json` → both commands registered.
- Suggested fix: Create the 2 commands and `standards/design-pipeline.md`. Register in opencode.json. Update workflow.md. Depends on #81 and #82 (agents must exist before commands can invoke them).

### 82. Model fallback mechanism for design agents
- Status: backlog
- Type: feat
- Severity: medium
- Report: william_pereira
- Base branch: main
- Reviewers: 1 (runtime)
- Remote: -
- PR: -
- Location: agents/design/*.md, opencode.json
- Description: Implement model fallback in the design pipeline. Instead of hardcoding `model: anthropic/claude-opus-4-5` in agent frontmatter, agents use the user's default model. Prompt text documents preference without enforcing it. Prevents silent failures when preferred model is unavailable.
- Impact: Prevents pipeline failures when the preferred model is unavailable. The art-director benefits from high-capability models for creativity, but the pipeline must work with any model.
- Business rules:
  1. Design agents MUST NOT have `model:` in frontmatter — user's default model.
  2. Agent prompts document model preference textually: "benefits from high-capability models but works with any model."
  3. `/ocf:build-ui` command MAY include preferred `model` field — fallback to user's default if unavailable.
  4. art-director documents: "temperature: 0.7 recommended for creative output."
  5. ui-implementer documents: "temperature: 0.1 recommended for precise implementation."
  6. Model preference is documentation, not requirement — pipeline works with any model.
- Acceptance criteria:
  1. `grep -c "model:" agents/design/*.md` → 0 occurrences.
  2. All agent prompts contain model preference documentation.
  3. `opencode.json` command template for build-ui may have optional `model` field.
- Tests:
  1. `grep "model:" agents/design/art-director.md agents/design/ui-architect.md agents/design/ui-implementer.md agents/design/ui-critic.md agents/design/ui-auditor.md agents/design/ui-refactor-planner.md` → 0 matches.
  2. `grep -i "high-capability\|works with any model" agents/design/*.md` → ≥4 matches.
- Suggested fix: Remove any `model:` from agent frontmatter (should be done during #81 creation). Add model preference documentation to prompts. Independent of other issues but best done as part of #81.

### 83. Design sector documentation (READMEs, agent-skill mapping, standards)
- Status: backlog
- Type: doc
- Severity: medium
- Report: william_pereira
- Base branch: main
- Reviewers: 1 (docs)
- Remote: -
- PR: -
- Location: agents/design/README.md, agents/README.md, skills/README.md, standards/design-pipeline.md, workflow.md, opencode.json
- Description: Create design sector documentation: README listing all 6 agents with pipeline flow and skill mapping, update parent READMEs, create output conventions standard, update workflow.md with design pipeline entry point, register agents/commands in opencode.json.
- Impact: Makes the design sector discoverable and maintainable. Without documentation, new users cannot find the pipeline or understand agent-skill relationships.
- Business rules:
  1. `agents/design/README.md` lists all 6 agents with one-line description, skills consumed, pipeline position.
  2. `agents/design/README.md` includes flow diagram (Greenfield: brief → art-director → ui-architect → ui-implementer → ui-critic; Audit: codebase → ui-auditor → ui-refactor-planner → ... → UI).
  3. `agents/README.md` updated to include design sector.
  4. `skills/README.md` updated to include design sector.
  5. `standards/design-pipeline.md` documents output file names, directory structure, session protocol, model preference.
  6. `workflow.md` documents design pipeline as entry point: `ocf:build-ui` and `ocf:audit-ui`.
  7. `opencode.json` updated to register new commands and agents.
  8. All documentation in English (per #73).
- Acceptance criteria:
  1. `agents/design/README.md` exists with all 6 agents listed.
  2. `agents/README.md` includes design sector.
  3. `skills/README.md` includes design sector.
  4. `standards/design-pipeline.md` exists with output conventions.
  5. `workflow.md` documents design pipeline entry points.
  6. `opencode.json` registers all design agents and commands.
- Tests:
  1. `ls agents/design/README.md` → exists.
  2. `grep -c "art-director\|ui-architect\|ui-implementer\|ui-critic\|ui-auditor\|ui-refactor-planner" agents/design/README.md` → ≥6.
  3. `grep "design" agents/README.md` → design sector listed.
  4. `grep "design" skills/README.md` → design sector listed.
  5. `ls standards/design-pipeline.md` → exists.
  6. `grep "build-ui\|audit-ui" workflow.md` → design pipeline documented.
  7. `jq '.agents | keys | map(select(startswith("design/")))' opencode.json | wc -l` → ≥6 agents registered.
- Suggested fix: Create documentation files after #81, #82, and #83 are implemented (agents and commands must exist to be documented). Update parent READMEs and workflow.md. Register everything in opencode.json.

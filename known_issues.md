## Known Issues

Single source of truth for tracked work in this project.

### Format

```markdown
### <id>. <title>
- Status: backlog | ready | open | in-progress | in-review | in-qa | in-publish | resolved
- Type: bug | feat | doc | chore
- Severity: critical | high | medium | low
- Report: <user-name> | <model-name>
- Base branch: <default-branch> | <branch-name>
- Reviewers: <number> (<profile1>, <profile2>)
- Remote: - | #<remote-id>
- PR: - | #<pr-number>
- Location: <file-path>:<line-numbers>
- Description: <brief>
- Impact: <what or who is affected>
- Business rules: <specific business logic, constraints, and domain rules>
- Acceptance criteria: <what must be true for the issue to be complete>
- Suggested fix: <approach or next step>
```

`Business rules:` is required for `feat` type issues.
`Base branch:` is set during discovery (usually `main`/`master`).
`Reviewers:` stores count and profiles (set during discovery, e.g. `1 (backend)`).
`Remote:` is populated at the end of discovery (PM asks user, creates if confirmed).
Auto-created by `ocf:promote` or `ocf:develop` if still missing.

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

### 26. `standards/issues.md` não documenta campo `Base branch:` e sintaxe de perfis em `Reviewers:`
- Status: ready
- Type: doc
- Severity: medium
- Report: opencode
- Base branch: main
- Reviewers: 1 (docs)
- Remote: -
- PR: -
- Location: standards/issues.md, standards/pt/issues.md, standards/es/issues.md, known_issues.md:8-22
- Description: O formato canônico em standards/issues.md omite o campo `- Base branch:` e a sintaxe `(<profile1>, <profile2>)` para Reviewers, que estão presentes no header real do known_issues.md e são consumidos por scripts. O mesmo problema existe em standards/es/issues.md (falta Base branch e perfil) e standards/pt/issues.md (falta perfil).
- Impact: Agentes/usuários que leem standards/issues.md produzem entries sem campos obrigatórios para os scripts.
- Business rules:
  1. standards/issues.md DEVE incluir `- Base branch:` após `- Report:`.
  2. standards/issues.md DEVE usar `- Reviewers: <number> (<profile1>, <profile2>)` em vez de `- Reviewers: <number> (set during discovery, default 1)`.
  3. O campo `- Acceptance criteria:` DEVE estar presente em standards/issues.md e known_issues.md.
  4. O known_issues.md DEVE incluir `- Acceptance criteria:` no Format header.
  5. standards/pt/issues.md DEVE atualizar Reviewers syntax para `<número> (<perfil1>, <perfil2>)`.
  6. standards/es/issues.md DEVE incluir `- Base branch:` e atualizar Reviewers syntax para `<número> (<perfil1>, <perfil2>)`.
  7. As descrições dos campos DEVEM ser consistentes entre as três línguas.
- Acceptance criteria:
  1. standards/issues.md contém `- Base branch: <default-branch> | <branch-name>` no entry format.
  2. standards/issues.md contém `- Reviewers: <number> (<profile1>, <profile2>)`.
  3. standards/pt/issues.md contém `- Reviewers: <número> (<perfil1>, <perfil2>)`.
  4. standards/es/issues.md contém `- Base branch:` e `- Reviewers: <número> (<perfil1>, <perfil2>)`.
  5. known_issues.md Format header contém `- Acceptance criteria:`.
  6. standards/issues.md e standards/pt/issues.md mantêm `Acceptance criteria:` (já presentes).
  7. standards/es/issues.md adiciona `- Acceptance criteria:` se necessário.
- Suggested fix: Atualizar os 3 arquivos standards e o Format header do known_issues.md para espelhar o formato canônico.

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
- Status: backlog
- Type: chore
- Severity: low
- Report: opencode
- Base branch: main
- Reviewers: 1
- Remote: -
- PR: -
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

### 42. Agente designer + skills de design-taste para UI de frontend
- Status: in-publish
- Type: feat
- Severity: medium
- Report: william_pereira
- Base branch: main
- Reviewers: 2 (frontend, ux-ui)
- Remote: #33
- PR: #34
- Location: agents/designer.md, skills/design/*/SKILL.md, opencode.json
- Description: Criar o agente `designer` (frontend product agent) que transforma descrições em UI funcional seguindo brief → explore → plan → build → review, e instalar as skills de design do repo `Leonxlnx/taste-skill` (design-taste-frontend default; redesign-existing-projects, minimalist-ui). O skill v2 obriga o agente a ler o brief, inferir a direção de design e só então gerar código.
- Impact: Habilita build de UIs polidas e funcionais a partir de descrição, com direção estética explícita e reuso do design system existente do projeto, em vez de estética genérica.
- Business rules:
  1. O agente DEVE ser criado como `agents/designer.md` (global) no formato opencode (frontmatter + prompt).
  2. O agente DEVE seguir a ordem de workflow: brief → explore → plan → build → review.
  3. O agente DEVE ler o SKILL.md de design do projeto ANTES de gerar qualquer UI; as regras do skill sobrepõem os defaults do agente.
  4. O agente DEVE usar o design system existente do projeto (tokens, componentes, convenções) antes de introduzir novos padrões.
  5. O agente NÃO DEVE usar defaults genéricos (gradientes roxos, headers com emoji, grids de 3 colunas) salvo se o brief pedir.
  6. O agente DEVE detectar o framework do projeto (React/Vue/Svelte/Astro...) e a component library instalada (shadcn/radix/headlessui).
  7. O agente SÓ DEVE adicionar dependências se realmente necessário e DEVE perguntar antes.
  8. O agente DEVE convidar feedback após cada build e tratar follow-ups como refinamento.
  9. As skills de design DEVEM ser instaladas via `npx skills add` com os skills: design-taste-frontend (default), redesign-existing-projects (redesign/audit), minimalist-ui (Notion/Linear). Nota: os nomes design-audit-frontend, design-minimal-frontend e design-soft-frontend NÃO existem no repo `Leonxlnx/taste-skill`; os equivalentes reais são redesign-existing-projects e minimalist-ui, e não há skill dedicada de soft UI/glassmorphism (fallback: design-taste-frontend com vibe "glassy"/"soft").
  10. O mapeamento de casos de uso → skill DEVE ser documentado (landing novo → taste; redesign → audit; minimalista → minimal; soft/glass → soft).
  11. O agente DEVE usar `mode: all` e modelo `anthropic/claude-sonnet-4-20250514`.
  12. Permissões do agente DEVM restringir edição a `src/**`, `app/**`, `components/**`, `public/**` e bash a `npm run dev`, `npm install *`, `npx *` (resto `ask`).
- Acceptance criteria:
  1. `agents/designer.md` existe com frontmatter válido (description, mode, model, permission).
  2. O prompt do agente contém as 5 fases (brief/explore/plan/build/review) e as regras de design.
  3. `skills/design/` contém SKILL.md(s) instalados do taste-skill.
  4. O SKILL.md é lido automaticamente pelo opencode (skills.paths configurado se necessário).
  5. O mapeamento dos 4 casos de uso → skill está documentado.
  6. `opencode.json` válido após a mudança.
  7. Agente acessível via Tab/@designer.
- Suggested fix: (1) rodar `npx skills add https://github.com/Leonxlnx/taste-skill --skill design-taste-frontend` na raiz, (2) repetir para redesign-existing-projects e minimalist-ui, (3) criar `agents/designer.md` com o conteúdo fornecido, (4) registrar skills.paths se instalado fora do padrão, (5) documentar mapeamento de casos de uso.


### 46. nginx como requisito + HTTPS local para o opencode web service
- Status: ready
- Type: feat
- Severity: high
- Report: PO
- Base branch: main
- Reviewers: 2 (devops, runtime)
- Remote: -
- PR: -
- Location: scripts/setup-web.sh, scripts/setup-nginx.sh, scripts/nginx-opencode.conf, scripts/opencode.service, opencode.json, scripts/README.md
- Description: Adicionar nginx como requisito do setup e expor o opencode web (que roda via systemd em 127.0.0.1:4096) através de um reverse proxy com HTTPS local. Cria `setup-nginx.sh` + template `nginx-opencode.conf`, orquestrados por `setup-web.sh --with-nginx`. Certificado via mkcert para `https://opencode.local`, redirecionando HTTP→HTTPS, com seleção inteligente de porta HTTP (80 → 8080 → 8081 → próxima livre, pois a porta 80 está ocupada pelo container docker gateway-go-nginx-1).
- Impact: Elimina acesso manual a localhost:4096; padroniza `https://opencode.local`; garante serviço systemd com bind estável; segurança TLS local sem warnings.
- Business rules:
  1. `setup-web.sh` DEVE aceitar `--with-nginx`; quando presente, DEVE invocar `setup-nginx.sh` como parte do fluxo de instalação/atualização.
  2. `setup-nginx.sh` DEVE instalar o pacote nginx (full) se ausente, usando o gerenciador de pacotes detectado de `/etc/os-release` (apt para Debian/Ubuntu, dnf para RHEL-family).
  3. O certificado DEVE usar mkcert como ÚNICO mecanismo (`mkcert -install` com CAROOT preservado; leaf cert para `<hostname>`, `127.0.0.1`, `::1` em `/etc/opencode/certs/`). Se mkcert ausente, DEVE abortar com erro claro — sem fallback self-signed.
  4. A porta HTTP DEVE ser selecionada automaticamente: tenta 80; se ocupada, 8080; se ocupada, 8081; assim por diante até a próxima livre. A porta HTTPS é sempre 443.
  5. Se a porta 443 estiver ocupada, o setup DEVE abortar com erro claro antes de escrever qualquer configuração.
  6. HTTP (`http://opencode.local:<porta-http>`) DEVE responder 301 redirect para `https://opencode.local`.
  7. A config nginx DEVE ser renderizada de `scripts/nginx-opencode.conf` com `server_name <hostname>`, `listen <porta-http>` + `443 ssl`, `proxy_pass http://127.0.0.1:4096`, `X-Forwarded-Proto https`, headers de WebSocket upgrade e `proxy_read_timeout 3600s`.
  8. `scripts/opencode.service` DEVE pinar `ExecStart` com `web --hostname 127.0.0.1 --port 4096` (evita drift que quebraria o proxy).
  9. Certificados DEVEM ficar em `/etc/opencode/certs/` (cert 0644, key 0640, root:root).
  10. O setup DEVE ser idempotente (rodar 2x não quebra nada) e NÃO DEVE modificar vhosts existentes nem o container docker que ocupa a porta 80.
  11. `--uninstall` DEVE remover apenas o footprint nginx do opencode (site config + `/etc/opencode/certs/`); DEVE manter o pacote nginx, outros vhosts, a CA mkcert, o serviço opencode e a entrada em `/etc/hosts`.
  12. O hostname DEVE ser parametrizável via `--hostname` (default `opencode.local`).
  13. A documentação de `setup-web.sh` DEVE referenciar `william_pereira` (underscore), nunca `william-pereira`.
  14. O setup DEVE garantir a entrada `<hostname> → 127.0.0.1` em `/etc/hosts` de forma idempotente (adiciona se faltar, não duplica).
  15. Durante a instalação, o setup DEVE PERGUNTAR ao usuário se deseja abrir as portas HTTP/HTTPS escolhidas (ou portas customizadas) no firewall ativo, e DEVE documentar no README instruções manuais para abrir portas após a instalação.
  16. Após o setup, `nginx -t` DEVE passar, o nginx DEVE ser recarregado, e o serviço opencode DEVE permanecer ativo em `127.0.0.1:4096`.
  17. O restart do serviço (`ocf:restart-web`) DEVE continuar funcionando após o nginx ser adicionado.
- Acceptance criteria:
  1. `./setup-web.sh --user william_pereira --bin /home/william_pereira/.opencode/bin/opencode --with-nginx` completa com exit 0 nesta máquina (porta 80 ocupada por docker, 443 livre).
  2. `nginx -t` reporta sucesso após o setup.
  3. A porta HTTP selecionada está livre e é a próxima disponível na sequência 80→8080→8081→...
  4. `curl -sI http://opencode.local:<porta-http>/` retorna 301 com `Location: https://opencode.local/...`.
  5. `curl --cacert "$(mkcert -CAROOT)/rootCA.pem" https://opencode.local/` retorna 200 com a UI do opencode web.
  6. `systemctl cat opencode` mostra `--hostname 127.0.0.1 --port 4096` no ExecStart.
  7. `systemctl is-active opencode nginx` → ambos `active`.
  8. Rodar `setup-nginx.sh` uma segunda vez exit 0; sem server blocks duplicados.
  9. Uma requisição proxied carrega `X-Forwarded-Proto: https`.
  10. `setup-nginx.sh --uninstall` remove `/etc/nginx/conf.d/opencode.conf` e `/etc/opencode/certs/`; `nginx -t` ainda passa; pacote nginx ainda instalado; container docker da porta 80 intacto; entrada `/etc/hosts` mantida; serviço opencode ativo.
  11. `ocf:restart-web` funciona e `https://opencode.local` está acessível depois.
  12. `setup-web.sh --help` e o comment de usage mostram `william_pereira`.
  13. `/etc/hosts` contém `opencode.local → 127.0.0.1` exatamente uma vez após double setup.
  14. Durante a instalação, o usuário é perguntado sobre abrir portas no firewall; README documenta as instruções manuais.
  15. Handshake WebSocket (wss) funciona através do proxy.
- Suggested fix: Criar `scripts/setup-nginx.sh` + `scripts/nginx-opencode.conf`, pinar `--hostname/--port` no `opencode.service`, adicionar `--with-nginx` ao `setup-web.sh`, atualizar `ocf:setup-web`/`ocf:restart-web` no opencode.json e documentar no `scripts/README.md`.

### 47. Reset de sessões e gestão completa do serviço opencode web (stop/reset)
- Status: in-publish
- Type: feat
- Severity: medium
- Report: william_pereira
- Base branch: main
- Reviewers: 1 (devops)
- Remote: #42
- PR: #43
- Location: scripts/reset-web.sh (novo), opencode.json (ocf:reset-web, ocf:stop-web), scripts/README.md, Makefile
- Description: O serviço systemd `opencode` (web) está documentado e tem comandos de criar (`ocf:setup-web`/`setup-web.sh`) e reiniciar (`ocf:restart-web`), mas NÃO há comando de parar nem de zerar o cache/sessões. O banco de sessões em `~/.local/share/opencode/opencode.db` cresce (atualmente ~1,6 GB) e o usuário quer a capacidade de zerar as sessões e reiniciar o serviço.
- Impact: Gestão completa do serviço (criar/parar/reiniciar/status/zerar sessões); resolve o problema de cache/sessões acumuladas do servidor web com um comando seguro.
- Business rules:
  1. `scripts/reset-web.sh` DEVE parar o serviço systemd `opencode`, limpar o banco de sessões e reiniciar o serviço.
  2. A limpeza DEVE visar `~/.local/share/opencode/opencode.db*` (e `log/`), usando `${XDG_DATA_HOME:-$HOME/.local/share}/opencode` como base — auth.json e account.json DEVEM ser preservados.
  3. Antes de remover, o banco DEVE ser movido para um backup timestamped em `<data-dir>/backups/opencode.db.<YYYYmmdd-HHMMSS>`.
  4. Se o serviço não existir, o script DEVE abortar com erro claro (sem criar banco novo às cegas).
  5. O script DEVE aceitar `--list`/`--dry-run` para mostrar o tamanho do banco e o que seria limpo, sem agir.
  6. Comandos `ocf:reset-web` e `ocf:stop-web` DEVEM ser registrados no opencode.json.
  7. A documentação (scripts/README.md) DEVE cobrir: criar, parar, reiniciar, status e zerar sessões.
  8. O reset DEVE ser seguro para rodar via `sudo systemctl` (service user william_pereira).
- Acceptance criteria:
  1. `scripts/reset-web.sh` existe e `bash -n` passa.
  2. `reset-web.sh --list` mostra o tamanho do banco de sessões sem modificar nada.
  3. Rodar o reset: stop → backup timestamped → remove opencode.db* → start; auth.json/account.json permanecem.
  4. `ocf:reset-web` e `ocf:stop-web` registrados no opencode.json (JSON válido).
  5. `scripts/README.md` documenta criar/parar/reiniciar/status/zerar sessões.
  6. `make test-scripts` continua passando (sem regressão).
- Suggested fix: criar `scripts/reset-web.sh` (stop → backup → limpa db/log → start, com `--list`/`--dry-run`), registrar `ocf:reset-web` e `ocf:stop-web` no opencode.json, atualizar `scripts/README.md` e `Makefile`, e seguir o pipeline.

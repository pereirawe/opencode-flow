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

### 21. Perda progressiva de dados em `resolved_issues.md` no fechamento de issues
- Status: backlog
- Type: bug
- Severity: high
- Report: opencode
- Base branch: main
- Reviewers: 1
- Remote: -
- PR: -
- Location: scripts/close_issue.sh:88-101
- Description: close_issue.sh usa `tail -n +4` para preservar cabeçalho ao pré-pender novos entries, mas isso remove as 3 primeiras linhas do conteúdo existente a cada execução — corrompendo registros antigos progressivamente.
- Impact: Perda cumulativa de dados no arquivo de issues resolvidas. Entradas antigas são silenciosamente truncadas a cada fechamento.
- Suggested fix: Substituir `tail -n +4` por `cat "$RESOLVED_FILE"` para preservar todo o conteúdo existente.

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

### 39. Disparo de pipeline de desenvolvimento por comentário remoto `@aibot:develop`
- Status: in-publish
- Type: feat
- Severity: critical
- Report: PO
- Base branch: main
- Reviewers: 3 (devops, runtime, security)
- Remote: #30
- PR: -
- Location: scripts/aibot-watcher.sh, scripts/aibot-watcher.service, scripts/aibot-watcher.timer, scripts/setup-aibot-watcher.sh, scripts/remote.sh, scripts/sync_github_issues.sh, scripts/tests/*, standards/aibot-messages.md, agents/development/aibot.md, opencode.json, workflow.md, aibot-repos.json, Makefile
- Description: Criar um watcher (systemd timer) que observa comentários em issues remotas (GitHub/GitLab) e, ao detectar `@aibot:develop`, dispara o pipeline completo de desenvolvimento da issue comentada (equivalente a `/ocf:develop <id>`), terminando em senior review, QA, criação de MR e um comentário padrão do aibot avisando que o desenvolvimento terminou e o MR está pronto para revisão/merge. Issues não rastreadas localmente são recusadas com mensagem padrão. Execução via `opencode run --attach` no servidor web existente, com per-repo flock para concorrência serial e paralelismo entre repos.
- Impact: Permite que qualquer pessoa (ou o próprio aibot) dispare desenvolvimento completo de issues pequenas via comentário remoto, sem acesso ao terminal — pipelines paralelos por repo no servidor.
- Business rules:
  1. Apenas repos listados como chaves em `~/.config/opencode/aibot-repos.json` são allowlisted; o watcher DEVE recusar operar em qualquer outro repo.
  2. O watcher DEVE pollear APENAS issue comments (nunca PR comments nem merge states) em repos allowlisted, usando `gh`/`glab` conforme o provider detectado, com cursor persistente por repo; cada comentário DEVE ser processado no máximo uma vez.
  3. Apenas comentários contendo o token `@aibot:develop` como palavra standalone disparam; outros comentários são ignorados mas o cursor ainda avança.
  4. A issue comentada DEVE já estar rastreada localmente: o `.opencode/known_issues.md` do workspace DEVE conter entrada com `Remote:` igual ao id remoto do comentário. Caso contrário, o watcher DEVE postar a mensagem padrão "não rastreada localmente" e NÃO DEVE iniciar pipeline.
  5. Apenas um develop por issue: dentro do flock, o watcher DEVE re-checar o Status — `in-progress`/`in-review`/`in-qa`/`in-publish` → mensagem padrão "já em andamento"; `resolved` → "já resolvida"; senão dispara.
  6. Serialização por repo via `flock -n` (non-blocking) mantida por todo o run de develop; repos rodam em paralelo; um segundo trigger em repo travado é deferido para o próximo tick.
  7. O trigger DEVE ser `opencode run --attach http://127.0.0.1:4096 --auto --dir <workspace> --model "${AIBOT_MODEL:-opencode-go/deepseek-v4-flash}" --command "ocf:develop" <local-id>` — SEM o separador `--` (o formulário com `--` quebra no opencode 1.18.7 com `G.includes is not a function`; corrigido durante senior review). O default do modelo DEVE ser o ID qualificado `opencode-go/deepseek-v4-flash` (o ID bare não resolve no servidor). O comando executa o pipeline completo contínuo (promote → develop → senior review → QA → correções → committer gate → MR). O mesmo vale para `ocf:aibot-notify`: `--command "ocf:aibot-notify" <remote-id> <msg-key>` sem `--`.
  8. Em sucesso (issue atinge `in-publish` com `PR: #n`), o watcher DEVE postar a mensagem padrão de sucesso via agente aibot, incluindo o link do MR lido do known_issues.md.
  9. Em falha (qualquer bloqueio: conflito git, regra de negócio ausente/ambígua, falha de modelo), o watcher DEVE postar a mensagem padrão "não foi possível desenvolver, tarefa deve ser revisada" e NÃO DEVE criar MR.
  10. Todas as mensagens DEVEM seguir `standards/aibot-messages.md` e ser postadas pelo subagente `development/aibot` via comando `ocf:aibot-notify` — uma mensagem por trigger.
  11. A detecção de provider DEVE usar `scripts/remote.sh` (extraído de `sync_github_issues.sh`) baseada em `remote.origin.url`.
  12. O watcher DEVE rodar como systemd timer+service (`OnCalendar=*:0/2`, `Persistent=true`, `TimeoutStartSec=0`) sob o usuário opencode; DEVE fazer health-check do web server (127.0.0.1:4096) antes de disparar e skip+log quando estiver down.
  13. O `--auto` DEVE ser usado apenas se a permission config do servidor negar explicitamente operações perigosas; a fronteira de segurança efetiva = allowlist de repos + gate de issue rastreada + modelo confiável + deny rules explícitas (validadas pelo revisor de security como gate). As deny rules vinculam a sessão principal/comando, o agente `aibot` e o `develop-router`; os agentes de implementação (`developer`/`devs/*`) rodam com bash irrestrito sob `--auto` (permissão de agente substitui a global) e têm apenas deny rules de EDIT para arquivos críticos — o gate de segurança DEVE refletir esse limite com precisão (não superestimar a proteção).
  14. O watcher NÃO DEVE pollear merge/PR status — isso permanece exclusivo de `ocf:check-pr`/close-requester.
  15. Cursor, lock e state DEVEM viver em `~/.config/opencode/state/aibot/` (cursor = último comentário processado; lock = arquivo flock); nenhum secret armazenado.
  16. `workflow.md` DEVE documentar o watcher como novo entry point que alimenta o pipeline contínuo.
  17. Comentários do próprio aibot NUNCA disparam (exclusão de autor para evitar loop).
  18. Apenas issue comments disparam; comentários em PR/review NÃO disparam.
- Acceptance criteria:
  1. `aibot-watcher.timer` + `.service` instalados e enabled; timer dispara a cada 2 minutos (`systemctl list-timers`).
  2. Postar `@aibot:develop` em issue rastreada (`Remote: #n`) em repo allowlisted dispara develop completo até `in-publish`; MR criado com `PR: #n` populado; aibot posta comentário padrão de sucesso com link do MR.
  3. Postar `@aibot:develop` em issue não rastreada → aibot posta "não rastreada localmente"; sem mudança de status, branch ou MR.
  4. Postar em issue já `in-progress` → "já em andamento"; exatamente um run de develop.
  5. Dois comentários `@aibot:develop` na mesma issue no mesmo tick → apenas um run de develop.
  6. Triggers em dois repos diferentes no mesmo tick → runs em paralelo com workspaces/branches isolados.
  7. Comentários sem o token são ignorados (cursor avança, sem pipeline, sem mensagem).
  8. Restart do serviço não re-dispara comentários já processados (cursor persiste).
  9. Web server down → watcher loga e sai limpo; resume no próximo tick sem erro.
  10. Mensagem de sucesso segue `standards/aibot-messages.md` e contém o link do MR.
  11. Caminho de falha (ex: `feat` sem `Business rules:`) → "não foi possível desenvolver, tarefa deve ser revisada"; sem MR.
  12. Regression: `sync_github_issues.sh --dry-run` se comporta igual antes/depois da extração de `remote.sh`.
  13. Replay do mesmo stream de comentários não re-triggera (cursor prova: 1 run).
  14. Comentários do aibot nunca disparam desenvolvimento (self-trigger prevention).
  15. `@aibot:develop` dentro de code fence / quoted reply / texto linkado não dispara; exact match por linha.
  16. Comentário em PR não dispara; apenas issue comments.
  17. `aibot-repos.json` com workspace vazio/inexistente → recusa com mensagem padrão e saída limpa.
  18. Matriz de provider: github / gitlab / remote desconhecido → handling correto cada.
  19. Security review: com `--auto`, um edit de arquivo crítico do opencode (opencode.json, aibot-repos.json, aibot-watcher.sh, state/**, ~/.ssh/**) é negado por deny rules (globais e de agente) presentes e provadas; os agentes de implementação têm bash irrestrito sob `--auto` (limite documentado e refletido no gate).
  20. `workflow.md` documenta o novo entry point e a fronteira de no-merge-polling.
- Suggested fix: Criar `scripts/remote.sh` (extrair de sync_github_issues.sh), `aibot-repos.json`, `standards/aibot-messages.md`, `agents/development/aibot.md`, comando `ocf:aibot-notify`, `scripts/aibot-watcher.sh` + unit/timer templates, hardening de permission rules, e documentar em `workflow.md`.
- Notes (implementação — revisores validarem):
  1. CWD quirk: o watcher resolve o tracker do workspace preferindo `.opencode/known_issues.md` com entries reais, caindo para `<workspace>/known_issues.md` (o repo de config do opencode tem template vazio em `.opencode/`). Para o exemplo `pereirawe/opencode-flow`, um trigger real dispararia `ocf:develop` a partir do workspace root, onde `promote.sh` resolve o tracker por CWD (`.opencode/known_issues.md` vazio) → "Issue not found" → mensagem `cannot-develop`. Projetos padrão (tracker real em `.opencode/`) funcionam normalmente.
  2. Fronteira de segurança (AC 19): deny rules explícitas em `opencode.json` valem sob `--auto`. Pela semântica de merge do opencode, config de bash de um agente substitui a global para aquele agente — as deny rules protegem a sessão principal/comando e agentes sem `bash` próprio; agentes dev com `bash: allow` ficam fora dessa camada específica (o revisor de security valida o gate). O agente `aibot` usa permissão granular (catch-all deny + allow gh/glab/git).
  3. Testes: 98 assertions em `scripts/tests/` (test_remote 12, test_watcher_unit 34, test_watcher_e2e 49, test_sync_regression 3) passando via `make test-scripts` — cobrem BR 1-18 e AC 2-18 (AC 1/19/20 verificados estaticamente; exigem runtime). O e2e usa mocks de gh/glab/opencode/curl injetados via PATH. `sync_github_issues.sh --dry-run` idêntico antes/depois da extração de `remote.sh` (AC 12).
  4. Senior review (1º ciclo): devops APPROVE; runtime REQUEST CHANGES (B1: `--` quebra no opencode 1.18.7; B2: modelo bare não resolve; M1: PR comments disparam no GitHub; M2: token em code fence dispara); security REQUEST CHANGES (B1 gate: deny rules não vinculam agentes de implementação; M1: PR comments). Correções aplicadas: sem `--`, modelo qualificado, filtro de PR no fetch, fence-awareness, deny rules de EDIT (globais e de agente), MAX_TRIGGERS_PER_TICK, cursor init no primeiro run, senha via env, streaming de log, `.gitignore` com `state/`, `systemd-analyze verify` no setup, health-check com `-f`, logs de falha. BR 7/13 e AC 19 atualizados para o formulário real.

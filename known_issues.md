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
- Status: ready
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

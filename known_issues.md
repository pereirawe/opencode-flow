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
- Suggested fix: <approach or next step>
```

`Business rules:` is required for `feat` type issues.
`Base branch:` is set during discovery (usually `main`/`master`).
`Reviewers:` stores count and profiles (set during discovery, e.g. `1 (backend)`).
`Remote:` is populated at the end of discovery (PM asks user, creates if confirmed).
Auto-created by `ocf:promote` or `ocf:develop` if still missing.

### 20. Agente Anderson — feedback de usuário leigo nas MRs
- Status: ready
- Type: feat
- Severity: medium
- Report: PO
- Base branch: main
- Reviewers: 2 (qa, ux-ui)
- Remote: #20
- PR: -
- Location: agents/ (novo agente), opencode.json, workflow.md
- Description: Criar agente "Anderson" — usuário leigo, ansioso, paulistano e puxa-saco — que comenta automaticamente em PT-BR nas MRs após o publish-requester, simulando feedback do cliente final.
- Impact: Fecha o gap de validação do ponto de vista do usuário final no pipeline. Força PRs a serem escritas de forma clara para não-técnicos.
- Business rules:
  1. Acionado AUTOMATICAMENTE após publish-requester criar a MR (novo step no pipeline)
  2. Lê APENAS título + body da PR — NÃO analisa diff/código
  3. Posta UM comentário único via gh ou glab
  4. Comentário INFORMATIVO — não bloqueia merge
  5. Tom: paulistano, leigo, ansioso, puxa-saco
  6. Sempre começa ELOGIANDO, depois faz perguntas ansiosas de leigo
  7. Usa gírias paulistanas: "mano", "sô", "tipo", "caraca", "véi"
  8. Comentário em PT-BR
  9. Se descrição da PR for vazia/curta: comenta que não entendeu e pede mais detalhes
  10. Detecta remote automaticamente (GitHub → gh, GitLab → glab)
  11. Comando manual ocf:anderson-feedback registrado em opencode.json
  12. Se gh/glab falhar: loga erro e continua (não falha pipeline)
- Suggested fix: Criar agents/anderson.md, registrar comando em opencode.json, atualizar workflow.md

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

### 22. Comando `ocf:review-external` registrado sem arquivo de documentação
- Status: in-publish
- Type: bug
- Severity: high
- Report: opencode
- Base branch: main
- Reviewers: 1
- Remote: #22
- PR: #21
- Location: commands/ocf:review-external.md
- Description: `ocf:review-external` está definido em opencode.json e referenciado no Makefile e prioritization.md, mas `commands/ocf:review-external.md` não existe. O comando funciona via template JSON mas não há documentação discoverable para o agente.
- Impact: Agente não tem instruções para executar o comando corretamente. Referências órfãs no Makefile e prioritization.
- Suggested fix: Criar `commands/ocf:review-external.md` ou remover referências órfãs.

### 23. Instruções contraditórias para contagem de revisores entre command doc e opencode.json
- Status: backlog
- Type: bug
- Severity: high
- Report: opencode
- Base branch: main
- Reviewers: 1
- Remote: -
- PR: -
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
- Status: backlog
- Type: doc
- Severity: medium
- Report: opencode
- Base branch: main
- Reviewers: 1
- Remote: -
- PR: -
- Location: standards/issues.md:9-24 vs known_issues.md:8-22
- Description: O formato canônico em standards/issues.md omite o campo `- Base branch:` e a sintaxe `(<profile1>, <profile2>)` para Reviewers, que estão presentes no header real do known_issues.md e são consumidos por scripts.
- Impact: Agentes/usuários que leem standards/issues.md produzem entries sem campos obrigatórios para os scripts.
- Suggested fix: Atualizar standards/issues.md para espelhar exatamente o formato do known_issues.md.

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
- Status: backlog
- Type: bug
- Severity: medium
- Report: opencode
- Base branch: main
- Reviewers: 1
- Remote: -
- PR: -
- Location: scripts/close_issue.sh:42-65
- Description: O script aceita status ready, open, in-progress, resolved e executa `gh issue close` sem verificar se o PR foi merged. Apenas in-publish tem verificação de merge.
- Impact: Fechamento acidental de issues remotas ainda em desenvolvimento. Sem proteção ou confirmação.
- Suggested fix: Restringir close_issue.sh a aceitar apenas status in-publish e resolved. Abortar com erro para outros status.

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
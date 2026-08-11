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

### 55. Decisão de discovery: conteúdo mock PT-BR com switcher EN/ES na landing
- Status: ready
- Type: feat
- Severity: low
- Report: ux-ui
- Base branch: main
- Reviewers: 2 (frontend, ux-ui)
- Remote: #55
- PR: -
- Location: `src/app/landing/`, `src/lib/mock/`
- Description: A landing tags.vizzupy.com tem o chrome (nav, hero, botões) localizado via i18n, mas o conteúdo mock (FAQ, cases, features de planos, idealPara, mensagens WhatsApp, JSON-LD) é PT-BR estático — com o switcher em EN/ES a página fica mista (UI EN + conteúdo PT). O conteúdo mock precisa ser traduzido aos 3 locales ou o switcher deve ser ocultado até que o conteúdo esteja completo.
- Impact: Experiência inconsistente para usuários EN/ES; JSON-LD em PT para todas as locales.
- Business rules:
  1. Todo conteúdo mock (FAQ, cases, features, WhatsApp, JSON-LD) DEVE ser traduzido a 3 locales: pt, en, es. Nenhum locale isento.
  2. O switcher (EN/ES) DEVE permanecer funcional e visível. Selecionar locale DEVE renderizar o conteúdo correspondente.
  3. O switcher DEVE ser ocultado SOMENTE quando todos os 3 locales tiverem conteúdo completo — é um fallback, não o caminho primário.
  4. JSON-LD DEVE seguir o padrão domain-checker para cada locale com @type, @context e locale específicos.
  5. Mensagens WhatsApp DEVEM ser locale-aware — cada template traduzido aos 3 locales.
  6. O fallback DEVE usar pt como locale primário quando nenhum locale for selecionado ou não traduzido.
  7. O switcher DEVE persistir a preferência de locale via NEXT_LOCALE cookie (já existente, middleware cookie-driven).
  8. O conteúdo mock DEVE estar completo antes de ocultar o switcher — sem localização parcial.
  9. WhatsApp NÃO DEVE renderizar em locale sem tradução.
  10. O switcher DEVE ser implementado como componente client-side (React context + i18n) — sem locale switching server-side.
  11. Modelo de dados dos mocks: exports com locale keys (`export const faqs = { pt: [...], en: [...], es: [...] }`) — sem mover para messages JSON (opção B do discovery). Os arquivos de mock são tree-shakeable e já testados; manter esse padrão.
  12. Currency locale-aware: `formatBRL()` em planos.ts DEVE usar o locale ativo (pt→R$, en→BRL, es→BRL) — não hardcoded pt-BR.
  13. Pluralização locale-aware: labels como "tag"/"tags" em planos-personal.tsx DEVEM usar o locale ativo.
  14. CDC e referências legais BR-only DEVEM ser removidas da renderização EN/ES ou adaptadas com equivalente local.
  15. Labels de unidade ("/mês") e valores de feature ("Sim", "Não", "Básicos", "Patrocinado") DEVEM ser locale-aware.
  16. Hero SVG aria-label e siteConfig.tagline ("Aqui pertinho!") DEVEM ser traduzidos aos 3 locales.
  17. JSON-LD por locale DEVE passar no Google Rich Results Test.
  18. NOTA: generateMetadata() das tool pages (BR5 antigo) pertence à issue #105, NÃO a esta issue. Escopo desta issue limita-se ao landing page (tags.vizzupy.com).
- Acceptance criteria:
  1. Todos os blocos de mock (FAQ, cases, features, WhatsApp, JSON-LD) existem em pt, en, es.
  2. O switcher é visível e funcional — ao clicar EN/ES o conteúdo muda.
  3. O switcher é ocultado quando todos os 3 locales têm conteúdo completo.
  4. O switcher persiste a preferência via NEXT_LOCALE cookie.
  5. JSON-LD segue o padrão domain-checker por locale.
  6. WhatsApp messages renderizam corretamente nos 3 locales.
  7. Fallback para pt funciona quando locale ausente ou inválido.
  8. Sem console errors ao trocar de locale.
  9. Currency (formatBRL) usa o locale ativo (R$/BRL).
  10. Pluralização usa o locale ativo.
  11. CDC e referências legais BR são ocultadas/adaptadas para EN/ES.
  12. "Sim"/"Não"/"Básicos"/"Patrocinado" são locale-aware.
  13. "/mês" é locale-aware.
  14. Hero SVG aria-label é traduzido.
  15. JSON-LD de cada locale passa no Google Rich Results Test.
  16. Navegação com browser back/forward mantém o locale correto.
  17. Googlebot sem cookie recebe fallback pt consistente.
  18. tsc --noEmit sem erros; npm test passa.
- Suggested fix: ~40h total (12h tradução + 5h JSON-LD + 5h WhatsApp + 6h switcher + 7h testes + 5h edge cases). Modelo: locale-keyed exports nos arquivos mock existentes. Sessão de discovery PO → CTO → Tech Lead → QA concluída. Afeta também issues 47-51 do EPIC 44. NOTA: generateMetadata das tool pages é escopo da issue #105.

---

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

### 56. Mandatory `Tests:` field captured during discovery (test standards pre-development)
- Status: ready
- Type: feat
- Severity: medium
- Report: william_pereira
- Base branch: main
- Reviewers: 2 (qa, docs)
- Remote: -
- PR: -
- Location: standards/issues.md (en+pt+es), workflow.md, agents/development/product-owner.md, agents/development/quality-analyst.md, agents/development/discovery.md, known_issues.md (header Format block)
- Description: Make the `Tests:` field a mandatory part of every new issue entry, captured during discovery (QA pre-development, Phase 5), so developers write tests against documented `scenario → outcome` definitions instead of inventing them ad-hoc during development.
- Impact: Eliminates rework in dev sessions — every issue carries test standards before development, so Developer and QA know exactly what to verify up front; shrinks senior-review/QA loops. Docs+agents only — no script changes, no test surface.
- Business rules:
  1. `Tests:` field MUST be defined for every NEW issue before development starts — captured during the discovery phase, never added ad-hoc during development.
  2. `Tests:` is MANDATORY in every new issue entry. For `doc`/`chore` types, the literal `- Tests: -` is permitted (no test surface). For `feat`/`bug` types, at least one `scenario → outcome` line is REQUIRED and the value may NEVER be `-`.
  3. Scenario depth is a FLOOR with no upper bound: severity `critical`/`high` → ≥3 `scenario → outcome` lines; `medium` → ≥2; `low` → ≥1. If `- Severity:` is missing at QA validation time, the medium floor (≥2) applies.
  4. The `Tests:` conventions MUST be documented in standards/issues.md (en, pt, es) and in workflow.md (discovery pipeline section).
  5. Applies to ALL new issues going forward; existing in-flight issues in known_issues.md are NOT retroactively rewritten (MR diff is limited to the files in Location).
  6. Enforcement is "verified by QA pre-development review (Phase 5) and senior reviewers" — NOT enforced by scripts. No script gate is added or claimed by this issue.
  7. Missing or insufficient `Tests:` discovered during senior review or post-review QA = `incomplete-spec` (discovery gap), NOT a bug — per standards/code-review.md the issue returns to discovery refinement to capture the missing scenarios.
  8. The QA pre-development checklist (validate testability, apply severity floor, medium fallback when Severity missing, incomplete-spec tagging) MUST be written into the quality-analyst.md agent prompt.
  9. The product-owner.md prompt MUST instruct the PO to drive `Tests:` capture (`scenario → outcome`) during the discovery conversation, alongside business rules.
  10. The discovery.md orchestrator MUST include the QA pre-development `Tests:` validation as part of Phase 5, before PM promotion.
  11. known_issues.md header Format block MUST document the new `- Tests:` field with the `scenario → outcome` convention.
- Acceptance criteria:
  1. `- Tests:` appears in the known_issues.md header Format block and in standards/issues.md en+pt+es, with the scenario→outcome convention and the severity floor rules (≥3 critical/high, ≥2 medium, ≥1 low; medium floor when Severity missing).
  2. Enforcement wording in standards/issues.md and workflow.md reads exactly "verified by QA pre-development review (Phase 5) and senior reviewers" — no wording claims script/lint enforcement. An optional future promote.sh/lint gate is recorded only as a follow-up note, NOT in the AC.
  3. quality-analyst.md prompt contains the QA pre-development checklist: validate testability of `Tests:`, apply severity floor, medium fallback when `- Severity:` missing, tag `incomplete-spec` when `Tests:` missing/insufficient.
  4. product-owner.md prompt instructs the PO to drive `Tests:` scenario→outcome capture during discovery.
  5. discovery.md includes the Phase 5 QA pre-dev `Tests:` validation step before PM promotion.
  6. workflow.md documents the `Tests:` field, the severity floors, and the incomplete-spec classification rule.
  7. No existing issue entry in known_issues.md is modified (in-flight issues untouched); MR diff scope limited to the files in Location.
  8. en/pt/es standards/issues.md parity spot-checked — all three updated consistently.
- Suggested fix: Update the known_issues.md header Format block and standards/issues.md (en+pt+es) with the `- Tests:` field, severity floors, and enforcement wording; document the incomplete-spec classification in workflow.md; write the QA pre-dev checklist into quality-analyst.md; add the `Tests:` capture step to product-owner.md and the Phase 5 validation step to discovery.md. No script changes. Follow-up (NOT in this issue): optional promote.sh/lint gate.

### 57. Time-tracking fields in issue lifecycle (Opened/Ready/Started/Resolved + Durations)
- Status: ready
- Type: feat
- Severity: medium
- Report: william_pereira
- Base branch: main
- Reviewers: 2 (runtime, devops)
- Remote: -
- PR: -
- Location: scripts/promote.sh, scripts/create_issue.sh, scripts/close_issue.sh, standards/issues.md (en+pt+es), standards/resolved-issue.md (en), workflow.md, scripts/tests/test_timestamps.sh (NEW)
- Description: Add timestamp fields (Opened, Ready, Started) to the known_issues.md entry format, stamp them on script status transitions (promote.sh, create_issue.sh), stamp Resolved at close time, and compute stage durations (Durations) into the resolved archive so per-stage cycle time can be measured.
- Impact: Enables measuring per-stage cycle time (time in backlog, time to ready, dev time, total time to resolution) driving process improvement with real data. Touches the core lifecycle scripts — regression risk mitigated by the new plain-bash test suite. New-issues-only; no retroactive rewriting.
- Business rules:
  1. Timestamps recorded per-issue as fields in the known_issues.md entry (no separate tracking file): `- Opened: <YYYY-MM-DD>`, `- Ready: <YYYY-MM-DD>`, `- Started: <YYYY-MM-DD>`; `Resolved` and `Durations` are recorded at close time in the archive entry. Field order in known_issues.md: `Status` < `Opened` < `Ready` < `Started` (asserted by tests).
  2. Scripts stamp timestamps on status transitions: promote.sh sets `Ready` on backlog→ready and `Started` on ready→in-progress; create_issue.sh sets `Opened` on remote creation success (if not already set); close_issue.sh sets `Resolved` (= close date / today) and computes durations for the archive.
  3. `Opened` is stamped ONLY on remote creation success; when the remote is auto-created during promotion (mode 2), promote.sh backfills `Opened` set-if-absent with today's date (documented approximation).
  4. Duration math MUST use UTC-anchored parse `TZ=UTC date -d "$d" +%s` (DST-robust). Naive local-epoch `/86400` day counting is REJECTED (fails the spring-forward DST scenario t21).
  5. Guard start > end: render each component `-` BEFORE division; floor values at 0 (non-negative); `0d` when diff = 0; when ALL dates are missing, output the literal `- Durations: -`.
  6. `Resolved` = close date (today); the total duration is relative to the close date.
  7. Nothing depends on the unreachable `open` status (issue #25) — except create_issue.sh's legacy open path, which is preserved unchanged.
  8. No trailer-sync via pre_commit.sh (issue #24): timestamp stamping is performed by the pipeline scripts directly, NOT by commit-trailer parsing.
  9. Applies ONLY to new issues created after implementation; no retroactive reconstruction of existing known_issues.md entries or resolved_issues.md archive entries (existing archive entries preserved verbatim — backward compat).
  10. Missing timestamps tolerated in the archive (fields optional, `-` allowed); durations computed only from available timestamps.
  11. Idempotency required (issue #40 CI re-runs): re-running promote.sh/create_issue.sh/close_issue.sh on the same entry MUST NOT duplicate timestamps, corrupt fields, or append duplicate archive entries (exactly one archive entry after a double-run).
  12. Durations = difference between relevant timestamps, computed at close time and stored in the archive entry.
  13. Archive dup guard (issue #29) preserved: close_issue.sh continues to check for existing IDs in resolved_issues.md before appending.
- Acceptance criteria:
  1. NEW `scripts/tests/test_timestamps.sh` ships with the full scenario list t01–t25, including DST spring-forward (t21), double-run idempotency (t19), and prompt-bypass (t20); `make test-scripts` passes (run_all.sh auto-discovers test_*.sh).
  2. Field order asserted: `Status` < `Opened` < `Ready` < `Started` in known_issues.md entries.
  3. Existing pipeline gates unchanged — regression assertions for promote/create/close behavior (t07, t13).
  4. Archive backward compat: existing resolved_issues.md entries preserved verbatim; exactly one archive entry after a double-run of close_issue.sh.
  5. standards/resolved-issue.md (en) reconciled with actual script output — add `Severity` and `Durations` after `Resolved`, drop the legacy `PR` field; en/pt/es standards/issues.md parity spot-checked.
  6. Tests deterministic/self-contained: mock `date` and mock `gh`/`glab` via PATH, no network, no TTY.
  7. promote.sh stamps `Ready` (backlog→ready) and `Started` (ready→in-progress), and backfills `Opened` set-if-absent when auto-creating the remote.
  8. create_issue.sh stamps `Opened` only on remote creation success.
  9. close_issue.sh stamps `Resolved` (today) and computes per-component durations with the guard/floor rules (`-` per component on start>end, `0d` when diff=0, literal `- Durations: -` when all missing).
  10. Duration math passes the DST spring-forward scenario (t21) using `TZ=UTC date -d "$d" +%s`.
  11. No dependency introduced on the unreachable `open` status; create_issue.sh legacy open path unchanged.
  12. Idempotency verified: re-running each script on the same entry produces no duplicate or corrupted fields.
  13. `bash -n` clean on all modified scripts; full `make test-scripts` suite passes.
- Suggested fix: Add `Opened`/`Ready`/`Started` to the known_issues.md entry format and stamping logic in promote.sh (Ready on backlog→ready, Started on ready→in-progress, backfill `Opened` set-if-absent) and create_issue.sh (`Opened` on remote success); extend close_issue.sh to stamp `Resolved` and compute `Durations` using `TZ=UTC date -d "$d" +%s` with per-component guards/floors and the dup guard preserved; update standards/issues.md (en+pt+es) and standards/resolved-issue.md (en); add scripts/tests/test_timestamps.sh (t01–t25). Rebase onto #56 after it lands (shared standards/issues.md + workflow.md).

### 58. develop-router bloqueado: allow patterns bash usam paths relativos que não casam com invocação real
- Status: in-publish
- Type: bug
- Severity: critical
- Report: william_pereira
- Base branch: main
- Reviewers: 2 (security, runtime)
- Remote: #50
- PR: #51
- Location: agents/development/develop-router.md:11-20, workflow.md (security boundary section)
- Description: O agente `develop-router` (usado pelo `/ocf:develop`) define bash com catch-all `"*": deny` e allow patterns com paths RELATIVOS (`"scripts/promote.sh *"`, `"scripts/create_issue.sh *"`). No fluxo real, executado a partir do workspace do projeto alvo, os scripts são invocados com caminho ABSOLUTO (`$HOME/.config/opencode/scripts/promote.sh`, `$SCRIPTS_DIR/create_issue.sh`). O pattern relativo não casa → o catch-all `"*": deny` bloqueia → erro "The user has specified a rule which prevents you from using this specific tool call" em TODO ciclo de develop. Comandos essenciais de orquestração (ls/cat/head/which para detecção de linguagem, telegram-notify.sh exigido pelo AGENTS.md, gh/glab) também são negados pelo catch-all.
- Impact: Todo `/ocf:develop` falha na promoção (promote/create_issue) — o pipeline de entrega fica impossibilitado de rodar via router. Violação do AGENTS.md (telegram-notify obrigatório). Foi observado em logs de 2026-08-10 (07:22–11:05) com dezenas de denials em `create_issue.sh 110`, `ls go.mod pyproject.toml ...`, `telegram-notify.sh`, `gh pr view`, etc.
- Business rules:
  1. Os allow patterns de bash do `develop-router` DEVEM casar tanto invocações relativas quanto ABSOLUTAS (`$SCRIPTS_DIR`/`$HOME/.config/opencode/scripts/`) dos scripts `promote.sh` e `create_issue.sh`.
  2. O catch-all `"*": deny` DEVE ser preservado como base (boundary de segurança do workflow.md) — a correção é de allow patterns, não de remoção do deny.
  3. As deny rules destrutivas de git (`git push --force*`, `git reset --hard*`, `git clean -f*`, `git branch -D *`) DEVEM permanecer DEPOIS de `git *: allow` (findLast) e após a correção.
  4. `telegram-notify.sh` DEVE ser permitido para o router (AGENTS.md obriga notificação de conclusão/falha).
  5. Comandos read-only de orquestração usados na detecção de linguagem (ls/cat/head/which, e `gh *`/`glab *`) DEVEM ser permitidos OU substituídos pelo uso de ferramentas glob/read/grep no prompt do router.
  6. O router NÃO DEVE editar arquivos (edit: deny preservado) — só bash read-only + scripts de pipeline.
  7. Nenhum comando `*` além dos allow explícitos DEVE ser liberado.
- Acceptance criteria:
  1. `$HOME/.config/opencode/scripts/promote.sh <id>` e `/home/<user>/.config/opencode/scripts/create_issue.sh <id>` (paths absolutos) são ALLOWED pelo bash do develop-router.
  2. `scripts/promote.sh <id>` (path relativo) continua ALLOWED.
  3. `git push --force`, `git reset --hard`, `git clean -f`, `git branch -D` continuam DENIED.
  4. `telegram-notify.sh` roda sem deny no router.
  5. `ls`/`cat`/`head`/`which` de arquivos do workspace ou `gh *`/`glab *` não disparam o erro de permissão (ou o prompt usa glob/read/grep).
  6. `edit` permanece deny no router.
  7. `/ocf:develop` numa issue `ready` conclui a promoção (promote + create_issue) sem erro de permissão.
- Suggested fix: Em `agents/development/develop-router.md`, trocar os allow patterns para casar path absoluto: `"*scripts/promote.sh *": allow` e `"*scripts/create_issue.sh *": allow` (ou `"$HOME/.config/opencode/scripts/*.sh *"` + variante relativa). Adicionar `"*scripts/telegram-notify.sh *": allow`. Adicionar allow de `gh *`/`glab *` e de comandos read-only de inspeção (`ls *`, `cat *`, `head *`, `which *`) OU instruir o router no prompt a usar as ferramentas glob/read/grep em vez de bash para inspeção. Manter deny destrutivos de git após `git *: allow` e `edit: deny`. Validar com sessão `/ocf:develop` real.
### 59. Test runner único com cache de resultados (fingerprint) para agentes de development
- Status: in-publish
- Type: feat
- Severity: high
- Report: william_pereira
- Base branch: main
- Reviewers: 2 (qa, runtime)
- Remote: #52
- PR: #53
- Location: scripts/test-runner.sh (NEW), skills/development/test-runner/SKILL.md (NEW), scripts/tests/test_test_runner.sh (NEW), agents/development/developer.md, agents/development/devs/golang.md, agents/development/devs/python.md, agents/development/senior-reviewers/README.md, agents/development/quality-analyst.md, agents/development/committer.md, agents/development/delivery.md, scripts/pre_commit.sh, workflow.md, standards/commits.md
- Description: Criar `scripts/test-runner.sh` — entrypoint único de testes para agentes de development, com bootstrap de ambiente, detecção de runner, fingerprint de mudanças e cache de resultados em `.opencode/test-cache/`. Uma skill `test-runner` documenta o protocolo (check/run/status) para qualquer agente. Prompts de developer, devs/*, senior-reviewers, quality-analyst, committer e delivery passam a consumir o cache quando fresco e rodar testes apenas quando há mudança mínima. `pre_commit.sh` delega ao runner.
- Impact: Elimina execuções repetidas da mesma suite com saída idêntica (developer → senior review → QA → committer rodam o mesmo código 5–7x). Reduz erros de ambiente repetidos (cada agente invoca comando próprio e perde diagnóstico com `2>/dev/null`). Padroniza diagnóstico e reduz tempo de ciclo e tokens.
- Business rules:
  1. `scripts/test-runner.sh` DEVE ser o entrypoint único de testes para agentes — nunca comandos ad hoc (`go test`, `pytest`, `npm test`).
  2. O script DEVE detectar o runner automaticamente (go/cargo/npm/pytest/poetry) e fazer bootstrap de ambiente (venv, node_modules) com diagnóstico claro em caso de erro de ambiente.
  3. O script DEVE suportar: `--check` (cache válido? exit 0 + caminho do relatório; sem cache válido exit 3), `--run` (executa, grava cache, imprime resumo + exit code), `--status` (estado legível).
  4. Fingerprint DEVE ser hash de `git rev-parse HEAD` + arquivos de código/teste alterados (tracked + unstaged). Mudança mínima → fingerprint muda → re-executa.
  5. Cache DEVE ficar em `.opencode/test-cache/<branch>-<runner>.result` e ser gitignored.
  6. Cache NUNCA DEVE bloquear: se não há cache válido ou o script falha, o agente DEVE rodar os testes direto e usar o resultado para o próprio uso.
  7. A skill `test-runner` DEVE documentar o protocolo (check/run/status) e o fallback.
  8. Os prompts DEVEM instruir: cache fresco → reutiliza; sem cache → roda e popula; não bloquear em ausência de cache.
  9. `committer.md` gate "Tests passing" DEVE ser satisfeito por cache fresco OU execução recente bem-sucedida — nunca re-rodar suite idêntica.
  10. `senior-reviewers` DEVE confirmar testes via cache quando fresco; testes pontuais do domínio são livres.
  11. `pre_commit.sh` DEVE delegar ao runner (cache-aware) e NÃO rodar suite completa em todo commit sem verificação de fingerprint.
- Acceptance criteria:
  1. `scripts/test-runner.sh` existe, é executável e `bash -n` limpo; suporta `--check`/`--run`/`--status`.
  2. `--check` sem cache válido sai com exit 3; com cache válido sai exit 0 e imprime o caminho do relatório.
  3. `--run` em projeto com runner detectado executa a suite, grava `.opencode/test-cache/<branch>-<runner>.result`, imprime resumo e exit code.
  4. Fingerprint muda quando um arquivo de código/teste é editado (teste prova); sem mudança, `--check` continua exit 0.
  5. Sem git repo, o script ainda funciona (fingerprint baseado em mtime/conteúdo) ou diagnostica claramente.
  6. Erro de ambiente (runner ausente, deps faltando) produz mensagem clara de diagnóstico, não falha silenciosa (`2>/dev/null` removido).
  7. `skills/development/test-runner/SKILL.md` documenta protocolo + fallback; registro `permission.skill` adicionado.
  8. Prompts de developer, devs/golang, devs/python, senior-reviewers/README, quality-analyst, committer e delivery referenciam o runner/cache.
  9. `pre_commit.sh` delega ao runner e não roda suite completa sem checar fingerprint.
  10. `scripts/tests/test_test_runner.sh` cobre: check válido/inválido, run popula cache, re-run não re-executa, fingerprint muda com edição, fallback sem git, diagnóstico de ambiente; `make test-scripts` passa.
  11. `workflow.md` e `standards/commits.md` documentam o runner e a regra de re-uso.
- Tests:
  1. `scripts/tests/run_all.sh` → todas as suites (incluindo test_test_runner.sh) passam: exit 0.
  2. Mock runner em PATH → `test-runner.sh --run` grava cache com fingerprint e exit code corretos.
  3. Repetir `--run` com mesma fingerprint → saída vem do cache (runner mock NÃO é chamado de novo; contador de invocações prova).
  4. Tocar arquivo de teste → fingerprint muda → `--run` re-executa (contador de invocações incrementa).
  5. `--check` antes de qualquer `--run` → exit 3; depois de `--run` → exit 0 + caminho do relatório.
  6. Diretório sem git (TMPDIR) → `--status` diagnostica; `--run` não quebra (fallback documentado).
- Suggested fix: Criar `scripts/test-runner.sh` (detecção de runner, bootstrap env, fingerprint via `git rev-parse HEAD` + `git status --porcelain` + hashes de arquivos alterados, cache JSON em `.opencode/test-cache/`, modos check/run/status). Criar `skills/development/test-runner/SKILL.md` com protocolo e fallback. Adicionar permissão da skill em opencode.json. Atualizar prompts: developer.md, devs/golang.md, devs/python.md, senior-reviewers/README.md, quality-analyst.md, committer.md, delivery.md. Delegar pre_commit.sh ao runner. Adicionar testes em scripts/tests/test_test_runner.sh. Documentar em workflow.md e standards/commits.md.


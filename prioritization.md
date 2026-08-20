# PO Prioritization Proposals

This file documents the Product Owner's prioritization proposals for backlog items.
Proposals are registered here before being promoted to `known_issues.md`.

## Format

Each proposal follows this structure:

```markdown
### Proposal YYYY-MM-DD-<N>: <title>
- Priority: critical | high | medium | low
- Business value: <what value this delivers>
- Target sprint: <sprint-name | next | backlog>
- Description: <brief>
- Business rules: <known business logic, constraints, domain rules>
- Stakeholders: <who requested or benefits>
- Rationale: <why now, why this priority>
- Dependencies: <related issues, external factors>
- Proposed issue type: bug | feat | doc | chore
```

`Business rules:` is required for `feat` proposals — document everything known
at proposal time. Unknown rules will be captured during discovery refinement.

## Active Proposals

### Proposal 2026-06-09-1: Consolidar decisões de branch, revisores e issue remota no discovery
- Priority: high
- Business value: Elimina interrupções no desenvolvimento eliminando perguntas redundantes do PM na promoção. Tudo que pode ser decidido no discovery (branch base, revisores, issue remota) já deve estar definido e registrado em `known_issues.md` antes do desenvolvimento começar.
- Target sprint: next
- Description: O discovery pipeline atual (PO → CTO → Tech Lead → QA → PO → PM) captura regras de negócio, critérios de aceite e histórias, mas não define branch base, revisores e issue remota. Isso é perguntado na promoção (PM), causando interrupção. A proposta é mover essas decisões para o discovery:
  1. Branch base (main ou outra) decidida durante discovery e registrada no `known_issues.md`
  2. Perfis e quantidade de senior reviewers decididos durante discovery
  3. Issue remota criada durante discovery, com Remote já populado
  4. PM promotion vira execução automática sem perguntas
- Business rules:
  1. `known_issues.md` DEVE ter campo `- Base branch: <branch>` definido no discovery.
  2. `known_issues.md` DEVE ter campo `- Reviewers: <count>` com perfis (ex: "2 backend, performance") definido no discovery.
  3. A issue remota DEVE ser criada durante discovery (CTO ou Tech Lead define momento ideal) e `Remote:` preenchido.
  4. PM promotion DEVE ser puramente executório: checkout da base branch, criar feature branch, atualizar status para `in-progress`.
  5. PM NÃO DEVE perguntar base branch, revisores ou criar remote durante promoção.
  6. Scripts de promote DEVEM ler os campos do `known_issues.md` em vez de interagir com o usuário.
  7. O formato do issue no `known_issues.md` DEVE ser atualizado para suportar os novos campos.
- Stakeholders: Dev, PM, Senior Reviewers, PO
- Rationale: Todo ciclo de issue atual tem pelo menos 2 interrupções do PM para confirmar coisas que poderiam ser decididas no discovery. Isso quebra fluxo do desenvolvedor e adiciona latência desnecessária.
- Dependencies: Issues #1, #2 (já resolvidas), #7 (resolvida) — padrão de issue tracking já consolidado.
- Proposed issue type: feat

### Proposal 2026-06-01-1: Criar issue remota obrigatória durante promoção
- Priority: high
- Business value: Garante rastreabilidade entre issues locais e remotas; evita que issues sejam desenvolvidas sem contraparte remota para visibilidade do time.
- Target sprint: next
- Description: Tornar obrigatória a criação da issue remota durante o fluxo de promoção. O `promote.sh` mantém duas etapas (promote → create_issue), mas o pipeline DEVE validar que o campo `Remote:` não está vazio antes de permitir o desenvolvimento (`in-progress`). O `ocf:promote` DEVE perguntar ao usuário se deseja criar a issue remota agora ou depois, mas bloquear o avanço para `in-progress` sem ela.
- Business rules:
  1. O promote.sh mantém status `open` e Remote `-` (como hoje).
  2. O create_issue.sh DEVE ser chamado obrigatoriamente antes de qualquer trabalho de desenvolvimento.
  3. O pipeline DEVE validar que `Remote:` contém um ID válido (não `-`) antes de permitir `in-progress`.
  4. O `ocf:promote` DEVE verificar se Remote está preenchido e, se não estiver, perguntar: "Criar issue remota agora? (s/N)".
  5. Se o usuário recusar, a issue fica como `open` e o desenvolvedor não pode iniciar até que Remote seja preenchido.
  6. Scripts de validação (pre-commit, maintain) DEVM verificar issues `open` sem Remote e alertar.
- Stakeholders: Desenvolvedores, PM, PO
- Rationale: Sem essa validação, issues podem ser trabalhadas sem contraparte remota, perdendo rastreabilidade no GitHub/GitLab.
- Dependencies: Nenhuma — refine sobre promote.sh e create_issue.sh existentes.
- Proposed issue type: feat

### Proposal 2026-06-01-2: Revisar e enriquecer o PR template
- Priority: medium
- Business value: PRs mais completos e padronizados facilitam revisão, reduzem ciclos de ida-e-volta e documentam decisões técnicas.
- Target sprint: next
- Description: Expandir o `standards/pr-template.md` (e suas traduções em `standards/pt/`, `standards/es/`, etc.) para um template único mais completo, com seções que podem ser omitidas quando não aplicáveis.
- Business rules:
  1. O template DEVE ser único (não múltiplos templates por tipo).
  2. Seções opcionais DEVEM ser claramente marcadas como `(opcional)`.
  3. O template DEVE incluir: Resumo executivo, Contexto/Motivação, O que mudou, Checklist, Screenshots/Evidências (opcional), Breaking Changes (opcional), Rollback Plan (opcional), Referência à Issue, Riscos, Como Testar.
  4. A seção "Referência à Issue" DEVE ser obrigatória — link para a issue na known_issues.md via `Relates to: #<id>`.
  5. O publish-requester DEVE preencher automaticamente o template com dados da issue.
  6. Todas as traduções (pt, es, fr, de, ja, zh) DEVEM ser atualizadas em paralelo.
- Stakeholders: Devs, Senior Reviewers, QA, Committer
- Rationale: Template atual é muito enxuto — faltam contexto de decisão, evidências e plano de rollback, que são cruciais para revisões seguras.
- Dependencies: Nenhuma
- Proposed issue type: feat

### Proposal 2026-06-01-3: Workflow de revisão externa de branches/MRs
- Priority: high
- Business value: Permite que qualquer dev solicite revisão técnica de código de outros desenvolvedores (mesmo fora do pipeline opencode) de forma padronizada, com geração de relatório e post opcional de comentários críticos no MR.
- Target sprint: next
- Description: Criar comando `ocf:review-external` + agente `agents/development/review-external.md`. O fluxo: (1) usuário informa URL de MR/PR ou branch remota; (2) fetch + checkout; (3) revisão técnica com senior-reviewers; (4) geração de relatório .md local; (5) pergunta se deseja postar comentários críticos/high no MR via gh/glab; (6) postagem opcional.
- Business rules:
  1. O comando DEVE aceitar URL de MR (GitHub/GitLab) ou branch remota.
  2. DEVE fazer fetch da branch e checkout local para análise.
  3. A revisão DEVE usar os senior-reviewers agents por domínio (backend, frontend, security, data, devops, etc).
  4. Comentários DEVEM ser classificados como: critical, high, medium, low, nit.
  5. O relatório local DEVE ser salvo em `.opencode/reviews/review-<branch>-<timestamp>.md`.
  6. Apenas comentários critical e high DEVEM ser elegíveis para postagem automática.
  7. O revisor DEVE ser perguntado antes de postar: "Postar os <n> comentários críticos/high no MR? (s/N)".
  8. A revisão DEVE focar exclusivamente em aspectos técnicos: corretude, segurança, performance, estrutura, boas práticas.
  9. O revisor NÃO DEVE assumir contexto de negócio que não está explícito no MR ou na issue referenciada.
  10. Se uma regra de negócio parecer violada mas não está documentada, DEVE ser classificada como `incomplete-spec` (não bug) e registrada como nova issue na known_issues.md.
- Stakeholders: Desenvolvedores, Senior Reviewers, QA
- Rationale: Atualmente não há workflow para revisar código de fora do pipeline opencode. Isso unifica o processo e garante qualidade consistente.
- Dependencies: Agentes senior-reviewers já existem; precisamos do agente review-external e comando no opencode.json.
- Proposed issue type: feat

### Proposal 2026-08-02-2: Disparo de pipeline de desenvolvimento por comentario remoto `@aibot:develop`
- Priority: critical
- Business value: Permite que qualquer pessoa (ou o proprio aibot) dispare o desenvolvimento completo de uma issue apenas comentando `@aibot:develop` na issue remota (GitHub/GitLab) — sem acesso ao terminal. Habilita resolucao paralela de pequenas issues em pipelines independentes aproveitando o servidor local.
- Target sprint: next
- Description: Criar um watcher/servico que observa comentarios novos em issues remotas (GitHub/GitLab) e, ao detectar `@aibot:develop`, executa o equivalente a `ocf:develop <id>` — pipeline completo terminando em senior review, QA, criacao de MR e um comentario do aibot avisando que o desenvolvimento terminou e o MR esta pronto para revisao/merge. Se durante o desenvolvimento faltar regra de negocio clara ou existir conflito que impeça a execucao, o aibot DEVE comentar que nao foi possivel desenvolver e que a tarefa deve ser revisada. O processo de develop nao pode estar rodando concorrentemente para a mesma issue.
- Business rules:
  1. Um comentario contendo exatamente `@aibot:develop` em uma issue remota (GitHub ou GitLab) DEVE disparar o desenvolvimento da issue em que o comentario foi postado.
  2. O gatilho DEVE funcionar tanto para issues GitHub quanto GitLab, identificando o provider pelo remote do repositorio.
  3. O desenvolvimento disparado DEVE seguir o pipeline completo (promote → develop → senior review → QA → correcoes → committer gate → publish/MR), equivalente a `/ocf:develop <id>`.
  4. Nao DEVE haver execucao concorrente: se um develop para a mesma issue ja estiver em andamento (`in-progress`), o novo comando DEVE ser ignorado e o aibot DEVE comentar que ja existe um desenvolvimento em andamento para a issue.
  5. Ao terminar com sucesso, o aibot DEVE comentar na issue remota avisando que o desenvolvimento terminou, informando o numero/URL da MR criada e que esta pronta para revisao e merge.
  6. Se durante o desenvolvimento houver regra de negocio ausente/ambigua ou conflito que impeça a execucao, o aibot DEVE comentar que nao foi possivel desenvolver e que a tarefa deve ser revisada — sem criar MR.
  7. Mensagens de sucesso e de erro DEVEM seguir um standard uniforme (`standards/`), com links e informacoes consistentes.
  8. O watcher DEVE rodar como servico no mesmo servidor onde o opencode roda (aproveitando o servidor do repositorio) e suportar multiplos repositorios/projetos em paralelo.
  9. Cada repo disparado DEVE ter um workspace/branch isolado (`issue-<id>-<slug>`) para permitir pipelines paralelos.
- Stakeholders: PO, Dev, PM, Senior Reviewers, QA, Committer, Publish Requester
- Rationale: Automatiza o ciclo completo a partir de um simples comentario remoto; habilita aibot a resolver pequenas issues em paralelo.
- Dependencies: Base ja existente (pipeline ocf:develop, publish-requester, close-requester, scripts create/promote).
- Proposed issue type: feat

### Proposal 2026-08-06-1: Sincronização bidirecional de issues com Jira Cloud
- Priority: high
- Business value: Unifica o tracking de trabalho — cada issue do pipeline tem contraparte real no backlog do Jira, com status, comentários e refinamento sincronizados automaticamente entre `known_issues.md` e o Jira. Elimina dupla manutenção e garante que stakeholders no Jira vejam o progresso real (aprovado, refinado, em desenvolvimento, em revisão, publicado).
- Target sprint: next
- Description: Integrar o pipeline com Jira Cloud via MCP/API. Ao criar ou registrar uma issue (`ocf:discovery` / `ocf:develop`), criar o card no backlog do Jira se ele não existir; se já existir, vincular o card à issue padrão. Identificação pela chave do projeto (ex: `DEV-123`) usando o prefixo do projeto Jira. Sincronizar automaticamente cada transição de status do pipeline (backlog→ready→in-progress→in-review→in-qa→in-publish→resolved) para o workflow do Jira, e alinhar comentários/refinamento entre repositório e Jira.
- Business rules:
  1. Jira Cloud DEVE ser o provider alvo (REST v3, MCP oficial do Atlassian).
  2. A identificação da issue Jira DEVE usar a chave do projeto (ex: `DEV-123`) — prefixo + número sequencial.
  3. Ao registrar uma issue nova, o pipeline DEVE criar o card no backlog do Jira se a chave não existir.
  4. Se a chave Jira já existir, o pipeline DEVE vincular o card à issue padrão em `known_issues.md` (novo campo `Jira:` ou reuso de `Remote:`).
  5. Cada transição de status em `known_issues.md` DEVE refletir automaticamente no workflow do Jira (mapa completo).
  6. Comentários, refinamento e demais informações DEVEM estar alinhados entre repositório e Jira (sincronização de comentários).
  7. O mapa de status pipeline→Jira DEVE ser configurável por projeto (nomes de status do workflow do Jira variam).
- Stakeholders: PO, PM, Dev, QA, Committer, equipe que consome o Jira
- Rationale: O usuário quer que a issue do repositório e do Jira estejam sincronizadas em todas as etapas — aprovado, refinado, em desenvolvimento, em revisão. Sem integração, o status diverge e o time do Jira não tem visibilidade do pipeline.
- Dependencies: Config existente de `mcpServers` em opencode.json (hoje: GitHub, Notion); scripts `create_issue.sh`, `promote.sh`, `close_issue.sh`; padrão de campo `Remote:`.
- Proposed issue type: feat

### Proposal 2026-08-06-2: Agente de setor OWASP e Cybersecurity (consultor + revisor + gate)
- Priority: high
- Business value: Habilita consultoria, revisão e políticas de segurança em qualquer momento do ciclo — o agente atua como senior reviewer de segurança em MRs, é convocável on-demand para auditorias/tarefas específicas, e pode bloquear MRs quando vulnerabilidades critical/high são encontradas. Substitui o revisor de segurança genérico atual por um especialista OWASP completo.
- Target sprint: next
- Description: Criar agente `development/security-owasp` (setor development) que consolida o perfil de segurança do pipeline: consultor de políticas e arquitetura, revisor de código em MRs (senior reviewer perfil `security`), executor de auditorias on-demand e gate de bloqueio para vulnerabilidades critical/high. Entregue como agente + skills OWASP dedicadas (`owasp-top10`, `owasp-asvs`, `owasp-wstg`, `owasp-samm`, `threat-modeling`, `secure-code-review`), dominando Top 10 + ASVS + WSTG + SAMM. Segue o locale do projeto via locale-loader.
- Business rules:
  1. O agente DEVE ser criado como `agents/development/security-owasp.md` (formato opencode com frontmatter válido) no setor development.
  2. O agente DEVE poder atuar em 3 modos: (a) consultor — políticas de segurança, arquitetura e conformidade; (b) revisor — senior reviewer de segurança em MRs; (c) executor on-demand — auditorias e tarefas específicas a qualquer momento.
  3. O agente DEVE poder ser registrado como revisor de perfil `security` no campo `- Reviewers:` das issues.
  4. O agente DEVE bloquear/recusar a aprovação de MR quando encontrar vulnerabilidades de severidade critical ou high, reportando com evidências e recomendação de correção.
  5. O agente DEVE dominar OWASP Top 10 (2021), ASVS 4.0, WSTG e SAMM como frameworks de referência.
  6. As skills DEVM ser criadas sob `skills/development/security/` com SKILL.md por framework (top10, asvs, wstg, samm, threat-modeling, secure-code-review).
  7. As skills DEVM registrar os CWE mapeados por categoria OWASP Top 10 e os níveis de verificação ASVS (L1/L2/L3).
  8. O agente DEVE seguir o locale do projeto via locale-loader (relatórios e recomendações no idioma de `.opencode/locale`), mantendo termos técnicos em inglês.
  9. O agente DEVE publicar relatórios de auditoria em arquivo local (ex: `.opencode/reviews/security-<target>-<timestamp>.md`) antes de postar/comentar qualquer coisa.
  10. O agente NÃO DEVE modificar código — apenas reportar; correções são feitas pelo developer no fluxo normal.
  11. O agente DEVE integrar com o gate do committer: vulnerabilidade critical/high não resolvida impede `in-publish`.
  12. O `senior-reviewers/security.md` existente DEVE ser avaliado para evolução em vez de duplicação (perfil de revisor pode delegar ao agente OWASP).
- Stakeholders: Dev, Senior Reviewers, QA, Committer, PO, time de segurança
- Rationale: O pipeline hoje só tem um revisor de segurança genérico (checklist curto). O usuário quer um especialista que aja como consultor, revisor e gate a qualquer momento, com base OWASP completa e skills carregáveis — elevando a segurança de entregas a um padrão verificável.
- Dependencies: Estrutura de skills existente (`skills/development/go|python`), padrão de senior reviewers (`agents/development/senior-reviewers/`), committer gate (`agents/development/committer.md`), locale-loader.
- Proposed issue type: feat

### Proposal 2026-08-05-1: Skills externas via clone + `skills.paths` (vendor), sem copia
- Priority: high
- Business value: Skills externas (taste-skill, motion-design, color-expert, etc.) passam a ser carregadas in-place a partir de clones git em `~/.config/opencode/vendor/`, atualizáveis com `git pull` sem reimportar. Elimina divergência entre o upstream e o conteúdo copiado, reduz manutenção e torna o comportamento padrão para futuras importações.
- Target sprint: next
- Description: Mudar a estratégia de importação de skills externas de "copiar para `skills/<sector>/`" para "clonar em `~/.config/opencode/vendor/` e registrar via `skills.paths`". Migrar as design skills existentes do taste-skill (issue #42) para o novo esquema, importar a nova lista de repos de design (motion-design, color-expert, icon-generator, brand-to-design, responsive-craft, ux-flow-designer, frontend-designer), e registrar a regra como padrão para que agentes em outras sessões sigam o mesmo comportamento (AGENTS.md, decisions.md, skill-importer, comando `ocf:import-skill`, script `skill-vendor.sh`).
- Business rules:
  1. Skills externas DEVEM ser mantidas como clones git em `~/.config/opencode/vendor/` (um clone por repo upstream), NUNCA copiadas para `skills/`.
  2. `opencode.json` DEVE registrar `skills.paths` apontando para `vendor/` para o loader varrer `**/SKILL.md` recursivamente.
  3. `vendor/**` DEVE estar no `.gitignore` (não versionar conteúdo de terceiros).
  4. O script `skill-vendor.sh` DEVE gerenciar vendor: `add <url> [--sparse <paths>]`, `update <name>`, `list`, `remove <name>`.
  5. O `skill-importer` skill DEVE usar a estratégia de clone e DEVE ser registrado em `permission.skill`.
  6. Repos com múltiplas skills DEVEM usar sparse checkout para carregar apenas as skills desejadas.
  7. A identidade da skill é o `name` do frontmatter do SKILL.md (não o nome da pasta) — IDs existentes (design-taste-frontend, redesign-existing-projects, minimalist-ui) DEVEM ser preservados.
  8. As 3 design skills copiadas (skills/design/*) DEVEM ser removidas e substituídas pelo clone do taste-skill.
  9. A regra DEVE estar visível em sessões futuras via AGENTS.md + ADR em decisions.md + comando `ocf:import-skill`.
- Stakeholders: Dev, designer, PO, QA
- Rationale: A importação por cópia (npx skills add / import_claude_skill.sh) cria divergência com o upstream e exige reimportação manual para atualizar. O clone in-place resolve isso e é o modo recomendado para skills de terceiros.
- Dependencies: Issue #42 (merged, main já contém as design skills).
- Proposed issue type: feat

### Proposal 2026-08-10-1: Always create test standards pre-development
- Priority: high
- Business value: Eliminates rework in dev sessions — every issue carries test standards/definitions before development, so the Developer and QA know exactly what to verify up front, and senior review/QA loops shrink.
- Target sprint: next
- Description: Mandate that every issue includes explicit test standards/definitions BEFORE development begins. Define a `Tests:` field convention in standards/issues.md (additional field, already hinted there), document in workflow.md that test standards are defined during discovery (QA pre-development phase), and update the discovery pipeline (development/product-owner, development/quality-analyst, development/discovery agents) so every `feat`/`bug` issue carries test scenarios. Prevents rework: developers write tests against documented scenarios instead of inventing them.
- Business rules:
  1. `Tests:` field MUST be defined for every issue before development (discovery phase), not added ad-hoc during development.
  2. `Tests:` conventions MUST be documented in standards/issues.md and workflow.md.
  3. Applies to all new issues (feat and bug); existing in-flight issues are not retroactively rewritten.
  4. QA pre-development phase validates testability of the `Tests:` field.
- Stakeholders: Developer, QA, Senior Reviewers, PM, PO
- Rationale: Rework is the biggest waste in the pipeline; test standards up front cut review loops and QA rework.
- Dependencies: Issue #32 (test automation gap for scripts) is related but separate; this issue is about process standards, not script test coverage.
- Proposed issue type: feat

### Proposal 2026-08-10-2: Time-tracking fields in issue lifecycle
- Priority: medium
- Business value: Enables measuring per-stage cycle time (time in backlog, time to ready, dev time, total time to resolution). Drives process improvement with real data.
- Target sprint: next
- Description: Add timestamp fields to the issue entry format in standards/issues.md (opened, ready, in-progress/started, finished/resolved) and carry them into the resolved archive (standards/resolved-issue.md). Scripts stamp timestamps: create_issue.sh and/or promote.sh stamp when opened; promote.sh stamps when moved to ready (backlog→ready) and to in-progress (ready→in-progress); close_issue.sh stamps finished date and computes stage durations for the archive. Only for NEW issues; tolerate missing timestamps in existing entries/archive.
- Business rules:
  1. Timestamps recorded per-issue as fields in known_issues.md entries (no separate tracking file).
  2. Each timestamp field: `- Opened: <date>`, `- Ready: <date>`, `- Started: <date>`, `- Resolved: <date>` (dates, YYYY-MM-DD).
  3. Scripts stamp timestamps on status transitions: promote.sh (backlog→ready sets Ready; ready→in-progress sets Started), create_issue.sh (sets Opened when remote created, if not already set), close_issue.sh (sets Resolved and computes durations).
  4. Applies ONLY to new issues created after implementation; no retroactive reconstruction.
  5. Missing timestamps tolerated in archive (fields optional, "-" allowed).
  6. Duration = difference between relevant timestamps, computed at close time and stored in the archive entry.
- Stakeholders: PM, PO, Developer, QA
- Rationale: The pipeline currently has no timing data; stage durations are unknowable. Cheap to add while touching standards.
- Dependencies: Must stay consistent with the real lifecycle scripts actually drive (promote.sh sets in-progress, close_issue.sh archives). Issue #25 (open unreachable) means the `open` status should NOT be part of the timestamp design. Issue #24 (trailer sync claims) means timestamp stamping must be done by scripts directly, NOT via pre_commit trailer parsing.

### Proposal 2026-08-11-1: Test runner único com cache de resultados (fingerprint) para agentes de development
- Priority: high
- Business value: Elimina execuções repetidas da mesma suite de testes com saída idêntica ao longo do pipeline (developer → senior review → QA → committer), reduzindo tempo de ciclo, tokens e erros de ambiente. Cada agente continua apto a rodar testes para o próprio uso quando não há cache — o cache é otimização, nunca bloqueio.
- Target sprint: next
- Description: Criar `scripts/test-runner.sh` (entrypoint único de testes com bootstrap de ambiente, detecção de runner, fingerprint de mudanças e cache em `.opencode/test-cache/`) + skill `test-runner` que qualquer agente de development carrega quando precisa validar testes. Atualizar os prompts de developer, devs/golang, devs/python, senior-reviewers (README), quality-analyst, committer, delivery e delegar `pre_commit.sh` ao runner para que todos consumam cache quando fresco e rodem só com mudança mínima.
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
- Stakeholders: Developer, QA, Senior Reviewers, Committer, Publish Requester
- Rationale: O mesmo código é testado 5–7x por ciclo com saída idêntica; erros de ambiente se repetem porque cada agente invoca comando próprio. Entrypoint único + fingerprint + cache elimina a repetição e padroniza diagnóstico.
- Dependencies: Base de scripts existente (scripts/tests/, make test-scripts); skills em `skills/<sector>/`.
- Proposed issue type: feat

### Proposal 2026-08-13-1: Hub de currículo + geração de currículo direcionado a vaga (otimização para contratação acelerada)
- Priority: high
- Business value: Permite ao candidato ter um hub central de dados (JSON mestre + README) a partir do currículo PDF + export oficial do LinkedIn + arquivos complementares, e gerar currículos PDF sob medida por vaga (multi-portal) em segundos — acelerando candidaturas e maximizando match com ATS/keywords.
- Target sprint: next
- Description: Criar fluxo multi-agente de otimização de currículos:
  1. **Hub (ocf:cv-hub)**: recebe currículo em PDF (obrigatório) + export oficial do LinkedIn (`https://www.linkedin.com/mypreferences/d/download-my-data`, opção "Baixe um arquivo de dados maior...") + arquivos complementares opcionais (certificados, portfólio, projetos). Agentes extraem e consolidam dados em um hub por candidato em diretório dedicado (`~/carreira/<nome-candidato>/`): `hub.json` (fonte de verdade para análise de IA) + `README.md` (resumo humano).
  2. **Tailor (ocf:cv-tailor)**: recebe o diretório do candidato + link/texto de vaga (LinkedIn via export/colado, ou qualquer portal), analisa a vaga, extrai requisitos/keywords, e gera versão do currículo direcionada à vaga via HTML → PDF (engine: Chrome headless `--print-to-pdf`; fallback LibreOffice). Idioma do currículo segue o idioma da vaga.
- Business rules:
  1. O hub DEVE ser construído em diretório dedicado por candidato (`~/carreira/<nome-candidato>/`), padrão `hub.json` + `README.md` + `resumes/` (PDFs gerados) + `entradas/` (originais: PDF currículo, export LinkedIn, complementos).
  2. `hub.json` DEVE ser o schema canônico estruturado para análise de IA (seções: dados-pessoais, resumo, experiencia, educacao, skills, certificacoes, projetos, idiomas, links) — validável por script de schema.
  3. `README.md` DEVE ser gerado a partir do `hub.json` (resumo executivo humano), nunca editado manualmente em divergência com o JSON.
  4. Entrada mínima obrigatória: currículo em PDF. Export do LinkedIn e complementos são opcionais (hub flexível).
  5. O fluxo do LinkedIn DEVE usar EXCLUSIVAMENTE exportação oficial (documentada no comando: `https://www.linkedin.com/mypreferences/d/download-my-data`, opção "Baixe um arquivo de dados maior...") — NUNCA scraping anônimo/logado de linkedin.com (bloqueio anti-bot).
  6. A análise de vaga DEVE aceitar multi-portal: texto/URL colado pelo usuário de qualquer portal (LinkedIn, Indeed, Gupy, site da empresa) + export oficial LinkedIn quando aplicável.
  7. `ocf:cv-tailor` DEVE extrair da vaga: requisitos obrigatórios, requisitos desejáveis, keywords/tecnologias, senioridade, idiomas, e mapping vs `hub.json` (gap analysis: requisito atendido/parcial/não atendido).
  8. O currículo direcionado DEVE ser gerado em PDF (HTML → PDF via Chrome headless `--print-to-pdf`, com fallback LibreOffice), salvando também o HTML fonte em `resumes/`.
  9. O idioma do currículo gerado DEVE seguir o idioma da vaga (vaga em inglês → currículo em inglês); hub mantém dados brutos bilingues quando disponíveis.
  10. O currículo direcionado DEVE adaptar conteúdo (summary, ordem de skills, projetos mais relevantes) SEM fabricar/mentir informações — apenas reordenar, destacar e reformular o que já existe no hub.
  11. TODA informação gerada que não exista no hub DEVE ser marcada como placeholder/inferência (`[INFERIDO]`) para revisão humana — nunca silenciosa.
  12. Nenhum dado pessoal sensível (telefone, e-mail, endereço) DEVE vazar para arquivos além do escopo do candidato; o currículo direcionado DEVE incluir contato apenas se presente no hub.
  13. Os comandos DEVEM ser registrados em `opencode.json` como `ocf:cv-hub` e `ocf:cv-tailor`, apoiados por agentes/skills dedicados sob `agents/career/` e `skills/career/`.
- Stakeholders: Candidatos (uso pessoal do william_pereira), Recrutadores (lado consumidor do PDF), PO
- Rationale: Processo manual de adaptação de currículo por vaga é lento e inconsistente; um hub estruturado permite geração rápida, rastreável e alinhada a ATS/keywords.
- Dependencies: Chrome headless já instalado (151); LibreOffice (26.2) como fallback; PDF.js/`pdftotext` para extração de PDF (verificar disponibilidade); schema JSON próprio.
- Proposed issue type: feat
### Proposal 2026-08-13-2: Agente de otimização do perfil — análise, plano de ações, mercado salarial e vagas-alvo (cv-optimize)
- Priority: high
- Business value: Após o hub ser construído (ocf:cv-hub), o candidato precisa saber COMO melhorar o perfil antes de gerar currículos direcionados. O cv-optimize analisa qualificações, pontua o perfil, sugere vagas-alvo, avalia pretensão salarial CLT vs PJ (faixas de mercado marcadas [INFERIDO]), detecta lacunas de contexto no hub e gera um plano de ações priorizado — aprimorando muito o perfil e orientando as candidaturas.
- Target sprint: next
- Description: Criar comando `ocf:cv-optimize <dir-candidato>` + agente `career/cv-optimizer` + skill `cv-optimizer`. Fluxo: (1) se o hub não existir, invoca `ocf:cv-hub` primeiro; (2) lê `hub.json` e valida; (3) analisa qualificações gerais (senioridade, completude por seção, pontos fortes/fraques); (4) calcula score do perfil (0-100 por seção + global, com justificativa); (5) sugere perfis de vagas-alvo (cargos, segmentos, stacks) que o perfil melhor encaixa — baseado em análise offline, sem busca real; (6) avalia pretensão salarial de mercado CLT vs PJ por faixas de senioridade/stack/região, TODAS marcadas [INFERIDO] para revisão humana; (7) detecta informações ausentes no hub que dariam mais contexto (métricas, projetos sem link, certificações sem validade, idiomas sem nível formal); (8) gera plano de ações priorizado com impacto estimado; (9) gera relatório único `.md` em `~/carreira/<nome>/profile-analysis.md` (opcionalmente acompanhado de tasks.json estruturado para rastreabilidade futura).
- Business rules:
  1. O comando `ocf:cv-optimize <dir-candidato>` DEVE rodar após o `ocf:cv-hub`; se `hub.json` não existir ou for inválido, DEVE invocar o fluxo do `cv-hub` primeiro (perguntando os caminhos das fontes) e então continuar.
  2. O agente `career/cv-optimizer` DEVE ler e validar `hub.json` (`python3 $SCRIPTS_DIR/cv/validate.py`) antes de analisar; hub inválido → corrigir ou pedir reconstrução via cv-hub.
  3. A análise DEVE cobrir: qualificações gerais (senioridade, principais skills, pontos fortes e pontos fracos), completude por seção do hub, e cobertura vs vagas-alvo.
  4. O score do perfil DEVE ser numérico (0-100) com breakdown por seção (dados-pessoais, resumo, experiencia, educacao, skills, certificacoes, projetos, idiomas, links) e justificativa textual de cada nota.
  5. A sugestão de vagas-alvo DEVE ser baseada em análise OFFLINE do hub (perfis de cargo/segmento/stack que o perfil encaixa) — SEM busca real de vagas na web (LinkedIn bloqueia; nenhuma vaga concreta é listada como fato).
  6. A pretensão salarial de mercado DEVE ser entregue como faixas por senioridade/stack/região para CLT e PJ, TODAS marcadas `[INFERIDO]` e sem fabricar fontes — o candidato revisa e ajusta antes de usar.
  7. A detecção de lacunas DEVE listar informações ausentes no hub que aumentariam contexto (ex.: conquistas sem métrica, projetos sem link, certificações sem validade, idiomas sem nível formal, gaps de datas na experiência).
  8. O plano de ações DEVE ser priorizado (impacto estimado alto/médio/baixo × esforço) e incluir ações para: preencher lacunas do hub, fortalecer seções fracas, fechar gaps das vagas-alvo (cursos/certificações).
  9. A entrega DEVE ser um relatório único `.md` em `~/carreira/<candidato>/profile-analysis.md`; um `tasks.json` estruturado pode acompanhar para futura integração com rastreamento de issues.
  10. NENHUM dado inventado: toda inferência/estimativa (salário, vagas, impacto) DEVE ser marcada `[INFERIDO]`; nada de dados pessoais sensíveis.
  11. O agente NÃO DEVE modificar o `hub.json` — apenas reportar; a edição é feita pelo usuário (ou num ciclo futuro de enriquecimento do hub).
  12. Comando/agente/skill DEVEM seguir o padrão do setor career (agents/career/, skills/career/, commands/ocf:cv-*.md, permission edit apenas ~/carreira/**).
- Stakeholders: Candidato (william_pereira), Recrutadores (lado consumidor), PO
- Rationale: O fluxo atual tem "criar hub" e "gerar currículo para vaga", mas falta a etapa estratégica de APRIMORAR o perfil — saber o que melhorar, qual vaga mirar e quanto pedir. É o elo que transforma dados em ação.
- Dependencies: Issue #60 (merged — fluxo cv-hub/cv-tailor, schema hub.json, validate.py, pdf.sh); Chrome/LibreOffice não necessários nesta etapa (sem PDF).
- Proposed issue type: feat

### Proposal 2026-08-14-1: Remover etiqueta `[INFERIDO]` do output final do currículo (gate + decisão humana)
- Priority: critical
- Business value: O candidato volta a conseguir partilhar o PDF do currículo sem etiquetas de incerteza que geram insegurança no recrutador. Alinha o output final com o princípio de qualidade percebida: o currículo partilhável transparece confiança; inferências ficam restritas aos artefactos internos de revisão humana.
- Target sprint: next
- Description: O fluxo cv-tailor atual instrui os agentes a marcar `[INFERIDO]` no HTML/PDF final — skill `cv-tailor` (regra 2 das Regras rígidas), agente `career/cv-tailor` (regra 2), comando `ocf:cv-tailor`, template do comando no `opencode.json` e `workflow.md` (secção career). Isso vaza para o artefacto partilhável. Correção: (1) `[INFERIDO]` passa a ser permitido APENAS em artefactos internos (hub.json, profile-analysis.md, gap-analysis.md, lista de inferências); (2) NO HTML/PDF final nenhum `[INFERIDO]` pode aparecer — o que for inferido é omitido/reformulado ou decidido pelo candidato ANTES da geração; (3) gate de verificação (script) que detecta e bloqueia `[INFERIDO]` no HTML/PDF; (4) fluxo de validação humana com a lista de inferências antes de gerar o PDF.
- Business rules:
  1. `[INFERIDO]` DEVE ser permitido APENAS em artefactos internos de revisão humana: hub.json, profile-analysis.md, analise-perfil.pdf, gap-analysis.md e listas de inferências (ex.: `resumes/<slug>/inferences.md`).
  2. NO output partilhável final — `resumes/<slug>/index.html` e `resumes/<slug>/curriculo.pdf` — NENHUM `[INFERIDO]` pode aparecer (nem variações case-insensitive: [inferido], [Inferido], "inferido").
  3. Conteúdo inferido DEVE ser omitido, reformulado ou aprovado pelo candidato ANTES da geração — nunca embutido no output final.
  4. DEVE existir um gate de verificação (script `scripts/cv/check-inference.sh` ou hook no pdf.sh) que escaneie o HTML (e o texto do PDF via pdftotext quando disponível) e BLOQUEIE a geração com exit != 0 e mensagem clara listando as ocorrências.
  5. Fluxo de validação humana: o agente DEVE listar todas as inferências e pedir decisão do candidato sobre cada uma (reformular/omitir, ou promover a facto apenas com confirmação de dado real) ANTES de gerar o HTML/PDF final.
  6. As instruções que pedem "marcar [INFERIDO] no HTML/PDF" DEVEM ser removidas de: skill cv-tailor, agente career/cv-tailor, comando ocf:cv-tailor, template do comando em opencode.json e workflow.md.
  7. cv-hub (hub.json) e cv-optimizer (profile-analysis.md/pdf, gap-analysis) MANTÊM `[INFERIDO]` nos artefactos internos — sem alteração de comportamento.
- Stakeholders: Candidato (william_pereira), Recrutadores (lado consumidor do PDF), PO
- Rationale: A etiqueta no output final quebra a partilha e a qualidade percebida; é uma decisão de spec errada herdada da issue #60 (BR 11 interpretada como "marcar no PDF"). Correção pequena e de alto valor — antes do padrão de design.
- Dependencies: Issues #60/#61 (fluxo career, resolvidas). Arquivos partilhados com a proposta 2026-08-14-2 (cv-tailor/cv-pdf) — executar em sequência (#62 → #63) para evitar conflitos de merge.
- Proposed issue type: bug

### Proposal 2026-08-14-2: Padrão de design de currículo 100% ATS-friendly, imprimível e sóbrio
- Priority: high
- Business value: Todos os currículos gerados passam a seguir um padrão consistente, profissional e parseável por ATS — máxima compatibilidade com recrutamento automatizado, impressão em P&B legível e estética executiva sóbria. Elimina CSS ad-hoc por geração (hoje cada agente escreve o seu).
- Target sprint: next
- Description: Definir e entregar um padrão de design de currículo para o setor career: (1) documento `standards/cv-design.md` com regras concretas e testáveis (ATS, impressão A4/P&B, estilo sóbrio, regra de páginas por senioridade); (2) template HTML/CSS de referência em `skills/career/cv-pdf/templates/resume.html` usado como base pelo cv-tailor; (3) atualização dos prompts (skill cv-tailor, agente career/cv-tailor, skill cv-pdf, comando ocf:cv-tailor, opencode.json) para mandatar o padrão. Convocar o designer e skills de design (design-taste-frontend, minimalist-ui) para a definição visual.
- Business rules:
  1. O padrão DEVE ser documentado em `standards/cv-design.md` com regras concretas e testáveis (não opiniões).
  2. ATS-friendly: headings semânticos com seções padrão (Experiência, Educação, Skills, Certificações, Projetos, Idiomas); texto real selecionável (nunca texto em imagem); sem colunas/multicol que quebrem o parse; sem tabelas complexas; fontes seguras ATS (Helvetica/Arial/sans-serif, sem Google Fonts online); sem emoji/caracteres decorativos; datas em formato texto; contraste >= 4.5:1 (WCAG AA).
  3. Imprimível: A4 com margens de 12–15mm; legível em preto-e-branco (nada de informação dependente de cor); sem fundos/imagens em print; `@media print` limpo.
  4. Estilo sóbrio profissional: tipografia clara com hierarquia discreta (nome > título/seção > corpo); espaçamento generoso; máximo 1 cor de acento opcional e grayscale-safe; sem gradientes, sombras, bordas decorativas, emoji.
  5. Regra de páginas por senioridade: Júnior/Pleno → 1 página; Sênior/Especialista/Lead → até 2 páginas; nunca 3+. Densidade: max ~600–700 palavras/página.
  6. Template HTML/CSS de referência DEVE existir em `skills/career/cv-pdf/templates/resume.html` — o cv-tailor parte dele e adapta conteúdo, NUNCA escreve CSS do zero.
  7. O template DEVE incluir `@page { size: A4; margin: 12-15mm }`, print CSS, e ser locale-aware (pt/en/es conforme hub/resumo_i18n).
  8. Os prompts de cv-tailor (skill+agente+comando) e cv-pdf (skill) DEVEM mandatar o padrão: carregar `standards/cv-design.md` e usar o template.
  9. O agente cv-tailor DEVE verificar conformidade com o padrão (checklist ATS/print/páginas) antes de gerar o PDF.
- Stakeholders: Candidato (william_pereira), Recrutadores/ATS (lado consumidor), Designer, PO
- Rationale: Hoje o design do currículo é ad-hoc (regras mínimas no cv-pdf/cv-tailor, sem template, sem padrão documentado). Um padrão único com template elimina variação e garante ATS/print/estética de forma verificável.
- Dependencies: Executar APÓS a proposta 2026-08-14-1 (arquivos partilhados cv-tailor/cv-pdf; #63 incorpora o estado consolidado do INFERIDO).
- Proposed issue type: feat

### Proposal 2026-08-14-3: Standardize career sector language — English prompts, English hub.json schema, user-locale analysis outputs
- Priority: critical
- Business value: Aligns the career sector with the rest of the config (English prompts), makes hub.json portable and tool-readable across locales, and ensures outputs meet the user in their language. English is the operational language of the pipeline; mixing Portuguese in agents/skills/schema keys creates friction in non-PT contexts and makes the hub harder to consume programmatically.
- Target sprint: next
- Description: Rewrite ALL career sector prompts (agents, skills, commands, schema descriptions, validator messages) in English. Migrate hub.json keys and ENUM values from Portuguese to English (dados_pessoais→personal_info, experiencia→experience, educacao→education, certificacoes→certifications, idiomas→languages, projetos→projects, resumo→summary, resumo_i18n→summary_i18n, data_geracao→generated_date, fontes→sources, nome→name, empresa→company, cargo→title, instituicao→institution, curso→course, emissor→issuer, desde→since, nivel→level, importancia→importance, cidade→city, estado→state, pais→country, disponibilidade→availability, pretensao_salarial→salary_expectation, visto_trabalho→work_visa, etc.; enums: Concluído→completed, Em andamento→in_progress, iniciante→beginner, avancado→advanced, etc.). Add locale rule: analysis files (profile-analysis.md, gap-analysis.md) generated in the user's communication language; tailored resumes in the job offer's language (already correct). Provide migration path for existing hubs (pt keys → en keys). Update validate.py and schema.json accordingly. Update test_cv.sh fixtures.
- Business rules:
  1. ALL career sector agent prompts, skill prompts, command bodies, schema descriptions, and validator error messages MUST be in English.
  2. hub.json keys and ENUM values MUST be in English (snake_case). The schema is the canonical structure for all locales.
  3. Analysis outputs (profile-analysis.md, gap-analysis.md, inferences.md) MUST be generated in the language the user communicates in (detected from session locale or explicit user instruction).
  4. Tailored resumes (curriculo.pdf/index.html) MUST be in the job offer's language (already correct — preserve this rule).
  5. A migration helper or documented migration path MUST exist for existing hub.json files with Portuguese keys (pt→en).
  6. schema.json descriptions and ENUM values MUST be in English.
  7. validate.py error messages MUST be in English.
  8. Command descriptions (frontmatter `description`) are already in English — preserve. Command bodies (instructions) MUST also be in English.
  9. The `resumo` field becomes `summary`; `resumo_i18n` becomes `summary_i18n` with the same structure ({pt, en, es}).
  10. opencode.json command templates for career (lines 118-127) are already in English — preserve and verify consistency with the new schema keys.
  11. test_cv.sh fixtures MUST use English schema keys.
  12. README.md generated from hub MUST follow the hub's language.
  13. [INFERIDO] rules (from issue #62) MUST be preserved — the label stays in Portuguese as a domain constant (it's a protocol token, not a language choice); internal analysis files keep it, final resume PDFs never.
  14.承接 issues #62 and #63 content MUST be consistent with the new English key names when they reference hub.json structure.
- Stakeholders: william_pereira, PO, designer, developer
- Rationale: The career sector is the only sector with Portuguese prompts and schema keys. This creates inconsistency, limits portability, and makes the hub harder to consume programmatically. English prompts match the rest of the config. English schema keys make the hub a proper canonical structure. User-locale outputs respect the end-user experience.
- Dependencies: Issue #62 (INFERIDO gate — share cv-tailor files), Issue #63 (design standard — share cv-pdf/cv-tailor files). Coordinate branch merge order: #62 → #64 → #63 (or #64 first if #62 hasn't started).
- Proposed issue type: feat

### Proposal 2026-08-14-4: Standard structure for career sector analysis reports — standards/cv-analysis.md + report templates
- Priority: high
- Business value: Ensures all analysis outputs (profile-analysis.md, gap-analysis.md, interview prep, ATS score reports) share a consistent structure, making them predictable for the candidate and comparable across runs. Today each skill defines its own format ad-hoc.
- Target sprint: next
- Description: Create `standards/cv-analysis.md` defining the canonical structure for ALL career sector report files: standard heading hierarchy, section order, table formats (gap analysis, score, actions), [INFERIDO] inline rules (internal files only — from #62), locale rules (output language = user communication language — from #64), and report-specific templates. Create HTML templates for analise-perfil.html (A4, same design language as cv-pdf). Apply the standard across cv-optimizer and cv-tailor skills/agents.
- Business rules:
  1. `standards/cv-analysis.md` MUST exist and define the canonical structure for all career sector analysis reports.
  2. All report files (profile-analysis.md, gap-analysis.md, inferences.md) MUST follow the standard: consistent heading hierarchy, section order, table format, and [INFERIDO] inline convention.
  3. The standard MUST mandate report language = user communication language (from #64 locale rule).
  4. [INFERIDO] markers MUST be inline in internal reports (hub.json, profile-analysis.md, gap-analysis.md, inferences.md) and NEVER in final resume PDFs (from #62).
  5. HTML report templates (analise-perfil.html) MUST share the design language defined in standards/cv-design.md (from #63) — A4, sober style, ATS-clean headings.
  6. Gap analysis tables MUST use a uniform format: requirement | match (atendido/parcial/not_met) | evidence in hub.
  7. Score tables MUST use: section | score (0-100) | justification.
  8. Action plan tables MUST use: id | action | impact | effort | priority | target_profile.
  9. No metadata headers ("Gerado em:", "Fonte:", "Ferramenta:", "Nota:") — start directly with content (existing rule, preserved).
  10. The standard MUST be referenced by cv-optimizer and cv-tailor skills/agents/commands.
- Stakeholders: william_pereira, PO, QA
- Rationale: Without a shared standard, each report is structurally different, making it hard to compare runs or build tooling on top. A single standard makes reports predictable, comparable, and professional.
- Dependencies: Issue #64 (English + locale rule), Issue #62 ([INFERIDO] rules), Issue #63 (cv-design.md for HTML template design language). Execute after #64.
- Proposed issue type: feat

### Proposal 2026-08-14-5: Cover letter generation — ocf:cv-cover-letter
- Priority: high
- Business value: A tailored cover letter is an essential complement to the tailored resume in job applications. Generating it from the hub + job analysis (same data already available to cv-tailor) adds significant commercial value with minimal new infrastructure.
- Target sprint: next
- Description: Create command `ocf:cv-cover-letter <candidate-dir> <job>`, agent `career/cv-cover-letter`, and skill `cv-cover-letter`. Given the candidate hub and a job description (same input as cv-tailor — pasted text, file, URL), generate a tailored cover letter in PDF (HTML→PDF via cv-pdf) in the job's language. Reuse the gap analysis from cv-tailor if available, or generate inline. Never fabricate content — only rephrase and highlight what exists in the hub. The cover letter follows the same design standard (standards/cv-design.md from #63) and analysis standard (standards/cv-analysis.md from #65).
- Business rules:
  1. Command `ocf:cv-cover-letter <candidate-dir> <job>` MUST generate a tailored cover letter PDF from the candidate's hub.json + job description.
  2. The agent MUST validate hub.json before generating (same as cv-tailor).
  3. Job input formats: same as cv-tailor (pasted text, file, LinkedIn export, URL with curl -L).
  4. The cover letter MUST be in the job offer's language.
  5. NEVER fabricate experience, skills, or achievements — only rephrase and highlight what exists in the hub.
  6. The cover letter MUST follow the design standard (standards/cv-design.md — A4, sober, ATS-clean).
  7. No [INFERIDO] markers in the final PDF — same rule as cv-tailor (#62).
  8. Output structure: `~/carreira/<candidato>/cartas/<slug-da-vaga>/carta-apresentacao.pdf` + `index.html`.
  9. If hub is missing/invalid, tell the user to run `ocf:cv-hub` first.
  10. The cover letter MUST reference specific achievements from the hub that match the job's key requirements.
  11. The agent MUST be registered in opencode.json (permission, skill allow) with `temperature: 0.2` and edit restricted to `~/carreira/**`.
  12. The skill MUST be registered in `permission.skill` in opencode.json.
- Stakeholders: william_pereira, PO, designer
- Rationale: The career sector only generates the resume. A cover letter is the natural complement and is expected in most application workflows. Same data, same infrastructure — high value, low effort.
- Dependencies: Issue #64 (English schema + locale), Issue #63 (design standard). Execute after #64.
- Proposed issue type: feat

### Proposal 2026-08-14-6: LinkedIn profile optimization suggestions — ocf:cv-linkedin
- Priority: high
- Business value: Completes the LinkedIn workflow — today the sector only extracts FROM LinkedIn. The reverse operation (optimizing the LinkedIn profile TO match a target role) is high commercial value: headline, about section, and skills optimization are the most impactful LinkedIn profile sections for recruiter discoverability.
- Target sprint: next
- Description: Create command `ocf:cv-linkedin <candidate-dir> [<job>]`, agent `career/cv-linkedin`, and skill `cv-linkedin`. Given the candidate hub and optionally a target job, generate LinkedIn profile optimization suggestions: optimized headline (≤220 chars), about section (≤2600 chars), skills section (top 50 ranked by relevance to target role), and featured section recommendations. Output as a markdown report (`linkedin-optimization.md`) in the user's communication language. NEVER involves scraping or modifying LinkedIn directly — the user copies/pastes suggestions manually.
- Business rules:
  1. Command `ocf:cv-linkedin <candidate-dir> [<job>]` MUST generate LinkedIn profile optimization suggestions from the candidate's hub.json.
  2. If a job is provided, suggestions MUST be optimized for that target role; if not, suggestions MUST be optimized for the candidate's inferred seniority and target profiles (from cv-optimizer if available).
  3. Suggestions MUST cover: headline (≤220 chars), about section (≤2600 chars), skills ranking (top 50), and featured section.
  4. NEVER scrape or modify linkedin.com — all output is suggestions the user copies manually.
  5. Output report: `~/carreira/<candidato>/linkedin-optimization.md` in the user's communication language.
  6. NEVER fabricate content — only rephrase and highlight what exists in the hub.
  7. No [INFERIDO] in the output file (it's an actionable suggestion file, not an internal analysis — same as final resume PDFs per #62).
  8. The agent MUST validate hub.json before generating.
  9. Character limits MUST respect LinkedIn's actual limits (headline 220, about 2600, skills 50).
  10. The agent MUST be registered in opencode.json (permission, skill allow) with `temperature: 0.2` and edit restricted to `~/carreira/**`.
  11. The skill MUST be registered in `permission.skill` in opencode.json.
  12. The report MUST follow standards/cv-analysis.md (#65) structure.
- Stakeholders: william_pereira, PO
- Rationale: LinkedIn is the primary channel for recruiter discoverability. Optimizing the profile for target roles is the highest-leverage action a candidate can take — and the hub already contains all the data needed.
- Dependencies: Issue #64 (English schema + locale), Issue #65 (analysis standard). Execute after #64.
- Proposed issue type: feat

### Proposal 2026-08-14-7: Interview preparation kit — ocf:cv-interview-prep
- Priority: high
- Business value: Given the hub + a target job, generates a structured interview preparation kit: likely questions for the role, STAR-format answers based on real hub experience, questions to ask the interviewer, and technical topics to review. This is high commercial value — it bridges the gap between "having a good resume" and "performing well in the interview".
- Target sprint: next
- Description: Create command `ocf:cv-interview-prep <candidate-dir> <job>`, agent `career/cv-interview-prep`, and skill `cv-interview-prep`. Given the candidate hub and a job description, generate: (1) likely interview questions for the role (behavioral + technical), (2) suggested STAR-format answers mapped to real experience from the hub, (3) questions the candidate should ask the interviewer, (4) technical topics to review based on the job's required skills. Output as `interview-preparation.md` in the user's communication language. NEVER fabricate experience — STAR answers must reference real hub entries.
- Business rules:
  1. Command `ocf:cv-interview-prep <candidate-dir> <job>` MUST generate a structured interview preparation kit.
  2. The kit MUST include: likely questions (behavioral + technical), STAR answers mapped to hub experience, questions to ask the interviewer, and technical topics to review.
  3. STAR answers MUST reference real achievements from the hub — NEVER fabricate experience.
  4. Questions MUST be role-appropriate (derived from the job's requirements/seniority).
  5. Output: `~/carreira/<candidato>/interview-preparation.md` in the user's communication language.
  6. No [INFERIDO] in the output (actionable prep file, not internal analysis).
  7. The agent MUST validate hub.json before generating.
  8. If a question cannot be answered from the hub (gap), the kit MUST flag it as a preparation gap to review.
  9. The agent MUST be registered in opencode.json (permission, skill allow) with `temperature: 0.2` and edit restricted to `~/carreira/**`.
  10. The skill MUST be registered in `permission.skill` in opencode.json.
  11. The report MUST follow standards/cv-analysis.md (#65) structure.
- Stakeholders: william_pereira, PO
- Rationale: A great resume gets the interview; interview prep wins the job. The hub already contains the raw material for STAR answers. This is the highest-impact complement to the existing CV generation flow.
- Dependencies: Issue #64 (English schema + locale), Issue #65 (analysis standard). Execute after #64.
- Proposed issue type: feat

### Proposal 2026-08-14-8: ATS compatibility scoring of generated resume — ocf:cv-ats-score
- Priority: medium
- Business value: After generating a tailored resume with cv-tailor, the candidate needs to know how well it matches the ATS keywords and format. An ATS score gives a measurable, comparable metric and actionable recommendations to improve the match before sending.
- Target sprint: next
- Description: Create command `ocf:cv-ats-score <candidate-dir> <job-slug>`, agent `career/cv-ats-score`, skill `cv-ats-score`. Given a generated resume PDF (from cv-tailor) and the original job description, extract text from the PDF (pdftotext), analyze keyword density vs the job's requirements, detect ATS red flags (tables, images, multi-column, missing standard sections), and produce a score (0-100) + actionable recommendations. Output as `ats-score.md` in the job's slug directory.
- Business rules:
  1. Command `ocf:cv-ats-score <candidate-dir> <job-slug>` MUST analyze the generated resume PDF against the original job description.
  2. Analysis MUST extract text from the PDF via `pdftotext` (best-effort — if pdftotext unavailable, report limitation).
  3. Analysis MUST cover: keyword density (job keywords found in resume vs total), ATS red flags (tables, images as text, multi-column layouts, missing standard sections — contact, experience, education, skills), and section detection score.
  4. Score MUST be 0-100 with breakdown: keyword_match (40%), section_completeness (30%), format_compliance (30%).
  5. Output: `~/carreira/<candidato>/resumes/<slug>/ats-score.md` in the user's communication language.
  6. The agent MUST be registered in opencode.json with bash allow for `pdftotext*`, `python3*`, `ls*`, `grep*`.
  7. The skill MUST be registered in `permission.skill` in opencode.json.
  8. The agent MUST NOT modify any files (read-only + report) — edit restricted to `~/carreira/**`.
  9. Recommendations MUST be actionable and specific (e.g., "Add 'Kubernetes' to the skills section — it appears 5x in the job but 0x in your resume").
  10. The report MUST follow standards/cv-analysis.md (#65) structure.
- Stakeholders: william_pereira, PO, QA
- Rationale: The ATS score closes the loop — generate, measure, optimize. Without it, the candidate has no feedback on whether the tailored resume actually matches the job's ATS keywords.
- Dependencies: Issue #64 (English + locale), Issue #62 (INFERIDO gate — the ATS score is on the final resume), Issue #65 (analysis standard). Execute after #64.
- Proposed issue type: feat

### Proposal 2026-08-14-9: Hub update flow — incremental edits to existing hub.json
- Priority: high
- Business value: Today the only way to update the hub is to recreate it from scratch. Candidates frequently need to add a new experience, certification, or skill. An incremental update flow avoids re-processing the entire PDF/LinkedIn export and lets the candidate edit the hub directly.
- Target sprint: next
- Description: Create command `ocf:cv-hub-update <candidate-dir>`, enhancing the existing cv-hub flow to support incremental edits. The user provides new information (pasted text, new PDF, new file) and the agent updates the existing hub.json with the new entries (new experience, skill, certification, project) without recreating the entire hub. Alternatively, accept manual edits to hub.json and validate + regenerate README.md. Command can also be `ocf:cv-hub <dir> --update`.
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
- Stakeholders: william_pereira, PO
- Rationale: Candidates evolve — new jobs, new certifications, new skills. Requiring a full hub rebuild every time is friction. Incremental updates keep the hub current with minimal effort.
- Dependencies: Issue #64 (English schema — the update flow uses the new English keys). Execute after #64.
- Proposed issue type: feat

### Proposal 2026-08-14-10: Keyword density and match percentage in gap analysis
- Priority: medium
- Business value: The gap analysis currently classifies requirements as atendido/parcial/not_met but doesn't quantify the match. A percentage (met/total) and keyword density map gives the candidate a clear, comparable metric of how well the resume matches the job.
- Target sprint: next
- Description: Enhance the cv-tailor gap analysis to include: (1) match percentage (requirements met / total requirements × 100), (2) keyword density map showing each job keyword and its count in the resume, (3) a "coverage heatmap" showing which sections of the resume contain the most job keywords. These metrics complement the ATS score (#69) and give the candidate actionable insight at the gap analysis stage.
- Business rules:
  1. The gap analysis in cv-tailor MUST include a match percentage (met / total × 100).
  2. The gap analysis MUST include a keyword density map: each job keyword → count in the generated resume.
  3. The gap analysis MUST include a coverage summary by section (which resume sections contain the most job keywords).
  4. The match percentage MUST use加权 weighting: mandatory requirements weigh 2x, desirable 1x.
  5. The keyword density MUST be computed on the final resume text (extracted from index.html or the PDF).
  6. The gap analysis report MUST follow standards/cv-analysis.md (#65) table format.
  7. The metrics MUST be computed in the cv-tailor skill/agent, not as a separate command (enhance existing, not new agent).
  8. No new agent or command — this is an enhancement to cv-tailor.
- Stakeholders: william_pereira, PO
- Rationale: A qualitative atendido/parcial/not_met classification is useful but not actionable enough. Quantifying the match gives the candidate a clear metric to optimize and compare across jobs.
- Dependencies: Issue #64 (English schema), Issue #65 (analysis standard). Execute after #64.
- Proposed issue type: feat

### Proposal 2026-08-14-11: Technical corrections — validate.py, schema.json, agents/README, templates, curl security
- Priority: medium
- Business value: Fixes latent bugs and structural gaps in the career sector infrastructure that reduce reliability and maintainability.
- Target sprint: next
- Description: Bundle of technical corrections: (D1) validate.py should use schema.json via jsonschema library with fallback to hand-rolled validator; (D2) improve validation — formats (email, url), nested required fields, summary_i18n, cross-field consistency (start < end in experience, since <= current year); (D3) create agents/career/README.md listing the 3 agents, responsibilities, flow, and commands; (D4) define README.md template for hub output; (D5) restrict or remove curl -L in cv-tailor (replace with "paste text" requirement to eliminate SSRF via file:// redirects).
- Business rules:
  1. validate.py MUST use schema.json as the source of truth when jsonschema is available; fall back to the existing hand-rolled validator when jsonschema is not installed (zero dependency regression).
  2. validate.py MUST validate email format (basic regex), URL format (basic regex), summary_i18n keys (pt/en/es), and cross-field: experiencia.inicio < experiencia.fim (when fim != "atual"/"present").
  3. agents/career/README.md MUST exist and list: cv-extractor, cv-optimizer, cv-tailor (+ any new agents from #66/#67/#68/#69/#70), their responsibilities, the career flow, and the available commands.
  4. A README.md template MUST be defined (in the cv-hub skill or standards/) showing the canonical structure of the human-readable hub README: name + title, contact, summary, experience, education, skills, certifications, projects, languages, links.
  5. curl -L MUST be removed from cv-tailor agent permissions and skill instructions — replace with "ask user to paste job description text" (LinkedIn always blocks; other portals may have file:// redirects or SSRF vectors). The `curl -L*` bash permission in cv-tailor.md and the curl instructions in cv-tailor SKILL.md and command MUST be removed.
  6. No existing functionality MUST break — all changes must pass `make test-scripts`.
  7. test_cv.sh MUST be updated for any validation behavior changes.
- Stakeholders: william_pereira, developer, QA
- Rationale: These are latent bugs and structural gaps found during the career sector audit. Bundling them avoids 5 separate small issues while making meaningful progress on sector health.
- Dependencies: Issue #64 (English schema — validate.py changes must use English keys). Execute after #64.
- Proposed issue type: chore

### Proposal 2026-08-14-12: Standardize project language to English (prompts, skills, docs, scripts) with locale-aware responses
- Priority: high
- Business value: Removes the PT/EN mix across the entire config (~44 files in agents/, commands/, skills/ still carry Portuguese instruction prose). English as the single operational language makes every prompt, skill, command, script and document consistent, portable across locales and projects, and cheaper to maintain (one canonical version per artifact). The existing locale mechanism (locale-loader + `.opencode/locale`) keeps the user experience localized: agents respond in the user's input language or the project locale. Builds on the pattern proven by issue #64 (career sector) and generalizes it to the whole project.
- Target sprint: next
- Description: Rewrite ALL remaining Portuguese-language artifacts to English: agent prompts (`agents/**`), skill prompts (`skills/**/SKILL.md`), command docs and `opencode.json` command templates (`commands/**`, `opencode.json`), scripts (`scripts/**` — comments, usage/help text, error messages), and project docs (`AGENTS.md`, `workflow.md`, `conventions.md`, `decisions.md`, `architecture.md`, `standards/*.md` English originals). Standards keep their pt/es translations (existing pattern). New artifacts are authored in English and must carry the locale-aware response rule. Issue #64 (career sector) lands first; this issue then applies the same rule to the remaining project surface without re-touching files #64 already standardized.
- Business rules:
  1. English MUST be the operational language of the entire project configuration: agent prompts (`agents/**`), skill prompts (`skills/**/SKILL.md` frontmatter + body), command docs and `opencode.json` command templates (`commands/ocf:*.md`), scripts (`scripts/**` — code comments, usage/help text, error messages, interactive prompts), and project documentation (`AGENTS.md`, `workflow.md`, `conventions.md`, `decisions.md`, `architecture.md`, `standards/*.md` English originals).
  2. Existing Portuguese-language artifacts (currently ~44+ files across agents/, commands/, skills/, scripts/, docs) MUST be rewritten to English. The rewrite is content-preserving: no instruction, business rule, or behavior change — only the language. Technical terms, command names (`ocf:cv-hub`, `ocf:develop`, etc.), code identifiers, and domain constants (e.g. `[INFERIDO]` per issues #62/#64) remain unchanged.
  3. Standards MAY keep their localized translations in `standards/pt/` and `standards/es/` (existing pattern preserved). The English originals in `standards/` are the source of truth; locale-loader resolves the localized version for agents working under a pt/es project locale.
  4. Response/output language rule: every agent MUST respond to the user and produce user-facing outputs in the language the user communicates in (the input language). When the input language is not applicable or is ambiguous, the agent MUST use the project locale resolved via locale-loader (`.opencode/locale` project first, then `~/.config/opencode/locale` global, then English default). This applies to chat responses, generated reports, Telegram notifications, and remote issue comments.
  5. NEW artifacts (new agents, skills, commands, scripts, standards, docs) MUST be authored in English. Any new agent/skill that produces user-facing content MUST include this locale-aware response rule in its prompt. New standards documents MUST ship with `standards/pt/` and `standards/es/` translations (existing locale-loader rule, preserved).
  6. Overlap with issue #64 (career sector): #64 MUST land first; this proposal then becomes the general rule covering the ENTIRE project, including any career-sector files #64 did not touch. Files already standardized by #64 MUST NOT be re-rewritten (no duplicate diffs). Where a sector-specific rule conflicts with this general rule, the general rule wins unless the sector rule is explicitly more specific and compatible (e.g. cv-tailor resumes in the job offer's language — kept).
  7. Verification gate: a language-conformance check MUST pass before promotion (grep-based check in `scripts/tests/` and/or QA pre-development review): no Portuguese instruction prose in `agents/`, `commands/`, `skills/`, `scripts/`, or the English standards originals. Exemptions: `standards/pt/`, `standards/es/`, `vendor/**` (third-party upstream), domain constants, and historical/archived content (rule 8).
  8. Historical content is NOT retroactively rewritten where it has no operational value: `resolved_issues.md` archive entries, git history, and closed proposals. New/edited entries in `known_issues.md` and new proposals in `prioritization.md` MUST be authored in English; existing mixed-language entries may be migrated opportunistically when touched, without a dedicated rewrite pass.
  9. `vendor/**` external skills are out of scope — third-party content remains exactly as upstream provides it (established convention per ADR 2026-08-05 / issue #50).
  10. Scripts' user-facing static messages (usage, errors, help) MUST be in English (operational tooling). Interactive prompts that directly ask the user a question MAY follow the project locale, but MUST default to English.
- Stakeholders: william_pereira (author/consumer of the config), all agents that read these prompts, Developer, QA, PO
- Rationale: The config is the opencode-flow product itself. English operational language keeps it consistent, portable and maintainable, and the user explicitly requires it. Issue #64 proved the pattern on the career sector; this generalizes it. The locale mechanism already exists — this issue only standardizes the authored language while keeping outputs localized for the user.
- Dependencies: Issue #64 (career sector standardization, backlog — MUST land first to avoid duplicate diffs on career files). locale-loader skill and `.opencode/locale` mechanism (already exist — foundation, not changed). Career bundle #62/#63/#65–#72 share files with this proposal (skills/career, agents/career, commands/ocf:cv-*) — coordinate merge order so this issue does not conflict with the career bundle. Issue #56 (test-runner) unaffected.
- Proposed issue type: feat

### Proposal 2026-08-14-13: Validate running delivery sessions in isolated containers for effective parallelization
- Priority: high
- Business value: Unblocks true parallel delivery on the local machine. Today each delivery session (`ocf:delivery` / `ocf:develop`) works on its own feature branch (`issue-<id>-<slug>`) but shares one working tree, so concurrent sessions collide on file writes, git operations and tracker updates. Isolating each session in its own container/workspace snapshot removes the collision surface, letting N tasks deliver in roughly the wall-clock time of one — a direct throughput multiplier for the pipeline. The #40 Docker image already proves headless runs work; this extends the same pattern to LOCAL parallel delivery.
- Target sprint: next
- Description: Spike-first. Prove that N parallel containerized delivery sessions can run concurrently on the local machine without overlapping file/git conflicts, then implement. Each session runs the full delivery pipeline (promote → develop → senior review → QA → corrections → committer gate → MR) inside its own container with a private working-tree snapshot (feature branch on top of the base branch). Reuse the #40 Docker image (`ghcr.io/pereirawe/opencode-flow`), which already packages the opencode binary + full config (agents, skills, commands, scripts, deny rules) and was validated for headless `opencode run --command "ocf:develop" <id> --auto`. Respect the #39/#40 boundaries: no merge polling, security deny rules bind inside containers, and the aibot-repos allowlist gates remote posting.
- Business rules:
  1. Spike-first: the issue MUST start with a validation spike before any production implementation. The spike MUST prove that N (configurable, default 3) parallel containerized delivery sessions complete concurrently on one host with ZERO file-write or git conflicts and results identical to serial execution. The spike outcome MUST be documented (`.opencode/spikes/containerized-delivery.md` or ADR) with explicit pass/fail criteria.
  2. Isolation semantics: each delivery session MUST run in its own container with a private working tree — a full snapshot of the target workspace at session start, with the feature branch `issue-<id>-<slug>` created on top of the base branch. File writes (source edits, `.opencode/known_issues.md` updates, `.opencode/reviews/**`, test cache) and git operations (checkout, commit, push) are confined to the session container and NEVER overlap with other sessions.
  3. Image reuse: the container base MUST reuse the #40 Docker image `ghcr.io/pereirawe/opencode-flow:latest` + semver tag (opencode binary + full config + deny rules). No new base image from scratch; extensions, if any, are layered on top and versioned.
  4. Concurrency: sessions MUST be serialized per-issue (an issue already `in-progress` in another session is skipped — same gate as #39/#40), while DIFFERENT issues run in parallel up to a configurable limit (default 3, capped by host resources, e.g. `AIBOT_MAX_PARALLEL`). Lock scope is per-issue, never global.
  5. No-merge-polling boundary: containerized sessions MUST NOT poll merge/PR status. Closing remote issues after merge remains exclusive to `ocf:check-pr` / Close Requester (#39/#40 boundary preserved).
  6. Security deny rules MUST bind inside containers: the global bash deny list (~21 destructive patterns) and the edit denies (opencode.json, aibot-repos.json, `state/**`, `~/.ssh/**`) are enforced by opencode's `--auto` evaluation with the packaged config. Containers run non-root and mount ONLY the session workspace (rw) plus a read-only config volume; `~/.ssh`, `state/`, and host secrets are NEVER mounted into sessions.
  7. Allowlist: remote posting (MR creation, aibot comments) is allowed ONLY for repos in the `aibot-repos.json` allowlist packaged in the image; other repos are refused with the standard message (same behavior as #39/#40). Remote comments follow `standards/aibot-messages.md` (one message per trigger).
  8. Resource management: each session container MUST have CPU/memory limits, a hard timeout, and cleanup-on-exit (container removed after success or failure; only logs/results are persisted). Orphaned containers from crashes MUST be reaped by the orchestrator.
  9. Credentials/state injection: remote credentials (`GH_TOKEN`/`GL_TOKEN`, `OPENCODE_API_KEY`) and the session's `telegram.env` (if any) are injected as environment variables at run time — NEVER baked into the image.
  10. Sync-back to host: the host workspace is NOT modified directly by sessions. After each session completes or fails, the orchestrator (a) fetches the pushed branch, (b) updates the host `known_issues.md` with the session's final issue status (`in-publish` + PR number, or `cannot-develop`), and (c) reconciles tracker updates — each session writes ONLY its own issue block, so conflicts are per-entry and the session's entry wins (authoritative). Sync-back failures are logged, never silent.
  11. Idempotency: re-running a session for the same issue MUST NOT duplicate branches, MRs, tracker entries, or remote comments (same requirement as #40 acceptance criteria).
  12. Spike success criteria: N parallel sessions (default 3, one host) complete with zero conflicts, no lost tracker updates, no duplicate MRs, wall-clock time materially below N× serial, identical end state to serial execution, and resource peaks within configured limits.
  13. Fallback: if the spike FAILS (conflicts not eliminable, resource constraints, or opencode headless limitations inside containers), the issue MUST report the findings and recommend a fallback — e.g. `git worktree`-based per-branch isolation on the host, or keeping #39's flock serialization — and NO production implementation proceeds without a passing spike or explicit user approval of the fallback.
- Stakeholders: william_pereira, Developer, PM, QA, Committer, Publish Requester, PO
- Rationale: Delivery is the pipeline's bottleneck — tasks queue behind a single working tree even though their branches are independent. Issue #40 already proved headless `ocf:develop` runs work in the packaged image; this proposal extends the same pattern to LOCAL parallel delivery, unlocking the throughput the pipeline was designed for.
- Dependencies: Issue #40 (AIBot in CI, in-progress — supplies the Docker image, headless `--auto` validation, deny rules, `aibot-repos.json` allowlist, `standards/aibot-messages.md` templates; this proposal reuses all of them). Issue #39 (aibot-watcher local, resolved — per-issue serialization gate and no-merge-polling boundary reused). Issue #56 (test-runner cache — each container gets its own cache copy; no cross-session cache sharing). Docker with the #40 image built and pullable.
- Proposed issue type: feat

### Proposal 2026-08-17-1: Design sector skills (foundation for Adorable pipeline)
- Priority: high
- Business value: Provides the shared visual language and pattern library that all 6 design agents consume. Without these skills, agents produce generic UI because they lack concrete design tokens, component patterns, and reference libraries. This is the foundation layer — everything else depends on it.
- Target sprint: next
- Description: Create 4 skills under `skills/design/` that encode concrete, testable UI patterns — not philosophy, but values. `reference-library` catalogs high-quality UI patterns (Dashboard Card, Data Table, Nav Rail, etc.) with exact CSS values. `component-patterns` defines anatomy per component type (Button, Card, DataTable, Form, Modal, Toast) with states, slots, and accessibility. `design-tokens` specifies the token system: 5 functional palette layers + 2 accent, 2 typography families, 8pt spacing scale, radius philosophy, shadow tiers, motion durations. `visual-hierarchy` rules for weight, contrast, density, and responsive patterns. All skills in English with bilingual trigger keywords.
- Business rules:
  1. `skills/design/reference-library/SKILL.md` MUST exist with concrete UI patterns (Dashboard Card, Data Table, Nav Rail, Metric Display, Empty State, Command Palette) — each pattern specifies exact CSS values (background hex, border, radius, padding, font sizes), NOT descriptions.
  2. `skills/design/component-patterns/SKILL.md` MUST exist with anatomy per component type: primitive (Button, Badge, Icon, Avatar, Separator, Skeleton, Spinner) and composite (Card, DataTable, Form, Dropdown, Modal, Toast, CommandPalette) — each defines states, slots/children, events, and accessibility.
  3. `skills/design/design-tokens/SKILL.md` MUST exist specifying: palette (5 functional layers: background, surface, border, text-primary, text-muted + 2 accent: primary, secondary + semantic: success, warning, error, info), typography (2 families: display + body, scale xs–4xl), spacing (4pt base, scale [4,8,12,16,24,32,48,64,96,128]), radius (philosophy declaration), shadow (sm/md/lg + philosophy), motion (fast/base/slow durations + easing curves).
  4. `skills/design/visual-hierarchy/SKILL.md` MUST exist with rules for: visual weight by element type, contrast ratios (WCAG AA minimum), density modes (compact/default/comfortable), responsive patterns (stack, hide, collapse, truncate, reorder, scroll).
  5. All skills MUST have English frontmatter `name` and `description` with bilingual trigger keywords (PT trigger phrases preserved as keyword appendix per #73 rule 11).
  6. All skills MUST follow `standards/cv-analysis.md` §2 general structure rules (one H1, H2 for sections, no metadata header).
  7. Skills MUST be registered in `opencode.json` under `permission.skill`.
  8. Skills MUST NOT contain code — they are pattern references consumed by agents as system prompt context.
- Stakeholders: william_pereira, Designer, Developer, PO
- Rationale: The proposal identified "Falta referência mais específica entre agentes e skills" and "Podem estar faltando skills" as key gaps. The 4 skills are the foundation that makes the difference between generic AI UI and Lovable-quality output. Without concrete patterns, agents invent. With them, agents execute.
- Dependencies: Issue #73 (language standardization, resolved — skills must be in English). Vendor taste-skill/minimalist-ui (reference patterns exist but are instruction-based, not pattern-based).
- Proposed issue type: feat

### Proposal 2026-08-17-2: Greenfield pipeline agents (art-director, ui-architect, ui-implementer, ui-critic)
- Priority: high
- Business value: The core 4-pass pipeline that produces Lovable-quality UI. Each agent has a single responsibility: art-director decides how it looks, ui-architect decides what exists and how it behaves, ui-implementer writes code, ui-critic gates quality. The separation eliminates the #1 cause of generic AI UI: one agent trying to think about layout, colors, components, and code simultaneously.
- Target sprint: next
- Description: Create 4 agents under `agents/design/` following the Adorable pipeline architecture. Each agent consumes the previous agent's JSON output and produces a structured JSON for the next. `art-director` receives a brief and produces `design_spec.json` (palette, typography, spacing, layout, component vocabulary, signature element, accessibility requirements). `ui-architect` consumes `design_spec.json` and produces `component_tree.json` (layout regions, component tree, props contracts, state machines, interaction map, build order). `ui-implementer` consumes both JSONs and writes production code (React/Vue/Next/PHP). `ui-critic` evaluates the code against a quality checklist and returns pass/iterate. All agents are subagents with `edit: deny` / `bash: deny` (except ui-implementer which needs `edit: allow` + `bash: allow`). No hardcoded model — uses user's default model with preference for high-capability models documented in prompt.
- Business rules:
  1. `agents/design/art-director.md` MUST exist with: mode=subagent, edit=deny, bash=deny, temperature=0.7. Process: deconstruct brief → audit defaults (reject AI anti-patterns) → 3 design directions → critique and select → produce design_spec.json. Output is pure JSON, no text before/after.
  2. `agents/design/ui-architect.md` MUST exist with: mode=subagent, edit=deny, bash=deny, temperature=0.2. Process: parse design_spec → map layout regions → complete component tree (primitives/composites/templates) → define contracts (props, states, events, accessibility) → interaction map → build order (6 phases: Foundation→Primitives→Composites→Templates→Signature→Polish). Output is pure JSON.
  3. `agents/design/ui-implementer.md` MUST exist with: mode=subagent, edit=allow, bash=allow, temperature=0.1. Process: parse 3 JSONs (design_spec + component_tree + refactor_plan when present) → verify environment → implement by build_order phase → verify against quality checklist. Stack-agnostic: React, Vue, Next.js, PHP+HTML with Tailwind, Bootstrap, CSS Modules, or vanilla CSS. Output is code files.
  4. `agents/design/ui-critic.md` MUST exist with: mode=subagent, edit=deny, bash=deny, temperature=0.3. Process: receive code → evaluate against quality_checklist from design_spec → check: tokens used (not hardcoded), all states implemented, mobile-first, visual hierarchy, purposeful animations → return pass (APPROVED) or iterate (ISSUES_FOUND with specific feedback per component).
  5. Model: NO `model:` in frontmatter. Agents use the user's configured model. Prompt text documents preference: "This agent benefits from high-capability models (Claude Opus, GPT-4o, etc.) but works with any model."
  6. All agents MUST consume and produce structured JSON — no ambiguous text output between agents.
  7. All agents MUST include the locale rule: "Respond in the user's input language; fallback → .opencode/locale (project → global) → EN."
  8. The art-director MUST reject AI design anti-patterns: cream+terracotta, dark+acid green, Inter for everything, generic purple gradient, numbered markers without content sequence, cards in equal 3-col grid without hierarchy.
  9. The art-director MUST generate 3 completely different design directions before selecting one — never go directly to spec.
  10. The art-director MUST define a signature element — the one visual detail that makes the product unmistakable.
  11. The ui-architect MUST map all 6 data states (idle, loading, success, error, empty, stale) for every async component — no exceptions.
  12. The ui-architect MUST define accessibility structurally (role, keyboard, focus management) — not as cosmetic aria-label at the end.
  13. The ui-implementer MUST implement every state defined in the contract — "I won't need an empty state" does not exist.
  14. The ui-critic MUST block delivery when any checklist item fails — no partial approvals.
  15. Agents MUST be registered in `opencode.json` with appropriate permissions.
- Stakeholders: william_pereira, Designer, Developer, PO, QA
- Rationale: The existing `designer.md` agent collapses brief→design→code into a single pass. The Adorable pipeline separates concerns so each agent has a clean context. The proposal proved this works — the draft agents show superior output quality vs single-pass. Issue #80 (skills) provides the pattern library these agents consume.
- Dependencies: Issue #80 (design sector skills — agents reference skills for patterns/tokens). Issue #73 (language standardization — agents in English). Existing `designer.md` (replaced by this pipeline, or coexists as a simpler alternative).
- Proposed issue type: feat

### Proposal 2026-08-17-3: Audit/Refactor agents (ui-auditor, ui-refactor-planner)
- Priority: high
- Business value: Enables the pipeline to work on EXISTING codebases, not just new projects. The ui-auditor produces a machine-readable diagnostic of the current frontend quality. The ui-refactor-planner consumes that diagnostic + the art-director's design_spec to produce a phased migration plan that never breaks working functionality. Together they turn "our UI is bad" into "here's exactly what to change, in what order, with what strategy."
- Target sprint: next
- Description: Create 2 agents under `agents/design/`. `ui-auditor` is stack-agnostic (React, Vue, Next.js, PHP+HTML, with or without Tailwind/Bootstrap) and uses bash to detect the stack, scan files, and analyze code. Produces `audit_report.json` with: stack detection, file inventory, visual audit (palette, typography, spacing consistency), structural audit (god components, prop drilling, duplication), state audit (missing loading/error/empty states), accessibility audit (missing alt, labels, ARIA roles, keyboard traps), responsiveness audit, performance visual audit, and severity-scored critical issues. `ui-refactor-planner` consumes the audit diagnostic + design_spec and produces `refactor_plan.json` with: issue triage (Group A blockers, Group B inline, Group C opportunistic), stack compatibility analysis, component decisions (PRESERVE/ADAPT/REFACTOR/SPLIT/REPLACE/DEPRECATE), phased plan (0–7 phases), dependency map, token mapping, and verification plan.
- Business rules:
  1. `agents/design/ui-auditor.md` MUST exist with: mode=subagent, edit=deny, bash=allow, temperature=0.1. MUST detect stack via bash before reading any component — classify as REACT_VITE, NEXTJS_APP, VUE_VITE, PHP_BLADE, PHP_HTML, HTML_VANILLA, etc.
  2. The auditor MUST use bash for detection only — never destructive operations (no rm, mv, write). Read-only analysis.
  3. The auditor MUST assign severity scores (1–5) per dimension: visual_consistency, component_structure, state_completeness, accessibility, responsiveness, performance_visual, maintainability.
  4. The auditor MUST cite file and line number for every issue — generic diagnostics are useless.
  5. The auditor MUST preserve what's good — `preserved_patterns` is as important as `critical_issues`.
  6. `agents/design/ui-refactor-planner.md` MUST exist with: mode=subagent, edit=deny, bash=deny, temperature=0.2. MUST consume audit diagnostic + design_spec and produce a phased migration plan.
  7. The planner MUST classify issues into Group A (blockers — resolved before anything new), Group B (resolved during migration), Group C (opportunities — if capacity allows).
  8. The planner MUST never plan big bang — every phase leaves the project functional with rollback possible.
  9. The planner MUST never delete before replacing — DEPRECATE comes after REPLACE is in production.
  10. The planner MUST adapt strategy to stack: Tailwind tokens via CSS custom properties, Bootstrap via SCSS variable overrides, PHP via partials + CSS custom properties.
  11. The planner MUST define verification per phase: manual checks, automated tests (if exist), rollback signals.
  12. Both agents MUST output pure JSON — no text before/after.
  13. Both agents MUST include the locale rule.
  14. Both agents MUST be registered in `opencode.json`.
- Stakeholders: william_pereira, Developer, PO
- Rationale: The proposal identified the need for audit+refactor when "before de criar o ui implementer eu quero que já te do um projeto com o frontend ruim implementado eu possa auditar, revisar e planejar o refatoramento". This extends the pipeline from greenfield-only to any existing codebase. Depends on Issue #80 (skills) for the design_spec that the planner consumes.
- Dependencies: Issue #80 (design skills — planner references token/component patterns). Issue #81 (greenfield agents — ui-implementer is reused for the actual code writing after planning).
- Proposed issue type: feat

### Proposal 2026-08-17-4: /ocf:build-ui orchestration command + output file conventions
- Priority: high
- Business value: The entry point that makes the pipeline usable. Without a command, users must manually invoke each agent in sequence. The command orchestrates the 4-pass flow (art-director → ui-architect → ui-implementer → ui-critic) and the audit flow (ui-auditor → ui-refactor-planner → optional pipeline). Output file conventions ensure that pipeline artifacts are findable and resumable across sessions.
- Target sprint: next
- Description: Create 2 commands (`ocf:build-ui` for greenfield, `ocf:audit-ui` for existing codebases) and define output file conventions. `ocf:build-ui` receives a brief, invokes art-director → ui-architect → ui-implementer → ui-critic in sequence. `ocf:audit-ui` receives a project path, invokes ui-auditor → ui-refactor-planner, then optionally feeds into the build pipeline. Output convention: all pipeline artifacts go to `.opencode/design-outputs/<session-id>/` with standardized names (`design_spec.json`, `component_tree.json`, `audit_report.json`, `refactor_plan.json`). Session IDs enable resuming interrupted flows.
- Business rules:
  1. `commands/ocf:build-ui.md` MUST exist and orchestrate: art-director → ui-architect → ui-implementer → ui-critic in sequence.
  2. `commands/ocf:audit-ui.md` MUST exist and orchestrate: ui-auditor → ui-refactor-planner, with optional continuation into the build pipeline.
  3. The commands MUST pass JSON outputs between agents as context — each agent receives the previous agent's output file path.
  4. The commands MUST handle failure at any stage — if art-director fails, do not proceed to ui-architect. Log the failure and notify via Telegram.
  5. Output directory: `.opencode/design-outputs/<session-id>/` where session-id is timestamp-based (e.g., `2026-08-17T14-30-00`).
  6. Output file names: `design_spec.json`, `component_tree.json`, `refactor_plan.json`, `audit_report.json`, `quality_report.json` (from ui-critic).
  7. The commands MUST be registered in `opencode.json` with appropriate permissions.
  8. The commands MUST accept a brief (for build-ui) or project path (for audit-ui) as input.
  9. The commands MUST support resumption: if a session is interrupted, re-running with the same session-id skips completed stages.
  10. The commands MUST detect and use the user's configured model — no hardcoded model in the command template.
  11. The commands MUST follow the response-language rule: respond in the user's input language.
  12. Output file conventions MUST be documented in a standard file (e.g., `standards/design-pipeline.md`).
- Stakeholders: william_pereira, Developer, PO
- Rationale: The proposal identified "a referência dos arquivos resultantes entre skills me parece não está bem definida" and "o nome de cada arquivo na final está sem definição". The command + conventions solve both: a clear entry point and deterministic output paths. Session-based output enables multi-model flows (art-director with Opus, implementer with Sonnet) and resumability.
- Dependencies: Issue #81 (greenfield agents — command invokes them). Issue #82 (audit agents — audit command invokes them). Issue #80 (skills — agents reference them).
- Proposed issue type: feat

### Proposal 2026-08-17-5: Model fallback mechanism for design agents
- Priority: medium
- Business value: Prevents pipeline failures when a preferred model is unavailable. The design pipeline benefits from high-capability models (art-director needs creativity, ui-architect needs precision), but should degrade gracefully to the user's configured model rather than failing.
- Target sprint: next
- Description: Implement model fallback in the design pipeline. Instead of hardcoding `model: anthropic/claude-opus-4-5` in agent frontmatter (which fails if the model is unavailable), agents use the user's default model. The prompt text documents model preference ("This agent benefits from high-capability models") without enforcing it. The command template in opencode.json can optionally specify a preferred model, with automatic fallback to the user's default.
- Business rules:
  1. Design agents MUST NOT have `model:` in their frontmatter — they use the user's configured default model.
  2. Agent prompts SHOULD document model preference textually: "This agent produces best results with high-capability models (Claude Opus, GPT-4o, etc.) but works with any model."
  3. The `/ocf:build-ui` command template in `opencode.json` MAY include a `model` field for preferred model — if the model is unavailable, opencode falls back to the user's default.
  4. The art-director (creativity-heavy) SHOULD document: "temperature: 0.7 recommended for creative output."
  5. The ui-implementer (precision-heavy) SHOULD document: "temperature: 0.1 recommended for precise implementation."
  6. The model preference documentation MUST NOT be a hard requirement — the pipeline must work with any model.
- Stakeholders: william_pereira, Developer
- Rationale: The proposal identified "Definição HardCoded do modelo, deveria ser apenas uma sugestão. Ou ter fallback para o modelo definido pelo usuário." This is a medium-priority fix that prevents silent failures when the preferred model is unavailable.
- Dependencies: None (independent of other issues).
- Proposed issue type: feat

### Proposal 2026-08-17-6: Design sector documentation (READMEs, agent-skill mapping, standards)
- Priority: medium
- Business value: Makes the design sector discoverable and maintainable. Without documentation, new users (and agents) cannot find the design pipeline, understand which agent uses which skill, or know the output conventions. The README serves as the entry point; the mapping document prevents drift between agents and skills.
- Target sprint: next
- Description: Create `agents/design/README.md` listing all 6 agents, their responsibilities, the pipeline flow, and which skills each agent references. Update `agents/README.md` to include the design sector. Update `skills/README.md` to include the design sector. Create `standards/design-pipeline.md` documenting the output file conventions, session management, and pipeline stages. Update `workflow.md` to document the design pipeline as a new entry point alongside the existing delivery pipeline.
- Business rules:
  1. `agents/design/README.md` MUST exist listing: art-director, ui-architect, ui-implementer, ui-critic, ui-auditor, ui-refactor-planner — with one-line description, skills consumed, and pipeline position for each.
  2. `agents/design/README.md` MUST include a flow diagram (ASCII or Mermaid) showing: Greenfield: brief → art-director → ui-architect → ui-implementer → ui-critic → UI. Audit: codebase → ui-auditor → ui-refactor-planner → art-director → ... → UI.
  3. `agents/README.md` MUST be updated to include the design sector alongside existing sectors (bi, business-ops, career, commercial, development, finance, marketing, sales).
  4. `skills/README.md` MUST be updated to include the design sector (reference-library, component-patterns, design-tokens, visual-hierarchy).
  5. `standards/design-pipeline.md` MUST exist documenting: output file names, output directory structure (.opencode/design-outputs/<session-id>/), session resumption protocol, model preference guidelines.
  6. `workflow.md` MUST be updated to document the design pipeline as an entry point: `ocf:build-ui` (greenfield) and `ocf:audit-ui` (existing codebase).
  7. `opencode.json` MUST be updated to register the new commands and agents.
  8. All documentation MUST be in English (per #73).
- Stakeholders: william_pereira, Developer, PO
- Rationale: The proposal identified "Falta atualização dos Readme.md para acrescentar e integrar com o fluxo atual ou funcionalidades existentes" and "Falta referência mais específica entre agentes e skills". Documentation is the glue that makes the sector maintainable.
- Dependencies: Issues #80–#84 (all design sector issues — documentation references the final state).
- Proposed issue type: doc

### Proposal 2026-08-17-7: Blank space after RESUMO section in cv-pdf resume template — blanket `section { break-inside: avoid; }` pushes Experiência to page 2
- Priority: high
- Business value: Every resume generated by `ocf:cv-tailor` inherits the template's print CSS. The blanket `section { break-inside: avoid; }` makes the print engine move the ENTIRE (long) Experiência section to page 2 when it does not fit the remaining page-1 space, leaving a large blank gap after the short RESUMO section on page 1. This degrades the perceived quality of the sector's core shareable deliverable, wastes page space, and can push a junior/pleno resume to 2 pages — violating `standards/cv-design.md` §4. Fixing it restores a professional, space-efficient layout for all generated resumes.
- Target sprint: next
- Description: The resume template `skills/career/cv-pdf/templates/resume.html` applies `section { break-inside: avoid; }` to ALL sections in its print CSS (lines 95-101). The RESUMO section is short (lines 118-121); when the following Experiência section does not fit in the remaining page-1 space, the print engine relocates the entire section to page 2, leaving a large blank gap after RESUMO. Fix: replace the blanket rule with a targeted approach — keep `break-inside: avoid` on short sections and `.entry` entries, keep `h2 { break-after: avoid; }` and `.header { break-after: avoid; }` (no orphaned headings), and allow long content sections to break naturally (optionally with `orphans`/`widows` protection against single-line stranding) so page 1 is filled. CSS-only change; the template remains the mandatory base for cv-tailor.
- Business rules:
  1. The final resume PDF MUST NOT contain a large blank gap after the RESUMO (Summary) section caused by the print engine relocating the entire Experiência section to page 2.
  2. The root cause is the blanket `section { break-inside: avoid; }` rule in the template's print CSS (lines 95-101) applying to ALL sections, including long ones such as Experiência — the fix MUST address this root cause directly.
  3. The fix MUST be CSS-only, confined to `skills/career/cv-pdf/templates/resume.html` — no HTML structure changes, no content changes, and no changes to the cv-tailor/cv-pdf skills, agents, or commands.
  4. The template MUST remain the mandatory base for cv-tailor (cv-tailor copies it and adapts only content, never CSS) — the fix MUST NOT alter this contract.
  5. The fix MUST preserve the intent of `standards/cv-design.md` §2.4: sections and entries MUST still avoid awkward splits where appropriate. Short sections and individual entries (`.entry`) MUST keep `break-inside: avoid`; long content sections (e.g., Experiência) MAY be allowed to break across pages.
  6. The fix MUST NOT introduce new blank space elsewhere: `h2 { break-after: avoid; }` and `.header { break-after: avoid; }` MUST be preserved so headings are never orphaned at the bottom of a page, and section margins (`section { margin-bottom: 6mm; }`) MUST NOT create visible gaps at page breaks.
  7. The fix MUST keep `standards/cv-design.md` §2.2 (no excessive whitespace) and §4 (page limits: 1 page junior/pleno, at most 2 senior+) achievable — a junior/pleno resume MUST still fit on exactly one page.
  8. If the literal §2.4 wording needs refinement to distinguish short vs long sections, the refinement MUST be documented in `standards/cv-design.md` and its conformity checklist — never a silent CSS-only divergence from the standard.
  9. The fix MUST be validated against a representative resume with a long Experiência section: page 1 filled with content after RESUMO, no blank gap, no orphaned heading at the page boundary.
  10. The fix MUST pass `make test-scripts` (regression) and any existing template/conformity checks.
- Stakeholders: william_pereira (candidate/user of ocf:cv-tailor), recruiters/ATS (consumers of the PDF), PO, QA
- Rationale: The bug affects every resume generated by the career sector — the template is the mandatory base for cv-tailor, so the defect is systematic, not an edge case. The resume is the sector's core shareable deliverable; a large blank gap degrades perceived quality, wastes page space, and can violate the page-count standard. The fix is small, CSS-only, and high-leverage.
- Dependencies: None blocking. Related: `standards/cv-design.md` (§2.4 wording may need refinement per BR 8); issue #63 (design standard this fix must respect); career bundle #62/#64/#65 — coordinate merge order to avoid conflicts on shared cv files.
- Proposed issue type: bug

### Proposal 2026-08-19-1: Differentiated bug discovery flow — fast, prioritized, token-efficient (still refined)
- Priority: high
- Business value: Bugs are the highest-frequency issue type and the most time/token-sensitive, yet today every `bug` runs the same full 6-phase discovery designed for features (PO → CTO → Tech Lead → PO → QA → PM). A critical bug delayed by a feature-oriented discovery cycle is a production risk. A differentiated bug flow cuts default discovery to ~2-3 phases, applies bug-specific prioritization (severity, impact, frequency, blocking), and reduces token consumption by ~50% while keeping refinement quality — business rules and `Tests:` remain mandatory, so "faster" never means "shallow".
- Target sprint: next
- Description: Create a differentiated discovery flow for `bug` type issues. Default lightweight flow: (1) PO triage — classify severity/impact/frequency/blocking, derive prioritization score, capture lean business rules and user story; (2) QA pre-development — validate testability and capture `Tests:` (`scenario → outcome`, severity floor); (3) PM — promote with `- Base branch:` and `- Reviewers:` already set. CTO and Tech Lead phases become OPTIONAL for bugs, invoked only on escalation. `feat` issues keep the full 6-phase flow unchanged. Complex bugs escalate to the full pipeline (same as today). Implementation touches: `workflow.md` (Discovery Pipeline — differentiate bug/feat), `agents/development/discovery.md` (orchestration with bug branch), `agents/development/product-owner.md` (bug triage prompt + prioritization matrix), `agents/development/quality-analyst.md` (lean bug validation), `agents/development/project-manager.md` (non-interactive promotion for triaged bugs), and optionally a `bug-triage` skill documenting the scoring matrix.
- Business rules:
  1. Bug discovery MUST be differentiated from feat discovery: `bug` issues default to a lightweight flow (≤3 phases); `feat` issues keep the full 6-phase flow (PO → CTO → Tech Lead → PO → QA → PM) unchanged.
  2. The lightweight bug flow MUST be: PO triage (mandatory) → QA pre-development (mandatory) → PM promotion (mandatory). The CTO and Tech Lead phases MUST be optional for bugs, invoked only on escalation (BR 6).
  3. Bug prioritization MUST use bug-specific criteria with a documented scoring matrix: severity (critical=5, high=4, medium=3, low=2) + impact scope (blocking / financial / broad user impact / isolated) + frequency (always / frequent / occasional / rare) + regression or security risk. The resulting `- Priority:` MUST be derived from the score and recorded in the issue entry.
  4. Token efficiency target: the bug flow MUST reduce discovery token consumption by ≥50% vs the full flow — fewer agent invocations, leaner prompts, no CTO/Tech Lead pass for non-escalated bugs (verifiable by phase-count proxy or session comparison).
  5. Refinement quality MUST NOT drop: business rules (when applicable) and `Tests:` (`scenario → outcome` lines, severity floor) remain MANDATORY for `bug` issues — a leaner flow never creates a spec gap. Bugs without a business-rule surface MUST state that explicitly ("no business rules") instead of omitting the field.
  6. Escalation to full discovery (6 phases) is triggered when: no clear root cause or missing repro steps, multi-layer or cross-cutting fix, business-rule ambiguity, security implications, or the fix touches architecture/standards. Escalated bugs MUST run the same pipeline as feats.
  7. `- Base branch:` and `- Reviewers:` MUST still be defined during bug discovery — PM promotion stays non-interactive (consistent with issue #9 resolution).
  8. Progressive prioritization: bugs with severity critical/high MUST rank above all non-critical feats in the backlog regardless of creation order.
- Stakeholders: william_pereira (reporter and consumer), PO, QA, PM, Developer, CTO, Tech Lead
- Rationale: The current mandatory rule covers only `feat` ("Every new feature MUST go through the full discovery pipeline"), but `bug` issues inherit the same full cost without the benefit — features need architectural alignment; most bugs do not. Bugs dominate the issue stream and suffer most from a feature-oriented discovery. A differentiated flow with bug-specific prioritization and escalation is the direct answer to the request: "faster, improved prioritization, token-efficient, but still refined".
- Dependencies: Issue #56 (test-runner — `Tests:` capture unchanged); issue #73 (language — new prompts authored in English, resolved); issue #37 (develop-router — delivery side unchanged); `standards/issues.md` (bug fields already exist: Severity, Report, Impact, Location). Touches `workflow.md` + discovery/orchestrator agents — no conflict with in-flight issues.
- Proposed issue type: feat

### Proposal 2026-08-19-2: Caché de credenciales git por proyecto (`.opencode/cache/git/`) con git credential helper
- Priority: high
- Business value: Elimina la fricción de credenciales en cada ciclo del pipeline: hoy, cuando las credenciales de GitLab/GitHub no están en la config local del repo, los agentes (sobre todo `developer` y `committer`) deben pedir permiso para hacer commit en cada prompt y cada interacción git es lenta y consume tokens. Con un caché de credenciales por proyecto + credential helper, git autentica sin prompts, los commits fluyen sin interrupción y el consumo de tokens y latencia por ciclo bajan drásticamente.
- Target sprint: next
- Description: Crear un caché de credenciales git por proyecto en `.opencode/cache/git/` (gitignored, permisos 0600) que almacena las credenciales y la identidad de commit (`user.name`/`user.email`). La importación es AUTOMÁTICA: cuando un agente recibe credenciales en la sesión, las escribe en el caché sin volver a preguntar. La integración con git se hace vía `git config credential.helper` apuntando al archivo del caché, de modo que git autentica sin prompts. Diseño de seguridad MÁXIMO: permisos 0600, redacción de secretos en logs/reportes y lectura restringida a los agentes autorizados del pipeline. Estructura decidida por el usuario: DOS issues `feat` separadas — esta propuesta es la issue #209 (caché de credenciales); el entorno de pruebas versionado es la issue #210 (propuesta 2026-08-19-3).
- Business rules:
  1. El caché DEBE ser por proyecto: `.opencode/cache/git/` en cada repositorio — NUNCA en `~/.config/opencode/` ni en el directorio global de opencode.
  2. `.opencode/cache/git/` DEBE añadirse al `.gitignore` de cada repositorio (hoy NO está ignorado; `.opencode/test-cache/` ya gitignored es el precedente a seguir).
  3. El contenido del caché DEBE incluir: credenciales git (URL del remote + username + token/password) Y la identidad de commit (`user.name` / `user.email`).
  4. Seguridad MÁXIMA: los archivos del caché DEBEN tener permisos 0600 (solo el propietario); el script de inicialización DEBE aplicar `chmod 0600` al crearlos.
  5. Las credenciales NUNCA DEBEN aparecer en claro en logs, reportes de revisión, salidas de comandos, notificaciones Telegram ni comentarios remotos — la redacción (ocultamiento de secretos) DEBE ser obligatoria en scripts, agentes y reportes, incluyendo el modo `--auto`.
  6. El caché DEBE ser legible únicamente por los agentes autorizados del pipeline (developer, committer, publish-requester); los permisos a nivel de agente (bash deny/allow) DEBEN restringir el acceso a `.opencode/cache/git/`.
  7. Auto-import: cuando un agente recibe credenciales en la sesión (del usuario, de variables de entorno o de la config del repo), DEBE escribirlas en el caché sin volver a preguntar, salvo que ya exista una entrada válida (no sobrescribir innecesariamente).
  8. Integración git: DEBE configurarse un git credential helper que apunte al archivo del caché (`git config credential.helper` a nivel de repo) para que git autentique sin prompts en fetch/push/commit.
  9. El helper DEBE fallar silenciosamente cuando el caché no exista o no sea legible — nunca mostrar prompts de credenciales ni mensajes de error que expongan secretos.
  10. El flujo DEBE respetar las fronteras de seguridad existentes: la global bash deny list y los permisos por agente siguen rigiendo; el manejo de credenciales NUNCA DEBE debilitarlos (ni en sesiones normales ni en `--auto`).
  11. DEBE existir un entrypoint único (script, ej. `scripts/git-cred-cache.sh` con subcomandos `--init`, `--set`, `--get`, `--status`) para inicializar, leer y verificar el caché — sin comandos git ad hoc por parte de los agentes.
  12. La identidad de commit en caché DEBE usarse en los commits del pipeline para que `developer`/`committer` nunca tengan que preguntar `user.name`/`user.email`.
- Stakeholders: william_pereira (consumidor del pipeline), Developer, Committer, Publish Requester, PM, QA
- Rationale: Hoy cada ciclo de issue sufre interacciones git lentas y prompts de permiso repetidos cuando las credenciales no están en la config local del repo — el problema más visible en developer y committer, y también en publish-requester (push). La decisión del usuario fue máxima seguridad + automatización total (auto-import sin re-preguntar + credential helper). El cambio es pequeño (script + reglas de permisos + gitignore) y elimina fricción en CADA ciclo del pipeline, reduciendo tokens y latencia de forma permanente.
- Dependencies: Sin dependencias bloqueantes. Relacionado: la global bash deny list y los permisos por agente ya existentes (los agentes del pipeline DEBEN actualizarse para autorizar el script/helper y restringir el acceso al caché); `.opencode/test-cache/` como precedente de gitignore; la propuesta 2026-08-19-3 (issue #210, entorno de pruebas) es independiente — se ejecuta como issue separada.
- Proposed issue type: feat

### Proposal 2026-08-19-3: Versionado y documentación del entorno de pruebas (manifest Node + Python + test-runner)
- Priority: high
- Business value: El entorno de pruebas no está documentado ni versionado — sobre todo Node.js: la versión cambia entre sesiones y no queda registrada en ningún lado. Las etapas de senior review y QA pueden tardar hasta 5x más porque cada sesión debe preguntar o reconfigurar el entorno. Documentar y versionar el entorno (manifest + `.nvmrc`/`.node-version` + reporte de versiones en el runner) convierte el entorno en un contrato explícito y repetible: reviewers y QA leen el mismo contrato sin re-preguntar, y los desvíos se detectan con una advertencia temprana.
- Target sprint: next
- Description: Definir y documentar el entorno de pruebas del repo con versiones en RANGO (ej. Node >=20 <23). (1) Crear `.nvmrc` + `.node-version` en la raíz; (2) crear el manifest del entorno versionado (committed): `standards/test-env.md` O `.opencode/env-manifest.md` — forma a decidir en refinamiento; (3) extender `scripts/test-runner.sh` para que `--status` reporte las versiones detectadas (Node, Python y la propia versión del runner) y advierta (warning) ante desvíos vs el manifest; (4) documentar el protocolo de entorno en `skills/development/test-runner/SKILL.md`. Política: RANGO + ADVERTENCIA solamente — el pipeline NUNCA se bloquea por desvío de versión. Estructura decidida por el usuario: issue #210, separada de la #209 (caché de credenciales — propuesta 2026-08-19-2).
- Business rules:
  1. El alcance DEBE cubrir: Node.js, Python y el propio test-runner (`scripts/test-runner.sh`).
  2. DEBEN existir `.nvmrc` (para nvm/volta) y `.node-version` (para nodenv/asdf) en la raíz del repo, ambos versionados (committed), con la versión de Node esperada.
  3. DEBE existir un manifest del entorno versionado (committed): `standards/test-env.md` O `.opencode/env-manifest.md` (forma a decidir en refinamiento) que registre los rangos esperados de Node, Python y el test-runner, más el procedimiento de bootstrap del entorno.
  4. La política de versión DEBE ser por RANGO (ej. Node >=20 <23) + ADVERTENCIA: el desvío NUNCA DEBE bloquear el pipeline (ni promotion ni delivery) — solo warning informativo.
  5. `scripts/test-runner.sh --status` DEBE reportar las versiones detectadas (node, python y su propia versión) y DEBE advertir sobre desvíos vs el manifest, indicando la versión esperada.
  6. El warning DEBE ser accionable (ej. "Node 19 detectado; el manifest requiere >=20 <23 — considere `nvm use`") y DEBE salir con un exit code que no interrumpa la ejecución ni el caché por fingerprint.
  7. El manifest DEBE estar versionado (committed) para que senior reviewers y QA lean el mismo contrato en todas las sesiones.
  8. `skills/development/test-runner/SKILL.md` DEBE documentar el protocolo de entorno: ubicación del manifest, cómo interpretar los warnings y cómo reportar la versión usada.
  9. Cuando el entorno detectado difiera del manifest, los agentes (developer/reviewers/QA) DEBEN registrar la versión realmente usada en el reporte de tests para que las etapas siguientes no re-pregunten ni reconfiguren.
  10. La extensión del runner DEBE ser compatible con los modos `--check`/`--run`/`--status` existentes y con el caché por fingerprint de `.opencode/test-cache/` (sin cambios de contrato).
- Stakeholders: william_pereira, Developer, Senior Reviewers, QA, Committer, PO
- Rationale: La causa raíz del "hasta 5x más lento en review/QA" es que el entorno no es un contrato conocido: cada sesión descubre o reconfigura la versión de Node. El fix es barato (manifest + `.nvmrc`/`.node-version` + reporte de versiones en el runner ya existente) y de efecto permanente: el entorno queda documentado, versionado y autodiagnosticado con warning — sin añadir fricción al pipeline (nunca bloquea).
- Dependencies: Issue #56 (test-runner, resuelta — el runner ya existe y esta propuesta lo extiende sin cambiar su contrato); `package.json` en la raíz (Node) y Python3 en scripts (`sync-jira.sh`, cv) ya presentes; Makefile disponible. Sin dependencia con la issue #209 (propuesta 2026-08-19-2) — se ejecuta como issue separada.
- Proposed issue type: feat

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


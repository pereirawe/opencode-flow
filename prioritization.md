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
- Description: Criar comando `ocf:review-external` + agente `agents/review-external.md`. O fluxo: (1) usuário informa URL de MR/PR ou branch remota; (2) fetch + checkout; (3) revisão técnica com senior-reviewers; (4) geração de relatório .md local; (5) pergunta se deseja postar comentários críticos/high no MR via gh/glab; (6) postagem opcional.
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

## Lifecycle

1. **Proposal** — PO registers the idea with business context and priority
2. **CTO/TL Review** — CTO and Tech Lead assess architectural impact and feasibility
3. **Refined** — User story created with acceptance criteria by PO, refined by TL
4. **QA Review** — QA ensures testability and adds quality criteria
5. **Promoted** — Entry added to `known_issues.md` as `backlog` or `ready`
6. **Executed** — Follows standard issue lifecycle from `known_issues.md`

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
`Remote:` is populated at the end of discovery (when issue reaches `ready`).

### 9. Consolidar decisões de branch, revisores e issue remota no discovery
- Status: ready
- Type: feat
- Severity: high
- Report: opencode
- Base branch: main
- Reviewers: 1 (tech-lead, runtime)
- Remote: #18
- Location: `known_issues.md` format, `workflow.md`, `agents/project-manager.md`, `scripts/promote.sh`, `standards/prioritization.md`, `standards/resolved-issue.md`, `agents/tech-lead.md`, `agents/cto.md`, `agents/product-owner.md`, `agents/quality-analyst.md`, `agents/publish-requester.md`, `agents/committer.md`, `Makefile`
- Description: Mover decisões de branch base, perfis de revisores e criação de issue remota do PM promotion para o discovery pipeline. PM promotion vira puramente executória (sem perguntas ao usuário).
- Impact: Elimina 3 interrupções por issue no pipeline, reduz lead time e fortalece known_issues.md como fonte única de verdade.
- Business rules:
  1. `known_issues.md` DEVE ter campo `- Base branch:` definido no discovery.
  2. `- Reviewers:` no formato `<count> (<profile1>, <profile2>)` definido no discovery. Profiles válidos: backend, data, devops, frontend, mobile, performance, qa, runtime, security, ux-ui. Se profile inválido, emitir warning.
  3. Issue remota DEVE ser criada quando issue atinge `ready`. **Tech Lead** é responsável.
  4. Se criação remota falhar → `Remote: error:<motivo>`. Retry antes de `in-progress`.
  5. PM promotion: ler campos do `known_issues.md`, checkout+pull da base branch, criar feature branch, status → `in-progress`.
  6. PM NÃO DEVE perguntar base branch, revisores ou criar remote na promoção.
  7. Scripts de promote DEVEM ler de `known_issues.md`, não interagir com usuário.
  8. Formato do issue atualizado conforme esta issue.
  9. Issues antigas (sem `Base branch:` ou `Reviewers:` sem perfis) DEVEM fallback: auto-detecção branch (main → master → origin/HEAD), count via `grep -o '^[0-9]*'`.
  10. Scripts impactados: `pre_commit.sh`, `maintain.sh`, `close_issue.sh`, `create_issue.sh`, `promote.sh`, `config.sh` DEVEM ser atualizados.
  11. `resolved-issue.md` mantém `- Reviewers: <number>` (só count, sem profiles).
- Acceptance criteria:
  1. Issue em `backlog` com campos preenchidos → discovery concluído → `ready` com todos campos populados.
  2. Issue em `ready` → PM executa promote → `in-progress` sem perguntas, branch `issue-<id>-<slug>` criado da `Base branch`.
  3. Issue com `- Reviewers: 1` (formato antigo) → promote extrai count=1 via fallback.
  4. Issue sem `- Base branch:` → promote auto-detecta branch default.
  5. Issue `ready` com `Remote: error:rate limit` → promote bloqueia com erro claro.
- Suggested fix: Seguir ordem: (1) schema known_issues.md + resolved-issue.md, (2) scripts promote.sh + create_issue.sh + close_issue.sh + pre_commit.sh + maintain.sh + config.sh, (3) agentes (project-manager, tech-lead, cto, po, qa, publish-requester, committer), (4) workflow.md + Makefile, (5) testes.

### Status Lifecycle

- `backlog`: item captured but not yet refined or prioritized
- `ready`: item refined, approved, testable — ready for development
- `open`: item selected locally and awaiting remote issue creation (legacy, use ready instead)
- `in-progress`: remote issue exists and work has started
- `in-review`: senior review completed, awaiting QA verification
- `in-qa`: QA verifying post-review corrections (may loop back to `in-progress`)
- `in-publish`: Committer gate passed, MR created, awaiting merge
- `resolved`: MR approved and merged (moved to archive)

Resolved issues move to `resolved_issues.md` (same directory as this file). See `standards/resolved-issue.md` for the archive format.

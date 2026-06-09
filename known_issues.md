## Known Issues

Single source of truth for tracked work in this project.

### Format

```markdown
### <id>. <title>
- Status: backlog | ready | open | in-progress | in-review | in-qa | in-publish | resolved
- Type: bug | feat | doc | chore
- Severity: critical | high | medium | low
- Report: <user-name> | <model-name>
- Reviewers: <number> (set during promotion, default 1)
- Remote: - | #<remote-id>
- PR: - | #<pr-number>
- Location: <file-path>:<line-numbers>
- Description: <brief>
- Impact: <what or who is affected>
- Business rules: <specific business logic, constraints, and domain rules>
- Suggested fix: <approach or next step>
```

`Business rules:` is required for `feat` type issues.
`Reviewers:` is set during promotion and consumed during senior review and MR creation.


### 6. Revisar e enriquecer o PR template
- Status: in-progress
- Type: feat
- Severity: medium
- Report: william.pereira@digitalup.intranet
- Reviewers: 1
- Remote: #16
- Location: `standards/pr-template.md`:1-16, `standards/pt/pr-template.md`:1-16, `standards/es/pr-template.md`, `standards/fr/pr-template.md`, `standards/de/pr-template.md`, `standards/ja/pr-template.md`, `standards/zh/pr-template.md`, `agents/publish-requester.md`:17-18
- Description: Expandir o PR template atual (en/pt/es/fr/de/ja/zh) para um template único mais completo, com seções opcionais. O publish-requester deve preencher automaticamente os dados da issue.
- Impact: PRs mais completos reduzem idas-e-voltas em revisão e documentam decisões técnicas.
- Business rules:
  1. O template DEVE ser único (não múltiplos templates por tipo de issue).
  2. Seções opcionais DEVEM ser claramente marcadas como `(opcional)` no template.
  3. O template DEVE incluir: Resumo executivo, Contexto/Motivação, O que mudou, Checklist, Screenshots/Evidências (opcional), Breaking Changes (opcional), Rollback Plan (opcional), Referência à Issue (obrigatório), Riscos, Como Testar.
  4. A seção "Referência à Issue" DEVE conter `Relates to: #<id>` linkando para a known_issues.md.
  5. O agente publish-requester DEVE preencher automaticamente o template com: título da issue, ID, branch name, e remote reference.
  6. Todas as traduções existentes (pt, es, fr, de, ja, zh) DEVEM ser atualizadas em paralelo com o template en.
  7. O template en (`standards/pr-template.md`) é o padrão; os localized templates devem seguir a mesma estrutura.
- Suggested fix: Revisar `standards/pr-template.md` adicionando as novas seções. Atualizar cada tradução. Atualizar `agents/publish-requester.md` para usar o novo template e preencher campos automaticamente.

### Status Lifecycle

- `backlog`: item captured but not yet refined or prioritized
- `ready`: item refined, approved, testable — ready for development
- `open`: item selected locally and awaiting remote issue creation
- `in-progress`: remote issue exists and work has started
- `in-review`: senior review completed, awaiting QA verification
- `in-qa`: QA verifying post-review corrections (may loop back to `in-progress`)
- `in-publish`: Committer gate passed, MR created, awaiting merge
- `resolved`: MR approved and merged (moved to archive)

Resolved issues move to `resolved_issues.md` (same directory as this file). See `standards/resolved-issue.md` for the archive format.

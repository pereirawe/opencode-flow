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
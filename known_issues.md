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

### 3. Landing page não possui Content Security Policy (CSP)
- Status: in-review
- Type: chore
- Severity: medium
- Report: senior-reviewers/security
- Base branch: main
- Reviewers: 1 (security)
- Remote: -
- PR: -
- Location: advogados/index.html
- Description: Nenhuma CSP definida. A página carrega Google Fonts via CDN externo e usa data URIs em inline SVGs.
- Impact: Sem defesa em profundidade contra injeção de scripts via dependências comprometidas.
- Suggested fix: Adicionar &lt;meta http-equiv="Content-Security-Policy"&gt; com allowlist para Google Fonts e data: URIs.
- Business rules: (none — this is a chore, not a feat)


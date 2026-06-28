# Rastreamento de Issues

Rastreamento em dois níveis:
- **Global**: `~/.config/opencode/known_issues.md` — issues de config do opencode
- **Projeto**: `<projeto>/.opencode/known_issues.md` — issues específicas do projeto

## Formato de Entrada

```markdown
### <id>. <título>
- Status: backlog | ready | open | in-progress | in-review | in-qa | in-publish | resolved
- Type: bug | feat | doc | chore
- Severity: critical | high | medium | low
- Report: <nome-usuário> | <nome-modelo>
- Base branch: <default-branch> | <branch-name>
- Reviewers: <número> (definido durante discovery, default 1)
- Remote: - | #<id-remoto>
- PR: - | #<pr-number>
- Location: <caminho-arquivo>:<linhas>
- Description: <descrição breve>
- Impact: <o que ou quem é afetado>
- Business rules: <regras de negócio, restrições e regras de domínio>
- Acceptance criteria: <o que deve ser verdade para a issue ser considerada completa>
- Suggested fix: <abordagem ou próximo passo>
```

## Ciclo de Vida

```
backlog -> ready -> open -> in-progress -> in-review -> in-qa -> in-publish -> resolved
```

| Status | Significado |
|--------|-------------|
| `backlog` | Capturado, ainda não refinado |
| `ready` | Claro, aprovado, testável — pronto para execução |
| `open` | Selecionado, aguardando criação remota |
| `in-progress` | Issue remota existe, trabalho iniciado |
| `in-review` | Senior review concluído, aguardando QA |
| `in-qa` | QA verificando pós-review (pode voltar para `in-progress`) |
| `in-publish` | Committer aprovou, MR criado, aguardando merge |
| `resolved` | MR aprovado e mesclado (movido para arquivo) |

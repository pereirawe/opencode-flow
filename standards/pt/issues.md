# Rastreamento de Issues

Rastreamento em dois níveis:
- **Global**: `~/.config/opencode/known_issues.md` — issues de config do opencode
- **Projeto**: `<projeto>/.opencode/known_issues.md` — issues específicas do projeto

## Formato de Entrada

```markdown
### <id>. <título>
- Status: backlog | ready | open | in-progress | resolved
- Type: bug | feat | doc | chore
- Severity: critical | high | medium | low
- Reported by: <nome-usuário> | <nome-modelo>
- Remote: - | #<id-remoto>
- Location: <caminho-arquivo>:<linhas>
- Description: <descrição breve>
- Impact: <o que ou quem é afetado>
- Suggested fix: <abordagem ou próximo passo>
```

## Ciclo de Vida

```
backlog -> ready -> open -> in-progress -> resolved
```

| Status | Significado |
|--------|-------------|
| `backlog` | Capturado, ainda não refinado |
| `ready` | Claro e aprovado para execução |
| `open` | Selecionado, aguardando criação remota |
| `in-progress` | Issue remota existe, trabalho iniciado |
| `resolved` | Completo ou fechado |

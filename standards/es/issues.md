# Seguimiento de Issues

Seguimiento en dos niveles:
- **Global**: `~/.config/opencode/known_issues.md` — issues de configuración de opencode
- **Proyecto**: `<proyecto>/.opencode/known_issues.md` — issues específicas del proyecto

## Formato de Entrada

```markdown
### <id>. <título>
- Status: backlog | ready | open | in-progress | resolved
- Type: bug | feat | doc | chore
- Severity: critical | high | medium | low
- Reported by: <nombre-usuario> | <nombre-modelo>
- Remote: - | #<id-remoto>
- Location: <ruta-archivo>:<líneas>
- Description: <descripción breve>
- Impact: <qué o quién es afectado>
- Suggested fix: <enfoque o siguiente paso>
```

## Ciclo de Vida

```
backlog -> ready -> open -> in-progress -> resolved
```

| Status | Significado |
|--------|-------------|
| `backlog` | Capturado, aún no refinado |
| `ready` | Claro y aprobado para ejecutar |
| `open` | Seleccionado, esperando creación remota |
| `in-progress` | Issue remota existe, trabajo iniciado |
| `resolved` | Completado o cerrado |

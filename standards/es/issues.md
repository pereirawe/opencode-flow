# Seguimiento de Issues

Seguimiento en dos niveles:
- **Global**: `~/.config/opencode/known_issues.md` — issues de configuración de opencode
- **Proyecto**: `<proyecto>/.opencode/known_issues.md` — issues específicas del proyecto

## Formato de Entrada

```markdown
### <id>. <título>
- Status: backlog | ready | open | in-progress | in-review | in-qa | in-publish | resolved
- Type: bug | feat | doc | chore
- Severity: critical | high | medium | low
- Report: <nombre-usuario> | <nombre-modelo>
- Base branch: <default-branch> | <branch-name>
- Reviewers: <número> (<perfil1>, <perfil2>)
- Remote: - | #<id-remoto>
- PR: - | #<pr-number>
- Location: <ruta-archivo>:<líneas>
- Description: <descripción breve>
- Impact: <qué o quién es afectado>
- Business rules: <reglas de negocio específicas, restricciones y reglas de dominio>
- Acceptance criteria: <qué debe ser verdadero para que la issue se considere completa>
- Suggested fix: <enfoque o siguiente paso>
```

## Ciclo de Vida

```
backlog -> ready -> open -> in-progress -> in-review -> in-qa -> in-publish -> resolved
```

| Status | Significado |
|--------|-------------|
| `backlog` | Capturado, aún no refinado |
| `ready` | Claro, aprobado, testeable — listo para ejecución |
| `open` | Seleccionado, esperando creación remota |
| `in-progress` | Issue remota existe, trabajo iniciado |
| `in-review` | Senior review completado, esperando QA |
| `in-qa` | QA verificando post-review (puede volver a `in-progress`) |
| `in-publish` | Committer aprobó, MR creado, esperando merge |
| `resolved` | MR aprobado y fusionado (movido a archivo) |

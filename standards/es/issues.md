# Seguimiento de Issues

Seguimiento en dos niveles:
- **Global**: `~/.config/opencode/known_issues.md` — issues de configuración de opencode
- **Proyecto**: `<proyecto>/.opencode/known_issues.md` — issues específicas del proyecto

## Formato de Entrada

```markdown
### <id>. <título>
- Status: backlog | ready | open | in-progress | in-review | in-qa | in-publish | resolved
- Opened: <YYYY-MM-DD> | -
- Ready: <YYYY-MM-DD> | -
- Started: <YYYY-MM-DD> | -
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
- Tests: <escenario → resultado, definidos durante el discovery>
- Suggested fix: <enfoque o siguiente paso>
```

### Timestamps (Opened / Ready / Started / Resolved + Durations)

Los timestamps de ciclo de vida por issue se almacenan como campos de la
entrada en `known_issues.md` (`- Opened:`, `- Ready:`, `- Started:`, en ese
orden después de `- Status:`) y se calculan/almacenan en el archivo de
resueltas al cierre (`- Resolved:` y `- Durations:`). Los escriben
directamente los scripts del pipeline — nunca mediante parsing de trailers de
commit (issue #24).

| Campo | Escrito por | Cuándo |
|-------|-------------|--------|
| `- Opened:` | `scripts/create_issue.sh` | al crear la issue remota con éxito (set-if-absent). `scripts/promote.sh` hace backfill set-if-absent en el modo 2 (ready → in-progress) con la fecha actual — aproximación documentada cuando la issue remota se creó antes de la función de timestamps (BR 3). |
| `- Ready:` | `scripts/promote.sh` | al transicionar backlog → ready (set-if-absent) |
| `- Started:` | `scripts/promote.sh` | al transicionar ready → in-progress (set-if-absent) |
| `- Resolved:` | `scripts/close_issue.sh` | al cierre (= fecha de cierre / hoy) |
| `- Durations:` | `scripts/close_issue.sh` | al cierre, en la entrada del archivo de resueltas — diferencia en días entre los timestamps, con parse anclado en UTC (`TZ=UTC date -d "$d" +%s`, robusto a DST) |

Componentes de `Durations`: `backlog` (Opened→Ready), `waiting`
(Ready→Started), `dev` (Started→Resolved), `total` (Opened→Resolved, relativo
a la fecha de cierre). Guards: un componente renderiza `-` cuando una fecha
está ausente o start > end (guardado ANTES de la división); `0d` cuando la
diferencia es cero; los valores están limitados a 0 (no negativos); cuando
TODAS las fechas están ausentes, el campo entero renderiza el literal
`- Durations: -`.

La escritura es idempotente (set-if-absent): re-ejecutar un script nunca
duplica ni sobrescribe timestamps existentes, y `close_issue.sh` nunca añade
una entrada duplicada en el archivo de resueltas. Los timestamps se aplican
solo a issues nuevas — las entradas existentes nunca se reescriben
retroactivamente.

### `Tests:` — estándar obligatorio de pruebas

`Tests:` es OBLIGATORIO en cada issue nueva, capturado durante el discovery
(QA pre-desarrollo, Fase 5) como líneas `escenario → resultado` — nunca
añadido ad-hoc durante el desarrollo. Los desarrolladores escriben pruebas
contra estos escenarios documentados en lugar de inventarlos sobre la marcha.

- Para tipos `doc`/`chore`, el literal `- Tests: -` está permitido (sin
  superficie de prueba).
- Para tipos `feat`/`bug`, al menos una línea `escenario → resultado` es
  OBLIGATORIA y el valor NUNCA puede ser `-`.
- La profundidad de escenarios es un PISO sin límite superior, por severidad:
  `critical`/`high` → ≥3 líneas `escenario → resultado`; `medium` → ≥2; `low`
  → ≥1. Si `- Severity:` está ausente en el momento de la validación del QA,
  se aplica el piso medio (≥2).
- La aplicación es **verificada por la revisión pre-desarrollo del QA
  (Fase 5) y por los senior reviewers** — NO aplicada por scripts.
- `Tests:` ausente o insuficiente encontrado durante senior review o QA
  post-revisión = `incomplete-spec` (brecha de discovery), NO un bug — la
  issue vuelve al refinamiento del discovery para capturar los escenarios
  ausentes.
- Se aplica a TODAS las issues nuevas; las issues existentes en curso no se
  reescriben retroactivamente.

> Follow-up (no forma parte de ningún gate): un gate opcional de
> `promote.sh`/lint podría aplicar `Tests:` mecánicamente en el futuro.

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

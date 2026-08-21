# Estándar de Entorno de Pruebas (test-env)

Entorno de pruebas versionado y verificado para el pipeline: `.nvmrc`,
`.node-version` y `.opencode/env-manifest.md` fijan y validan las versiones de
Node/Python/test-runner usadas para ejecutar la suite. Aplica a todo proyecto
que use `scripts/test-runner.sh` y al bootstrap de `scripts/init.sh`.

## Formato del manifest (`.opencode/env-manifest.md`)

El manifest es una **instancia de proyecto, committeada**. DEBE contener una
sección ESTRICTA machine-parseable además de la prosa con el procedimiento de
bootstrap. La sección estricta la parsea `scripts/test-runner.sh` — una línea
`key: range` por cada entrada, sin indentación, sin marcadores markdown:

```text
## Strict (machine-parseable)

node: >=20 <23
python: >=3.10 <4
test-runner: >=1.0
```

Claves soportadas: `node`, `python`, `test-runner`. SOLO se parsea la sección
estricta — las líneas de prosa que empiecen con una de esas claves (antes del
encabezado `## Strict` o después del siguiente encabezado `##`) se ignoran, así
que la prosa es libre. Los comentarios en línea `#` en las líneas de rango se
eliminan antes de validar (p. ej. `node: >=20 <23 # nvm 22`). Las claves
duplicadas dentro de la sección estricta emiten un warning y GANA el último
valor.

## Política de rangos

- **Los pines viven en archivos**: `.nvmrc` y `.node-version` fijan una versión
  concreta de Node (p. ej. `22`) para compatibilidad con nvm/fnm/mise.
- **Los rangos viven en el manifest**: el rango soportado (p. ej. `>=20 <23`)
  se declara en la sección estricta.
- **Pin ⊆ rango**: el pin de `.nvmrc`/`.node-version` DEBE satisfacer el rango
  `node` del manifest; el sync guard lo verifica.
- **Sintaxis de rango**: tokens de restricción separados por espacio `>=X`,
  `>X`, `<=X`, `<X`, `=X` o `X` puro (exacto). `>=20 <23` significa
  `20 <= v < 23`. Las versiones comparan como `x.y.z` (partes ausentes valen 0).
- **Rango malformado** (p. ej. `node: >=20 <`): el parser degrada con gracia —
  warning accionable, validación omitida, nunca crash.

## Sync guard

`scripts/test-runner.sh` compara, en `--status` y `--run`:

1. `.nvmrc` ↔ `.node-version` — ambos archivos de pin DEBEN tener la misma
   versión (comparada NORMALIZADA: `22` y `22.0.0` son iguales). Un archivo de
   pin VACÍO ya es un warning de consistencia (BR 1 exige una versión pinned).
2. pin `.nvmrc`/`.node-version` ↔ rango `node` del manifest — el pin DEBE
   satisfacer `pin ⊆ rango`.

Cualquier discrepancia emite un **warning de consistencia** (`sync guard: ...`)
en stderr. Nunca cambia el exit code y nunca bloquea la ejecución.

## Contrato de warnings

- Los warnings van al **stderr**, prefijados `[test-env] WARNING:`, y son
  **accionables**: versión actual + rango esperado + hint de instalación.
- Se emiten en **`--status` y `--run`** — NUNCA en `--check` (`--check` mantiene
  el stderr vacío incluso con el entorno desincronizado).
- **Política warning-only**: los exit codes `0/1/2/3` nunca cambian por los
  checks de entorno; `--status` siempre sale `0`.
- **Herramienta ausente** (`node`/`python3`): warning informativo, nunca error.
- **Manifest ausente/malformado**: warning + validación omitida, exit intacto.
- **Drift** (versiones del `.result` cacheado ≠ entorno actual): warning en
  `--status`, no bloqueante.

## Metadatos de versión

Todo `.result` del caché registra las versiones realmente usadas:

```text
node_version=v22.3.1
python_version=3.12.0
runner_version=1.0.0
```

Los reportes de prueba DEBEN incluir un campo `Version:` obtenido de la salida
de `--status` o de los metadatos del `.result`, para que las etapas posteriores
del pipeline nunca re-pregunten qué versión ejecutó la suite.

## Fingerprint

`.nvmrc`, `.node-version` y `.opencode/env-manifest.md` están **excluidos del
fingerprint**: cambiar metadatos de entorno nunca invalida el caché de
resultados — solo los cambios de código/pruebas lo invalidan.

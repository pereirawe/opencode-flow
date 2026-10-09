# Formato

Ejecuta el formateador del proyecto antes de commitear, para que el
código/changelog entre siempre formateado, sin disciplina por proyecto ni
configuración manual.

Issue: #246.

## `scripts/format.sh`

`scripts/format.sh` detecta el formateador del proyecto, lo ejecuta sobre los
archivos seleccionados y degrada con elegancia cuando no hay ningún binario
instalado.

```
scripts/format.sh [--staged | --all | --diff <range>] [--check]
```

| Flag | Significado |
|------|-------------|
| `--staged` | Formatea solo archivos en stage (`git diff --cached --diff-filter=ACMR`). Por defecto. |
| `--all` | Formatea todo archivo rastreado (`git ls-files`). |
| `--diff <range>` | Formatea los archivos cambiados en un rango git, p. ej. `main...HEAD`. |
| `--check` | No escribe; sale distinto de cero cuando hay formato pendiente. |

Códigos de salida: `0` éxito o skip elegante; `1` `--check` encontró cambios
pendientes; `3` error de uso.

## Detección

La detección es por grupo de archivos; cada grupo cuyo binario está disponible
se ejecuta (y, para Prettier, cuyo opt-in del proyecto existe). Los grupos sin
formateador se omiten (el script nunca instala nada).

| Grupo | Formateador | Archivos |
|-------|-------------|----------|
| Prettier | `npx --no-install prettier`, si no `prettier` — **solo cuando el proyecto opta** | `.js .jsx .ts .tsx .mjs .cjs .json .css .scss .less .md .markdown .yml .yaml .html .htm .vue .svelte` |
| Go | `gofmt` | `.go` |
| Shell | `shfmt` | `.sh .bash` |
| Python | `ruff format`, si no `black` | `.py` |

Prettier solo se ejecuta cuando el proyecto lo configura: un archivo
`.prettierrc*`, un `prettier.config.*` o una clave `prettier` en `package.json`
(el `.prettierrc*`/`prettier.config.*` del proyecto se respeta automáticamente).
Esto evita reformatear proyectos que no usan Prettier solo porque hay un
`prettier` global en el `PATH`. Los grupos Go, shell y Python se ejecutan
siempre que el binario esté disponible.

`node_modules/`, `vendor/`, `dist/`, `build/` y `.git/` nunca se formatean.
Cuando no se formatea nada, `format.sh` sale `0` con un mensaje de skip —
`[format] no supported formatter found for <mode> files — skipping` (ningún
binario) o `[format] no eligible <mode> files for the available formatter(s) —
skipping` (hay herramienta pero ningún archivo candidato). La ausencia de
formateador nunca bloquea un commit.

## Integración

- `scripts/pre_commit.sh` ejecuta `format.sh --staged` **antes** del paso de
  tests y re-agrega **solo los archivos que el formateador reescribió** y que no
  tenían cambios sin-stage previos (`git add -- <file>`), para que el formato
  entre en el mismo commit sin commitear hunks parcialmente en stage por
  accidente. Un `format.sh` o formateador ausente no bloquea.
- `scripts/committer-check.sh` ejecuta `format.sh --diff <base>...HEAD --check`
  (con fallback a `--staged --check`) como **WARN no bloqueante**:
  `GATE: WARN — formatting changes pending` nunca cambia el veredicto a FAIL.

## Tests

`scripts/tests/test_format.sh` usa shims falsos de formateador en el `PATH`, así
que no requiere Prettier/gofmt/shfmt/ruff/black instalados.

```bash
bash scripts/tests/test_format.sh
```

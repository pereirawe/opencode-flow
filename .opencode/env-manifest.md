# Environment Manifest

Instancia del entorno de pruebas del proyecto (committeado). La sección
STRICTA de abajo es parseada por `scripts/test-runner.sh` para comparar las
versiones realmente usadas contra los rangos soportados — no cambies el
formato de esas líneas. El resto del archivo es prosa libre.

## Strict (machine-parseable)

node: >=20 <23
python: >=3.10 <4
test-runner: >=1.0

## Bootstrap

1. **Node (pinned 22)** — instalar y activar la versión pinned:
   `nvm install 22 && nvm use` (o `fnm use` / `mise use node@22`). Los archivos
   `.nvmrc` y `.node-version` fijan el pin; el rango soportado vive aquí.
2. **Python** — crear un venv con una versión en rango (`>=3.10 <4`):
   `python3 -m venv .venv && .venv/bin/pip install -e ".[dev]"`.
3. **Test runner** — ejecutar la suite con `bash scripts/test-runner.sh --run`
   (o `bash scripts/test-runner.sh --status` para ver el estado del entorno).
4. **Reportes** — registrar siempre el campo `Version:` en los reportes de test
   usando la salida de `--status` (o los metadatos del `.result` cacheado).

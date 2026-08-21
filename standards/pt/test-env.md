# Padrão de Ambiente de Testes (test-env)

Ambiente de testes versionado e verificado para o pipeline: `.nvmrc`,
`.node-version` e `.opencode/env-manifest.md` fixam e validam as versões de
Node/Python/test-runner usadas para executar a suíte. Aplica-se a todo projeto
que usa `scripts/test-runner.sh` e ao bootstrap de `scripts/init.sh`.

## Formato do manifest (`.opencode/env-manifest.md`)

O manifest é uma **instância de projeto, committeada**. DEVE conter uma seção
STRICTA machine-parseable além da prosa com o procedimento de bootstrap. A
seção estrita é parseada por `scripts/test-runner.sh` — uma linha
`key: range` por vez, sem indentação, sem marcadores markdown:

```text
## Strict (machine-parseable)

node: >=20 <23
python: >=3.10 <4
test-runner: >=1.0
```

Chaves suportadas: `node`, `python`, `test-runner`. APENAS a seção estrita é
parseada — linhas de prosa que comecem com uma dessas chaves (antes do
cabeçalho `## Strict` ou depois do próximo cabeçalho `##`) são ignoradas, então
a prosa é livre. Comentários inline `#` nas linhas de faixa são removidos antes
da validação (ex.: `node: >=20 <23 # nvm 22`). Chaves duplicadas dentro da
seção estrita emitem um warning e o ÚLTIMO valor vence.

## Política de faixas (ranges)

- **Pins vivem em arquivos**: `.nvmrc` e `.node-version` fixam uma versão
  concreta de Node (ex.: `22`) para compatibilidade com nvm/fnm/mise.
- **Faixas vivem no manifest**: a faixa suportada (ex.: `>=20 <23`) é declarada
  na seção estrita.
- **Pin ⊆ faixa**: o pin de `.nvmrc`/`.node-version` DEVE satisfazer a faixa
  `node` do manifest; o sync guard verifica isso.
- **Sintaxe de faixa**: tokens de restrição separados por espaço `>=X`, `>X`,
  `<=X`, `<X`, `=X` ou `X` puro (exato). `>=20 <23` significa `20 <= v < 23`.
  Versões comparam como `x.y.z` (partes ausentes valem 0).
- **Faixa malformada** (ex.: `node: >=20 <`): o parser degrada com graça —
  warning acionável, validação pulada, nunca crash.

## Sync guard

`scripts/test-runner.sh` compara, em `--status` e `--run`:

1. `.nvmrc` ↔ `.node-version` — os dois arquivos de pin DEVEM ter a mesma
   versão (comparação NORMALIZADA: `22` e `22.0.0` são iguais). Um arquivo de
   pin VAZIO já é um warning de consistência (BR 1 exige versão pinned).
2. pin `.nvmrc`/`.node-version` ↔ faixa `node` do manifest — o pin DEVE
   satisfazer `pin ⊆ faixa`.

Qualquer divergência emite um **warning de consistência** (`sync guard: ...`)
no stderr. Nunca altera o exit code e nunca bloqueia a execução.

## Contrato de warnings

- Warnings vão para o **stderr**, prefixados `[test-env] WARNING:`, e são
  **acionáveis**: versão atual + faixa esperada + hint de instalação.
- Emitidos em **`--status` e `--run`** — NUNCA em `--check` (`--check` mantém o
  stderr vazio mesmo com ambiente dessincronizado).
- **Política warning-only**: os exit codes `0/1/2/3` nunca são alterados pelos
  checks de ambiente; `--status` sempre sai `0`.
- **Ferramenta ausente** (`node`/`python3`): warning informativo, nunca erro.
- **Manifest ausente/malformado**: warning + validação pulada, exit intacto.
- **Drift** (versões do `.result` cacheado ≠ ambiente atual): warning em
  `--status`, não bloqueante.

## Metadados de versão

Todo `.result` do cache registra as versões realmente usadas:

```text
node_version=v22.3.1
python_version=3.12.0
runner_version=1.0.0
```

Relatórios de teste DEVEM incluir um campo `Version:` obtido da saída de
`--status` ou dos metadados do `.result`, para que etapas posteriores do
pipeline nunca re-perguntem qual versão executou a suíte.

## Fingerprint

`.nvmrc`, `.node-version` e `.opencode/env-manifest.md` são **excluídos do
fingerprint**: alterar metadados de ambiente nunca invalida o cache de
resultados — só mudanças de código/testes invalidam.

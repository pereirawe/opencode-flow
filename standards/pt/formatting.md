# Formatação

Rode o formatador do projeto antes de commitar, para que o código/changelog
entre sempre formatado, sem disciplina por projeto nem configuração manual.

Issue: #246.

## `scripts/format.sh`

`scripts/format.sh` detecta o formatador do projeto, roda sobre os arquivos
selecionados e degrada com elegância quando nenhum binário está instalado.

```
scripts/format.sh [--staged | --all | --diff <range>] [--check]
```

| Flag | Significado |
|------|-------------|
| `--staged` | Formata apenas arquivos em stage (`git diff --cached --diff-filter=ACMR`). Padrão. |
| `--all` | Formata todo arquivo rastreado (`git ls-files`). |
| `--diff <range>` | Formata os arquivos alterados num range git, ex. `main...HEAD`. |
| `--check` | Não grava; sai diferente de zero quando há formatação pendente. |

Exit codes: `0` sucesso ou skip gracioso; `1` `--check` achou mudanças
pendentes; `3` erro de uso.

## Detecção

A detecção é por grupo de arquivos; cada grupo cujo binário está disponível roda
(e, no caso do Prettier, cujo opt-in do projeto existe). Grupos sem formatador
são pulados (o script nunca instala nada).

| Grupo | Formatador | Arquivos |
|-------|-----------|----------|
| Prettier | `npx --no-install prettier`, senão `prettier` — **só quando o projeto opta** | `.js .jsx .ts .tsx .mjs .cjs .json .css .scss .less .md .markdown .yml .yaml .html .htm .vue .svelte` |
| Go | `gofmt` | `.go` |
| Shell | `shfmt` | `.sh .bash` |
| Python | `ruff format`, senão `black` | `.py` |

O Prettier só roda quando o projeto o configura: um arquivo `.prettierrc*`, um
`prettier.config.*` ou uma chave `prettier` no `package.json` (o
`.prettierrc*`/`prettier.config.*` do projeto é respeitado automaticamente).
Isso evita reformatar projetos que não usam Prettier só porque existe um
`prettier` global no `PATH`. Os grupos Go, shell e Python rodam sempre que o
binário está disponível.

`node_modules/`, `vendor/`, `dist/`, `build/` e `.git/` nunca são formatados.
Quando nada é formatado, `format.sh` sai `0` com uma mensagem de skip —
`[format] no supported formatter found for <mode> files — skipping` (nenhum
binário) ou `[format] no eligible <mode> files for the available formatter(s) —
skipping` (existe ferramenta, mas nenhum arquivo candidato). A ausência de
formatador nunca bloqueia um commit.

## Integração

- `scripts/pre_commit.sh` roda `format.sh --staged` **antes** do passo de testes
  e re-adiciona **apenas os arquivos que o formatador reescreveu** e que não
  tinham mudanças não-staged prévias (`git add -- <file>`), para a formatação
  entrar no mesmo commit sem nunca commitar hunks parcialmente em stage por
  acidente. `format.sh` ou formatador ausente não bloqueia.
- `scripts/committer-check.sh` roda `format.sh --diff <base>...HEAD --check`
  (com fallback para `--staged --check`) como **WARN não-bloqueante**:
  `GATE: WARN — formatting changes pending` nunca muda o veredito para FAIL.

## Testes

`scripts/tests/test_format.sh` usa shims falsos de formatador no `PATH`, então
não exige Prettier/gofmt/shfmt/ruff/black instalados.

```bash
bash scripts/tests/test_format.sh
```

# WIP List — Pendências e Próximas Features

## Issues ativas em `known_issues.md`

| # | Título | Status | Prioridade |
|---|--------|--------|------------|
| 4 | Add tech-lead agent role to pipeline | backlog | low |
| 7 | Align global config with latest OpenCode docs | in-progress | high |
| 8 | Create project bootstrap template | in-progress | high |
| 9 | Multi-locale standards system | in-progress | medium |

## Pendências estruturais (não viram issues)

- **Tech Lead ausente** — Item 13 passo 5 do fluxo original. Não há `agents/tech-lead.md`. Issue #4 cobre isso.
- **Itens 7-11 conceituais** — Auto-reparo, auto-proteção, auto-evolução. Fora de escopo por ora.

---

## Features Implementadas

### ✅ E — Tracker maintenance (`/roc:maintain`)

- `commands/roc:maintain.md` — comando para manutenção completa de `known_issues.md` + `wip/list.md`
- `scripts/maintain.sh` — checa remote states, detecta stale entries, reporta mismatches
- `Makefile` — target `make maintain`
- `opencode.json` — registrado comando `roc:maintain`

### ✅ A — Branch review naming convention

Review output agora segue `<modelo>_<branch>_issues.md`:
- `commands/roc:review-branch.md` — output template atualizado com modelo + branch
- `standards/issues.md` — documentado o padrão de nomenclatura

### ✅ B — Resolved issue archive

- `standards/resolved-issue.md` — template compacto criado
- `scripts/close_issue.sh` — agora arquiva em `resolved_issues.md` ao fechar (prepend, mais recente primeiro)
- `scripts/config.sh` — adicionado `RESOLVED_FILE` (global ou project-level)
- `known_issues.md` — footer com referência ao archive
- `commands/roc:archive-issue.md` — comando documentado
- Arquivo de resolvidas: `resolved_issues.md` na raiz do config

### ✅ C — Remote integration (GitLab / GitHub)

- `standards/issues.md` — campo `Remote:` documentado como obrigatório
- `commands/roc:promote.md` — flow atualizado com criação de remote issue
- `commands/roc:review-branch.md` — comentar no PR/MR adicionado às responsabilidades
- `agents/publish-requester.md` — remote detection (gh/glab via `git remote` + AGENTS.md)
- `commands/roc:sync-issues.md` — novo comando para sync bidirecional
- `skills/issue-manager/SKILL.md` — regras de remote sync adicionadas
- `scripts/create_issue.sh` — já criava remote issues (confirmado)
- `scripts/close_issue.sh` — já fechava remote issues (confirmado)

### ✅ D — Commit flags para atualização de status

- `commands/roc:commit.md` — novo comando com template + trailers automáticos
- `standards/commits.md` — seção de trailer flags adicionada (`Status:`, `Remote:`, `Closes`)
- `agents/publish-requester.md` — trailers no commit body adicionados às responsabilidades
- `scripts/pre_commit.sh` — validação de trailers (detecta `Status:`, `Closes`, issue references)
- `opencode.json` — registrados comandos `roc:commit`, `roc:sync-issues`, `roc:archive-issue`

---

## Ordem sugerida (próximos passos)

1. **Issue #7** — Alinhar config com schema OpenCode (crítico)
2. **Issue #8** — Bootstrap template (finalizar)
3. **Issue #9** — Multi-locale (finalizar)
4. **Issue #4** — Tech Lead agent (baixa prioridade)

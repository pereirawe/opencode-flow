# OpenCode Project Configuration

[![Version](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fraw.githubusercontent.com%2Fpereirawe%2Fopencode-flow%2Fmain%2Fpackage.json&query=%24.version&label=version&color=blue)](https://github.com/pereirawe/opencode-flow/releases)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen)](CONTRIBUTING.md)
[![GitHub stars](https://img.shields.io/github/stars/pereirawe/opencode-flow?style=social)](https://github.com/pereirawe/opencode-flow/stargazers)
[![GitHub last commit](https://img.shields.io/github/last-commit/pereirawe/opencode-flow)](https://github.com/pereirawe/opencode-flow/commits/main)
[![GitHub Discussions](https://img.shields.io/badge/discussions-welcome-brightgreen)](https://github.com/pereirawe/opencode-flow/discussions)

**Version:** 2.2.0 — [License](LICENSE) (MIT)

Configuração multi-setor para OpenCode com agentes C-level, skills especializadas
e pipeline de desenvolvimento completo. Vive em `~/.config/opencode/` e é
carregado automaticamente como **config global**.

## Installation

### Quick install (curl | bash)

```bash
curl -fsSL https://raw.githubusercontent.com/pereirawe/opencode-flow/main/install.sh | bash
```

With options:

```bash
curl -fsSL https://raw.githubusercontent.com/pereirawe/opencode-flow/main/install.sh | bash -s -- --branch=v1.0.0 --dir=$HOME/.config/opencode
```

### Manual

```bash
git clone --depth 1 https://github.com/pereirawe/opencode-flow ~/.config/opencode
```

## Updating

```bash
bash ~/.config/opencode/scripts/update.sh          # update to latest
bash ~/.config/opencode/scripts/update.sh --check   # check only
```

Or via Make:

```bash
make -C ~/.config/opencode update
```

## Estrutura

| Caminho | Propósito |
|---------|-----------|
| `AGENTS.md` | Entrypoint instructions |
| `opencode.json` | Configuração OpenCode + comandos + permissões |
| `workflow.md` | Pipeline de desenvolvimento (descoberta → MR) |
| `architecture.md` | Visão técnica e decisões estruturais |
| `conventions.md` | Convenções e boas práticas |
| `decisions.md` | Architecture Decision Records |
| `known_issues.md` | Rastreador de issues ativas |
| `prioritization.md` | Propostas de priorização do PO |
| `resolved_issues.md` | Issues resolvidas (formato compacto) |
| `VERSION` | Versão atual |
| `LICENSE` | MIT License |
| `agents/` | **88 agentes** em 8 setores + 5 C-levels |
| `commands/` | Documentação de comandos `/ocf:*` |
| `skills/` | **68 skills** reutilizáveis por setor |
| `scripts/` | Shell helpers (issue lifecycle + setup web) |
| `standards/` | Padrões de desenvolvimento (branching, commits, PR, issues, code-review) + traduções locale |
| `.opencode/` | Bootstrap template (copiar para outros projetos) |
| `docs/` | Documentação de fluxos do pipeline (`docs/flows.md`) |

### Agentes por Setor

| Setor | Agentes | Skills | C-Level |
|-------|---------|--------|---------|
| **C-Level** | ceo, cto, cfo, cmo, coo | — | Estratégico |
| **Development** | 15 agentes (developer, cto, po, pm, qa, committer, publish, close, docs, devs/*, senior-reviewers/*) | 9 skills (Go, Python) | `cto` |
| **Marketing** | 23 agentes (seo, ads, cro, copywriting, content, email, analytics, social, video, etc.) | 25 skills | `cmo` |
| **Sales** | 10 agentes (pipeline, prospecting, enablement, proposals, discovery, closing, negotiation, etc.) | 6 skills | — |
| **Finance** | 6 agentes (modeling, budgeting, cost, revenue, reporting, cfo) | 6 skills | `cfo` |
| **Commercial** | 6 agentes (pricing, deal-desk, partnerships, channel, forecasting, rfp) | 6 skills | — |
| **BI** | 5 agentes (analytics-engineering, dashboard, data-analysis, automation, governance) | 5 skills | — |
| **Business Ops** | 6 agentes (process-mapper, vendor, capacity, comms, knowledge, procurement) | 6 skills | `coo` |
| **Shared** | — | 5 skills (issue-manager, graphify, locale-loader, skill-importer, skill-creator) | — |

### C-Level Team

| Agente | Domínio | Delega para |
|--------|---------|-------------|
| `ceo` | Estratégia global, board, OKRs | Todos os setores |
| `cto` | Tecnologia, arquitetura, engenharia | `development/*` |
| `cfo` | Finanças, fundraising, M&A | `finance/*`, `commercial/*` |
| `cmo` | Marketing, growth, marca | `marketing/*` |
| `coo` | Operações, processos, eficiência | `business-ops/*` |

## Usage

```bash
make scan-issues        # static analysis + prompt /ocf:scan-issues
make review             # show git diff + prompt /ocf:review-branch
make promote id=<n>     # promote backlog item to open
make close-issue id=<n> # close + archive issue
make maintain           # scan for stale entries + prompt /ocf:maintain
make bootstrap target=<path>  # copy .opencode/ template to project
make init target=<path> # init project with repo context
```

## Slash Commands

| Command | Purpose |
|---------|---------|
| `/ocf:init` | Initialize `.opencode/` project config |
| `/ocf:scan-issues` | Deep codebase analysis and issue detection |
| `/ocf:review-branch` | Full PR/MR-style code review |
| `/ocf:review-external` | External branch/MR review with structured report |
| `/ocf:discovery [proposal\|id]` | Run discovery — routes by Type+severity into a LOOP (feat-full / bug-expedite / bug-lean / chore) and writes a canonical, linted issue |
| `/ocf:plan-feature` | Alias of `/ocf:discovery` for feature planning |
| `/ocf:promote <id>` | Promote backlog item + create remote issue |
| `/ocf:develop [id...]` | Run the lifecycle up to MR (flattened engine: dev → parallel reviewers → committer-check → create-pr), then STOP for manual merge |
| `/ocf:develop-full [id...]` | End-to-end for one or more issues (flattened engine → auto-merge → close+archive). Agents only for judgment |
| `/ocf:commit` | Create structured commit with status trailers |
| `/ocf:sync-issues` | Sync known_issues with remote tracker |
| `/ocf:archive-issue <id>` | Archive resolved issue to compact format |
| `/ocf:close-issue <id>` | Close remote issue and archive after PR merge |
| `/ocf:check-pr [id]` | Check PR merge status and auto-archive merged |
| `/ocf:maintain` | Full maintenance of tracker files |
| `/ocf:backup` | Create timestamped backup excluding junk |
| `/ocf:bump-version` | Calculate version bump, update changelog, commit, tag, and publish to main |

## Como Usar os Agentes

```bash
# C-Level (estratégico)
@ceo    "Planeje o próximo quarter com metas por setor"
@cto    "Revise a arquitetura do projeto X"
@cfo    "Prepare o board deck mensal"
@cmo    "Estratégia de lançamento do produto Y"
@coo    "Mapeie o processo de onboarding do cliente"

# Execução tática por setor
@marketing/seo   "Audite o SEO do site"
@sales/pipeline  "Previsão de receita para o mês"
@finance/budgeting "Análise de variância do orçamento"
@bi/dashboard-design "Crie um dashboard de KPIs"
```

## Pipeline in Action

This project dogfoods its own pipeline. Here's a real cycle (v1.4.2 release):

```
# 1. DISCOVERY — identify improvement (remove unused locale dirs)
→ PO identifies the need (fr/de/ja/zh standards are stale)
→ CTO/Tech Lead validate minimal impact
→ QA confirms no breaking changes
→ PM promotes: issue registered in known_issues.md

# 2. DEVELOPMENT — implement + auto-proceed to review
→ Developer removes 4 locale dirs, updates opencode.json
→ Tests run, self-review passes
→ Status → in-review (no pause, no asking)

# 3. PUBLISHING — gate → MR → release
→ Committer verifies: senior review done, QA passed, tests passing
→ Publish Requester creates MR (chore: remove unused locales)
→ MR merged to main
→ Maintainer runs: /ocf:bump-version
```

```
$ /ocf:bump-version
  Current VERSION: 1.4.1
  Last tag: v1.4.1
  Commits since tag: 1 (chore)
  Suggested: 1.4.2 (patch)
  
  Confirm bump to 1.4.2? [Y/n]: Y
  
  ✓ VERSION updated: 1.4.1 → 1.4.2
  ✓ README.md version badge updated
  ✓ CHANGELOG.md entry added
  ✓ Commit: chore: bump version to 1.4.2
  ✓ Tag: v1.4.2
  ✓ Push to origin/main --tags
  ✓ GitHub Release created: v1.4.2
  → https://github.com/pereirawe/opencode-flow/releases/tag/v1.4.2
```

Every change in this repo follows the same lifecycle. See `workflow.md` for the complete pipeline definition.

## Pipeline Overview

The pipeline is split into **Init/Bootstrap** (prepare a project), **Discovery**
(turn an idea into a tracked, linted issue) and **Delivery** (turn an issue into
a merged, archived MR). All stages are token-optimized: mechanical steps are
scripts, agents appear only for judgment. The full textual breakdown, with
diagrams per stage, lives in [`docs/flows.md`](docs/flows.md).

### End-to-end

```mermaid
flowchart TD
  subgraph SETUP["Init / Bootstrap"]
    I1["make init target=... (init.sh)"]
  end
  subgraph DISC["Discovery"]
    D1["/ocf:discovery"] --> D2{"Type + Severity"}
    D2 --> D3["Loop + append-issue.sh + issue-lint.sh --strict"]
    D3 --> D4["Loop error review (#244)"]
  end
  subgraph DELIV["Delivery"]
    V1["promote.sh + create_issue.sh"] --> V2["preflight.sh"]
    V2 --> V3["detect-lang.sh → dev agent"]
    V3 --> V4["Developer: implementa + testes"]
    V4 --> V5["Senior reviewers em PARALELO"]
    V5 -->|issues| V4
    V5 -->|aprova| V6["committer-check.sh + issue-lint.sh --strict"]
    V6 --> V7["create-pr.sh (MR)"]
  end
  subgraph PUB["Publish"]
    P1["develop-full: merge-and-close.sh → archive"]
    P2["develop: MR aberto → /ocf:check-pr"]
  end
  I1 --> D1
  D4 --> V1
  V7 --> P1
  V7 --> P2
```

### Init / Bootstrap

`/ocf:init` (ou `make init target=<path> [locale=xx]`) copia o template
`.opencode/` **sem sobrescrever** arquivos do projeto, resolve o locale em 4
níveis (argumento → locale do projeto → global → `en`), injeta o contexto git no
`AGENTS.md`, faz um sweep reduzido (nunca remove `standards/`, `README.md` ou
`resolved_issues.md`) e configura LSP **opt-in** (`INIT_CONFIGURE_LSP=1`).
Template obrigatório ausente aborta com `FATAL` sem escrita parcial.

### Discovery — loops by Type + Severity

Bugs and features do **not** share a flow. Discovery selects a LOOP from
`- Type:` + `- Severity:` (see `workflow.md` § Loop Profiles). Bugs trade depth
for **speed** but keep a **higher quality bar**; feats keep full depth.

```mermaid
flowchart TD
  A[Proposal or existing issue] --> B{Type + Severity}
  B -->|feat| C[feat-full: PO rules+Tests → TL branch/reviewers]
  B -->|bug critical/high| D[bug-expedite: PO triage → 2 reviewers + security]
  B -->|bug low/medium| E[bug-lean: PO triage → 1 reviewer]
  B -->|doc/chore| F[chore: script only]
  C --> G[append-issue.sh → issue-lint.sh --strict → ready]
  D --> G
  E --> G
  F --> G
  G --> H[Loop error review #244]
```

Every loop ends by writing a **canonical** entry (`scripts/append-issue.sh`) and
validating it (`scripts/issue-lint.sh`) — no free-form PO/PM prose, no separate
QA-agent pass. PM and remote creation are deferred to promotion.

### Loop Error Review (#244)

Cada loop registra falhas em um journal JSONL
(`.opencode/loop-journal/loop-<loop>-<id>.jsonl`); o agente
`development/loop-error-reviewer` usa `scripts/loop-error-triage.sh` para
classificar e **registrar issues** no tracker **global** (config do opencode) ou
do **projeto** onde o loop rodou. Manualmente: `/ocf:triage-errors`.

```mermaid
flowchart TD
  A["Falha em alguma fase do loop"] --> B["loop-journal.sh append (JSONL)"]
  B --> C["loop-error-triage.sh --plan"]
  C --> D{"Agente julga: acionável?"}
  D -->|"global (config/tooling)"| E["append-issue.sh → known_issues.md global"]
  D -->|"projeto (workspace)"| F["append-issue.sh → known_issues.md do projeto"]
  D -->|"ignorar/dup"| G["Descartado"]
```

Detalhes em [`docs/flows.md`](docs/flows.md) e `standards/loop-journal.md`.

### Delivery — flattened engine (develop / develop-full)

There is **no orchestrator agent** in the critical path. The command drives
scripts directly; `scripts/detect-lang.sh` picks the dev agent. Agents appear
only for implementation (developer) and parallel domain review (senior
reviewers).

```mermaid
flowchart LR
  P[promote.sh + create_issue.sh] --> W[preflight.sh: warm inventory]
  W --> L[detect-lang.sh → pick dev agent]
  L --> D[Developer: implement + tests]
  D --> FMT[pre_commit: format.sh --staged #246]
  FMT --> R[Senior reviewers in PARALLEL]
  R -->|issues| D
  R -->|approve| G[committer-check.sh + issue-lint.sh --strict]
  G -->|PASS| PR[create-pr.sh: MR]
  PR --> F[develop-full: merge-and-close.sh → archive]
  PR -->|develop| STOP[MR OPEN — manual merge]
```

- **`/ocf:develop-full`** runs the full chain including auto-merge + archive.
- **`/ocf:develop`** stops at MR creation (manual merge); closing is `/ocf:check-pr`.

### Gates — Committer + Formatter (#246)

Before commit/committer the project formatter runs automatically:
`scripts/format.sh` (Prettier only when configured, plus `gofmt`/`shfmt`/
`ruff`/`black`), wired into `scripts/pre_commit.sh` (re-stages rewritten files
with no pre-existing unstaged edits) and a non-blocking WARN in
`scripts/committer-check.sh`. See `standards/formatting.md`.

### Remote entry point — aibot-watcher (#39)

A systemd timer (`OnCalendar=*:0/2`) reads `@aibot:develop` comments on
allowlisted repos and runs the equivalent of `/ocf:develop-full`; failed runs
append to the loop journal so the Loop Error Review can triage them.

### Lifecycle

```mermaid
stateDiagram-v2
  [*] --> backlog
  backlog --> ready
  ready --> open
  open --> ip
  ready --> ip
  state "in-progress" as ip
  state "in-review" as ir
  state "in-qa" as iq
  state "in-publish" as ipb
  ip --> ir
  ir --> ip: correções
  ir --> iq
  iq --> ip: correções
  iq --> ipb
  ipb --> resolved: MR merged
  resolved --> [*]
```

Timestamps are stored with **date + time** (`YYYY-MM-DDTHH:MM`) so lifecycle
durations in `resolved_issues.md` are precise (hours for sub-day gaps).

The pipeline runs continuously after promotion — no user confirmation needed between steps.
See `workflow.md` and [`docs/flows.md`](docs/flows.md) for complete details.

## Web Service

O OpenCode pode rodar como serviço systemd para acesso web persistente:

```bash
# Instalar/atualizar o serviço
make setup-web

# Reiniciar após alterações de config, agents ou skills
make restart-web

# Acesso via navegador
http://<host>:4096
```

O template do serviço está em `scripts/opencode.service` e o instalador em
`scripts/setup-web.sh`. Compatível com qualquer ambiente Linux que tenha
systemd.

## Bootstrap a New Project

```bash
make bootstrap target=../my-project
```

This copies `.opencode/` template into the target project root.
See `.opencode/README.md` for details.

## License

MIT — see [LICENSE](LICENSE).
### Career (/cv) lean defaults

The career skills under `skills/career/*` now run LEAN by default — one
deterministic recommendation per section to save tokens and go straight to the
point. Where applicable, two flags control behavior:

- `expand=on` (or CLI `--expand`) — enables modest expansions (e.g. cv-linkedin
  increases headline variants up to 3, Featured up to 5, recruiter alerts up to
  5, DM templates up to 3; cv-tailor suggests placements for up to top‑15
  missing keywords instead of top‑5).
- `mode=pas` (or CLI `--mode pas`) — uses PAS (Problema → Agitação → Solução)
  for About/letter drafting in `cv-linkedin`/`cv-cover-letter`.

All shareable artifacts stay free of `[INFERIDO]`. Objective‑first behavior is
preserved: if `hub.profile_objective` is missing and the user does not answer a
single clarification, the assumed objective is declared explicitly at the top of
the report — never silently.

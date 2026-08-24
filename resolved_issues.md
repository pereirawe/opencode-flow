# Resolved Issues

Issues resolved from `known_issues.md`. See `standards/resolved-issue.md` for format.

### 215. cv-optimizer global score (qualificação total) sometimes 0 — empty sections must be excluded from the weighted average
- Resolved: 2026-08-24
- Durations: backlog=0d waiting=0d dev=0d review=- qa=- publish=0d total=0d
- Severity: medium
- Type: bug
- Report: william_pereira
- Reviewers: 2
- Remote: #131
- Summary: As a candidate, I want the optimizer's global score (qualificação total) to reflect a real weighted average, so that a strong profile is never reported as 0. Today the scoring protocol is ambiguous — Refine cv-optimizer/SKILL.md §3 (Profile score) — Global = weighted average over present/non-empty sections only (experience 1.5x, skills 1.5x, others 1x), the 0-global guard (only when every section is empty), and a worked example; document the exclusion rule in standards/cv-analysis.md §4.2; add regression assertions in scripts/tests/test_cv.sh; run `make test-scripts`. Effort ~2-3h.

### 214. Aplicar "Swiss Measure" al template del currículo — numerales tabulares, escala tipográfica tokenizada, negrita racionada, hairline endurecido y footer de página 2
- Resolved: 2026-08-24
- Durations: backlog=0d waiting=0d dev=0d review=0d qa=0d publish=0d total=0d
- Severity: medium
- Type: feat
- Report: william_pereira
- Reviewers: 2
- Remote: #129
- Summary: Implementar la dirección de diseño "Swiss Measure" del art-director (design_spec.json) en el template del currículo — (1) en resume.html

### 213. Refinar el patrón single-column ATS del currículo (jerarquía tipográfica, meta-línea con fechas alineadas, énfasis en métricas)
- Resolved: 2026-08-24
- Durations: backlog=0d waiting=0d dev=0d review=0d qa=0d publish=0d total=0d
- Severity: medium
- Type: feat
- Report: william_pereira
- Reviewers: 2
- Remote: #127
- Summary: Refinar el template de referencia del currículo (resume.html) y el estándar cv-design.md con un patrón single-column tipográfico refinado que respeta todas las reglas ATS — (1) refinar `skills/career/cv-pdf/templates/resume.html` (header lockup, `.entry-head` flex con fechas a la derecha, ritmo de espaciado, nota de `<strong>` para métricas) preservando las reglas de impresión; (2) actualizar `standards/cv-design.md` (§3 jerarquía + `.entry-head` + `<strong>`, §5 checklist); (3) añadir la instrucción de `<strong>` para métricas en cv-tailor skill y agent; (4) extender `scripts/tests/test_cv.sh` y correr `make test-scripts`. Esfuerzo ~3-5h. Origen

### 212. Gate de aplicación (umbral mínimo de match) + sección preferences en el hub + énfasis en logros cuantificados para cv-tailor y cv-cover-letter
- Resolved: 2026-08-24
- Durations: backlog=0d waiting=0d dev=0d review=0d qa=0d publish=0d total=0d
- Severity: medium
- Type: feat
- Report: william_pereira
- Reviewers: 2
- Remote: #125
- Summary: Mejorar el sector career del pipeline con tres cambios coordinados — (1) extender `schema.json` + `validate.py` (sección `preferences` + validación 0–100 y tipos); (2) documentar la sección en `cv-hub/SKILL.md`; (3) añadir el gate de aplicación y la priorización de logros cuantificados en `cv-tailor` y `cv-cover-letter` (skills, agents, commands); (4) documentar §3.5 + protocolo del gate en `standards/cv-analysis.md`; (5) extender `scripts/tests/test_cv.sh` y correr `make test-scripts`. Esfuerzo ~4-6h. Origen

### 83. Design sector documentation (READMEs, agent-skill mapping, standards)
- Resolved: 2026-08-21
- Type: doc
- Report: william_pereira
- Reviewers: 1
- Remote: #123
- Severity: medium
- Summary: Create design sector documentation — Create documentation files after #81, #82, and #83 are implemented (agents and commands must exist to be documented). Update parent READMEs and workflow.md. Register everything in opencode.json.

### 82. Model fallback mechanism for design agents
- Resolved: 2026-08-21
- Durations: backlog=0d waiting=0d dev=0d review=- qa=- publish=0d total=0d
- Severity: medium
- Type: feat
- Report: william_pereira
- Reviewers: 1
- Remote: #121
- Summary: Implement model fallback in the design pipeline. Instead of hardcoding `model — Remove any `model:` from agent frontmatter (should be done during #81 creation). Add model preference documentation to prompts. Independent of other issues but best done as part of #81.

### 81. /ocf:build-ui orchestration command + output file conventions
- Resolved: 2026-08-21
- Durations: backlog=0d waiting=0d dev=0d review=- qa=- publish=0d total=0d
- Severity: high
- Type: feat
- Report: william_pereira
- Reviewers: 2
- Remote: #119
- Summary: Create 2 orchestration commands and define output file conventions. `/ocf:build-ui` orchestrates the 4-pass greenfield pipeline; `/ocf:audit-ui` orchestrates audit+refactor. Output conventions define deterministic file paths for pipeline artifacts, enabling resumption and multi-model flows. — Create the 2 commands and `standards/design-pipeline.md`. Register in opencode.json. Update workflow.md. Depends on #81 and #82 (agents must exist before commands can invoke them).

### 80. Audit/Refactor agents (ui-auditor, ui-refactor-planner)
- Resolved: 2026-08-21
- Durations: backlog=0d waiting=0d dev=0d review=- qa=- publish=0d total=0d
- Severity: high
- Type: feat
- Report: william_pereira
- Reviewers: 2
- Remote: #117
- Summary: Create 2 agents for existing codebase refactoring — Create the 2 agents under `agents/design/` based on the drafts in `.opencode/adorable-proposal/` but rewritten in English, with no hardcoded model. Depends on #80 (skills) for token/component references that the planner consumes.

### 79. Greenfield pipeline agents (art-director, ui-architect, ui-implementer, ui-critic)
- Resolved: 2026-08-21
- Durations: backlog=0d waiting=0d dev=0d review=- qa=- publish=0d total=0d
- Severity: high
- Type: feat
- Report: william_pereira
- Reviewers: 2
- Remote: #115
- Summary: Create the core 4-pass Adorable pipeline — Create the 4 agents under `agents/design/` based on the drafts in `.opencode/adorable-proposal/` but rewritten in English, with no hardcoded model. Registration is file-based

### 78. Design sector skills (foundation for Adorable pipeline)
- Resolved: 2026-08-21
- Durations: backlog=0d waiting=0d dev=0d review=- qa=- publish=0d total=0d
- Severity: high
- Type: feat
- Report: william_pereira
- Reviewers: 2
- Remote: #113
- Summary: Create 4 skills under `skills/design/` that encode concrete, testable UI patterns for the Adorable pipeline. These skills are the foundation consumed by all 6 design agents — without them, agents produce generic UI. — Create the 4 skills under `skills/design/` with concrete patterns (not philosophy), English frontmatter, bilingual trigger keywords, and register in opencode.json. Reference vendor taste-skill/minimalist-ui for pattern examples but create original content.

### 209. Caché de credenciales git por proyecto (git creds cache)
- Resolved: 2026-08-21
- Durations: backlog=0d waiting=2d dev=0d review=- qa=- publish=0d total=2d
- Severity: high
- Type: feat
- Report: william_pereira
- Reviewers: 3
- Remote: #106
- Summary: Como agente del pipeline de opencode, quiero un caché de credenciales git por proyecto (`.opencode/cache/git/`) gestionado por un único script seguro, para autenticarme y crear commits en operaciones automáticas (`--auto`) sin prompts interactivos ni exposición de secretos en salidas, logs o fingerprints. — implementar `scripts/git-cred-cache.sh` como punto único de acceso (subcomandos `--init`/`--set`/`--get`/`--erase`/`--identity`/`--status`) con permisos 0700/0600 en cada escritura, redacción centralizada vía `redact_secret()` en `config.sh`, deny de read/edit sobre `.opencode/cache/**` con orden findLast para `--auto`, auto-import idempotente e integración git vía `credential.helper store` + `credential.interactive never`; ajustar permisos por agente (developer/committer/publish-requester), EXCLUDE_RE del test-runner y ADR en `standards/decisions.md`. Esfuerzo ~9-11h. Origem

### 208. Differentiated bug discovery flow — fast, prioritized, token-efficient (still refined)
- Resolved: 2026-08-21
- Durations: backlog=- waiting=- dev=0d review=- qa=- publish=0d total=2d
- Severity: high
- Type: feat
- Report: william_pereira
- Reviewers: 3
- Remote: #105
- Summary: As a Product Owner, I want a differentiated discovery flow for `bug` issues — a lean triage track (PO triage → QA pre-development → PM promotion, ≤3 agent invocations) with a documented prioritization score and a clear escalation path to the full 6-phase flow — so that bug issues reach development faster, are prioritized by business impact instead of insertion order, and consume at least 50% fewer discovery tokens than the full flow while remaining refined. — Effort ~9–10h across 9 tasks (T1–T9), branch `issue-208-bug-discovery-lean` off `main`:

### 210. Versionado del entorno de tests (test env)
- Resolved: 2026-08-21
- Durations: backlog=0d waiting=2d dev=0d review=- qa=- publish=0d total=2d
- Severity: medium
- Type: feat
- Report: william_pereira
- Reviewers: 2
- Remote: #107
- Summary: Como desarrollador y QA del pipeline de opencode, quiero un entorno de pruebas versionado y verificado (`.nvmrc`, `.node-version` y `.opencode/env-manifest.md`), para ejecutar la suite siempre contra versiones conocidas de Node/Python/test-runner y recibir advertencias no bloqueantes cuando haya discrepancias. — extender test-runner.sh con TEST_RUNNER_VERSION, detección de versiones, parser estricto del manifest y comparación de rangos, emitiendo advertencias accionables en `--status`/`--run` (nunca `--check`), metadatos de versión en `.result` y exclusión de `.nvmrc`/`.node-version`/env-manifest del fingerprint; crear `.nvmrc`, `.node-version` y `.opencode/env-manifest.md`, documentar el protocolo en `standards/test-env.md` (localizado pt/es/en) y en el SKILL del test-runner, y crear placeholders condicionales en init.sh. Esfuerzo ~8-9h. Origem

### 207. Standards (en/pt/es) fora do array `instructions` — loading via locale-loader (~22K tokens/sessão)
- Resolved: 2026-08-19
- Durations: backlog=0d waiting=0d dev=0d review=0d qa=0d publish=0d total=0d
- Severity: high
- Type: chore
- Report: cto
- Reviewers: 1
- Remote: #103
- Summary: O array `instructions` injeta `standards/*.md` (13 arquivos en ≈ 14K tokens) + `standards/pt/*` (~4K) + `standards/es/*` (~4K) em TODA sessão, totalizando ~22K tokens. O locale ativo é `pt`, mas en+es são carregados igualmente. O `locale-loader` skill já existe para carregar standards por demanda no idioma certo — o array `instructions` anula esse propósito e injeta traduções incompletas (pt/es sem seções `Tests:`/timestamps vs en completo). — Editar opencode.json:11-13 removendo os três globs de standards; garantir que AGENTS.md referencia locale-loader; validar com teste de config. Origem

### 34. `known_issues.md` global carregado como instrução para todos os projetos
- Resolved: 2026-08-19
- Durations: -
- Severity: low
- Type: chore
- Report: opencode
- Reviewers: 1
- Remote: -
- Summary: `opencode.json` inclui `~/.config/opencode/known_issues.md` no array `instructions`. Como a config é herdada por todos os projetos, as issues do opencode são injetadas no contexto de qualquer projeto que use esta config global. — Mover known_issues.md para fora de instructions, usando AGENTS.md para referenciá-lo apenas quando trabalhando no próprio opencode.

### 206. `prioritization.md` e `known_issues.md` no array `instructions` — carregamento por demanda em vez de injeção (~44,8K tokens/sessão)
- Resolved: 2026-08-19
- Durations: backlog=0d waiting=0d dev=0d review=- qa=0d publish=0d total=0d
- Severity: high
- Type: chore
- Report: cto
- Reviewers: 1
- Remote: #101
- Summary: O array `instructions` injeta `~/.config/opencode/known_issues.md` (~65 KB ≈ 17,1K tokens) e `~/.config/opencode/prioritization.md` (~105 KB ≈ 27,7K tokens) em TODA sessão, somando ~45% do contexto fixo. São artefatos de tracking/discovery lidos por demanda (padrão awk já usado nos comandos ocf:promote/develop/commit) — não precisam estar no contexto permanente. Resolve o problema já documentado na issue #34 (backlog). — Editar opencode.json:7,10 removendo os dois globs; manter instrução de leitura por demanda no AGENTS.md; fechar issue #34 como resolved. Origem

### 205. `instructions` array em opencode.json injeta glob `agents/*/*.md` — duplicação de agentes auto-registrados (~33,6K tokens/sessão)
- Resolved: 2026-08-19
- Durations: backlog=0d waiting=0d dev=0d review=- qa=- publish=0d total=0d
- Severity: high
- Type: chore
- Report: cto
- Reviewers: 1
- Remote: #99
- Summary: O array `instructions` em opencode.json (linha 8) inclui `~/.config/opencode/agents/*/*.md`, injetando os prompts completos de ~89 agentes (~127 KB ≈ 33,6K tokens) no contexto de TODA sessão. A documentação oficial do opencode confirma que arquivos em `~/.config/opencode/agents/` já são auto-registrados como subagentes (invocáveis via Task tool) — o glob é duplicação pura — Editar opencode.json:8 removendo o glob `~/.config/opencode/agents/*/*.md`; adicionar teste em scripts/tests/ que valide o array `instructions`. Origem

### 40. AIBot nativo em GitHub Actions / GitLab CI com imagem Docker do opencode config
- Resolved: 2026-08-17
- Durations: -
- Severity: critical
- Type: feat
- Report: PO
- Reviewers: 2
- Remote: #32
- Summary: Executar o pipeline de desenvolvimento completo em CI remoto (GitHub Actions / GitLab CI) ao detectar `@aibot:develop` em comentário de issue. O workflow usa uma **imagem Docker pre-built** do opencode config (`ghcr.io/pereirawe/opencode-flow:latest` + tag semver) que inclui opencode binary + config completa (agents, skills, commands, scripts, deny rules). O workflow roda `opencode run --command "ocf:develop" <id> --auto` em **modo headless** (sem `--attach`) no runner CI, cria a MR e o aibot comenta o link. Paralelismo massivo — Criar `Dockerfile` + `scripts/build-opencode-image.sh` (build GHCR + tag semver), `.github/workflows/aibot-develop.yml` (trigger issue_comment → filter `@aibot:develop` → allowlist/tracker gates → `opencode run` headless → MR + notify), validar modo headless em spike, documentar em `workflow.md` e `scripts/README.md`. O watcher local (issue 39) permanece como fallback.


### 27. `opencode.json` referencia `/temp/*` em vez de `/tmp/*`
- Resolved: 2026-08-17
- Durations: backlog=0d waiting=0d dev=0d total=0d
- Severity: low
- Type: bug
- Report: opencode
- Reviewers: 1
- Remote: -
- Summary: Correct `/temp/*` typo to `/tmp/*` in opencode.json line 291. Single-character fix for Linux temp directory path. PR #94 merged.

### 28. `close_issue.sh` fecha issue remota sem verificar merge do PR para status não-`in-publish`
- Resolved: 2026-08-17
- Durations: backlog=0d waiting=0d dev=0d total=0d
- Severity: medium
- Type: bug
- Report: opencode
- Reviewers: 1 (devops)
- Remote: -
- Summary: close_issue.sh already has all safety checks: rejects non-accepted statuses, verifies PR merge for in-publish, checks remote state for resolved, asks user confirmation, and continues local archive on remote failure. Code verified and syntax-checked.

### 37. Delegar `ocf:develop` para router e agentes Go/Python
- Resolved: 2026-08-17
- Durations: backlog=0d waiting=0d dev=0d total=0d
- Severity: medium
- Type: feat
- Report: opencode
- Reviewers: 1 (docs, runtime)
- Remote: -
- Summary: develop-router registered in opencode.json pointing to development/develop-router agent. Go and Python specialized agents exist with REGISTRY.md. Router has task permissions for development/devs/*. All components verified.

### 75. standards/cv-analysis.md lacks a report-type section for linkedin-optimization.md
- Resolved: 2026-08-17
- Durations: backlog=0d waiting=0d dev=1d total=1d
- Severity: low
- Type: doc
- Report: opencode
- Reviewers: 1
- Remote: -
- Summary: Add §3.4 to standards/cv-analysis.md documenting linkedin-optimization.md H2 section order; rename all career filenames to English (profile-analysis, inferences, resumes, interview-preparation); add explicit language rule. PR #93 merged.

Issues resolved from `known_issues.md`. See `standards/resolved-issue.md` for format.

### 73. Standardize project language to English (prompts, skills, docs, scripts) with locale-aware responses
- Resolved: 2026-08-17
- Durations: backlog=0d waiting=0d dev=0d total=0d
- Severity: high
- Type: feat
- Report: william_pereira
- Reviewers: 2 (docs, qa)
- Remote: -
- Summary: Rewrite ALL remaining Portuguese-language artifacts to English. Add canonical response-language rule to AGENTS.md. Ship scripts/tests/test_language.sh as language-conformance gate. Standards keep pt/es translations. PR #93 merged.

### 38. Criar agentes orquestradores Discovery e Delivery
- Resolved: 2026-08-17
- Durations: backlog=0d waiting=0d dev=0d total=0d
- Severity: medium
- Type: feat
- Report: william_pereira
- Reviewers: 1 (docs, runtime)
- Remote: -
- Summary: Create Discovery and Delivery orchestrator agents. Register ocf:discovery and ocf:delivery commands. Update READMEs and workflow.md. PR #93 merged.

### 20. Agente Anderson — feedback de usuário leigo nas MRs
- Resolved: 2026-08-17
- Durations: backlog=0d waiting=0d dev=0d total=0d
- Severity: medium
- Type: feat
- Report: PO
- Reviewers: 2 (qa, ux-ui)
- Remote: #20
- Summary: Create Anderson agent that posts automated PT-BR feedback on MRs. All 12 business rules implemented. PR #93 merged.

### 71. Keyword density and match percentage in gap analysis
- Resolved: 2026-08-17
- Durations: backlog=0d waiting=0d dev=2d total=2d
- Severity: medium
- Type: feat
- Report: william_pereira
- Reviewers: 1
- Remote: #87
- Summary: Enhance the cv-tailor gap analysis to include — Enhance cv-tailor skill/agent with keyword density and match percentage logic; update gap-analysis.md format in standards/cv-analysis.md. Execute after #64 and #65. Origem

### 36. `scan_issues.sh` usa globs hardcoded que não cobrem diretórios do projeto
- Resolved: 2026-08-17
- Durations: -
- Severity: low
- Type: chore
- Report: opencode
- Reviewers: 1
- Remote: -
- Summary: O script escaneia apenas `./src ./cmd ./internal ./*.go ./*.py ./*.js ./*.ts ./*.rs`. Projetos com layouts diferentes (monorepo, app/, lib/, scripts/) são ignorados. — Incluir scripts/ nos targets. Adicionar suporte a config `.opencode/scan-patterns` ou escanear a raiz com .gitignore-aware tool.

### 23. Instruções contraditórias para contagem de revisores entre command doc e opencode.json
- Resolved: 2026-08-17
- Durations: -
- Severity: high
- Type: bug
- Report: opencode
- Reviewers: 1
- Remote: #22
- Summary: commands/ocf:review-branch.md diz "Ask user for reviewer count (default 1)", enquanto opencode.json (fonte da verdade) diz "Read from `- Reviewers:` field; if absent or empty, default to 1 — do NOT ask the user." — Alinhar commands/ocf:review-branch.md com opencode.json — remover "Ask user" e usar leitura do campo na issue.

### 72. Technical corrections — validate.py, schema.json, agents/README, templates, curl security
- Resolved: 2026-08-16
- Durations: backlog=0d waiting=0d dev=1d total=1d
- Severity: medium
- Type: chore
- Report: william_pereira
- Reviewers: 1
- Remote: #89
- Summary: Bundle of technical corrections — Refactor validate.py to use schema.json; add format/cross-field validation; create agents/career/README.md; define README.md template; remove curl -L from cv-tailor. Execute after #64 (English schema). Origem

### 70. Hub update flow — incremental edits to existing hub.json
- Resolved: 2026-08-15
- Durations: backlog=0d waiting=0d dev=0d total=0d
- Severity: high
- Type: feat
- Report: william_pereira
- Reviewers: 2
- Remote: #85
- Summary: Create command `ocf:cv-hub-update <candidate-dir>`, enhancing the existing cv-hub flow to support incremental edits. The user provides new information (pasted text, new PDF, new file) and the agent updates the existing hub.json with the new entries (new experience, skill, certification, project) without recreating the entire hub. Alternatively, accept manual edits to hub.json and validate + regenerate README.md. Command can also be `ocf:cv-hub <dir> --update`. — Extend cv-hub skill/agent with update mode; create command (separate or --update flag); register in opencode.json with hub.json edit permission. Execute after #64 (English schema). Origem

### 69. ATS compatibility scoring of generated resume — ocf:cv-ats-score
- Resolved: 2026-08-15
- Durations: backlog=0d waiting=0d dev=0d total=0d
- Severity: medium
- Type: feat
- Report: william_pereira
- Reviewers: 1
- Remote: #83
- Summary: Create command `ocf:cv-ats-score <candidate-dir> <job-slug>`, agent `career/cv-ats-score`, skill `cv-ats-score`. Given a generated resume PDF (from cv-tailor) and the original job description, extract text from the PDF (pdftotext), analyze keyword density vs the job's requirements, detect ATS red flags (tables, images, multi-column, missing standard sections), and produce a score (0-100) + actionable recommendations. Output as `ats-score.md` in the job's slug directory. — Create agent, skill, command; register in opencode.json; use pdftotext for text extraction; compute score and recommendations. Execute after #64, #62, and #65. Origem

### 68. Interview preparation kit — ocf:cv-interview-prep
- Resolved: 2026-08-15
- Durations: backlog=0d waiting=0d dev=0d total=0d
- Severity: high
- Type: feat
- Report: william_pereira
- Reviewers: 1
- Remote: #81
- Summary: Create command `ocf:cv-interview-prep <candidate-dir> <job>`, agent `career/cv-interview-prep`, and skill `cv-interview-prep`. Given the candidate hub and a job description, generate — Create agent, skill, command; register in opencode.json. Execute after #64 and #65. Origem

### 67. LinkedIn profile optimization suggestions — ocf:cv-linkedin
- Resolved: 2026-08-15
- Durations: backlog=0d waiting=0d dev=0d total=0d
- Severity: high
- Type: feat
- Report: william_pereira
- Reviewers: 1
- Remote: #79
- Summary: Create command `ocf:cv-linkedin <candidate-dir> [<job>]`, agent `career/cv-linkedin`, and skill `cv-linkedin`. Given the candidate hub and optionally a target job, generate LinkedIn profile optimization suggestions — Create agent, skill, command; register in opencode.json. Execute after #64 and #65. Origem

### 66. Cover letter generation — ocf:cv-cover-letter
- Resolved: 2026-08-15
- Durations: backlog=0d waiting=0d dev=0d total=0d
- Severity: high
- Type: feat
- Report: william_pereira
- Reviewers: 2
- Remote: #77
- Summary: Create command `ocf:cv-cover-letter <candidate-dir> <job>`, agent `career/cv-cover-letter`, and skill `cv-cover-letter`. Given the candidate hub and a job description (same input as cv-tailor — pasted text, file, URL), generate a tailored cover letter in PDF (HTML→PDF via cv-pdf) in the job's language. Reuse the gap analysis from cv-tailor if available, or generate inline. Never fabricate content — only rephrase and highlight what exists in the hub. The cover letter follows the same design standard (standards/cv-design.md from #63) and analysis standard (standards/cv-analysis.md from #65). — Create agent, skill, command; register in opencode.json; reuse cv-pdf for PDF generation; follow cv-design.md and cv-analysis.md standards. Execute after #64 and #65. Origem

### 65. Standard structure for career sector analysis reports — standards/cv-analysis.md + report templates
- Resolved: 2026-08-15
- Durations: backlog=0d waiting=0d dev=0d total=0d
- Severity: high
- Type: feat
- Report: william_pereira
- Reviewers: 2
- Remote: #75
- Summary: Create `standards/cv-analysis.md` defining the canonical structure for ALL career sector report files — Create `standards/cv-analysis.md`; update cv-optimizer and cv-tailor skills/agents/commands to reference it; create HTML template for analise-perfil.html. Execute after #64. Origem

### 64. Standardize career sector language — English prompts, English hub.json schema, user-locale analysis outputs
- Resolved: 2026-08-15
- Durations: backlog=0d waiting=0d dev=0d total=0d
- Severity: critical
- Type: feat
- Report: william_pereira
- Reviewers: 2
- Remote: #71
- Summary: Rewrite ALL career sector prompts (agents, skills, commands, schema descriptions, validator messages) in English. Migrate hub.json keys and ENUM values from Portuguese to English. Add locale rule — Rewrite all career prompts in English; migrate schema.json keys/enums to English and update validate.py accordingly; update test_cv.sh fixtures; provide a migration helper (scripts/cv/migrate-schema.py or documented manual steps); verify opencode.json consistency. Coordinate merge order

### 75. Rename candidate directory root `~/carreira/` → `~/career/` (English standardization follow-up)
- Resolved: 2026-08-15
- Durations: backlog=0d waiting=0d dev=0d total=0d
- Severity: medium
- Type: chore
- Report: william_pereira
- Reviewers: 1
- Remote: #73
- Summary: Issue #64 standardized the career sector prompts/schema to English but the candidate directory root is still referenced as `~/carreira/<candidate-name>/` (Portuguese). Rename the directory root to `~/career/<candidate-name>/` across all career agents, skills, commands, opencode.json templates and permission rules, workflow.md, and test_cv.sh. — sed/string-replace `~/carreira/` → `~/career/` across the listed in-scope files; update opencode.json permission rules; update test_cv.sh fixture path; verify with grep + make test-scripts. Note

### 48. Sincronização bidirecional de issues com Jira Cloud (cards, status e comentários)
- Resolved: 2026-08-15
- Durations: backlog=- waiting=- dev=0d total=0d
- Severity: high
- Type: feat
- Report: PO
- Reviewers: 2
- Remote: #69
- Summary: Integrar o pipeline com Jira Cloud (REST v3) — (1) criar `scripts/sync-jira.sh` (core REST v3

### 49. Agente de setor OWASP e Cybersecurity (consultor + revisor + gate)
- Resolved: 2026-08-15
- Durations: backlog=- waiting=- dev=0d total=0d
- Severity: high
- Type: feat
- Report: PO
- Reviewers: 2
- Remote: #67
- Summary: Criar agente `development/security-owasp` (setor development) que consolida o perfil de segurança do pipeline — (1) criar `agents/development/security-owasp.md` com frontmatter (subagent, temperature 0.1, permission

### 57. Time-tracking fields in issue lifecycle (Opened/Ready/Started/Resolved + Durations)
- Resolved: 2026-08-14
- Durations: -
- Severity: medium
- Type: feat
- Report: william_pereira
- Reviewers: 2
- Remote: #65
- Summary: Add timestamp fields (Opened, Ready, Started) to the known_issues.md entry format, stamp them on script status transitions (promote.sh, create_issue.sh), stamp Resolved at close time, and compute stage durations (Durations) into the resolved archive so per-stage cycle time can be measured. — Add `Opened`/`Ready`/`Started` to the known_issues.md entry format and stamping logic in promote.sh (Ready on backlog→ready, Started on ready→in-progress, backfill `Opened` set-if-absent) and create_issue.sh (`Opened` on remote success); extend close_issue.sh to stamp `Resolved` and compute `Durations` using `TZ=UTC date -d "$d" +%s` with per-component guards/floors and the dup guard preserved; update standards/issues.md (en+pt+es) and standards/resolved-issue.md (en); add scripts/tests/test_timestamps.sh (t01–t25). Rebase onto #56 after it lands (shared standards/issues.md + workflow.md).

### 56. Mandatory `Tests:` field captured during discovery (test standards pre-development)
- Resolved: 2026-08-14
- Type: feat
- Report: william_pereira
- Reviewers: 2
- Remote: #63
- Severity: medium
- Summary: Make the `Tests:` field a mandatory part of every new issue entry, captured during discovery (QA pre-development, Phase 5), so developers write tests against documented `scenario → outcome` definitions instead of inventing them ad-hoc during development. — Update the known_issues.md header Format block and standards/issues.md (en+pt+es) with the `- Tests:` field, severity floors, and enforcement wording; document the incomplete-spec classification in workflow.md; write the QA pre-dev checklist into quality-analyst.md; add the `Tests:` capture step to product-owner.md and the Phase 5 validation step to discovery.md. No script changes. Follow-up (NOT in this issue)

### 63. Padrão de design de currículo ATS-friendly — standards/cv-design.md + template HTML/CSS de referência
- Resolved: 2026-08-14
- Type: feat
- Report: william_pereira
- Reviewers: 2
- Remote: #61
- Severity: high
- Summary: Added standards/cv-design.md with testable ATS/print/sober-style/page-count rules and the reference template skills/career/cv-pdf/templates/resume.html (A4 12-15mm, system fonts, single-column, no emoji/Google Fonts, @media print, locale-aware). cv-tailor now starts from the template and verifies conformity before PDF generation (never CSS from scratch); cv-pdf skill documents the standard. 64 tests green.

### 62. `[INFERIDO]` vaza para o HTML/PDF final do currículo gerado pelo cv-tailor (gate + fluxo de decisão humana)
- Resolved: 2026-08-14
- Type: bug
- Report: william_pereira
- Reviewers: 2
- Remote: #59
- Severity: critical
- Summary: Created `scripts/cv/check-inferido.sh` gate blocking [INFERIDO] (case-insensitive) in the final resume HTML/PDF — exit 1 listing occurrences, best-effort pdftotext. Reworked cv-tailor skill/agent/command prompts to resolve inferences with the candidate (inferences.md) before generation. cv-hub/cv-optimizer keep [INFERIDO] in internal artifacts; 46 tests green.

### 42. Agente designer + skills de design-taste para UI de frontend
- Resolved: 2026-08-14
- Type: feat
- Report: william_pereira
- Reviewers: 2
- Remote: #33
- Severity: medium
- Summary: Criar o agente `designer` (frontend product agent) que transforma descrições em UI funcional seguindo brief → explore → plan → build → review, e instalar as skills de design do repo `Leonxlnx/taste-skill` (design-taste-frontend default; redesign-existing-projects, minimalist-ui). O skill v2 obriga o agente a ler o brief, inferir a direção de design e só então gerar código. — (1) rodar `npx skills add https://github.com/Leonxlnx/taste-skill --skill design-taste-frontend` na raiz, (2) repetir para redesign-existing-projects e minimalist-ui, (3) criar `agents/designer.md` com o conteúdo fornecido, (4) registrar skills.paths se instalado fora do padrão, (5) documentar mapeamento de casos de uso.

### 61. Agente de otimização do perfil — análise, plano de ações, mercado salarial e vagas-alvo (ocf:cv-optimize)
- Resolved: 2026-08-13
- Type: feat
- Report: william_pereira
- Reviewers: 2
- Remote: #56
- Severity: high
- Summary: Criar o agente `career/cv-optimizer` + comando `ocf:cv-optimize <dir-candidato>` que roda após o `ocf:cv-hub` para aprimorar o perfil do candidato. Analisa qualificações gerais, calcula score do perfil (0-100 por seção + global), sugere perfis de vagas-alvo, avalia pretensão salarial de mercado CLT vs PJ (faixas `[INFERIDO]`), detecta lacunas de contexto no hub e gera um plano de ações priorizado. Entrega — (1) criar `agents/career/cv-optimizer.md` (subagent, temperature 0.2, edit apenas ~/carreira/**, deny "*" primeiro); (2) criar `skills/career/cv-optimizer/SKILL.md` (protocolo de análise

### 60. Hub de currículo + geração de currículo direcionado a vaga (ocf:cv-hub / ocf:cv-tailor)
- Resolved: 2026-08-13
- Type: feat
- Report: william_pereira
- Reviewers: 2
- Remote: #54
- Severity: high
- Summary: Fluxo multi-agente de otimização de currículos para contratação acelerada. Fase 1 (hub) — Criar `agents/career/cv-extractor.md`, `agents/career/cv-tailor.md`, `skills/career/cv-hub/SKILL.md`, `skills/career/cv-tailor/SKILL.md`, `skills/career/cv-pdf/SKILL.md`, `commands/ocf:cv-hub.md`, `commands/ocf:cv-tailor.md`, `scripts/cv/pdf.sh`, `scripts/cv/schema.json`; registrar comandos/agentes/skills no `opencode.json`; documentar no `workflow.md`/`standards/issues.md`. Origem

### 58. develop-router bloqueado: allow patterns bash usam paths relativos que não casam com invocação real
- Resolved: 2026-08-11
- Type: bug
- Report: william_pereira
- Reviewers: 2
- Remote: #50
- Severity: critical
- Summary: Corrige o bug crítico de permissão do `develop-router` que bloqueava toda promoção via `/ocf:develop` (allow patterns bash usavam paths relativos que nunca casavam com as invocações absolutas). `develop-router.md` e `delivery.md` agora usam padrões wildcard-prefixed para scripts de pipeline (`$HOME`/`$SCRIPTS_DIR`), `gh`/`glab`, mantendo catch-all deny, edit deny e destructive-git denies. PR #51 merged.

### 59. Test runner único com cache de resultados (fingerprint) para agentes de development
- Resolved: 2026-08-11
- Type: feat
- Report: william_pereira
- Reviewers: 2
- Remote: #52
- Severity: high
- Summary: Cria scripts/test-runner.sh (entrypoint único de testes com bootstrap de ambiente, detecção de runner, fingerprint e cache em .opencode/test-cache/), skill test-runner com protocolo check/run/status, prompts atualizados (developer, devs/*, senior-reviewers, quality-analyst, committer, delivery), pre_commit.sh delegado ao runner e testes scripts/tests/test_test_runner.sh. PR #53 merged.

### 46. nginx como requisito + HTTPS local para o opencode web service
- Resolved: 2026-08-08
- Type: feat
- Report: PO
- Reviewers: 2
- Remote: #46
- Severity: high
- Summary: Adiciona nginx como reverse proxy com HTTPS local via mkcert. setup-nginx.sh (313 linhas) com seleção inteligente de porta HTTP, template nginx-opencode.conf com 301 redirect/WebSocket/HTTPS, setup-web.sh --with-nginx, opencode.service com ExecStart pinado, firewall detection, idempotente.

### 26. `standards/issues.md` não documenta campo `Base branch:` e sintaxe de perfis em `Reviewers:`
- Resolved: 2026-08-08
- Type: doc
- Report: opencode
- Reviewers: 1
- Remote: #45
- Severity: medium
- Summary: Atualiza os 3 arquivos de standards (en, pt, es) para incluir - Base branch:, sintaxe correta de Reviewers: <number> (<profile1>, <profile2>), e campos ausentes no ES (PR, Business rules, Acceptance criteria) para paridade completa entre idiomas.

### 47. Reset de sessões e gestão completa do serviço opencode web (stop/reset)
- Resolved: 2026-08-06
- Type: feat
- Report: william_pereira
- Reviewers: 1
- Remote: #42
- Severity: medium
- Summary: O serviço systemd `opencode` (web) está documentado e tem comandos de criar (`ocf:setup-web`/`setup-web.sh`) e reiniciar (`ocf:restart-web`), mas NÃO há comando de parar nem de zerar o cache/sessões. O banco de sessões em `~/.local/share/opencode/opencode.db` cresce (atualmente ~1,6 GB) e o usuário quer a capacidade de zerar as sessões e reiniciar o serviço. — criar `scripts/reset-web.sh` (stop → backup → limpa db/log → start, com `--list`/`--dry-run`), registrar `ocf:reset-web` e `ocf:stop-web` no opencode.json, atualizar `scripts/README.md` e `Makefile`, e seguir o pipeline.

### 45. Remover modelos definidos dos agentes e deletar o agente Anderson
- Resolved: 2026-08-05
- Type: chore
- Report: william_pereira
- Reviewers: 1
- Remote: #39
- Severity: medium
- Summary: Remover o campo `model:` do frontmatter de todos os agentes (designer, ceo, anderson) — os modelos fixados causam bloqueios (ex. — (1) git rm agents/development/anderson.md; (2) remover `model:` de designer.md e ceo.md; (3) remover bloco `ocf:anderson-feedback` do opencode.json; (4) limpar workflow.md (11.5/10.5), publish-requester.md, prioritization.md, aibot-messages.md; (5) registrar issue, promover, revisar, MR.

### 44. Revisar e importar novo lote de skills externas (design/dev/marketing) via vendor
- Resolved: 2026-08-05
- Type: feat
- Report: william_pereira
- Reviewers: 1
- Remote: #36
- Severity: medium
- Summary: Revisar e importar um novo lote de skills externas seguindo a estratégia vendor da issue #43 (clone em `~/.config/opencode/vendor/` + `skills.paths`, NUNCA `npx skills add`). Lote — (1) registrar a issue e promover na branch da #43; (2) revisar cada repo (gh api / README / estrutura); (3) `skill-vendor.sh add` com sparse quando necessário; (4) atualizar skills/README.md; (5) rodar testes; (6) commitar e seguir o pipeline (review → QA → committer → MR).

### 43. Skills externas via clone + `skills.paths` (vendor dir), sem copia
- Resolved: 2026-08-05
- Type: feat
- Report: william_pereira
- Reviewers: 2
- Remote: #35
- Severity: medium
- Summary: Mudar a estratégia de importação de skills externas de "copiar para `skills/<sector>/`" (import_claude_skill.sh / npx skills add) para "clonar em `~/.config/opencode/vendor/` e carregar in-place via `skills.paths`". Migrar as 3 design skills do taste-skill (issue #42) para o clone sparse, importar os 7 novos repos de design (motion-design, color-expert, icon-generator, brand-to-design, responsive-craft, ux-flow-designer, frontend-designer), e registrar a regra como padrão para todas as sessões futuras. — Implementar conforme BR 1-11. Criar `scripts/skill-vendor.sh`; clonar repos em vendor (taste-skill com sparse); atualizar opencode.json (skills.paths + permission.skill) e .gitignore; git rm das cópias em skills/design; reescrever skill-importer; registrar regra em AGENTS.md/conventions.md/decisions.md; criar comando ocf:import-skill; adicionar testes.

### 39. Disparo de pipeline de desenvolvimento por comentário remoto `@aibot:develop`
- Resolved: 2026-08-04
- Type: feat
- Report: PO
- Reviewers: 3
- Remote: #30
- Severity: critical
- Summary: Criar um watcher (systemd timer) que observa comentários em issues remotas (GitHub/GitLab) e, ao detectar `@aibot:develop`, dispara o pipeline completo de desenvolvimento da issue comentada (equivalente a `/ocf:develop <id>`), terminando em senior review, QA, criação de MR e um comentário padrão do aibot avisando que o desenvolvimento terminou e o MR está pronto para revisão/merge. Issues não rastreadas localmente são recusadas com mensagem padrão. Execução via `opencode run --attach` no servidor web existente, com per-repo flock para concorrência serial e paralelismo entre repos. — Criar `scripts/remote.sh` (extrair de sync_github_issues.sh), `aibot-repos.json`, `standards/aibot-messages.md`, `agents/development/aibot.md`, comando `ocf:aibot-notify`, `scripts/aibot-watcher.sh` + unit/timer templates, hardening de permission rules, e documentar em `workflow.md`.

### 21. Perda progressiva de dados em `resolved_issues.md` no fechamento de issues
- Resolved: 2026-08-04
- Type: bug
- Report: opencode
- Reviewers: 1
- Remote: #28
- Severity: high
- Summary: close_issue.sh usa `tail -n +4` para preservar cabeçalho ao pré-pender novos entries, mas isso remove as 3 primeiras linhas do conteúdo existente a cada execução — corrompendo registros antigos progressivamente. — Substituir `tail -n +4` por `cat "$RESOLVED_FILE"` para preservar todo o conteúdo existente.

### 9. Consolidar decisões de branch, revisores e issue remota no discovery
- Resolved: 2026-06-09
- Type: feat
- Report: opencode
- Reviewers: 1
- Remote: #18
- Severity: high
- Summary: Mover decisões de branch base, perfis de revisores e criação de issue remota do PM promotion para o discovery pipeline. PM promotion vira puramente executória (sem perguntas ao usuário). — Seguir ordem
- Resolved: 2026-06-09
- Type: feat
- Report: william.pereira@digitalup.intranet
- Reviewers: 1
- Remote: #12
- PR: #13
- Summary: install.sh agora valida se opencode está instalado e atualizado antes de instalar a config. Detecta método de instalação (npm/brew), oferece update, e aborta com mensagem clara se recusar instalar.

### 7. Melhorar ocf:init com detecção de linguagens, sugestão de LSPs e configuração automática do editor
- Resolved: 2026-06-09
- Type: feat
- Report: william.pereira@digitalup.intranet
- Reviewers: 1
- Remote: #14
- PR: #15
- Summary: Criado standards/lsp-catalog.json com mapeamentos linguagem→extensões VS Code. scripts/init.sh detecta linguagens, consulta catálogo, sugere LSPs e configura .vscode/settings.json com merge preservando existentes. make bootstrap delegado para init.sh.

### 2. Adicionar etapa de definição da branch base no pipeline de promoção
- Resolved: 2026-06-09
- Type: feat
- Report: william.pereira@digitalup.intranet
- Reviewers: 1
- Remote: -
- Summary: Implementada em workflow.md, project-manager.md, developer.md, branching.md, promote.sh e Makefile. PM pergunta base branch, faz checkout+pull, cria branch issue-<id>-<slug>.

### 1. Resolved issue archive goes to global instead of project `.opencode/`
- Resolved: 2026-06-09
- Type: bug
- Report: william.pereira@digitalup.intranet
- Reviewers: 1
- Remote: -
- Severity: high
- Summary: Fix aplicado em scripts/config.sh:25-29 — RESOLVED_FILE agora detecta .opencode/ no CWD com $(pwd -P) antes de cair no global.

### 7. Workflow de revisão externa de branches/MRs (ocf:review-external)
- Resolved: 2026-06-01
- Type: feat
- Report: william.pereira@digitalup.intranet
- Reviewers: 1
- Remote: #9
- PR: #10
- Summary: Criado comando ocf:review-external + agente agents/review-external.md para revisao de branches/MRs externos com relatorio estruturado (11 regras de negocio). Suporta MR URL (GitHub/GitLab) e branch remota.

Issues resolved from `known_issues.md`. See `standards/resolved-issue.md` for format.

### 4. Pergunta sobre quantidade de revisores seniors não está documentada no pipeline
- Resolved: 2026-06-01
- Type: bug
- Report: william.pereira@digitalup.intranet
- Reviewers: 1
- Remote: -
- Summary: Documentada pergunta ao usuário sobre quantidade de revisores seniors (default 1) no workflow.md, project-manager.md, commands/ocf:promote.md, commands/ocf:review-branch.md, opencode.json, e agents/publish-requester.md. Armazenamento em `- Reviewers:` no issue. Leitura do campo na issue, não do opencode.json.

### 5. Criar issue remota obrigatória durante promoção
- Resolved: 2026-06-01
- Type: feat
- Report: william.pereira@digitalup.intranet
- Reviewers: 1
- Remote: #2
- Summary: Tornado obrigatório criar issue remota durante promoção com pergunta "Criar agora? (s/N)". Adicionadas validações em pre_commit.sh e maintain.sh para issues open sem remote.

### 3. Workflow Issue Lifecycle não reflete o pipeline completo
- Resolved: 2026-06-01
- Type: feat
- Report: william.pereira@digitalup.intranet
- Reviewers: 1
- Remote: #1
- Summary: Issue Lifecycle realinhado com Agent Pipeline de 11 passos. Adicionados status in-qa e in-publish. Committer gate explícito. QA pre e post separados.

### 8. Adicionar comando ocf:develop e padronizar definição de comandos
- Resolved: 2026-06-01
- Type: feat
- Report: william.pereira@digitalup.intranet
- Reviewers: 1
- Remote: #4
- Summary: Adicionado comando `ocf:develop` que gerencia inicio de desenvolvimento com auto-promote e validacao. Sincronizado commands/*.md com templates do opencode.json e documentada regra de que JSON e a fonte da verdade.

### 2. Token Iugu hardcoded no código fonte
- Resolved: 2026-06-01
- Type: bug
- Reported by: opencode scan
- Remote: !268
- Summary: Substituído token hardcoded `9d3b710be41519cd99aee9b5f7379767` por `process.env.IUGU_TOKEN` em `saveIuguPayment()` em `src/config/api-config.js:179`.

### 8. Move locale from opencode.json to .opencode/locale file
- Resolved: 2026-05-25
- Type: bug
- Reported by: william.pereira@digitalup.intranet
- Remote: -
- Severity: critical
- Summary: `"locale": "pt"` in opencode.json caused ConfigInvalidError. Moved locale to `.opencode/locale` file. Created `standards/locale.md` documentation. Updated `roc:init` to ask for locale and pass it to init script. Added reviewer count question to `roc:review-branch` and `roc:promote` (interactive, not from opencode.json). Updated locale-loader skill description and Makefile bootstrap target.

### 9. Multi-locale standards system
- Resolved: 2026-05-25
- Type: feat
- Reported by: william.pereira@digitalup.intranet
- Remote: -
- Severity: medium
- Summary: Created standards/pt/ and standards/es/ with Portuguese and Spanish translations, locale-loader skill for locale resolution, locale file with pt, documented in conventions.md and architecture.md

### 11. Distinguish bugs from missing business rules in reviews
- Resolved: 2026-05-25
- Type: feat
- Reported by: william.pereira@digitalup.intranet
- Remote: -
- Severity: high
- Summary: Added `Business rules:` field to issue format (required for feat), type classification guide in issues.md, bug vs incomplete-spec distinction in code-review.md, mandatory discovery rule in workflow.md, and updated all agents to enforce business rule documentation before promotion

### 10. Discovery flow with typed issue creation and QA gate
- Resolved: 2026-05-25
- Type: feat
- Reported by: william.pereira@digitalup.intranet
- Remote: -
- Severity: medium
- Summary: Created agents/tech-lead.md, standards/prioritization.md, updated workflow.md pipeline with TL and QA-after-review steps, marked wip/ as obsolete, updated opencode.json

### 7. Align global config with latest OpenCode documentation
- Resolved: 2026-05-25
- Type: chore
- Reported by: william.pereira@digitalup.intranet
- Remote: -
- Summary: Fixed instruction paths, added $schema, normalized agent frontmatter, updated locale-loader skill, added senior reviewer locale-awareness via locale-loader, added reviewer count question to roc:review-branch and roc:promote, updated roc:init with locale prompt, cleaned up .gitignore and stale artifacts

### 1. backup: zip creation fails silently due to unsupported `**` patterns
- Resolved: 2026-05-26
- Type: fix
- Reported by: user
- Remote: -
- Summary: Removed `**` exclusion patterns (zip does not support them), added zip availability check, removed output suppression, fixed rsync non-zero exit aborting zip/symlink steps.
- Fixed in: 70147ca, 09f3611

### 4. Add tech-lead agent role to pipeline
- Resolved: 2026-05-25
- Type: feat
- Reported by: explore
- Remote: -
- Severity: low
- Summary: Created agents/tech-lead.md agent definition and added it to workflow.md pipeline — provides technical guidance between CTO (strategy) and Developer (implementation)

### 22. Comando `ocf:review-external` registrado sem arquivo de documentação
- Resolved: 2026-06-28
- Type: bug
- Report: opencode
- Reviewers: 1
- Remote: #22
- Severity: high
- Summary: Criado commands/ocf:review-external.md com documentação completa do workflow de revisão externa (10 domínios, 5 níveis de severidade, relatório estruturado, post opcional no MR). Criado .github/workflows/post-merge.yml para auto-close de issues via GitHub Action.

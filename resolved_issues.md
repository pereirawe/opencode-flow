# Resolved Issues

Issues resolved from `known_issues.md`. See `standards/resolved-issue.md` for format.

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
- Summary: Created `scripts/cv/check-inferido.sh` gate blocking [INFERIDO] (case-insensitive) in the final resume HTML/PDF — exit 1 listing occurrences, best-effort pdftotext. Reworked cv-tailor skill/agent/command prompts to resolve inferences with the candidate (inferencias.md) before generation. cv-hub/cv-optimizer keep [INFERIDO] in internal artifacts; 46 tests green.

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

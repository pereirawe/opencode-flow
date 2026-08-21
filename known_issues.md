## Known Issues

Single source of truth for tracked work in this project.

### Format

```markdown
### <id>. <title>
- Status: backlog | ready | open | in-progress | in-review | in-qa | in-publish | resolved
- Opened: <YYYY-MM-DD> | -
- Ready: <YYYY-MM-DD> | -
- Started: <YYYY-MM-DD> | -
- In review: <YYYY-MM-DD> | -
- In QA: <YYYY-MM-DD> | -
- In publish: <YYYY-MM-DD> | -
- Type: bug | feat | doc | chore
- Severity: critical | high | medium | low
- Report: <user-name> | <model-name>
- Base branch: <default-branch> | <branch-name>
- Reviewers: <number> (<profile1>, <profile2>)
- Remote: - | #<remote-id>
- Jira: - | <KEY-N>
- PR: - | #<pr-number>
- Location: <file-path>:<line-numbers>
- Description: <brief>
- Impact: <what or who is affected>
- Business rules: <specific business logic, constraints, and domain rules>
- Acceptance criteria: <what must be true for the issue to be complete>
- Tests: <scenario → outcome lines, defined during discovery>
- Suggested fix: <approach or next step>
```

`Business rules:` is required for `feat` type issues.
`Tests:` is MANDATORY for every new issue, captured during discovery as
`scenario → outcome` lines. For `doc`/`chore` types the literal `- Tests: -`
is permitted (no test surface). For `feat`/`bug` types at least one
`scenario → outcome` line is REQUIRED and the value may NEVER be `-`. Severity
floor: `critical`/`high` → ≥3 lines, `medium` → ≥2, `low` → ≥1; if `Severity`
is missing, the medium floor (≥2) applies. Enforcement is verified by QA
pre-development review (Phase 5) and senior reviewers — NOT enforced by
scripts. Missing or insufficient `Tests:` = `incomplete-spec` (discovery gap),
not a bug.
`Base branch:` is set during discovery (usually `main`/`master`).
`Reviewers:` stores count and profiles (set during discovery, e.g. `1 (backend)`).
`Remote:` is populated at the end of discovery (PM asks user, creates if confirmed).
Auto-created by `ocf:promote` or `ocf:develop` if still missing.
`Jira:` is optional (default `-`) — the Jira Cloud card key (e.g. `DEV-123`)
mirrored from this issue when the Jira sync is enabled (issue #48), separate
from `Remote:`. Populated by `scripts/sync-jira.sh` (hooks in
create_issue.sh/promote.sh/close_issue.sh or the `ocf:sync-jira` command);
non-blocking, local `Status:` always wins.
`Opened:`/`Ready:`/`Started:`/`In review:`/`In QA:`/`In publish:` lifecycle
timestamps are stamped by the pipeline scripts (create_issue.sh on remote
creation success; promote.sh on backlog→ready and ready→in-progress;
transition.sh on in-progress→in-review→in-qa→in-publish; close_issue.sh stamps
`Resolved:` and computes `Durations:` into the archive — per-stage components
backlog/waiting/dev/review/qa/publish/total). Set-if-absent, idempotent, new
issues only. See `standards/issues.md` for the full contract.

### 24. `pre_commit.sh` não sincroniza trailers de status com `known_issues.md`
- Status: backlog
- Type: bug
- Severity: high
- Report: opencode
- Base branch: main
- Reviewers: 1
- Remote: -
- PR: #93
- Location: scripts/pre_commit.sh:36-61, standards/commits.md
- Description: standards/commits.md documenta que trailers (Status:, Closes) sincronizam automaticamente com known_issues.md via pre_commit.sh, mas o script apenas detecta e loga os trailers — nunca modifica o arquivo de issues.
- Impact: Sincronização automática documentada não existe. Usuários/agentes precisam atualizar known_issues.md manualmente após cada commit.
- Suggested fix: Implementar atualização real de status em known_issues.md no pre_commit.sh, ou remover a alegação da documentação.

### 25. Status `open` no ciclo de vida é inatingível — nunca setado por scripts
- Status: backlog
- Type: bug
- Severity: medium
- Report: opencode
- Base branch: main
- Reviewers: 1
- Remote: -
- PR: #93
- Location: scripts/promote.sh, scripts/create_issue.sh, workflow.md, standards/issues.md
- Description: O ciclo de vida documentado é backlog→ready→open→in-progress, mas promote.sh transiciona backlog→ready e ready→in-progress sem nunca passar por open. create_issue.sh mantém status como ready. Nenhum script ou agente seta Status: open.
- Impact: Estado open é inatingível. Código que referencia Status: open (maintain.sh, pre_commit.sh) é dead logic. Diagrama de lifecycle é enganoso.
- Suggested fix: Remover open do ciclo de vida ou fazer create_issue.sh transicionar ready→open ao criar remote com sucesso.

### 28. `close_issue.sh` fecha issue remota sem verificar merge do PR para status não-`in-publish`
- Status: resolved
- Type: bug
- Severity: medium
- Report: opencode
- Base branch: main
- Reviewers: 1 (devops)
- Remote: -
- PR: #93
- Location: scripts/close_issue.sh:42-65
- Description: O script aceita status ready, open, in-progress, resolved e executa `gh issue close` sem verificar se o PR foi merged. Apenas in-publish tem verificação de merge.
- Impact: Fechamento acidental de issues remotas ainda em desenvolvimento. Sem proteção ou confirmação.
- Business rules:
  1. close_issue.sh DEVE aceitar apenas status `in-publish` e `resolved`.
  2. Para qualquer outro status, DEVE abortar com erro e não modificar known_issues.md nem resolved_issues.md.
  3. Para status `in-publish`, DEVE manter a verificação existente de merge do PR antes de fechar remote.
  4. Para status `resolved`, DEVE verificar se a issue remota já está fechada antes de tentar fechar.
  5. DEVE exibir confirmação ao usuário antes de fechar a issue remota: `"Fechar issue #<id> no remote? (s/N)"`.
  6. Se o usuário recusar, DEVE pular o fechamento remoto mas continuar o arquivamento local.
  7. O fechamento remoto NÃO DEVE travar o arquivamento local em caso de falha.
- Acceptance criteria:
  1. Script aceita apenas status `in-publish` e `resolved` para fechar remote.
  2. Status `ready`, `open`, `in-progress`, `backlog`, `in-review`, `in-qa` abortam com erro.
  3. Status `resolved` verifica se remote já está fechado antes de tentar fechar.
  4. Status `in-publish` verifica merge do PR (lógica existente preservada).
  5. Usuário é confirmado antes de fechar remote.
  6. Se usuário recusar, arquivamento local continua.
  7. Falha no fechamento remoto não interrompe arquivamento.
- Suggested fix: Restringir close_issue.sh a aceitar apenas status in-publish e resolved. Adicionar verificação de estado remoto para resolved. Adicionar confirmação do usuário.

### 29. IDs duplicados de issue em `resolved_issues.md`
- Status: backlog
- Type: bug
- Severity: medium
- Report: opencode
- Base branch: main
- Reviewers: 1
- Remote: -
- PR: #93
- Location: resolved_issues.md:17-25, resolved_issues.md:44-51
- Description: Duas entradas em resolved_issues.md têm o mesmo ID `### 7.` — uma para "Melhorar ocf:init" e outra para "Workflow de revisão externa". close_issue.sh nunca verifica duplicatas antes de append.
- Impact: IDs não únicos no arquivo de resolução. Confusão ao referenciar issues resolvidas por ID.
- Suggested fix: Verificar se o ID já existe em resolved_issues.md antes de fazer append; alertar ou usar sufixo.

### 30. Código morto: sentinelas awk `/^### Status/ {exit}` nas scripts de issue
- Status: backlog
- Type: chore
- Severity: low
- Report: opencode
- Base branch: main
- Reviewers: 1
- Remote: -
- PR: #93
- Location: scripts/promote.sh:25, scripts/create_issue.sh:21, scripts/close_issue.sh:20
- Description: As scripts usam `awk '/^### Status/ {exit}'` como sentinela de terminação, mas known_issues.md não tem linha começando com `### Status` — apenas `### Format`. O padrão nunca é triggerado.
- Impact: Código morto. Sem impacto em runtime pois a lógica de boundary é tratada por outros patterns.
- Suggested fix: Remover as linhas `/^### Status/ {exit}` ou substituir por pattern que efetivamente case (ex: `/^### [A-Z]/`).

### 31. `import_claude_skill.sh` escreve `opencode.json` sem validação atômica
- Status: backlog
- Type: bug
- Severity: medium
- Report: opencode
- Base branch: main
- Reviewers: 1
- Remote: -
- PR: #93
- Location: scripts/import_claude_skill.sh:30-42
- Description: O script lê e escreve opencode.json com json.dump sem validação, sem write atômico, sem preservar formatação original, e com `2>/dev/null` suprimindo erros.
- Impact: Se a escrita for interrompida, a configuração do opencode pode ser corrompida.
- Suggested fix: Usar write atômico (temp file + rename). Validar JSON antes de escrever. Preservar indentação original. Remover supressão de erro.

### 32. Scripts shell sem cobertura de testes automatizados
- Status: backlog
- Type: chore
- Severity: medium
- Report: opencode
- Base branch: main
- Reviewers: 1
- Remote: -
- PR: #93
- Location: scripts/*.sh (12 scripts, 0 testes)
- Description: 12 scripts shell sem nenhum teste automatizado. Eles contêm lógica awk complexa, paths de erro e edge cases que seriam pegos por testes.
- Impact: Bugs em scripts passam despercebidos. Propenso a regressões. A infraestrutura do pipeline é a parte menos testada do sistema.
- Suggested fix: Criar scripts/tests/ com BATS ou shellcheck. Adicionar target `make test-scripts`. Adicionar ao CI.

### 33. `promote.sh` ignora silenciosamente falhas de `git fetch`
- Status: backlog
- Type: bug
- Severity: medium
- Report: opencode
- Base branch: main
- Reviewers: 1
- Remote: -
- PR: #93
- Location: scripts/promote.sh:162
- Description: `git fetch origin "$BASE_BRANCH" 2>/dev/null || git fetch origin 2>/dev/null || true` — erros de rede, autenticação ou remote inexistente são completamente suprimidos sem warning.
- Impact: Desenvolvedores podem trabalhar em branch stale sem saber que o remote está inacessível. Possíveis conflitos de merge depois.
- Suggested fix: Logar warning quando fetch falhar. Substituir `2>/dev/null` por `2>&1` para visibilidade.

### 35. `sync_github_issues.sh`: detecção de estado de issue GitLab frágil e sem fechamento automático
- Status: backlog
- Type: bug
- Severity: low
- Report: opencode
- Base branch: main
- Reviewers: 1
- Remote: -
- PR: #93
- Location: scripts/sync_github_issues.sh:92-93
- Description: Detecção de estado no GitLab usa `glab issue view | head -5 | grep -i state` — frágil e dependente de formatação. Além disso, o branch GitLab nunca chama `SHOULD_CLOSE=true` para status resolved (linhas 91-94 faltam a lógica de fechamento).
- Impact: Issues GitLab em status resolved nunca são fechadas automaticamente pelo sync. Detecção quebra com mudanças de versão do glab.
- Suggested fix: Usar `glab issue view --json state --jq '.state'` se suportado. Adicionar lógica de close para GitLab resolved.

### 37. Delegar `ocf:develop` para router e agentes Go/Python
- Status: resolved
- Type: feat
- Severity: medium
- Report: opencode
- Base branch: main
- Reviewers: 1 (docs, runtime)
- Remote: -
- PR: #93
- Location: commands/ocf:develop.md, opencode.json, agents/development/develop-router.md, agents/development/devs/golang.md, agents/development/devs/python.md, skills/development/go/*, skills/development/python/*
- Description: Atualizar `ocf:develop` para invocar `develop-router` e registrar agentes especializados para Go e Python com skills dedicadas.
- Impact: O fluxo de desenvolvimento passa a rotear automaticamente para o agente mais específico, em vez de cair sempre no `developer` genérico, melhorando a qualidade idiomática em projetos Go e Python.
- Business rules:
  1. `/ocf:develop` deve invocar `develop-router` em vez de chamar `developer` diretamente.
  2. `develop-router` deve escolher `development/devs/golang` quando o contexto indicar Go.
  3. `develop-router` deve escolher `development/devs/python` quando o contexto indicar Python.
  4. O registro de agentes deve incluir `development/devs/golang` com `go.mod`, `.go`, `cmd/`, `internal/`.
  5. O registro de agentes deve incluir `development/devs/python` com `pyproject.toml`, `requirements.txt`, `setup.py`, `setup.cfg`, `.py`, `.pyi`, `src/`, `app/`, `tests/`.
  6. O agente Python deve se apoiar apenas nas fontes fornecidas para PEP 20, PEP 8, PEP 257, typing, dataclasses, excecoes e Google Python Style Guide.
  7. As skills Go e Python devem estar disponiveis para revisao e implementacao idiomatica quando necessarias.
  8. O ecossistema Python pode incluir skill especializada para Flask quando o desafio principal for desenho de API HTTP e nao sintaxe da linguagem.
- Suggested fix: Adicionar o router, registrar os agentes especializados e atualizar o comando/config para usar o novo fluxo.

### 74. Validate and run delivery sessions in isolated containers for effective parallelization
- Status: ready
- Type: feat
- Severity: high
- Report: william_pereira
- Base branch: main
- Reviewers: 2 (devops, security)
- Remote: -
- PR: #93
- Location: scripts/run-parallel-delivery.sh (NEW orchestrator), scripts/tests/test_parallel_delivery.sh (NEW), .opencode/spikes/containerized-delivery.md (NEW), state/parallel-delivery/ (host lockfiles, NEW, gitignored), scripts/telegram-notify.sh (env-var verification/tests), scripts/test-runner.sh (cache seeding integration), workflow.md (entry-point + boundary docs), opencode.json (command registration if applicable), scripts/README.md, aibot-repos.json (consumed, unchanged), Dockerfile (reference only — #40 image base)
- Description: Spike-first. Prove that N=3 parallel containerized delivery sessions complete concurrently on one host with zero file-write/git conflicts and results identical to serial execution, documenting the outcome in .opencode/spikes/containerized-delivery.md with pass/fail criteria. Each session runs the full delivery pipeline (promote → develop → senior review → QA → corrections → committer gate → MR) inside its own container with a private working-tree snapshot (feature branch issue-<id>-<slug> on the base branch), reusing the #40 image ghcr.io/pereirawe/opencode-flow (semver-tagged). Orchestrator handles per-issue host-side flock locking (state/parallel-delivery/), parallelism cap AIBOT_MAX_PARALLEL (default 3), cache seeding, session result contract, working-tree-only sync-back to host known_issues.md, resource limits/cleanup, and orphan reaping. Security/allowlist/no-merge-polling boundaries from #39/#40 preserved. If the spike fails, fall back to host-side git worktree isolation or #39 flock serialization.
- Impact: The delivery pipeline's throughput bottleneck on the local machine — concurrent ocf:delivery/ocf:develop sessions collide today on one shared working tree. This unblocks N parallel deliveries (default 3) per host. Touches the core lifecycle (promote/develop/publish) and security boundaries — regression risk mitigated by spike-gating, idempotency requirements, and the #39/#40 gate semantics being reused. BLOCKED ON #40 landing on main + GHCR image publish (semver) — do not promote to in-progress until that lands.
- Business rules:
  1. Spike-first with explicit preconditions: Docker daemon availability; image obtainment (GHCR pull OR build from #40 branch with semver tag); model-API egress from containers; explicit API-level parallelism measurement (not just wall-clock — the model API is likely the real bottleneck). Outcome documented in .opencode/spikes/containerized-delivery.md (or ADR) with pass/fail criteria.
  2. Spike evaluates BOTH isolation candidates: (a) git worktree host-side worktrees (bind-mounted into containers or worktree-only) and (b) full volume-copy clone per session (isolated .git). Pass/fail includes git-metadata race analysis; if shared-.git races cannot be eliminated, full-clone wins.
  3. Isolation semantics: each session runs in its own container with a private working tree; feature branch issue-<id>-<slug> on top of base branch; all writes/git ops confined to the session.
  4. Per-issue lock MUST be host-side (flock on host lockfile under state/parallel-delivery/); snapshot spawn re-checks fresh host status inside the lock (TOCTOU guard). Different issues run in parallel up to AIBOT_MAX_PARALLEL (default 3, runtime-configurable), capped by host resources AND model-API concurrency. Lock scope per-issue, never global.
  5. Image reuse: base MUST be ghcr.io/pereirawe/opencode-flow:latest + semver tag, semver-tagged and rebuildable via the #40 pipeline; extensions layered and versioned.
  6. Config source decision: spike validates both bind-mount ~/.config/opencode (rw session workspace + read-only config) and immutable image config; when the image is stale vs local config, bind-mount wins.
  7. Cache seeding: each snapshot is seeded with a copy of host .opencode/test-cache/; sessions never share cache (each container its own copy). Seeded cache may be stale (base-branch fingerprint) — test-runner --check reports stale and falls back to --run (never blocks).
  8. No-merge-polling boundary preserved: sessions never poll merge/PR status; closing remote issues remains exclusive to ocf:check-pr/Close Requester.
  9. Security: deny rules (global bash deny list + edit denies on opencode.json, aibot-repos.json, state/**, ~/.ssh/**) bind via --auto with the packaged config; non-root containers; only session workspace (rw) + read-only config mounted; ~/.ssh, state/, and telegram.env are NEVER mounted (runtime env injection only).
  10. Allowlist: remote posting only for repos in aibot-repos.json; messages per standards/aibot-messages.md (one per trigger).
  11. Credentials/state injection: GH_TOKEN/GL_TOKEN/OPENCODE_API_KEY env-injected at runtime, never baked into the image.
  12. Session result contract: each session MUST emit a structured result (exit code + result file at a fixed container path: final issue status, PR number, or cannot-develop) consumed by sync-back.
  13. Sync-back is working-tree only: host workspace not modified by sessions; orchestrator (a) fetches the pushed branch, (b) updates host known_issues.md with the session's final status as an uncommitted diff — never commit/push to host main, per-entry replace only (session entry wins, authoritative), AND the host tracker file is flocked during sync-back writes (concurrent sync-backs must not interleave/corrupt the file); failures logged, never silent.
  14. Resource management: CPU/mem limits, hard timeout, cleanup-on-exit; orphaned containers reaped by the orchestrator (including reap at startup, not only at session end).
  15. Idempotency: re-running a session for the same issue MUST NOT duplicate branches, MRs, tracker entries, or remote comments.
  16. telegram-notify.sh env-var path: the env-var credential loading (TELEGRAM_BOT_TOKEN/TELEGRAM_CHAT_ID) already exists in the script — this issue VERIFIES it works with no telegram.env file mounted (container mode) and adds test coverage + credential redaction assertion. Implementation only if the verification finds a gap.
  17. Spike success criteria: N=3 parallel sessions on one host, zero file/git conflicts, no lost tracker updates, no duplicate MRs, wall-clock materially below 3× serial, identical end state to serial, resource peaks within configured limits.
  18. Fallback: spike failure → documented findings + recommendation (host-side git worktree isolation, or #39 flock serialization); NO production implementation without a passing spike or explicit user approval.
- Acceptance criteria:
  1. .opencode/spikes/containerized-delivery.md (or ADR) exists documenting the spike with explicit pass/fail criteria covering the four preconditions: Docker daemon availability, image obtainment (GHCR pull or #40-branch build with semver tag), model-API egress from containers, and API-level parallelism measurement (not just wall-clock).
  2. The spike evaluated BOTH isolation candidates — host-side git worktree worktrees AND full volume-copy clones with isolated .git — including a documented git-metadata race analysis; if shared-.git races cannot be eliminated, the full-clone candidate wins.
  3. Spike success at N=3 on one host demonstrated: zero file/git conflicts, no lost tracker updates, no duplicate MRs, wall-clock materially below 3× serial, end state identical to serial execution, resource peaks within configured limits.
  4. If the spike failed, findings + fallback recommendation (host-side git worktree isolation, or #39 flock serialization) documented and NO production implementation proceeds without a passing spike or explicit user approval.
  5. Orchestrator enforces per-issue host-side flock on lockfiles under state/parallel-delivery/ (never a global lock); snapshot spawn re-checks fresh host issue status inside the lock (TOCTOU guard); different issues run in parallel up to AIBOT_MAX_PARALLEL (default 3, runtime-configurable), capped by host resources and model-API concurrency.
  6. Each session runs in its own container with a private working tree; feature branch issue-<id>-<slug> created on top of base branch; all file writes and git operations confined to the session container, never overlapping other sessions.
  7. Container base is ghcr.io/pereirawe/opencode-flow pinned to a semver tag (not latest-only), rebuildable via the #40 pipeline; extensions layered and versioned.
  8. Spike documented the config-source decision between bind-mount ~/.config/opencode (rw session workspace + read-only config) and immutable image config; when the image is stale vs local config, bind-mount wins.
  9. Each session snapshot seeded with a copy of host .opencode/test-cache/; sessions never share a cache (each container its own copy); stale seeded cache falls back to --run (never blocks).
  10. Sessions never poll merge/PR status; closing remote issues remains exclusive to ocf:check-pr/Close Requester (no-merge-polling boundary preserved).
  11. Security boundary verified: global bash deny list and edit denies (opencode.json, aibot-repos.json, state/**, ~/.ssh/**) bind via --auto with the packaged config; containers run non-root; only session workspace (rw) + read-only config volume mounted; ~/.ssh, state/, and telegram.env never mounted.
  12. Remote posting allowed only for repos in the aibot-repos.json allowlist; others refused with the standard message; remote comments follow standards/aibot-messages.md (one message per trigger).
  13. GH_TOKEN/GL_TOKEN/OPENCODE_API_KEY injected as env vars at runtime, never baked into the image, never in logs (redaction verified).
  14. Each session emits a structured result contract — exit code + result file (fixed container path) containing final issue status, PR number, or cannot-develop — consumed by sync-back.
  15. Sync-back is working-tree only: host workspace never modified directly by sessions; orchestrator fetches the pushed branch and updates host known_issues.md with the session's final status as an uncommitted diff (never commits/pushes to host main), per-entry replace only (session entry authoritative), tracker file flocked during writes; failures logged, never silent.
  16. Resource management: each session container has CPU/memory limits, a hard timeout, cleanup-on-exit; orchestrator reaps orphaned containers (at startup and session end).
  17. Idempotency verified: re-running a session for the same issue produces no duplicate branches, MRs, tracker entries, or remote comments.
  18. scripts/telegram-notify.sh works with only TELEGRAM_BOT_TOKEN/TELEGRAM_CHAT_ID env vars (no telegram.env file mounted) — verified with a mock-curl test; existing file-based fallback retained; credentials redacted from logs.
  19. Dependency gate: the issue may promote on main only after #40 lands and the GHCR image is published (semver); until then it stays ready/backlog with the dependency documented.
- Tests:
  1. Two concurrent runs of run-parallel-delivery.sh for the SAME issue → exactly one proceeds; the other exits with the skip message; flock file created under state/parallel-delivery/ (mock opencode via PATH).
  2. TOCTOU: status flips to in-progress between lock acquisition and branch creation (mock known_issues.md mutation) → orchestrator re-reads status post-lock and skips.
  3. Idempotent re-run: completed issue (PR: #n present) run again → no duplicate MR creation, no duplicate tracker entry; reports already-in-progress; exactly one result consumed.
  4. AIBOT_MAX_PARALLEL=1 with 3 ready issues → sessions execute serially (mock invocation log: no overlap, count = 3).
  5. Sync-back per-entry: session result contract (fixed path, machine-parseable) contains only its own issue block → host known_issues.md updated for that entry only; all other entries byte-identical (diff limited to the one block).
  6. Concurrent sync-back: two session results flushed simultaneously → host tracker file flocked during write; file remains valid with both entries intact (no interleave/corruption).
  7. Container crash mid-run (mock kill) → orchestrator reaps the container, runs cleanup, marks session failed, host status → cannot-develop.
  8. Hard timeout exceeded (mock sleep) → orchestrator kills session, cleanup runs, failure logged.
  9. Credential redaction: session logs containing GH_TOKEN / OPENCODE_API_KEY / TELEGRAM_BOT_TOKEN literal values → persisted logs/errors contain no token values (assert_not_contains on output artifacts).
  10. Env-var credentials: telegram-notify.sh with only TELEGRAM_BOT_TOKEN/TELEGRAM_CHAT_ID env (mock curl via PATH) → sends notification; missing token → graceful error, exit ≠ 0, no crash.
  11. Mount restrictions: docker argv contains rw mount ONLY for the session workspace; no ~/.ssh, no state/, no telegram.env mounts; container runs non-root (mock docker asserts argv).
  12. Allowlist gating: repo not in aibot-repos.json → session refuses with standard message; allowlisted repo → proceeds (mock allowlist + message-count assert).
  13. Image ref: container launched from ghcr.io/pereirawe/opencode-flow:<semver> (assert image argv; no custom base).
  14. Cache seeding: host .opencode/test-cache seeded; stale fingerprint in container → mock test-runner --check reports stale → fallback to --run executes (never blocks).
  15. Missing docker binary/daemon → clear diagnostic message, exit ≠ 0, no partial state.
  16. make test-scripts regression: full suite including new test_parallel_delivery.sh → exit 0.
  17. (spike gate — manual/PM) Spike doc .opencode/spikes/containerized-delivery.md exists with N=3 pass criteria met, both isolation candidates evaluated, API-concurrency cap measured → verified before production implementation is promoted.
  18. (manual QA/integration) Real N=3 parallel run on host: zero file/git conflicts, no duplicate MRs, wall-clock materially < 3× serial, resource peaks within limits → recorded in spike doc.
- Suggested fix: (1) run the spike first: validate the four preconditions (Docker daemon, image obtainment via GHCR or #40-branch build, model-API egress, API-level parallelism measurement), evaluate both isolation candidates (host-side git worktree vs full volume-copy clone with isolated .git) including git-metadata race analysis, document pass/fail in .opencode/spikes/containerized-delivery.md; (2) on pass: implement the orchestrator script scripts/run-parallel-delivery.sh (per-issue host-side flock under state/parallel-delivery/ with TOCTOU re-check, AIBOT_MAX_PARALLEL runtime cap, snapshot spawn with cache seeding, CPU/mem/time limits, cleanup + orphan reap, session result contract, working-tree-only sync-back as uncommitted diff with tracker flock); (3) verify/extend scripts/telegram-notify.sh env-only credentials (likely verification + tests only — support already exists); (4) add scripts/tests/test_parallel_delivery.sh covering locking, idempotency, result contract, sync-back, and deny-rule/allowlist gating; (5) document in workflow.md + scripts/README.md. Effort ~28–36h, spike-gated. BLOCKED ON #40 landing on main + GHCR image publish (semver) — do not promote to in-progress until that lands. Origem: Proposal 2026-08-14-13 em prioritization.md.

### 76. Mandatory `Tests:` field missing across career-bundle issues (#66-#72) — incomplete-spec discovery gap
- Status: backlog
- Opened: 2026-08-15
- Ready: -
- Started: -
- Type: chore
- Severity: medium
- Report: opencode
- Base branch: main
- Reviewers: 1 (qa)
- Remote: -
- PR: #93
- Location: known_issues.md (issues #66, #67, #68, #69, #70, #71, #72), standards/issues.md, workflow.md
- Description: The `Tests:` field is MANDATORY for every new issue, captured during discovery as `scenario → outcome` lines (feat/high → ≥3 lines; feat/bug → never `-`). All career-bundle issues were created WITHOUT the field: #66 (closed 2026-08-15), #67 (in-review), and #68-#72 (backlog). The QA pre-development Phase 5 check was skipped for this bundle and the senior reviewers did not flag it. This is an incomplete-spec discovery gap, NOT a bug — no code was written against undocumented scenarios (developers wrote tests from the sector standards), but the issue entries fail the mandatory field contract.
- Impact: Issue entries do not comply with the mandatory `Tests:` standard; the enforcement chain (QA Phase 5 → senior review → post-review QA) did not catch the systematic gap. Without capture, the committer cannot verify the test floor, and future discovery cycles lack the per-issue scenario contract. #67 itself is otherwise fully verified (all 12 BRs/ACs, tests passing) — only the entry field is missing.
- Business rules:
  1. `Tests:` MUST be captured in issue #67 with ≥3 `scenario → outcome` lines (feat/high floor) before the committer gate finalizes `in-publish`.
  2. `Tests:` MUST be captured in issues #68-#72 before each is promoted to `in-progress` (feat/high → ≥3; feat/medium → ≥2), per their severities.
  3. Issue #66 is already archived — the gap is documented here for traceability, no retroactive rewrite.
  4. QA Phase 5 (pre-development) MUST re-verify the `Tests:` field on every future issue before `ready`.
- Acceptance criteria:
  1. Issue #67 entry has `- Tests:` with ≥3 `scenario → outcome` lines.
  2. Each of #68-#72 has `- Tests:` meeting its severity floor before promotion.
  3. QA pre-development re-checks `Tests:` on all new issues (no recurrence).
- Tests: -
- Suggested fix: Discovery refinement: capture the `Tests:` field for #67 (proposed lines in the QA post-review report of 2026-08-15) and for #68-#72 in their respective discovery cycles; enforce the field in QA Phase 5 going forward. Optionally add a mechanical lint gate in promote.sh (follow-up noted in standards/issues.md).

### 77. cv-cover-letter ainda carrega o padrão curl -L (SSRF) — follow-up do #72 D5
- Status: backlog
- Opened: 2026-08-15
- Ready: -
- Started: -
- Type: bug
- Severity: medium
- Report: senior-reviewers/runtime
- Base branch: main
- Reviewers: 1 (security)
- Remote: -
- PR: #93
- Location: agents/career/cv-cover-letter.md:19,43, commands/ocf:cv-cover-letter.md:30, skills/career/cv-cover-letter/SKILL.md:30, opencode.json:139
- Description: O issue #72 (D5) removeu `curl -L` do cv-tailor (vetor SSRF via file:// redirects; LinkedIn sempre bloqueia). A mesma racionalidade se aplica ao cv-cover-letter, que ainda ensina/permite fetch de URL via `curl -L` no agente, skill, comando e template opencode.json. Encontrado na senior review do #72 (L1) e confirmado na re-review como follow-up obrigatório — fora do escopo do #72.
- Impact: Vetor SSRF e dependência de fetch de URL não confiável persistente no fluxo de carta de apresentação; inconsistência com o padrão do setor career estabelecido no #72.
- Business rules:
  1. `curl -L*` DEVE ser removido das permissões bash do agente cv-cover-letter (agents/career/cv-cover-letter.md:19).
  2. As instruções de fetch via URL com curl DEVM ser substituídas por "peça ao usuário para colar o texto da vaga" no agente, skill (skills/career/cv-cover-letter/SKILL.md:30) e comando (commands/ocf:cv-cover-letter.md:30).
  3. O template do comando ocf:cv-cover-letter em opencode.json (linha 139) DEVE ser atualizado para remover qualquer instrução de curl -L.
  4. A entrada de fonte da vaga DEVE aceitar texto colado, arquivo local ou export oficial — nunca fetch de URL com redirects.
- Acceptance criteria:
  1. `grep -rn "curl -L" agents/career/cv-cover-letter.md commands/ocf:cv-cover-letter.md skills/career/cv-cover-letter/SKILL.md opencode.json` → 0 ocorrências.
  2. O fluxo cv-cover-letter solicita texto da vaga colado pelo usuário em vez de fetch URL.
  3. `make test-scripts` passa com cobertura de teste atualizada (assert_not_contains curl nos quatro artefatos).
- Tests:
  1. Permissão bash do cv-cover-letter contém `curl -L` → gate falha e lista o artefato.
  2. Instrução "curl -L <url>" presente no SKILL/comando/template → gate falha com evidência.
  3. Texto da vaga colado pelo usuário → fluxo gera carta normalmente sem fetch de URL.
  4. `make test-scripts` com cv-cover-letter limpo → exit 0 (assert_not_contains curl em todos os artefatos).
- Suggested fix: Aplicar o mesmo tratamento do #72 D5 ao cv-cover-letter: remover permissão/instruções/template `curl -L` e exigir texto colado. Follow-up registrado na senior review do #72 (L1, não-bloqueante para o #72).

### 78. Design sector skills (foundation for Adorable pipeline)
- Status: backlog
- Type: feat
- Severity: high
- Report: william_pereira
- Base branch: main
- Reviewers: 2 (design, frontend)
- Remote: -
- PR: -
- Location: skills/design/reference-library/SKILL.md, skills/design/component-patterns/SKILL.md, skills/design/design-tokens/SKILL.md, skills/design/visual-hierarchy/SKILL.md
- Description: Create 4 skills under `skills/design/` that encode concrete, testable UI patterns for the Adorable pipeline. These skills are the foundation consumed by all 6 design agents — without them, agents produce generic UI.
- Impact: All 6 design agents (art-director, ui-architect, ui-implementer, ui-critic, ui-auditor, ui-refactor-planner) depend on these skills for pattern references, token systems, component anatomy, and visual hierarchy rules.
- Business rules:
  1. `skills/design/reference-library/SKILL.md` MUST exist with concrete UI patterns (Dashboard Card, Data Table, Nav Rail, Metric Display, Empty State, Command Palette) — each specifies exact CSS values, NOT descriptions.
  2. `skills/design/component-patterns/SKILL.md` MUST exist with anatomy per component type: primitive (Button, Badge, Icon, Avatar, Separator, Skeleton, Spinner) and composite (Card, DataTable, Form, Dropdown, Modal, Toast, CommandPalette).
  3. `skills/design/design-tokens/SKILL.md` MUST exist specifying: palette (5 functional layers + 2 accent + semantic), typography (2 families, scale xs–4xl), spacing (4pt base), radius philosophy, shadow tiers, motion durations.
  4. `skills/design/visual-hierarchy/SKILL.md` MUST exist with rules for: visual weight, contrast ratios (WCAG AA minimum), density modes, responsive patterns.
  5. All skills MUST have English frontmatter with bilingual trigger keywords (PT appendix per #73).
  6. Skills MUST be registered in `opencode.json` under `permission.skill`.
  7. Skills MUST NOT contain code — pattern references consumed by agents as system prompt context.
- Acceptance criteria:
  1. All 4 SKILL.md files exist under `skills/design/*/` with correct frontmatter.
  2. Each skill contains concrete, testable values (not philosophy or opinions).
  3. `opencode.json` registers all 4 skills.
  4. Skills follow `standards/cv-analysis.md` §2 structure rules.
- Tests:
  1. `ls skills/design/reference-library/SKILL.md skills/design/component-patterns/SKILL.md skills/design/design-tokens/SKILL.md skills/design/visual-hierarchy/SKILL.md` → all exist.
  2. `grep -c "MUST\|MUST NOT" skills/design/*/SKILL.md` → each skill has ≥10 MUST statements.
  3. `grep -c "background.*#\|border.*#\|radius.*px\|padding.*px" skills/design/reference-library/SKILL.md` → ≥10 concrete CSS values.
  4. `jq '.permission.skill' opencode.json` → all 4 skills registered.
  5. `grep -c "^#" skills/design/*/SKILL.md` → each skill has ≥3 H2 sections.
- Suggested fix: Create the 4 skills under `skills/design/` with concrete patterns (not philosophy), English frontmatter, bilingual trigger keywords, and register in opencode.json. Reference vendor taste-skill/minimalist-ui for pattern examples but create original content.

### 79. Greenfield pipeline agents (art-director, ui-architect, ui-implementer, ui-critic)
- Status: backlog
- Type: feat
- Severity: high
- Report: william_pereira
- Base branch: main
- Reviewers: 2 (design, frontend)
- Remote: -
- PR: -
- Location: agents/design/art-director.md, agents/design/ui-architect.md, agents/design/ui-implementer.md, agents/design/ui-critic.md
- Description: Create the core 4-pass Adorable pipeline: art-director (brief → design_spec.json), ui-architect (design_spec → component_tree.json), ui-implementer (JSONs → production code), ui-critic (quality gate). Each agent has a single responsibility and consumes/produces structured JSON.
- Impact: Replaces the single-pass `designer.md` with a pipeline that separates layout, architecture, implementation, and quality concerns — the key differentiator from generic AI UI.
- Business rules:
  1. `agents/design/art-director.md` — mode=subagent, edit=deny, bash=deny, temp=0.7. Process: deconstruct brief → audit defaults → 3 design directions → critique → design_spec.json.
  2. `agents/design/ui-architect.md` — mode=subagent, edit=deny, bash=deny, temp=0.2. Process: parse design_spec → layout regions → component tree → contracts → interaction map → build order.
  3. `agents/design/ui-implementer.md` — mode=subagent, edit=allow, bash=allow, temp=0.1. Process: parse JSONs → verify env → implement by build_order → verify checklist.
  4. `agents/design/ui-critic.md` — mode=subagent, edit=deny, bash=deny, temp=0.3. Process: receive code → evaluate checklist → pass/iterate.
  5. NO `model:` in frontmatter — user's default model. Prompt documents preference textually.
  6. All agents consume/produce structured JSON — no ambiguous text between agents.
  7. All agents include locale rule per #73.
  8. art-director rejects AI anti-patterns (cream+terracotta, Inter for everything, generic purple gradient, etc.).
  9. art-director generates 3 directions before selecting; defines signature element.
  10. ui-architect maps all 6 data states per async component; structural accessibility.
  11. ui-implementer implements every defined state — no skipping.
  12. ui-critic blocks delivery on any checklist failure — no partial approvals.
  13. Agents registered in `opencode.json` with correct permissions.
- Acceptance criteria:
  1. All 4 agent .md files exist under `agents/design/` with correct frontmatter.
  2. art-director produces valid JSON with brief_analysis, rejected_defaults, directions_considered, selected_direction, design_spec.
  3. ui-architect produces valid JSON with layout_regions, component_tree, components, interaction_map, build_order.
  4. ui-implementer reads JSONs and writes code files (not JSON).
  5. ui-critic returns APPROVED or ISSUES_FOUND with component-specific feedback.
  6. `opencode.json` registers all 4 agents with correct permissions.
- Tests:
  1. `ls agents/design/art-director.md agents/design/ui-architect.md agents/design/ui-implementer.md agents/design/ui-critic.md` → all exist.
  2. `grep "mode: subagent" agents/design/*.md` → all 4 agents are subagents.
  3. `grep "model:" agents/design/*.md` → 0 occurrences (no hardcoded model).
  4. `grep "edit: deny" agents/design/art-director.md agents/design/ui-architect.md agents/design/ui-critic.md` → all deny.
  5. `grep "edit: allow" agents/design/ui-implementer.md` → allow.
  6. `jq '.agents' opencode.json` → all 4 agents registered.
- Suggested fix: Create the 4 agents under `agents/design/` based on the drafts in `.opencode/adorable-proposal/` but rewritten in English, with no hardcoded model, and registered in opencode.json. Depends on #80 (skills) for pattern references.

### 80. Audit/Refactor agents (ui-auditor, ui-refactor-planner)
- Status: backlog
- Type: feat
- Severity: high
- Report: william_pereira
- Base branch: main
- Reviewers: 2 (devops, frontend)
- Remote: -
- PR: -
- Location: agents/design/ui-auditor.md, agents/design/ui-refactor-planner.md
- Description: Create 2 agents for existing codebase refactoring: ui-auditor (stack-agnostic diagnostic → audit_report.json) and ui-refactor-planner (diagnostic + design_spec → phased refactor_plan.json). Enables the pipeline to work on existing projects, not just greenfield.
- Impact: Extends the Adorable pipeline from new-project-only to any existing codebase. The auditor produces machine-readable diagnostics; the planner produces a migration plan that never breaks working functionality.
- Business rules:
  1. `agents/design/ui-auditor.md` — mode=subagent, edit=deny, bash=allow, temp=0.1. Detects stack via bash (REACT_VITE, NEXTJS_APP, VUE_VITE, PHP_BLADE, PHP_HTML, HTML_VANILLA, etc.).
  2. Auditor uses bash for detection only — never destructive (no rm, mv, write).
  3. Auditor assigns severity scores (1–5) per dimension: visual_consistency, component_structure, state_completeness, accessibility, responsiveness, performance_visual, maintainability.
  4. Auditor cites file and line for every issue; preserves what's good in `preserved_patterns`.
  5. `agents/design/ui-refactor-planner.md` — mode=subagent, edit=deny, bash=deny, temp=0.2. Consumes audit + design_spec → refactor_plan.json.
  6. Planner classifies: Group A (blockers), Group B (inline), Group C (opportunities).
  7. Planner never plans big bang; never deletes before replacing; adapts strategy to stack.
  8. Both output pure JSON; both include locale rule; both registered in opencode.json.
- Acceptance criteria:
  1. Both agent .md files exist under `agents/design/` with correct frontmatter.
  2. ui-auditor detects stack via bash and produces audit_report.json with scores, critical_issues, preserved_patterns.
  3. ui-refactor-planner produces refactor_plan.json with phases, component_decisions, token_mapping, dependency_map.
  4. `opencode.json` registers both agents.
- Tests:
  1. `ls agents/design/ui-auditor.md agents/design/ui-refactor-planner.md` → both exist.
  2. `grep "bash: allow" agents/design/ui-auditor.md` → allow.
  3. `grep "bash: deny" agents/design/ui-refactor-planner.md` → deny.
  4. `jq '.agents' opencode.json` → both agents registered.
- Suggested fix: Create the 2 agents under `agents/design/` based on the drafts in `.opencode/adorable-proposal/` but rewritten in English, with no hardcoded model. Depends on #80 (skills) for token/component references that the planner consumes.

### 81. /ocf:build-ui orchestration command + output file conventions
- Status: backlog
- Type: feat
- Severity: high
- Report: william_pereira
- Base branch: main
- Reviewers: 2 (design, docs)
- Remote: -
- PR: -
- Location: commands/ocf:build-ui.md, commands/ocf:audit-ui.md, standards/design-pipeline.md
- Description: Create 2 orchestration commands and define output file conventions. `/ocf:build-ui` orchestrates the 4-pass greenfield pipeline; `/ocf:audit-ui` orchestrates audit+refactor. Output conventions define deterministic file paths for pipeline artifacts, enabling resumption and multi-model flows.
- Impact: The entry point that makes the Adorable pipeline usable. Without commands, users must manually invoke each agent. Without conventions, output files are unnamed and undiscoverable.
- Business rules:
  1. `commands/ocf:build-ui.md` orchestrates: art-director → ui-architect → ui-implementer → ui-critic.
  2. `commands/ocf:audit-ui.md` orchestrates: ui-auditor → ui-refactor-planner (optional: → build pipeline).
  3. Commands pass JSON outputs between agents — each receives previous agent's output file path.
  4. Commands handle failure at any stage — log + Telegram notification, no continuation.
  5. Output directory: `.opencode/design-outputs/<session-id>/` (timestamp-based, e.g., `2026-08-17T14-30-00`).
  6. Output file names: `design_spec.json`, `component_tree.json`, `refactor_plan.json`, `audit_report.json`, `quality_report.json`.
  7. Commands registered in `opencode.json`.
  8. Commands accept brief (build-ui) or project path (audit-ui).
  9. Commands support resumption — re-run with same session-id skips completed stages.
  10. No hardcoded model in command template — user's default.
  11. Response-language rule: respond in user's input language.
  12. `standards/design-pipeline.md` documents output conventions, session management, pipeline stages.
- Acceptance criteria:
  1. `commands/ocf:build-ui.md` and `commands/ocf:audit-ui.md` exist.
  2. Commands pass JSON file paths between agents as context.
  3. `standards/design-pipeline.md` documents output file names, directory structure, session protocol.
  4. `opencode.json` registers both commands.
  5. `workflow.md` documents the design pipeline as an entry point.
- Tests:
  1. `ls commands/ocf:build-ui.md commands/ocf:audit-ui.md` → both exist.
  2. `grep -c "art-director\|ui-architect\|ui-implementer\|ui-critic" commands/ocf:build-ui.md` → ≥4 references.
  3. `grep -c "ui-auditor\|ui-refactor-planner" commands/ocf:audit-ui.md` → ≥2 references.
  4. `ls standards/design-pipeline.md` → exists.
  5. `grep "design-outputs" standards/design-pipeline.md` → output convention documented.
  6. `jq '.commands' opencode.json` → both commands registered.
- Suggested fix: Create the 2 commands and `standards/design-pipeline.md`. Register in opencode.json. Update workflow.md. Depends on #81 and #82 (agents must exist before commands can invoke them).

### 82. Model fallback mechanism for design agents
- Status: backlog
- Type: feat
- Severity: medium
- Report: william_pereira
- Base branch: main
- Reviewers: 1 (runtime)
- Remote: -
- PR: -
- Location: agents/design/*.md, opencode.json
- Description: Implement model fallback in the design pipeline. Instead of hardcoding `model: anthropic/claude-opus-4-5` in agent frontmatter, agents use the user's default model. Prompt text documents preference without enforcing it. Prevents silent failures when preferred model is unavailable.
- Impact: Prevents pipeline failures when the preferred model is unavailable. The art-director benefits from high-capability models for creativity, but the pipeline must work with any model.
- Business rules:
  1. Design agents MUST NOT have `model:` in frontmatter — user's default model.
  2. Agent prompts document model preference textually: "benefits from high-capability models but works with any model."
  3. `/ocf:build-ui` command MAY include preferred `model` field — fallback to user's default if unavailable.
  4. art-director documents: "temperature: 0.7 recommended for creative output."
  5. ui-implementer documents: "temperature: 0.1 recommended for precise implementation."
  6. Model preference is documentation, not requirement — pipeline works with any model.
- Acceptance criteria:
  1. `grep -c "model:" agents/design/*.md` → 0 occurrences.
  2. All agent prompts contain model preference documentation.
  3. `opencode.json` command template for build-ui may have optional `model` field.
- Tests:
  1. `grep "model:" agents/design/art-director.md agents/design/ui-architect.md agents/design/ui-implementer.md agents/design/ui-critic.md agents/design/ui-auditor.md agents/design/ui-refactor-planner.md` → 0 matches.
  2. `grep -i "high-capability\|works with any model" agents/design/*.md` → ≥4 matches.
- Suggested fix: Remove any `model:` from agent frontmatter (should be done during #81 creation). Add model preference documentation to prompts. Independent of other issues but best done as part of #81.

### 83. Design sector documentation (READMEs, agent-skill mapping, standards)
- Status: backlog
- Type: doc
- Severity: medium
- Report: william_pereira
- Base branch: main
- Reviewers: 1 (docs)
- Remote: -
- PR: -
- Location: agents/design/README.md, agents/README.md, skills/README.md, standards/design-pipeline.md, workflow.md, opencode.json
- Description: Create design sector documentation: README listing all 6 agents with pipeline flow and skill mapping, update parent READMEs, create output conventions standard, update workflow.md with design pipeline entry point, register agents/commands in opencode.json.
- Impact: Makes the design sector discoverable and maintainable. Without documentation, new users cannot find the pipeline or understand agent-skill relationships.
- Business rules:
  1. `agents/design/README.md` lists all 6 agents with one-line description, skills consumed, pipeline position.
  2. `agents/design/README.md` includes flow diagram (Greenfield: brief → art-director → ui-architect → ui-implementer → ui-critic; Audit: codebase → ui-auditor → ui-refactor-planner → ... → UI).
  3. `agents/README.md` updated to include design sector.
  4. `skills/README.md` updated to include design sector.
  5. `standards/design-pipeline.md` documents output file names, directory structure, session protocol, model preference.
  6. `workflow.md` documents design pipeline as entry point: `ocf:build-ui` and `ocf:audit-ui`.
  7. `opencode.json` updated to register new commands and agents.
  8. All documentation in English (per #73).
- Acceptance criteria:
  1. `agents/design/README.md` exists with all 6 agents listed.
  2. `agents/README.md` includes design sector.
  3. `skills/README.md` includes design sector.
  4. `standards/design-pipeline.md` exists with output conventions.
  5. `workflow.md` documents design pipeline entry points.
  6. `opencode.json` registers all design agents and commands.
- Tests:
  1. `ls agents/design/README.md` → exists.
  2. `grep -c "art-director\|ui-architect\|ui-implementer\|ui-critic\|ui-auditor\|ui-refactor-planner" agents/design/README.md` → ≥6.
  3. `grep "design" agents/README.md` → design sector listed.
  4. `grep "design" skills/README.md` → design sector listed.
  5. `ls standards/design-pipeline.md` → exists.
  6. `grep "build-ui\|audit-ui" workflow.md` → design pipeline documented.
  7. `jq '.agents | keys | map(select(startswith("design/")))' opencode.json | wc -l` → ≥6 agents registered.
- Suggested fix: Create documentation files after #81, #82, and #83 are implemented (agents and commands must exist to be documented). Update parent READMEs and workflow.md. Register everything in opencode.json.

### 202. Remove savings badge from Vitrine plan in business pricing table
- Status: ready
- Opened: 2026-08-17
- Ready: 2026-08-17
- Started: -
- Type: feat
- Severity: low
- Report: william_pereira
- Base branch: main
- Reviewers: 1 (frontend)
- Remote: -
- Jira: -
- PR: -
- Location: src/app/landing/_components/planos-business.tsx:126
- Description: Remove the "economize 26% vs plano anterior" savings badge ONLY from the Vitrine plan. The badge must remain visible for Destaque and Top plans. Single-line conditional change.
- Impact: Landing page business pricing table — Vitrine plan column no longer shows the green savings badge.
- Business rules:
  1. Badge MUST be hidden ONLY for the Vitrine plan (plan.id === "business-vitrine")
  2. Badge MUST remain visible for Destaque and Top plans with correct savings percentage
  3. Helper functions lowerPlan() and savingsPercent() MUST NOT be removed — still used by Destaque and Top
  4. i18n key planosBusiness.economia MUST NOT be removed — still used
  5. No visual changes to Destaque, Top, or any other plan
- Acceptance criteria:
  1. Vitrine column shows price + per-tag price but NO green savings badge
  2. Destaque column shows badge with "economize 23% vs plano anterior"
  3. Top column shows badge with "economize 18% vs plano anterior"
  4. lowerPlan() and savingsPercent() still imported and used in the file
  5. planosBusiness.economia key still present in all locale JSON files
  6. No TypeScript/build errors
- Tests:
  1. Vitrine column → no emerald savings badge rendered (snapshot or manual check)
  2. Destaque + Top columns → badge present with correct percentage values
  3. grep "business-vitrine" planos-business.tsx → conditional present on line 126
  4. grep "lowerPlan\|savingsPercent" planos-business.tsx → functions still imported and used
  5. grep "planosBusiness.economia" messages/{pt,en,es}.json → key present in all locale files
- Suggested fix: Add `plan.id !== "business-vitrine"` to the conditional guard on line 126: `{previous && plan.id !== "business-vitrine" ? (`

### 203. Blank space after RESUMO section in cv-pdf resume template — blanket `section { break-inside: avoid; }` pushes Experiência to page 2
- Status: in-publish
- Opened: 2026-08-17
- Ready: 2026-08-17
- Started: 2026-08-17
- Type: bug
- Severity: high
- Report: william_pereira
- Base branch: main
- Reviewers: 3 (frontend, docs, qa)
- Remote: #97
- Jira: -
- PR: #98
- Location: skills/career/cv-pdf/templates/resume.html:95-101, standards/cv-design.md §2.4/§5, standards/cv-analysis.md §6
- Description: Every resume generated by `ocf:cv-tailor` inherits the template's print CSS. The blanket `section { break-inside: avoid; }` (resume.html lines 95-101) makes the print engine move the ENTIRE (long) Experiência section to page 2 when it does not fit the remaining page-1 space, leaving a large blank gap after the short RESUMO section (lines 118-121) on page 1. This degrades the perceived quality of the sector's core shareable deliverable, wastes page space, and can push a junior/pleno resume to 2 pages — violating `standards/cv-design.md` §4. Fix: replace the blanket rule with a targeted approach — `section { break-inside: auto; orphans: 3; widows: 3; }`, keep `break-inside: avoid` on `.entry` and `break-after: avoid` on `h2`/`.header` — so page 1 is filled. CSS-only change; the template remains the mandatory base for cv-tailor.
- Impact: Every resume generated by the career sector is affected — the template is the mandatory base for cv-tailor, so the defect is systematic, not an edge case. The resume is the sector's core shareable deliverable; a large blank gap degrades perceived quality, wastes page space, and can violate the page-count standard (§4).
- Business rules:
  1. The final resume PDF MUST NOT contain a large blank gap after the RESUMO (Summary) section caused by the print engine relocating the entire Experiência section to page 2.
  2. The root cause is the blanket `section { break-inside: avoid; }` rule in the template's print CSS (lines 95-101) applying to ALL sections, including long ones such as Experiência — the fix MUST address this root cause directly.
  3. The fix MUST be CSS-only, confined to `skills/career/cv-pdf/templates/resume.html` — no HTML structure changes, no content changes, and no changes to the cv-tailor/cv-pdf skills, agents, or commands.
  4. The template MUST remain the mandatory base for cv-tailor (cv-tailor copies it and adapts only content, never CSS) — the fix MUST NOT alter this contract.
  5. The fix MUST preserve the intent of `standards/cv-design.md` §2.4: short sections and individual entries (`.entry`) MUST keep `break-inside: avoid`; long content sections (e.g., Experiência) MAY be allowed to break across pages.
  6. The fix MUST NOT introduce new blank space elsewhere: `h2 { break-after: avoid; }` and `.header { break-after: avoid; }` MUST be preserved so headings are never orphaned at the bottom of a page, and section margins (`section { margin-bottom: 6mm; }`) MUST NOT create visible gaps at page breaks.
  7. The fix MUST keep `standards/cv-design.md` §2.2 (no excessive whitespace) and §4 (page limits: 1 page junior/pleno, at most 2 senior+) achievable — a junior/pleno resume MUST still fit on exactly one page.
  8. The §2.4 wording refinement MUST be documented in `standards/cv-design.md` and its conformity checklist (§5) — never a silent CSS-only divergence from the standard.
  9. The fix MUST be validated against a representative resume with a long Experiência section: page 1 filled with content after RESUMO, no blank gap, no orphaned heading at the page boundary.
  10. The fix MUST pass `make test-scripts` (regression) and any existing template/conformity checks.
  11. `standards/cv-analysis.md` §6 MUST align — the refined rule is documented once in cv-design.md and referenced from both consumers (resume template and profile-analysis.html template).
  12. The BR 9 validation (representative resume with a long Experiência section) MUST be an explicit task in the implementation plan, not implicit.
- Acceptance criteria:
  1. The final resume PDF shows no large blank gap after the RESUMO section — page 1 is filled with content (BR 1, 9).
  2. The blanket `section { break-inside: avoid; }` rule is removed from the template's print CSS and replaced with `section { break-inside: auto; orphans: 3; widows: 3; }` (BR 2, 3).
  3. `.entry { break-inside: avoid; }`, `h2 { break-after: avoid; }` and `.header { break-after: avoid; }` remain in the template's print CSS (BR 5, 6).
  4. No HTML structure or content changes in resume.html; no changes to cv-tailor/cv-pdf skills, agents, or commands (BR 3, 4).
  5. `standards/cv-design.md` §2.4 and §5 checklist are updated to distinguish short sections (keep `break-inside: avoid`) from long content sections (may break); `standards/cv-analysis.md` §6 references the refined rule (BR 8, 11).
  6. A junior/pleno resume still fits on exactly one page; senior+ at most two (BR 7).
  7. `make test-scripts` passes with the new/extended regression test (BR 10).
- Tests:
  1. Resume with a long Experiência section rendered to PDF → `pdftotext -f 1 -l 1` page 1 contains BOTH the RESUMO text AND the first Experiência entry (content flows onto page 1); `pdfinfo` page count ≥ 1; no orphaned heading at the page boundary.
  2. Junior/pleno resume rendered to PDF → `pdfinfo` reports exactly 1 page (page-count standard §4 preserved).
  3. `grep "break-inside: auto" skills/career/cv-pdf/templates/resume.html` → present; `grep "section { break-inside: avoid"` → 0 matches in the print CSS.
  4. `grep "break-after: avoid" skills/career/cv-pdf/templates/resume.html` → h2 and .header rules still present.
  5. `grep "break-inside: avoid" standards/cv-design.md` → §2.4 refined wording distinguishes short vs long sections; §5 checklist updated.
  6. `grep "cv-design.md" standards/cv-analysis.md` → §6 references the refined rule from cv-design.md.
  7. `make test-scripts` → exit 0 with the new regression test covering the print CSS assertions.
  8. Resume with NO Experiência section rendered to PDF → no regression, no blank gap after RESUMO, page count unchanged.
  9. Very short resume (fits one page) rendered to PDF → exactly 1 page, no blank gaps between sections.
  10. Resume with many short sections rendered to PDF → each short section keeps `break-inside: avoid`; no orphaned h2 at page boundaries.
  11. Section ending exactly at a page boundary → h2 heading never orphaned at the bottom of a page (`break-after: avoid` holds).
  12. Senior 2-page resume rendered to PDF → page 2 flows correctly, no stranded single lines (orphans/widows protection).
- Suggested fix: Apply the Tech Lead approach (Option a): (1) edit `skills/career/cv-pdf/templates/resume.html` print CSS — replace `section { break-inside: avoid; }` with `section { break-inside: auto; orphans: 3; widows: 3; }`, keeping `.entry { break-inside: avoid; }` and `h2`/`.header { break-after: avoid; }`; (2) refine `standards/cv-design.md` §2.4 + §5 checklist to distinguish short sections (keep `break-inside: avoid`) from long content sections (may break); (3) align `standards/cv-analysis.md` §6 by reference; (4) add/extend regression test in scripts/tests/ and run `make test-scripts`; (5) validate with a representative resume with a long Experiência section (explicit task per BR 12); (6) update known_issues.md entry. Effort ~2-4h.

### 204. `profile-analysis.html` template still applies blanket `section { break-inside: avoid; }` — same blank-gap defect in analysis reports
- Status: backlog
- Opened: 2026-08-17
- Ready: -
- Started: -
- Type: bug
- Severity: medium
- Report: senior-reviewers/docs
- Base branch: main
- Reviewers: 1 (frontend)
- Remote: -
- Jira: -
- PR: -
- Location: skills/career/cv-optimizer/templates/profile-analysis.html:106,109, standards/cv-analysis.md §6
- Description: Follow-up from issue #203 senior review (docs profile, incomplete-spec finding). `standards/cv-analysis.md` §6 now documents the refined print rule ("short sections and entries keep `break-inside: avoid`; long content sections may break across pages with `orphans`/`widows` protection — per `standards/cv-design.md` §2.4"), but the analysis-report template `skills/career/cv-optimizer/templates/profile-analysis.html` still applies the blanket `section { break-inside: avoid; }` (line 106) plus `table tr { break-inside: avoid; }` (line 109). The docs describe behavior the template does not implement — the same blank-gap defect would occur in analysis reports with long sections. Classified as incomplete-spec during #203 review because BR 3 confined that fix to resume.html; this issue captures the gap for the profile-analysis.html consumer.
- Impact: Analysis reports (profile-analysis.html/PDF) with long sections can exhibit the same large blank gap after a short preceding section. Lower impact than resumes (analysis reports are reading artifacts, not ATS-submitted), but the documented standard (§6) overstates the template's actual behavior.
- Business rules:
  1. The `@media print` block in `skills/career/cv-optimizer/templates/profile-analysis.html` MUST replace the blanket `section { break-inside: avoid; }` with `section { break-inside: auto; orphans: 3; widows: 3; }`.
  2. `table tr { break-inside: avoid; }` MUST be preserved (canonical tables in analysis reports must not split rows).
  3. Short sections and `.entry`-like entries MUST keep `break-inside: avoid`; `h2 { break-after: avoid; }` MUST be preserved (no orphaned headings).
  4. The fix MUST be CSS-only, confined to the profile-analysis.html template — no HTML structure or content changes.
  5. The template MUST remain the base for cv-optimizer report rendering (content adapted, CSS never rewritten from scratch).
  6. `standards/cv-analysis.md` §6 MUST remain accurate after the fix (it already documents the refined rule — the template must catch up, not the docs).
- Acceptance criteria:
  1. `grep "section { break-inside: avoid" skills/career/cv-optimizer/templates/profile-analysis.html` → 0 matches in the print CSS.
  2. `grep "break-inside: auto" skills/career/cv-optimizer/templates/profile-analysis.html` → present with `orphans: 3; widows: 3;`.
  3. `grep "table tr { break-inside: avoid" skills/career/cv-optimizer/templates/profile-analysis.html` → still present.
  4. `grep "h2 { break-after: avoid" skills/career/cv-optimizer/templates/profile-analysis.html` → still present.
  5. `make test-scripts` passes with a regression assertion covering the template's print CSS.
- Tests:
  1. `grep "section { break-inside: avoid" profile-analysis.html` → 0 matches; `grep "break-inside: auto"` → present with orphans/widows.
  2. `grep "table tr { break-inside: avoid" profile-analysis.html` → present (table rows still protected).
  3. `grep "h2 { break-after: avoid" profile-analysis.html` → present (no orphaned headings).
  4. `make test-scripts` → exit 0 with the new/extended regression test.
- Suggested fix: Apply the same treatment as issue #203 to `skills/career/cv-optimizer/templates/profile-analysis.html`: replace the blanket `section { break-inside: avoid; }` with `section { break-inside: auto; orphans: 3; widows: 3; }`, keep `table tr { break-inside: avoid; }` and `h2 { break-after: avoid; }`, add a regression assertion in scripts/tests/test_cv.sh, and run `make test-scripts`. Effort ~1-2h. Origem: senior review do #203 (docs profile, finding 1 — incomplete-spec).

### 208. Differentiated bug discovery flow — fast, prioritized, token-efficient (still refined)
- Status: in-progress
- Opened: 2026-08-19
- Started: 2026-08-21
- In review: -
- In QA: -
- In publish: -
- Type: feat
- Severity: high
- Priority: high
- Report: william_pereira
- Base branch: main
- Reviewers: 3 (docs, qa, runtime)
- Remote: #105
- Jira: -
- PR: -
- Location: workflow.md (canonical — branch Discovery Pipeline by type), agents/development/discovery.md (orchestrator routes lean vs full), agents/development/product-owner.md (lean bug triage mode), agents/development/quality-analyst.md (lean validation), agents/development/project-manager.md (minimal rewrite — non-interactive promotion), standards/issues.md (new `- Priority:` field + `- Business rules: none` contract at L42-43 + optional `- Flow:` field), opencode.json (ocf:discovery template — 1-line adjustment), skills/development/bug-triage/SKILL.md (NEW — single source of the score matrix)
- Description: As a Product Owner, I want a differentiated discovery flow for `bug` issues — a lean triage track (PO triage → QA pre-development → PM promotion, ≤3 agent invocations) with a documented prioritization score and a clear escalation path to the full 6-phase flow — so that bug issues reach development faster, are prioritized by business impact instead of insertion order, and consume at least 50% fewer discovery tokens than the full flow while remaining refined.
- Impact: Every `bug` issue discovered through the pipeline (global `~/.config/opencode` config and any project using the template). Reduces discovery latency and token cost for the highest-volume issue type; improves prioritization correctness (critical/high bugs outrank non-critical feats — BR 8); keeps quality gates intact for bugs (business rules when applicable + `Tests:` severity floors). Non-blocking coordination note: issues #25 and #74 also touch `workflow.md` but neither is in-progress — merge-order coordination required, not a blocker.
- Business rules:
  1. Bug discovery MUST be differentiated from feat discovery: `bug` → lean track (≤3 phases); `feat` keeps the full 6-phase flow unchanged (BR from user, Phase 1).
  2. The lean track MUST run exactly three phases in order: PO triage → QA pre-development → PM promotion. CTO and Tech Lead are OPTIONAL and invoked ONLY on escalation.
  3. Bug prioritization MUST be derived from a documented score: Score = Severity + Impact + Frequency + Risk (4–15). Severity: critical=5, high=4, medium=3, low=2; Impact: blocking=4, financial=3, broad=2, isolated=1; Frequency: always=4, frequent=3, occasional=2, rare=1; Risk (regression/security): yes=+2, no=0. Buckets: 12–15→critical; 9–11→high; 6–8→medium; 4–5→low. Guard rule: severity=critical OR impact=blocking → `- Priority:` NEVER below high. The matrix lives in a single source (the `bug-triage` skill) — see BR 11.
  4. Token efficiency: the lean track MUST consume ≥50% fewer discovery tokens than the full flow, proxied by ≤3 agent invocations (PO, QA, PM) vs 6 for the full flow.
  5. Quality is mandatory for bugs too: business rules (when applicable) and `Tests:` (severity floor: critical/high ≥3, medium ≥2, low ≥1) MUST be present. Bugs with no business rule MUST declare the literal `- Business rules: none` — QA accepts this literal and REJECTS `-` (placeholder) as `incomplete-spec`.
  6. Escalation to the full 6-phase discovery MUST happen when: no root cause / no reproduction, fix is multi-layer or cross-cutting, business-rule ambiguity, security involvement, or the change touches architecture/standards. Escalated bugs MUST restart from the CTO (CTO → Tech Lead → PO#2 → QA → PM) and MUST set `- Flow: escalated`. Primary escalation decider: PO (triage); secondary: QA (lean phase 2); Developer signals gaps as new issues (existing flow).
  7. `- Base branch:` and `- Reviewers:` MUST be defined during bug discovery; PM promotion MUST be non-interactive (reads the entry fields, never asks).
  8. Progressive prioritization: critical/high bugs MUST rank above non-critical feats; a medium-severity bug persisting N days (N=7, default, configurable — documented policy, applied by the PO during triage/backlog review using existing `- Ready:`/`- Opened:` timestamps) MUST be raised to high. This is a PROCESS rule — no new scripts; future mechanization is explicitly out of scope.
  9. `standards/issues.md` MUST document the new `- Priority:` field (positioned immediately after `- Severity:`), the literal `- Business rules: none` contract for rule-less bugs (note at L42-43), and the optional `- Flow: lean | escalated` field for bugs. Feats MUST NOT carry `- Flow:` (full flow is the default). Scripts ignore extra fields (`Jira:` precedent).
  10. The `- Flow:` field MUST be set to `lean` when a bug enters via the lean track and MUST be updated to `escalated` when escalation restarts the flow at the CTO. It is informative for PM promotion — never a blocking gate.
  11. The score matrix (weights, buckets, guard rule, and two worked examples including a guard-rule case) MUST live ONLY in `skills/development/bug-triage/SKILL.md`, loaded on-demand via the skill tool by the PO during triage. Duplicating the matrix in any other file is forbidden (single source of truth).
  12. `agents/development/discovery.md` MUST read `- Type:` and route: `bug` → lean track (PO triage → QA → PM); `feat` → unchanged 6-phase flow. Escalation MUST restart from the CTO. The aging policy MUST be reflected as a triage checklist item.
  13. The `ocf:discovery` template in `opencode.json` MUST reflect the type-based routing (1-line adjustment): bugs run the lean track, feats run the full 6 phases.
  14. PM promotion for bugs MUST be non-interactive: reads `- Base branch:` and `- Reviewers:` from the entry; `- Flow:` and `- Priority:` are informative and MUST NOT block or require confirmation.
- Acceptance criteria:
  1. `workflow.md` Discovery Pipeline branches by `- Type:`: `bug` → lean track (PO triage → QA pre-development → PM promotion, ≤3 phases); `feat` → the 6-phase flow preserved verbatim (BR 1, 2, 4).
  2. `skills/development/bug-triage/SKILL.md` exists and is the single source of the score matrix (weights, buckets, guard rule, ≥2 worked examples) — the PO loads it on-demand during triage (BR 3, 11).
  3. `standards/issues.md` documents `- Priority:` (after `- Severity:`), the literal `- Business rules: none` contract (L42-43), and the optional `- Flow: lean | escalated` field for bugs; feats carry no `- Flow:` (BR 5, 9).
  4. `agents/development/discovery.md` routes lean vs full by type, documents the five escalation triggers with restart from CTO, and includes the aging checklist item (BR 6, 8, 12).
  5. `agents/development/product-owner.md` documents lean bug triage: matrix via skill, escalation decision (primary decider), aging re-triage, and `- Flow:`/`- Priority:` registration (BR 3, 6, 8).
  6. `agents/development/quality-analyst.md` validates lean bugs: `Tests:` severity floor, accepts literal `- Business rules: none`, rejects `-` as `incomplete-spec`, validates derived `- Priority:` against the matrix, and can escalate as secondary decider (BR 5, 6).
  7. `agents/development/project-manager.md` promotion is non-interactive: reads `- Base branch:` and `- Reviewers:`; `- Flow:`/`- Priority:` never prompt (BR 7, 14).
  8. The `ocf:discovery` template in `opencode.json` reflects the type-based routing (1-line change) (BR 13).
  9. The aging policy (N=7 default, configurable, timestamps-based, no new scripts) is documented in `workflow.md` and referenced by the discovery checklist (BR 8).
  10. A bug-issue fixture in final format (derived `- Priority:`, literal `- Business rules: none`, `- Tests:` scenarios, `- Flow: lean`) exists as the Developer reference for T9; `make test-scripts` passes (regression) (BR 5).
  11. The #25/#74 coordination note (shared `workflow.md`, non-blocking) is recorded in `workflow.md` (Impact).
- Tests:
  1. Bug with clear root cause + reproduction and no business rule → lean discovery runs exactly 3 phases (PO triage → QA → PM), zero CTO/TL invocations, entry carries `- Flow: lean`, `- Business rules: none`, `- Priority:` derived from the matrix, `- Tests:` meeting the severity floor → lands in `known_issues.md` with status ready.
  2. Bug with no root cause/repro, or multi-layer/cross-cutting fix, or rule ambiguity, or security, or touching architecture/standards → PO triage escalates → full discovery restarts from CTO (CTO → TL → PO#2 → QA → PM) and `- Flow:` is set to `escalated`.
  3. Bug with severity critical (5) but isolated impact (1), rare frequency (1), no risk (0) → raw score 7 (medium bucket) → guard rule overrides → `- Priority: high` (never below high).
  4. Bug with severity medium (3) and blocking impact (4) → raw score 8 (medium bucket) → guard rule overrides → `- Priority: high`.
  5. Bug entry with `- Business rules: -` (placeholder) → QA rejects as `incomplete-spec` and returns to PO refinement; the literal `- Business rules: none` is accepted.
  6. Bug with `- Priority:` absent or not matching the matrix → QA pre-development review flags it and returns to PO for re-triage.
  7. Medium-severity bug persisting ≥7 days in ready (from `- Ready:`/`- Opened:` timestamps) → PO re-triage raises `- Priority:` to high (aging rule, N=7, no new scripts).
  8. Feat issue → full 6-phase discovery preserved unchanged (PO → CTO → TL → PO → QA → PM), no lean routing.
  9. Lean bug track → agent invocation count ≤3 vs 6 for the full flow (BR 4 proxy) verified by reading the orchestration instructions in `workflow.md`/`discovery.md`, and confirmed on the first real bug after merge.
  10. Score matrix single source → grep for `blocking=4` and bucket ranges across the config → matches exist ONLY in `skills/development/bug-triage/SKILL.md` (0 matches in workflow.md, discovery.md, product-owner.md, standards/issues.md).
- Suggested fix: Effort ~9–10h across 9 tasks (T1–T9), branch `issue-208-bug-discovery-lean` off `main`:
  - T1 `standards/issues.md`: add `- Priority:` after `- Severity:`; document the literal `- Business rules: none` contract for rule-less bugs (note at L42-43); add the optional `- Flow: lean | escalated` field for bugs (feats omit it; scripts ignore extra fields — `Jira:` precedent).
  - T2 NEW `skills/development/bug-triage/SKILL.md`: single source of the score matrix (S critical=5/high=4/medium=3/low=2; I blocking=4/financial=3/broad=2/isolated=1; F always=4/frequent=3/occasional=2/rare=1; R regression/security yes=+2/no=0; Score=S+I+F+R, 4–15; buckets 12–15→critical, 9–11→high, 6–8→medium, 4–5→low; guard: S=critical OR I=blocking → never below high) + ≥2 worked examples (one guard-rule case) + escalation triggers + aging rule (N=7 default, configurable).
  - T3 `workflow.md` (canonical): branch the Discovery Pipeline by `- Type:` — `bug` → lean track (PO triage → QA pre-development → PM promotion), `feat` → unchanged 6 phases; document the aging policy (timestamps-based, no new scripts) and the #25/#74 coordination note.
  - T4 `agents/development/discovery.md`: orchestrator reads `- Type:` and routes lean vs full; escalation restarts from CTO; aging checklist item.
  - T5 `agents/development/product-owner.md`: lean bug triage mode — matrix via skill, escalation decision (primary), aging re-triage, `- Flow:`/`- Priority:` registration.
  - T6 `agents/development/quality-analyst.md`: lean validation — `Tests:` severity floor, accept literal `- Business rules: none` / reject `-`, validate derived `- Priority:`, secondary escalation.
  - T7 `agents/development/project-manager.md`: minimal rewrite — non-interactive promotion reading `- Base branch:`/`- Reviewers:`; `- Flow:`/`- Priority:` informative, never blocking.
  - T8 `opencode.json`: 1-line adjustment to the `ocf:discovery` template to reflect the type-based routing.
  - T9 Bug-issue fixture in final format (derived `- Priority:`, `- Business rules: none`, `- Tests:` scenarios, `- Flow: lean`) as Developer reference + `make test-scripts` regression pass.
  Origem: Proposal 2026-08-19-1 em prioritization.md (global).
- Review note: the `docs` reviewer profile is resolved at delivery Phase 8 via `development/technical-writer` (precedent: issues #37, #203).

### 209. Caché de credenciales git por proyecto (git creds cache)
- Status: ready
- Opened: 2026-08-19
- Ready: 2026-08-19
- Started: -
- Type: feat
- Severity: high
- Report: william_pereira
- Base branch: main
- Reviewers: 3 (security, runtime, qa)
- Remote: #106
- Jira: -
- PR: -
- Location: scripts/git-cred-cache.sh (NUEVO), scripts/config.sh, scripts/tests/test_git_cred_cache.sh (NUEVO), opencode.json, agents/development/developer.md, agents/development/committer.md, agents/development/publish-requester.md, .opencode/.gitignore, scripts/test-runner.sh (EXCLUDE_RE), standards/decisions.md, scripts/README.md
- Description: Como agente del pipeline de opencode, quiero un caché de credenciales git por proyecto (`.opencode/cache/git/`) gestionado por un único script seguro, para autenticarme y crear commits en operaciones automáticas (`--auto`) sin prompts interactivos ni exposición de secretos en salidas, logs o fingerprints.
- Impact: Todos los agentes y comandos que ejecutan git en modo automático (`--auto`, pipeline de delivery, aibot-watcher); seguridad del repositorio (secretos en texto plano con 0600); coordinación con snapshot/sync-back del issue #74; fingerprints del test-runner (nunca deben contener credenciales).
- Business rules:
  1. El caché DEBE ser por proyecto en `.opencode/cache/git/` y DEBE estar gitignored: se añade `cache/` a `.opencode/.gitignore`.
  2. Contenido SPLIT: `.opencode/cache/git/credentials` (formato git credential store) y `.opencode/cache/git/identity` (`name=`/`email=`). Las credenciales NUNCA DEBEN servirse para identidad ni viceversa.
  3. Seguridad MÁXIMA: directorio 0700 y archivos 0600 aplicados en CADA escritura (independiente del umask); redacción centralizada vía helper `redact_secret()` en scripts/config.sh; DENY de read y edit sobre `.opencode/cache/**` en los permisos (acceso SOLO vía script); gate de test `assert_not_contains`; lista global de denegación bash intacta; reglas de denegación con orden findLast para `--auto`.
  4. Integración git: `git config --local credential.helper 'store --file=<ABS>/.opencode/cache/git/credentials'` (store nativo de git, ruta ABSOLUTA) + `git config --local credential.interactive never`, de modo que `--auto` falle en vez de emitir un prompt.
  5. Auto-import AUTOMÁTICO: cuando un agente recibe credenciales en sesión (chat del usuario, env vars como GITLAB_TOKEN/GH_TOKEN, config de repo), DEBE escribirlas vía script sin re-preguntar; la escritura DEBE ser idempotente (salta si la entrada es válida) y `--force` sobrescribe; env var vacía se trata como ausente.
  6. Entrypoint único: `scripts/git-cred-cache.sh` con subcomandos `--init`, `--set`, `--get` (enmascarado), `--erase`, `--identity` y `--status` (100% redactado — también enmascara el email de identidad como `<set>`).
  7. Identidad de commit: se aplica vía `-c user.name/-c user.email` desde el caché cuando la config del repo no la tiene; NUNCA se muta `.git/config` para identidad ni secretos (el único campo que `--init` escribe en `.git/config` es `credential.helper`/`credential.interactive`).
  8. Fail-silent: caché ausente o ilegible → sin prompts (incluido stdin cerrado) y sin secretos en mensajes de error; `--status` es la ruta de diagnóstico.
  9. Permisos por agente: developer.md con bash granular (deny catch-all + `git *` allow + `*scripts/git-cred-cache.sh *` allow + denies destructivos AL FINAL); committer.md y publish-requester.md degradados de `bash: allow` a scoped (preservando `gh *`/`glab *`).
  10. Perfil de revisión: `3 (security, runtime, qa)`; el reviewer `security` es el gate OWASP (delegado a development/security-owasp), que DEBE rechazar la aprobación si hay vulnerabilidades critical/high sin resolver; `qa` cubre la regla 12 (superficie de test-runner).
  11. Coordinación con #74 (existe, status ready): el caché es SOLO host-side y DEBE excluirse de snapshot/sync-back; los contenedores continúan con env-injection.
  12. `EXCLUDE_RE` de test-runner.sh DEBE excluir `.opencode/cache` — las credenciales NUNCA entran en fingerprints (cross-dep con #210, misma superficie de archivo).
  13. ADR en standards/decisions.md: texto plano 0600 = modelo estándar de git; sin cifrado en reposo (límite declarado).
- Acceptance criteria:
  1. `--init`/`--set` crean `.opencode/cache/git/` con directorio 0700 y archivos 0600 (verificable con `stat`, incluso bajo umask 000/022).
  2. `--set` repetido con la misma entrada es idempotente (no duplica); `--force` sobrescribe la entrada válida; escrituras concurrentes dejan el store íntegro (flock/escritura atómica).
  3. `--get` devuelve valores enmascarados; `--status` no muestra ningún secreto ni el email de identidad (aparece como `<set>`).
  4. Credenciales e identidad se almacenan en archivos separados y nunca se sirven de forma intercambiada (`--get` nunca emite `name=`/`email=`; `--identity` nunca emite el token).
  5. opencode.json deniega read/edit de `.opencode/cache/**` (regla findLast) para agentes en `--auto`; el acceso ocurre solo vía script; los archivos de agentes (developer/committer/publish-requester) contienen las configuraciones de permisos granulares.
  6. El auto-import escribe automáticamente credenciales provenientes de GITLAB_TOKEN/GH_TOKEN, env vars o chat, sin re-preguntar; env var vacía no crea entrada.
  7. Con caché ausente/ilegible (chmod 000) y stdin cerrado, los comandos no emiten prompt y no exponen secretos en errores; `--status` sigue funcionando como diagnóstico.
  8. `--init` configura `credential.helper` (store apuntando al archivo del caché, ruta absoluta) y `credential.interactive never` en la config git local.
  9. La identidad se aplica vía `-c user.name/-c user.email` sin modificar `.git/config` para identidad/secretos cuando el repo no la define.
  10. El gate `assert_not_contains` pasa: sin secretos en salidas, logs o fingerprints (EXCLUDE_RE excluye `.opencode/cache`).
- Tests:
  1. `--set` con GITLAB_TOKEN en sesión bajo umask 000 y 022 → `.opencode/cache/git/credentials` con 0600 y directorio 0700; `--status` muestra todo enmascarado (email como `<set>`)
  2. `--get` con caché ausente e ilegible (chmod 000) y stdin cerrado (`</dev/null`) → sin prompt, sin secretos en el error, sin bloqueo; `--status` disponible como diagnóstico
  3. `--set` concurrente (2 invocaciones paralelas) → store íntegro y válido, una sola entrada; symlink en `.opencode/cache` → el script no escribe siguiendo el symlink fuera del proyecto (`pwd -P`)
  4. `GITLAB_TOKEN=""` (vacío) → tratado como ausente, sin entrada en el store; `--erase` posterior → `--get` fail-silent, `--status` muestra sin set
  5. grep de secretos y del email de identidad en la salida de `--status`, en errores y en logs → `assert_not_contains` pasa (0 coincidencias); cruce bidireccional: `--get` nunca emite identidad, `--identity` nunca emite el token
  6. Aserciones de configuración: opencode.json con read/edit-deny sobre `.opencode/cache/**` (orden findLast) + archivos de agentes con bash granular (deny catch-all, allows scoped, denies destructivos al final) → agentes denegados en `--auto`; acceso solo vía `git-cred-cache.sh`
  7. `--init` en un repo → `credential.helper` apunta al store del caché (ruta absoluta) y `credential.interactive=never`; `--set` repetido no duplica entradas y `--force` sobrescribe; EXCLUDE_RE de test-runner excluye `.opencode/cache` (tocar el caché no invalida fingerprint)
- Suggested fix: implementar `scripts/git-cred-cache.sh` como punto único de acceso (subcomandos `--init`/`--set`/`--get`/`--erase`/`--identity`/`--status`) con permisos 0700/0600 en cada escritura, redacción centralizada vía `redact_secret()` en `config.sh`, deny de read/edit sobre `.opencode/cache/**` con orden findLast para `--auto`, auto-import idempotente e integración git vía `credential.helper store` + `credential.interactive never`; ajustar permisos por agente (developer/committer/publish-requester), EXCLUDE_RE del test-runner y ADR en `standards/decisions.md`. Esfuerzo ~9-11h. Origem: Proposal 2026-08-19-2 em prioritization.md (global).

### 211. Dividir ocf:develop en dos comandos: ocf:develop (hasta MR, merge manual) y ocf:develop-full (auto-merge)
- Status: in-publish
- Opened: 2026-08-19
- Ready: 2026-08-19
- Started: 2026-08-19
- In publish: 2026-08-19
- Type: feat
- Severity: high
- Report: william_pereira
- Base branch: main
- Reviewers: 3 (runtime, devops, qa)
- Remote: #108
- Jira: -
- PR: -
- Location: opencode.json (template ocf:develop + nuevo ocf:develop-full), commands/ocf:develop.md, commands/ocf:develop-full.md (NUEVO), workflow.md, scripts/aibot-watcher.sh, scripts/run-ci-workflow.sh, scripts/tests/test_watcher_e2e.sh, scripts/tests/test_run_ci_workflow.sh, README.md, commands/README.md, agents/development/delivery.md, agents/development/develop-router.md, Dockerfile (comentario), skills/development/delivery-session-planner/SKILL.md
- Description: Como usuario del pipeline de opencode, quiero dividir el comando `ocf:develop` en dos variantes — `ocf:develop` que ejecuta el flujo completo hasta la CREACIÓN del MR y luego espera el merge manual, y `ocf:develop-full` que además auto-mergea las tareas recibidas (comportamiento actual de `ocf:develop`) — para poder elegir entre un punto de control humano antes del merge o una entrega totalmente automatizada.
- Impact: Todos los agentes y comandos que invocan el pipeline end-to-end: usuario, aibot-watcher (trigger `@aibot:develop`), CI headless (run-ci-workflow.sh), delivery-session-planner. El watcher y el CI dependen HOY del auto-merge de `ocf:develop` — tras la división DEBEN apuntar a `ocf:develop-full` para no perder la automatización. Los tests e2e (test_watcher_e2e.sh, test_run_ci_workflow.sh) asertan el comando `ocf:develop` y deben ajustarse por vía de trigger.
- Business rules:
  1. `ocf:develop` DEBE ejecutar el flujo completo hasta el paso 5 (promote → develop → senior review → QA → correcciones → committer gate → Publish Requester crea el MR) y DETENERSE. NO mergea, NO vuelve a la base, NO cierra/archiva. La issue queda en `in-publish` con `PR: #<n>` y el MR abierto.
  2. `ocf:develop` DEBE reportar el link del MR y el estado "esperando merge manual" en la notificación final (Telegram + resumen en sesión). El cierre/archivo se delega a `ocf:check-pr` / Close Requester tras el merge manual.
  3. `ocf:develop-full` DEBE mantener el comportamiento END-TO-END actual de `ocf:develop`: auto-merge autorizado (gh/glab), checkout local de la base actualizada, cierre de la issue remota + archivo local vía close_issue.sh. Después de la creación del MR, continúa sin pausa.
  4. Ambos comandos DEBEN aceptar el mismo formato de argumentos (lista de IDs, espacios/comas/guiones/#), deduplicar preservando orden, procesar secuencialmente y detenerse en el primer fallo (una única notificación de error).
  5. Ambos DEBEN enviar EXACTAMENTE una notificación Telegram al final (éxito o fallo), nunca intermedias; subagentes del pipeline (delivery, develop-router, implementación) siguen sin notificar.
  6. `aibot-watcher.sh` DEBE cambiar su trigger de `ocf:develop` a `ocf:develop-full` para preservar la semántica de auto-merge del `@aibot:develop` (BR 3 del watcher, issue #39).
  7. `run-ci-workflow.sh` (paso headless) DEBE usar `ocf:develop-full` en lugar de `ocf:develop` para mantener el auto-merge en CI.
  8. Los tests de scripts (`test_watcher_e2e.sh` línea 69/193-194, `test_run_ci_workflow.sh` línea 427) DEBEN asertar el comando correcto según la vía de trigger (watcher/CI → `ocf:develop-full`).
  9. `workflow.md` DEBE documentar la división: la sección "Exception — /ocf:develop full flow" pasa a describir `ocf:develop-full`; `ocf:develop` termina en MR con merge manual; la regla de no-polling del watcher se mantiene (el merge manual es del usuario, `ocf:check-pr` cierra).
  10. La documentación (README.md, commands/README.md, commands/ocf:develop.md, commands/ocf:develop-full.md nuevo, descripción en develop-router.md y delivery.md) DEBE reflejar la división; delivery.md ya cubre el "Post-merge pause" para `ocf:develop` (Phase 12 solo tras notificación de merge).
  11. Sin cambios de comportamiento en delivery/develop-router: ambos comandos invocan `development/delivery` saltando Phase 6 (ya promovido) y arrancando en Phase 7 (Developer).
- Acceptance criteria:
  1. `/ocf:develop <id>` sobre una issue `ready`/`in-progress` → issue llega a `in-publish` con `PR: #<n>`; el MR queda OPEN (no se ejecuta gh/glab merge); la issue no se archiva ni cierra; la notificación final reporta el MR y "esperando merge manual".
  2. `/ocf:develop-full <id>` sobre la misma clase de issue → mismo flujo PERO el MR se auto-mergea (gh pr merge / glab mr merge), la base local se actualiza, la issue remota se cierra y la entrada se archiva en resolved_issues.md con `Status: resolved`.
  3. Trigger `@aibot:develop` en una issue rastreada → el watcher invoca `--command ocf:develop-full <id>` (verificable en el log del watcher) y el MR se auto-mergea.
  4. CI headless (run-ci-workflow.sh) → invoca `ocf:develop-full <id>` (verificable en log) y el MR se auto-mergea.
  5. `ocf:develop 1 2` → procesa 1 hasta MR, NO lo mergea, deja la issue en `in-publish`, pasa a 2 desde la base actualizada; UNA sola notificación al final con ambos resúmenes.
- Tests:
  1. `ocf:develop <id>` en issue `ready` → `in-publish` + MR abierto; `gh pr view <n> --json state --jq .state` = OPEN; issue sin archivar; notificación final con link + "merge manual pendiente"
  2. `ocf:develop-full <id>` en issue `ready` → MR auto-mergeado (state MERGED); base local actualizada; issue cerrada + archivada con `Status: resolved`
  3. watcher con `@aibot:develop` → log del watcher contiene `--command ocf:develop-full <local_id>` (test_watcher_e2e.sh actualizado) y el MR termina MERGED
  4. CI headless → log contiene `--command ocf:develop-full <id>` (test_run_ci_workflow.sh actualizado) y MR MERGED
  5. `ocf:develop` con lista de 2 issues → secuencial: 1ª termina en `in-publish` sin merge, 2ª procesada desde la base; exactamente UNA notificación Telegram final
- Suggested fix: dividir el template de `ocf:develop` en opencode.json — `ocf:develop` conserva los pasos 1-5 + reporte "esperando merge manual" (sin pasos 6-8), y nuevo `ocf:develop-full` con el template completo actual (auto-merge + base + close/archive); crear `commands/ocf:develop-full.md` y actualizar `commands/ocf:develop.md`; cambiar watcher y CI a `ocf:develop-full`; actualizar tests e2e, workflow.md, READMEs y comentarios Dockerfile. Esfuerzo ~4-6h.


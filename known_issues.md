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



### 212. Gate de aplicación (umbral mínimo de match) + sección preferences en el hub + énfasis en logros cuantificados para cv-tailor y cv-cover-letter
- Status: in-publish
- Opened: 2026-08-24
- Ready: 2026-08-24
- Started: 2026-08-24
- In review: 2026-08-24
- In QA: 2026-08-24
- In publish: 2026-08-24
- Type: feat
- Severity: medium
- Report: william_pereira
- Base branch: main
- Reviewers: 2 (qa, runtime)
- Remote: #125
- Jira: -
- PR: #126
- Location: scripts/cv/schema.json, scripts/cv/validate.py, scripts/cv/check-inference.sh, skills/career/cv-hub/SKILL.md, skills/career/cv-tailor/SKILL.md, skills/career/cv-cover-letter/SKILL.md, agents/career/cv-tailor.md, agents/career/cv-cover-letter.md, commands/ocf:cv-tailor.md, commands/ocf:cv-cover-letter.md, standards/cv-analysis.md, scripts/tests/test_cv.sh
- Description: Mejorar el sector career del pipeline con tres cambios coordinados: (1) nueva sección `preferences` en el hub (dislikes, excluded_roles, min_match_percentage default 70%); (2) gate de aplicación en cv-tailor y cv-cover-letter — antes de generar el artefacto se compara el weighted match % del gap analysis contra el umbral; si es menor se escribe `feedback.md` (por qué no vale la pena postularse) y se pide decisión, si es mayor o igual se procede sin confirmación; (3) resaltar logros cuantificados (números/%) primero en el currículo y anclados en la carta. Nunca se inventan cifras.
- Impact: Candidatos del sector career (todos los que usan ocf:cv-tailor/ocf:cv-cover-letter). Evita generar currículos/cartas para ofertas con bajo match o que violan preferencias declaradas; ahorra tiempo/costos; los artefactos generados destacan los logros con métricas que más pesan en selección. Backward-compatible: `preferences` es opcional en el schema y los hubs existentes siguen siendo válidos.
- Business rules:
  1. `scripts/cv/schema.json` DEBE ganar una sección opcional de nivel raíz `preferences` con `dislikes` (array de strings, cosas que no gustan o no encajan en una oferta), `excluded_roles` (array de strings, funciones que el candidato no quiere asumir) y `min_match_percentage` (integer 0–100, umbral mínimo para aplicar). La sección NO DEBE ser required — los hubs existentes sin `preferences` siguen siendo válidos.
  2. `scripts/cv/validate.py` DEBE aceptar un bloque `preferences` válido y rechazar uno inválido: `min_match_percentage` no-entero o fuera de 0–100, items de `dislikes`/`excluded_roles` no-string, y claves desconocidas dentro de `preferences` (additionalProperties). Las rutas jsonschema y fallback DEBEN coincidir en las comprobaciones semánticas compartidas.
  3. El umbral por defecto DEBE ser 70% cuando `preferences.min_match_percentage` está ausente (decisión del candidato 2026-08-24), documentado en skills y estándar.
  4. El gate DEBE aplicarse tanto a cv-tailor como a cv-cover-letter (decisión del candidato 2026-08-24).
  5. Si weighted match % < umbral → NO se genera el currículo/carta; se escribe `resumes/<slug>/feedback.md` (o `cartas/<slug>/feedback.md`) con el análisis de por qué no vale la pena postularse (match vs umbral, requisitos `not_met`/`parcial` que arrastran el puntaje, y dealbreakers de `dislikes`/`excluded_roles` que la oferta viola) y se pide decisión al candidato: proceder de todos modos o detener.
  6. Si weighted match % ≥ umbral → se procede directamente con la generación SIN pedir confirmación (la decisión del gate queda registrada en `gap-analysis.md`).
  7. cv-cover-letter DEBE reutilizar la decisión del gate de cv-tailor cuando reutiliza `resumes/<slug>/gap-analysis.md`: si cv-tailor bloqueó y el candidato no hizo override, la carta NO se genera.
  8. `feedback.md` DEBE seguir la estructura canónica de `standards/cv-analysis.md` (nuevo §3.5: H1, sin metadata header, secciones Job context / Match percentage vs threshold / Reasons not to apply / Recommendation) y escribirse en el idioma de comunicación del usuario; los tokens de protocolo (`atendido`/`parcial`/`not_met`, `[INFERIDO]`) no se traducen.
  9. cv-tailor DEBE priorizar los logros cuantificados (que contienen dígitos/%) dentro de cada rol — primero los que tienen métricas, redactados con el número prominente — y reordenar/condensar solo lo que existe en el hub; NUNCA se inventan cifras.
  10. cv-cover-letter DEBE anclar cada requisito clave de la oferta en un logro numérico específico del hub cuando existe uno; NUNCA se inventan cifras.
  11. La regla `[INFERIDO]` y el gate `check-inference.sh` siguen aplicando SOLO a los artefactos finales compartibles (index.html/PDF); `feedback.md` y `gap-analysis.md` son artefactos internos y pueden contener `[INFERIDO]` inline.
- Acceptance criteria:
  1. `schema.json` contiene la sección `preferences` (dislikes, excluded_roles, min_match_percentage); un hub con `preferences` válido pasa `validate.py` (exit 0) y un hub sin `preferences` sigue pasando.
  2. `validate.py` rechaza `min_match_percentage: 150`, `min_match_percentage: "60"` y `dislikes: [123]` en ambas rutas (jsonschema y fallback).
  3. `skills/career/cv-hub/SKILL.md` documenta la sección `preferences` en el schema canónico, en el template del README y en las reglas de consolidación; el modo update permite agregar/actualizar `preferences`.
  4. `skills/career/cv-tailor/SKILL.md`, `agents/career/cv-tailor.md` y `commands/ocf:cv-tailor.md` documentan el gate: umbral por defecto 70%, comparación antes de generar, `feedback.md` + decisión cuando match < umbral, proceder sin confirmación cuando match ≥ umbral, y priorización de logros cuantificados.
  5. `skills/career/cv-cover-letter/SKILL.md`, `agents/career/cv-cover-letter.md` y `commands/ocf:cv-cover-letter.md` aplican el mismo gate (umbral 70% default, reutiliza la decisión de cv-tailor) y el anclaje en logros numéricos.
  6. `standards/cv-analysis.md` documenta el §3.5 (feedback report) y el protocolo del gate (comparación del §4.5 contra `preferences.min_match_percentage`).
  7. `scripts/tests/test_cv.sh` incluye aserciones del nuevo contrato (schema preferences, validate.py, skills/agents/commands) y `make test-scripts` pasa (exit 0).
- Tests:
  1. Hub con `preferences.min_match_percentage: 70` y oferta con weighted match 55% → cv-tailor NO genera index.html/curriculo.pdf, escribe `feedback.md` con el análisis y pide decisión al candidato
  2. Mismo hub, oferta con weighted match 80% → cv-tailor genera el currículo directamente SIN pedir confirmación y sin `feedback.md` (decisión registrada en gap-analysis.md)
  3. Hub sin `preferences` → el umbral por defecto 70% se aplica (match 65% bloquea; match 75% procede)
  4. `python3 validate.py` sobre un hub con `preferences` válido → exit 0; con `min_match_percentage: 150`, `min_match_percentage: "60"` o `dislikes: [123]` → exit 1 (ambas rutas: normal y CV_VALIDATE_FALLBACK=1)
  5. Hub con `dislikes: ["on-site"]` y oferta on-site + match < umbral → `feedback.md` lista el dealbreaker; con match ≥ umbral → genera currículo + carta sin bloqueo
  6. cv-cover-letter que reutiliza un `gap-analysis.md` bloqueado de cv-tailor (match < 70, sin override) → NO genera la carta; tras override del candidato → la genera
  7. `grep` en cv-tailor/cv-cover-letter skills+agents+commands → documentan `min_match_percentage`, umbral 70% default y la priorización/anclaje de logros con números
  8. `make test-scripts` → exit 0 con las nuevas aserciones en test_cv.sh
- Suggested fix: (1) extender `schema.json` + `validate.py` (sección `preferences` + validación 0–100 y tipos); (2) documentar la sección en `cv-hub/SKILL.md`; (3) añadir el gate de aplicación y la priorización de logros cuantificados en `cv-tailor` y `cv-cover-letter` (skills, agents, commands); (4) documentar §3.5 + protocolo del gate en `standards/cv-analysis.md`; (5) extender `scripts/tests/test_cv.sh` y correr `make test-scripts`. Esfuerzo ~4-6h. Origen: Proposal 2026-08-24-1 en prioritization.md.

### 213. Refinar el patrón single-column ATS del currículo (jerarquía tipográfica, meta-línea con fechas alineadas, énfasis en métricas)
- Status: in-publish
- Opened: 2026-08-24
- Ready: 2026-08-24
- Started: 2026-08-24
- In review: 2026-08-24
- In QA: 2026-08-24
- In publish: 2026-08-24
- Type: feat
- Severity: medium
- Report: william_pereira
- Base branch: main
- Reviewers: 2 (qa, ux-ui)
- Remote: #127
- Jira: -
- PR: #128
- Location: skills/career/cv-pdf/templates/resume.html, skills/career/cv-pdf/SKILL.md, standards/cv-design.md, skills/career/cv-tailor/SKILL.md, agents/career/cv-tailor.md, scripts/tests/test_cv.sh
- Description: Refinar el template de referencia del currículo (resume.html) y el estándar cv-design.md con un patrón single-column tipográfico refinado que respeta todas las reglas ATS: header lockup (nombre 17–20pt, cargo 11pt), nueva meta-línea `.entry-head` con título/empresa a la izquierda y fechas a la derecha en flex de una sola línea, énfasis de métricas cuantificadas vía `<strong>` (texto real, sin alterar cifras), y ritmo de espaciado refinado (~7mm entre secciones). Preserva las reglas de impresión existentes (break-inside:avoid en .entry, break-inside:auto + orphans/widows en secciones, break-after:avoid en h2/.header).
- Impact: Todos los currículos generados por ocf:cv-tailor (el template es la base obligatoria del sector). Mejora la calidad percibida del entregable principal sin romper ATS; riesgo bajo (cambio de template + estándar + instrucción de contenido).
- Business rules:
  1. El template DEBE conservar `@page { size: A4; margin: 12mm 15mm; }`, la fuente `Helvetica, Arial, sans-serif`, sin Google Fonts, sin emoji, layout single-column (sin `columns`/multicol) y sin tablas complejas.
  2. La meta-línea `.entry-head` DEBE ser flex en UNA línea de texto (título · empresa a la izquierda, fechas a la derecha con `justify-content: space-between`); NO DEBE ser tabla ni multicol; el DOM DEBE mantener orden de texto legible secuencialmente para el ATS.
  3. Las métricas/números de los logros cuantificados DEBEN envolverse en `<strong>` (texto real seleccionable) — NUNCA se alteran las cifras del hub; es énfasis visual únicamente.
  4. Las reglas de impresión existentes DEBEN preservarse: `.entry { break-inside: avoid; }`, `section { break-inside: auto; orphans: 3; widows: 3; }`, `.header`/`h2 { break-after: avoid; }` (sin regresión del issue #203).
  5. `standards/cv-design.md` DEBE documentar el patrón refinado (jerarquía 17–20pt/11pt/10.5–11pt/9.5–10.5pt, `.entry-head`, `<strong>` para métricas) y su checklist §5 DEBE incluir las nuevas aserciones.
  6. La instrucción de cv-tailor (skill y agent) DEBE indicar envolver las métricas de los logros cuantificados en `<strong>`.
  7. El cambio DEBE mantener el page-count estándar (§4: 1 página junior/pleno, máx. 2 senior+).
- Acceptance criteria:
  1. `resume.html` contiene `.entry-head` con `display: flex; justify-content: space-between` y una regla para `.dates`/`.meta` alineada; el `@page A4 12mm`, la fuente del sistema y las reglas de impresión existentes se conservan.
  2. El template sigue pasando las aserciones existentes de test_cv.sh (break-inside:auto en secciones, break-inside:avoid en .entry, break-after:avoid en h2/.header, sin Google Fonts/emoji).
  3. `standards/cv-design.md` documenta el patrón refinado y el checklist §5 lo incluye.
  4. `cv-tailor` skill/agent indican envolver las métricas en `<strong>`.
  5. `make test-scripts` pasa (exit 0) con las nuevas aserciones.
- Tests:
  1. `grep` en resume.html → `.entry-head`, `justify-content: space-between`, `.dates` presentes; `@page`/`A4`/`12mm`/`Helvetica` presentes; `break-inside: auto`, `.entry { break-inside: avoid; }`, `h2 { break-after: avoid; }` presentes; sin `fonts.googleapis.com` ni emoji
  2. `grep` en standards/cv-design.md → documenta `.entry-head` (o "meta-line"/"fechas alineadas") y `<strong>` para métricas en §3 y §5
  3. `grep` en cv-tailor skill y agent → instrucción de envolver métricas en `<strong>`
  4. `bash scripts/tests/test_cv.sh` → exit 0 (las aserciones nuevas y existentes pasan)
  5. Render con Chrome de un currículo con logros cuantificados → `pdftotext` extrae el texto con las cifras intactas (el `<strong>` no altera el texto) y el PDF sigue siendo ATS-parsable
  6. Currículo junior/pleno renderizado → `pdfinfo` reporta exactamente 1 página (page-count §4 preservado)
- Suggested fix: (1) refinar `skills/career/cv-pdf/templates/resume.html` (header lockup, `.entry-head` flex con fechas a la derecha, ritmo de espaciado, nota de `<strong>` para métricas) preservando las reglas de impresión; (2) actualizar `standards/cv-design.md` (§3 jerarquía + `.entry-head` + `<strong>`, §5 checklist); (3) añadir la instrucción de `<strong>` para métricas en cv-tailor skill y agent; (4) extender `scripts/tests/test_cv.sh` y correr `make test-scripts`. Esfuerzo ~3-5h. Origen: Proposal 2026-08-24-2 en prioritization.md.

### 214. Aplicar "Swiss Measure" al template del currículo — numerales tabulares, escala tipográfica tokenizada, negrita racionada, hairline endurecido y footer de página 2
- Status: in-publish
- Opened: 2026-08-24
- Ready: 2026-08-24
- Started: 2026-08-24
- In review: 2026-08-24
- In QA: 2026-08-24
- In publish: 2026-08-24
- Type: feat
- Severity: medium
- Report: william_pereira
- Base branch: main
- Reviewers: 2 (qa, ux-ui)
- Remote: #129
- Jira: -
- PR: #130
- Location: skills/career/cv-pdf/templates/resume.html, standards/cv-design.md, skills/career/cv-tailor/SKILL.md, agents/career/cv-tailor.md, scripts/tests/test_cv.sh
- Description: Implementar la dirección de diseño "Swiss Measure" del art-director (design_spec.json) en el template del currículo: espina de numerales tabulares (font-variant-numeric: tabular-nums en .dates/.contact/strong), escala tipográfica tokenizada en :root (--name 18pt, --role 11pt, --h2 10.5pt uppercase, --body 10pt, --meta 9.5pt), negrita racionada (<strong> solo para métricas), hairline endurecido (una sola regla 0.4pt bajo h2), footer de página 2 (nombre · página x de y, solo senior+), verificación pdftotext-diff en cv-tailor, y documentación en cv-design.md (§3.1 tabla de escala, §3.8 numerales tabulares, §3.7 reforzado, §5 lint grep). Todo 100% ATS-safe.
- Impact: Todos los currículos generados por ocf:cv-tailor (template obligatorio). Mejora el escaneo humano de ~6s (los números de impacto se alinean y resaltan) sin romper el parsing ATS; riesgo bajo (cambios CSS/tipográficos visuales + verificación mecanizada de dígitos).
- Business rules:
  1. El template DEBE aplicar `font-variant-numeric: tabular-nums;` y `font-feature-settings: 'tnum' 1;` en `.dates`, `.contact` y `strong`. Los dígitos NUNCA se alteran (ATS + gate de no-fabricación).
  2. La escala tipográfica DEBE centralizarse en custom properties `:root`: `--name: 18pt/700/-0.015em`, `--role: 11pt/600`, `--h2: 10.5pt/700 uppercase +0.05em`, `--body: 10pt/1.45`, `--meta/--dates/--contact: 9.5pt`; los valores hardcodeados DEBEN reemplazarse por los tokens.
  3. `<strong>` DEBE reservarse exclusivamente para métricas cuantificadas; cv-design.md §3.7 DEBE declarar "bold MUST NOT be used for any non-metric text".
  4. El sistema de hairline DEBE ser una única regla estructural: 0.4pt solid #d9d9d9 bajo h2 (padding-bottom 1.2mm); cualquier otro borde DEBE prohibirse en §3.4.
  5. cv-design.md DEBE documentar: §3.1 tabla de escala en puntos (valores exactos de la BR 2), nuevo §3.8 "Tabular numerals", §3.7 reforzado, y §5 con un item de lint grep manual de patrones prohibidos (`columns|multicol|<table|<img|fonts.googleapis|emoji`).
  6. El template DEBE incluir un `<footer class="page-footer">` (9pt muted) que cv-tailor inyecta con "nombre · página x de y" SOLO cuando el PDF supera 1 página (2-pass: render → pdfinfo → inyectar → re-render); para 1 página DEBE omitirse.
  7. cv-tailor DEBE verificar tras generar el PDF: diff `pdftotext` del PDF contra el HTML fuente — las secuencias de dígitos DEBEN coincidir exactamente.
  8. Todas las reglas ATS/print existentes DEBEN preservarse: @page A4 12mm 15mm, Helvetica/Arial/sans-serif, single-column (sin multicol/tablas), `.entry { break-inside: avoid; }`, `section { break-inside: auto; orphans: 3; widows: 3; }`, `.header`/`h2 { break-after: avoid; }`, sin Google Fonts, sin emoji, WCAG AA.
  9. El template DEBE seguir siendo la base obligatoria de cv-tailor (adaptar contenido, nunca reescribir CSS desde cero).
- Acceptance criteria:
  1. `resume.html` tiene `tabular-nums` y `'tnum' 1` en `.dates`, `.contact` y `strong`; las custom properties `--name/--role/--h2/--body/--meta` están en `:root` y los estilos las usan; el footer `.page-footer` existe.
  2. cv-design.md §3.1 (tabla de escala), §3.7 (negrita racionada), §3.8 (numerales tabulares) y §5 (lint grep) documentan las nuevas reglas.
  3. cv-tailor skill/agent documentan la verificación pdftotext-diff y la inyección 2-pass del footer.
  4. `scripts/tests/test_cv.sh` incluye aserciones de las nuevas reglas (tabular-nums, tokens, negrita racionada, footer, lint) y `make test-scripts` pasa (exit 0).
  5. Render mecanizado: un currículo con métricas → `pdftotext` extrae los dígitos idénticos al HTML fuente; un currículo junior/pleno → exactamente 1 página sin footer; un senior 2 páginas → footer presente en la página 2.
- Tests:
  1. `grep` en resume.html → `tabular-nums`, `'tnum' 1`, `--name: 18pt`, `--role: 11pt`, `--h2`, `--body`, `page-footer` presentes; `@page`/`A4`/`12mm`/`Helvetica` presentes; `break-inside: auto`, `.entry { break-inside: avoid; }`, `h2 { break-after: avoid; }` presentes; sin `fonts.googleapis.com` ni emoji
  2. `grep` en standards/cv-design.md → §3.8 "Tabular numerals" (o "tabular"), §3.7 "MUST NOT be used for any non-metric text", §5 item de lint grep (`multicol|<table|<img`)
  3. `grep` en cv-tailor skill y agent → paso de verificación `pdftotext` (diff de dígitos) y footer 2-pass (página 2)
  4. Render senior 2 páginas → `pdfinfo` ≥ 2 páginas y el texto del footer ("Página 2 de 2" o equivalente) aparece en la página 2; render junior → exactamente 1 página sin footer
  5. Render con métricas → `pdftotext` del PDF contiene los dígitos idénticos a la fuente (30%, 25%, etc.) — la espina tabular no altera el texto
  6. `bash scripts/tests/test_cv.sh` → exit 0
  7. `make test-scripts` → exit 0 (15 archivos)
- Suggested fix: (1) en resume.html: añadir tabular-nums/'tnum' a .dates/.contact/strong, crear las custom properties :root de la escala y reemplazar tamaños hardcodeados, añadir `<footer class="page-footer">` con CSS 9pt muted; (2) actualizar cv-design.md §3.1/§3.7/§3.8/§5; (3) documentar la verificación pdftotext-diff y el footer 2-pass en cv-tailor skill y agent; (4) extender scripts/tests/test_cv.sh y correr make test-scripts. Esfuerzo ~3-5h. Origen: Proposal 2026-08-24-3 en prioritization.md.

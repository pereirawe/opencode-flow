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

### 218. Profile-aware scoring criteria in cv-optimizer — per-domain section priorities (GitHub/project links not required for every profile)
- Status: in-publish
- Opened: 2026-08-24
- Ready: 2026-08-24
- Started: 2026-08-24
- In review: 2026-08-24
- In publish: 2026-08-24
- Type: feat
- Severity: medium
- Priority: medium
- Report: william_pereira
- Base branch: main
- Reviewers: 2 (qa, docs)
- Remote: #137
- Jira: -
- PR: -
- Location: skills/career/cv-optimizer/SKILL.md §2-§3, standards/cv-analysis.md §4.2, agents/career/cv-optimizer.md, commands/ocf:cv-optimize.md
- Description: As a candidate, I want the cv-optimizer to score my profile against criteria that fit MY area, so that missing a GitHub or project link never penalizes a profile for which it is not a requirement (e.g. lawyer, HR, marketing, commercial). Today the scoring criteria table (§3) is profile-agnostic — e.g. "links | at least LinkedIn + GitHub/site" and "projects | link = bonus" apply uniformly to every profile. The fix: detect the candidate's primary domain(s) from the hub (professional_title, skill categories, experience titles, summary) and apply per-domain section priorities (high/medium/low) that shape the section weights and criteria. The domain taxonomy MUST be extensible — new domains are derived by mapping the domain's nature to section relevance, not by an exhaustive closed list; a reference table covers the known domains (engineering, technology/IT, commercial/sales, human resources, legal, marketing, design).
- Impact: Every candidate using `ocf:cv-optimize`. Without the fix, profiles outside engineering/tech are scored against tech-centric criteria (GitHub/portfolio links treated as mandatory), producing unfair scores and wrong context-gap suggestions.
- Business rules:
  1. The optimizer MUST detect the candidate's primary domain(s) from the hub (professional_title, skill categories, experience titles, summary) before scoring — the detection is `[INFERIDO]`-marked in the report.
  2. Scoring criteria and section weights MUST be domain-relative: each domain defines high/medium/low section priorities; the criteria examples (e.g. `links` needing GitHub/site, `projects` needing links) apply per priority tier, never globally.
  3. The `links` criterion MUST be relaxed: LinkedIn is near-universal; GitHub/site/portfolio is REQUIRED only for domains where a technical/portfolio presence is expected (engineering, technology/IT, design). A missing GitHub/site MUST NOT lower the score of a non-tech profile that otherwise meets its domain's expectations.
  4. The domain taxonomy MUST be extensible: for a domain not in the reference table, the optimizer derives section priorities from the domain's nature (portfolio-driven → projects high; licensing/certification-driven → certifications high; client-facing → languages/experience high) instead of failing or defaulting to the tech template.
  5. A reference priority table MUST live in the skill for the known domains: engineering, technology/IT, commercial/sales, human resources, legal, marketing, design — each with high/medium/low per section.
  6. The per-section score rows and the Global computation from issue #215 MUST be preserved (empty sections excluded from the global; explicit weights), now with domain-relative weights.
  7. The detected domain(s) and the applied priorities MUST be reported in profile-analysis.md (General qualifications) so the candidate can audit the criteria.
  8. `standards/cv-analysis.md` §4.2 MUST document that scores are domain-relative and reference the skill's priority table.
  9. No web search, no fabrication, no change to hub.json — the detection is offline over the hub.
- Acceptance criteria:
  1. cv-optimizer skill §3 contains the per-domain priority table (engineering, technology/IT, commercial, HR, legal, marketing, design) and the extensibility rule for new domains.
  2. The `links` criterion no longer mandates GitHub/site globally — it is tiered by domain priority.
  3. The detected domain and applied priorities appear in profile-analysis.md General qualifications.
  4. A legal/HR/marketing hub without GitHub/site is NOT penalized in the links/projects rows (score reflects domain expectations).
  5. `make test-scripts` passes with the new regression assertions.
- Tests:
  1. Hub for a legal/HR/marketing profile with LinkedIn but no GitHub/site → links/projects rows are scored against the domain's expectations and do NOT force a low score; the report states the detected domain.
  2. Engineering/technology hub with GitHub + projects with links → links/projects rows score high (domain requires them).
  3. Domain NOT in the reference table → the optimizer derives priorities from the domain's nature and records the derivation (no failure, no tech-default).
  4. grep cv-optimizer/SKILL.md §3 → per-domain priority table present with the extensibility rule; grep the `links` criterion → no unconditional GitHub requirement.
  5. `make test-scripts` → exit 0 with the new/extended regression assertions.
- Suggested fix: Extend cv-optimizer/SKILL.md §2-§3 with domain detection + a per-domain priority reference table (engineering, technology/IT, commercial, HR, legal, marketing, design) and the extensibility rule; tier the `links`/`projects` criteria by priority; document domain-relative scoring in standards/cv-analysis.md §4.2; require the detected domain + applied priorities in profile-analysis.md; add regression assertions in scripts/tests/test_cv.sh; run `make test-scripts`. Effort ~3-4h.

### 219. cv-ats-score §3.2 section enumeration missing "Áreas de Atuação" (follow-up from #216)
- Status: backlog
- Opened: 2026-08-24
- Ready: -
- Started: -
- Type: chore
- Severity: low
- Priority: low
- Report: william_pereira
- Base branch: main
- Reviewers: 1
- Remote: -
- Jira: -
- PR: -
- Location: skills/career/cv-ats-score/SKILL.md §3.2, scripts/tests/test_cv.sh
- Description: Issue #216 added the "Áreas de Atuação" section to the resume template, the cv-tailor skill/agent and the cv-design/cv-analysis standards, but the cv-ats-score skill's §3.2 optional-standard-sections enumeration (used for section detection / section_completeness) was not updated to include it. Registered by the docs senior reviewer of #216 — zero scoring impact today (unknown sections are tolerated and never penalized), but the enumeration should stay in sync with the standard section set of cv-design.md §1.2 for future completeness scoring.
- Impact: Consistency only — no current scoring behavior change; keeps the career docs' section enumeration in sync with the standard set (cv-design.md §1.2, cv-analysis.md §4.7).
- Business rules:
  1. cv-ats-score/SKILL.md §3.2 optional-section enumeration MUST include "Áreas de Atuação", matching cv-design.md §1.2.
  2. Scoring behavior unchanged — the section remains optional; unknown sections stay tolerated (documented in the skill).
- Acceptance criteria:
  1. grep skills/career/cv-ats-score/SKILL.md §3.2 → "Áreas de Atuação" present in the optional-section enumeration.
  2. `make test-scripts` passes with the new regression assertion.
- Tests:
  1. grep `skills/career/cv-ats-score/SKILL.md` → "Áreas de Atuação" present in the §3.2 optional-section enumeration.
  2. `make test-scripts` → exit 0 with the new regression assertion.
- Suggested fix: Add "Áreas de Atuação" to the §3.2 optional-section enumeration in cv-ats-score/SKILL.md and one assert_contains in scripts/tests/test_cv.sh; run `make test-scripts`. Effort ~30min.




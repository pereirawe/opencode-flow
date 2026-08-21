# Scripts

Shell helpers for issue lifecycle management.

| Script | Purpose |
|--------|---------|
| `promote.sh` | Move issue from backlog→ready or ready→in-progress + branch |
| `create_issue.sh` | Create remote issue on GitHub/GitLab, populate `Remote:` field |
| `transition.sh` | Single status-transition entrypoint: update status + stamp per-stage timestamp (in-review/in-qa/in-publish) |
| `close_issue.sh` | Close remote issue, archive to `resolved_issues.md` |
| `scan_issues.sh` | Static analysis heuristics |
| `pre_commit.sh` | Pre-commit checks (tests + commit trailers) |
| `maintain.sh` | Scan known_issues for stale entries and sync status |
| `update.sh` | Check local version vs remote, apply updates |
| `backup.sh` | Intelligent timestamped backup excluding junk and preventing recursion |
| `init.sh` | Initialize `.opencode/` project config with locale and LSP detection |
| `sync_github_issues.sh` | Sync GitHub issues with local known_issues.md |
| `remote.sh` | Shared remote provider detection (github/gitlab/none/unknown) — sourced by scripts |
| `aibot-watcher.sh` | Poll remote issue comments for `@aibot:develop` and trigger the develop pipeline |
| `aibot-watcher.service` | Systemd oneshot unit template for the watcher (issue #39) |
| `aibot-watcher.timer` | Systemd timer template (`OnCalendar=*:0/2`) for the watcher (issue #39) |
| `setup-aibot-watcher.sh` | Install/uninstall the aibot watcher systemd timer + service |
| `skill-vendor.sh` | Manage external skills as git clones in `~/.config/opencode/vendor/` (add/update/list/remove) — loaded via `skills.paths`, never copied |
| `import_claude_skill.sh` | Deprecated shim — delegates to `skill-vendor.sh add` |
| `config.sh` | Shared configuration sourced by other scripts |
| `git-cred-cache.sh` | Per-project git credential cache — single secure entrypoint for `--init`/`--set`/`--get`/`--erase`/`--identity`/`--status` (issue #209) |
| `sync-jira.sh` | Jira Cloud sync (REST v3): create-card, transition, add-comment, full reconcile — hooks in create/promote/close_issue, non-blocking |
| `setup-web.sh` | Install/update opencode web systemd service for headless operation |
| `setup-nginx.sh` | Install nginx reverse proxy with mkcert HTTPS for opencode web |
| `nginx-opencode.conf` | Nginx config template — HTTP→HTTPS redirect + reverse proxy to :4096 |
| `opencode.service` | Systemd service template — replicated to other machines via `setup-web.sh` |

## Skill Vendor (external skills)

External skills are kept as **git clones** in `~/.config/opencode/vendor/` and
loaded in-place via `"skills": { "paths": ["~/.config/opencode/vendor"] }` in
`opencode.json`. They are never copied into `skills/`.

```bash
scripts/skill-vendor.sh add <git-url|owner/repo> [--sparse <paths...>]
scripts/skill-vendor.sh update <name>      # git pull — no re-import
scripts/skill-vendor.sh list
scripts/skill-vendor.sh remove <name>      # also unregisters its skills
```

Repos with multiple skills use sparse checkout so only the desired skills load
(e.g. `taste-skill --sparse skills/taste-skill skills/redesign-skill
skills/minimalist-skill`). `vendor/` is gitignored. See
`skills/shared/skill-importer/SKILL.md` for the agent-facing workflow.

## Jira Cloud sync (issue #48)

`sync-jira.sh` mirrors `known_issues.md` into Jira Cloud via the REST v3 API.
The pipeline hooks call it automatically: `create_issue.sh` creates the card,
`promote.sh` and `close_issue.sh` transition its status, and `ocf:sync-jira`
(`sync-jira.sh sync`) reconciles every issue that has a `- Jira:` field in one
run. Local `Status:` is the source of truth — Jira is a mirror.

Config: `.opencode/jira.json` (or env vars) + `JIRA_API_TOKEN` env. Without a
valid config the sync is disabled and the pipeline behaves exactly as before
(zero Jira calls). All operations are non-blocking and idempotent. `baseUrl`
should be `https://` (Basic auth over `http://` would leak email+token in
cleartext) — treat `jira.json` as an operator-owned, trusted file. Network
calls are bounded by `JIRA_CURL_TIMEOUT` (default 5s connect) and
`JIRA_CURL_MAXTIME` (default 30s total) so a hung host can never freeze the
pipeline. `JIRA_CONFIG_FILE` overrides the config path (default
`.opencode/jira.json`).

```bash
scripts/sync-jira.sh config                 # resolved config (no secrets)
scripts/sync-jira.sh ensure-card <file> <id>  # create card if Jira: -
scripts/sync-jira.sh transition <file> <id>   # move card to mapped status
scripts/sync-jira.sh add-comment <file> <id>  # one-way repo → Jira comment
scripts/sync-jira.sh sync [file]              # reconcile all cards
```

See `standards/mcp-registry.md` (Jira Cloud sync) for the full config schema
and the optional per-project Jira MCP server (agent-side backlog reads only —
the pipeline sync always lives in this script).

## Web Service

The `opencode.service` template runs `opencode web` as a persistent systemd
service. Use `setup-web.sh` to install from the template, or create it manually:

```bash
#!/bin/bash
USUARIO=$(whoami)
ARQUIVO="/etc/systemd/system/opencode.service"

sudo tee "$ARQUIVO" > /dev/null <<EOF
[Unit]
Description=Opencode web
After=network.target

[Service]
ExecStart=/home/$USUARIO/.opencode/bin/opencode web
Restart=always
RestartSec=5
User=$USUARIO

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable opencode.service
sudo systemctl start opencode.service
sudo systemctl status opencode.service --no-pager
```

Ou usar o script automatizado:

```bash
# Install/update (interactive)
./scripts/setup-web.sh

# Install/update (non-interactive)
sudo ./scripts/setup-web.sh --user william_pereira --bin /home/william_pereira/.opencode/bin/opencode

# Remove service
./scripts/setup-web.sh --uninstall

# Restart after config changes (agents, skills, commands)
sudo systemctl restart opencode
```

### Full service management

> **Terminal:** the commands use `sudo systemctl` — run them **in your terminal**,
> not from inside opencode (the agent has no terminal for the sudo password).
> The `ocf:start-web`/`ocf:stop-web`/`ocf:restart-web`/`ocf:reset-web`/
> `ocf:setup-web` commands only show the right command for you to run.

| Action | Command | `ocf:` |
|------|---------|--------|
| Create/install/update | `scripts/setup-web.sh [--user U] [--bin P]` | `ocf:setup-web` |
| Start | `sudo systemctl start opencode` | `ocf:start-web` |
| Stop | `sudo systemctl stop opencode` | `ocf:stop-web` |
| Restart | `sudo systemctl restart opencode` | `ocf:restart-web` |
| Status | `systemctl status opencode --no-pager` | — |
| Reset sessions + restart | `scripts/reset-web.sh` | `ocf:reset-web` |

**Clearing the cache/sessions** (`scripts/reset-web.sh`): the session database
(`~/.local/share/opencode/opencode.db`) grows with use (it can reach GBs).
The reset does `stop` → moves the database to a timestamped backup in
`~/.local/share/opencode/backups/` → clears `log/` → `start`. `auth.json` and
`account.json` are preserved. Use `--list` to check the size before acting:

```bash
./scripts/reset-web.sh --list     # shows service/data-dir/DB size (no changes)
./scripts/reset-web.sh            # stop -> backup -> clear -> start
```

The service file (`scripts/opencode.service`) is version-controlled here.
To replicate to another machine: copy the repo, run `setup-web.sh` pointing at
the target user and opencode binary path. After installation, access the web
UI at `http://<host>:4096` (default port).

### Nginx Reverse Proxy (HTTPS)

Add `--with-nginx` to `setup-web.sh` to set up a **mkcert-backed HTTPS reverse
proxy** that exposes the opencode web service through `https://opencode.local`:

```bash
# Full setup: service + nginx
sudo ./scripts/setup-web.sh --user william_pereira \
  --bin /home/william_pereira/.opencode/bin/opencode \
  --with-nginx

# Custom hostname
sudo ./scripts/setup-web.sh --with-nginx --hostname opencode.myproject.local
```

What `setup-nginx.sh` does:

1. **Installs nginx** (via apt for Debian/Ubuntu, dnf for RHEL-family) if missing.
2. **Checks mkcert** — aborts with a clear error if not found (no self-signed fallback).
3. **Selects HTTP port**: tries 80 → 8080 → 8081 → … (port 80 is occupied by
   docker on this machine).
4. **Checks port 443** is free — aborts if occupied.
5. **Adds `/etc/hosts`** entry (`<hostname> → 127.0.0.1`) — idempotent.
6. **Generates certs** via `mkcert` for `<hostname>`, `127.0.0.1`, `::1` into
   `/etc/opencode/certs/` (cert 644, key 640, root:root).
7. **Renders** `nginx-opencode.conf` with HTTP→HTTPS redirect (301),
   WebSocket upgrade headers, `proxy_read_timeout 3600s`, and
   `X-Forwarded-Proto https`.
8. **Tests & reloads** nginx (`nginx -t` + `systemctl reload nginx`).
9. **Asks** about opening firewall ports (ufw/firewalld/iptables).

**Idempotent**: running twice does not duplicate config blocks or `/etc/hosts`
entries. Never touches existing vhosts or the docker container on port 80.

Uninstall only the opencode footprint:

```bash
sudo ./scripts/setup-nginx.sh --uninstall
# Removes: /etc/nginx/conf.d/opencode.conf, /etc/opencode/certs/
# Keeps:   nginx package, other vhosts, mkcert CA, /etc/hosts entry, opencode service
```

#### Firewall

During installation the script asks about opening ports. For manual setup:

```bash
# ufw
sudo ufw allow <http-port>/tcp && sudo ufw allow 443/tcp

# firewalld
sudo firewall-cmd --add-port=<http-port>/tcp --permanent
sudo firewall-cmd --add-port=443/tcp --permanent
sudo firewall-cmd --reload

# iptables (runtime only — use iptables-save to persist)
sudo iptables -A INPUT -p tcp --dport <http-port> -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT
```

#### Running standalone

`setup-nginx.sh` can also be invoked directly:

```bash
sudo ./scripts/setup-nginx.sh --hostname opencode.local
sudo ./scripts/setup-nginx.sh --hostname opencode.local --non-interactive  # skip firewall prompt
```

## Git credential cache (issue #209)

`git-cred-cache.sh` is the **single access point** for the per-project git
credential cache in `.opencode/cache/git/` (gitignored). Pipeline agents use it
to authenticate and commit under `--auto` without interactive prompts and
without exposing secrets in outputs, logs, or fingerprints.

**Layout (split, never cross-served):**

- `.opencode/cache/git/credentials` — git credential-store format
  (`https://<user>:<token>@<host>`), managed by `--set`/`--get`/`--erase`
- `.opencode/cache/git/identity` — `name=`/`email=` lines, managed by
  `--identity`

**Subcommands** (run from the project root):

```bash
scripts/git-cred-cache.sh --init                     # local git store (absolute path) + interactive never
scripts/git-cred-cache.sh --set [--host H] [--user U] [--token T] [--force]
scripts/git-cred-cache.sh --get                      # masked output
scripts/git-cred-cache.sh --identity [--set [--name N] [--email E]]
scripts/git-cred-cache.sh --erase
scripts/git-cred-cache.sh --status                   # fully redacted diagnosis
```

`--set` imports credentials from `GITLAB_TOKEN` / `GH_TOKEN` / `GITHUB_TOKEN`
(empty is treated as absent) or from explicit `--token`/`--host`/`--user`
flags. Writes are idempotent — an existing valid entry is skipped unless
`--force` is given — and are flock-protected + atomic (tmp + `mv`).

**Security model:**

- Cache dir `0700` and files `0600` applied on **every** write (umask-independent).
- Redaction centralized in `redact_secret()` (`scripts/config.sh`); `--get`
  masks tokens and `--status` never prints secrets (identity email shows as
  `<set>`).
- `opencode.json` denies read/edit of `.opencode/cache/**` (findLast rule) —
  agents under `--auto` can only reach the cache through this script.
- Fail-silent: missing/unreadable cache + closed stdin → no prompts, no
  secrets in errors; `--status` is the diagnostic path.
- Symlink-safe: the project root is resolved with `pwd -P` and writes are
  refused when `.opencode`/`.opencode/cache`/the cache dir is a symlink.
- `--init` writes only `credential.helper` (absolute path to the cache store)
  and `credential.interactive=never` to `.git/config` — never identity or
  secrets.
- `.opencode/cache` is excluded from test-runner fingerprints (`EXCLUDE_RE`),
  so touching the cache never invalidates the test-result cache.

## Aibot Watcher (issue #39)

The watcher polls remote issue comments for `@aibot:develop` and triggers the
full continuous pipeline (develop → review → QA → committer → MR) via the
opencode web server. It runs as a systemd timer every 2 minutes.

Install (requires the opencode web service to be running):

```bash
./scripts/setup-aibot-watcher.sh --user william_pereira --bin /home/william_pereira/.opencode/bin/opencode
```

- Allowlist: `~/.config/opencode/aibot-repos.json` (only repos listed there
  are watched — others are refused).
- State: cursor + per-repo lock in `~/.config/opencode/state/aibot/`.
- Messages: `standards/aibot-messages.md`, posted by `development/aibot` via
  `ocf:aibot-notify`.
- Remove: `./scripts/setup-aibot-watcher.sh --uninstall`
- Tests: `make test-scripts` (plain-bash, mock gh/glab/opencode/curl — no deps)

Scripts operate on `known_issues.md` (global or project-level).
When an issue is closed, it's archived to `resolved_issues.md` in compact format.

# Scripts

Shell helpers for issue lifecycle management.

| Script | Purpose |
|--------|---------|
| `promote.sh` | Move issue from backlog→ready or ready→in-progress + branch |
| `create_issue.sh` | Create remote issue on GitHub/GitLab, populate `Remote:` field |
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
| `setup-web.sh` | Install/update opencode web systemd service for headless operation |
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

### Gestão completa do serviço

> **Terminal:** os comandos usam `sudo systemctl` — rode-os **no seu terminal**,
> não de dentro do opencode (o agente não tem terminal para a senha do sudo).
> Os comandos `ocf:start-web`/`ocf:stop-web`/`ocf:restart-web`/`ocf:reset-web`/
> `ocf:setup-web` apenas mostram o comando certo para você executar.

| Ação | Comando | `ocf:` |
|------|---------|--------|
| Criar/instalar/atualizar | `scripts/setup-web.sh [--user U] [--bin P]` | `ocf:setup-web` |
| Iniciar | `sudo systemctl start opencode` | `ocf:start-web` |
| Parar | `sudo systemctl stop opencode` | `ocf:stop-web` |
| Reiniciar | `sudo systemctl restart opencode` | `ocf:restart-web` |
| Status | `systemctl status opencode --no-pager` | — |
| Zerar sessões + reiniciar | `scripts/reset-web.sh` | `ocf:reset-web` |

**Zerar o cache/sessões** (`scripts/reset-web.sh`): o banco de sessões
(`~/.local/share/opencode/opencode.db`) cresce com o uso (pode chegar a GBs).
O reset faz `stop` → move o banco para um backup timestamped em
`~/.local/share/opencode/backups/` → limpa `log/` → `start`. `auth.json` e
`account.json` são preservados. Use `--list` para ver o tamanho antes de agir:

```bash
./scripts/reset-web.sh --list     # mostra serviço/data-dir/tamanho do DB (sem alterar)
./scripts/reset-web.sh            # stop -> backup -> limpa -> start
```

The service file (`scripts/opencode.service`) is version-controlled here.
To replicate to another machine: copy the repo, run `setup-web.sh` pointing at
the target user and opencode binary path. After installation, access the web
UI at `http://<host>:4096` (default port).

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

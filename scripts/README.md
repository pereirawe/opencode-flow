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
| `import_claude_skill.sh` | Import skills from claude-code-templates |
| `config.sh` | Shared configuration sourced by other scripts |
| `setup-web.sh` | Install/update opencode web systemd service for headless operation |
| `opencode.service` | Systemd service template — replicated to other machines via `setup-web.sh` |

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
sudo ./scripts/setup-web.sh --user william-pereira --bin /home/william-pereira/.opencode/bin/opencode

# Remove service
./scripts/setup-web.sh --uninstall

# Restart after config changes (agents, skills, commands)
sudo systemctl restart opencode
```

The service file (`scripts/opencode.service`) is version-controlled here.
To replicate to another machine: copy the repo, run `setup-web.sh` pointing at
the target user and opencode binary path. After installation, access the web
UI at `http://<host>:4096` (default port).

Scripts operate on `known_issues.md` (global or project-level).
When an issue is closed, it's archived to `resolved_issues.md` in compact format.

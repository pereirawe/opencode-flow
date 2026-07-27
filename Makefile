SHELL := /bin/bash
CONFIG_DIR := $(dir $(lastword $(MAKEFILE_LIST)))

.PHONY: scan-issues review help promote close-issue bootstrap init maintain update review-external sync-issues close-merged bump-version restart-web setup-web

help:
	@echo "OpenCode Flow — Targets:"
	@echo ""
	@echo "== Issue Lifecycle =="
	@echo "  make scan-issues             — static analysis + /ocf:scan-issues"
	@echo "  make review                  — git diff + /ocf:review-branch"
	@echo "  make promote id=<n>          — promote issue, create feature branch"
	@echo "  make close-issue id=<n>      — close + archive issue"
	@echo "  make maintain                — scan stale entries + /ocf:maintain"
	@echo "  make commit                  — atomic semantic commit"
	@echo ""
	@echo "== Web Service =="
	@echo "  make restart-web             — restart opencode web service (apply config changes)"
	@echo "  make setup-web               — install/update systemd service for opencode web"
	@echo ""
	@echo "== Project =="
	@echo "  make update                  — git pull + update"
	@echo "  make bootstrap target=<path> — copy .opencode/ template to project"
	@echo "  make init target=<path>      — init project config"
	@echo "  make bump-version            — version bump + changelog + tag + release"
	@echo "  make backup dir=<path>       — timestamped backup"

scan-issues:
	@echo "[make] scan-issues"
	@chmod +x $(CONFIG_DIR)scripts/scan_issues.sh 2>/dev/null || true
	@bash $(CONFIG_DIR)scripts/scan_issues.sh
	@echo "Next: run /ocf:scan-issues in assistant"

review:
	@echo "[make] review"
	@cd $(CONFIG_DIR) && git status --porcelain
	@echo ""
	@cd $(CONFIG_DIR) && git diff
	@echo "Next: run /ocf:review-branch in assistant"

promote:
	@bash $(CONFIG_DIR)scripts/promote.sh $(id)

close-issue:
	@bash $(CONFIG_DIR)scripts/close_issue.sh $(id)

maintain:
	@echo "[make] maintain"
	@chmod +x $(CONFIG_DIR)scripts/maintain.sh 2>/dev/null || true
	@bash $(CONFIG_DIR)scripts/maintain.sh
	@echo "Next: run /ocf:maintain in assistant"

update:
	@echo "[make] update"
	@bash $(CONFIG_DIR)scripts/update.sh

bootstrap:
	@if [ -z "$(target)" ]; then echo "Usage: make bootstrap target=/path/to/project [locale=en]"; exit 1; fi
	@locale="$(locale)"; \
	if [ -z "$$locale" ]; then \
	  locale="en"; \
	fi; \
	bash $(CONFIG_DIR)scripts/init.sh "$(target)" "$$locale"

commit:
	@echo "[make] Atomic semantic commit"
	@echo "Run /ocf:commit in the assistant to create a structured commit"
	@echo "Format: <type>(<scope>): <description>"
	@echo "See standards/commits.md for details"

init:
	@bash $(CONFIG_DIR)scripts/init.sh "$(target)" "$(locale)"

review-external:
	@echo "[make] review-external"
	@echo "Run /ocf:review-external in the assistant to review external branches/MRs"
	@echo "Usage: provide an MR URL (GitHub/GitLab) or remote branch name"

sync-issues:
	@echo "[make] sync-issues"
	@bash $(CONFIG_DIR)scripts/sync_github_issues.sh $(filter-out $@,$(MAKECMDGOALS))

close-merged:
	@echo "[make] close-merged"
	@echo "Run /ocf:close-requester in the assistant or use \`make close-issue id=<n>\` for a single issue"

bump-version:
	@echo "[make] bump-version"
	@echo "Run /ocf:bump-version in the assistant to calculate version, update changelog, commit, tag, and publish"

restart-web:
	@echo "[make] restart-web"
	@sudo systemctl restart opencode
	@echo "Service restarted."

setup-web:
	@echo "[make] setup-web"
	@bash $(CONFIG_DIR)scripts/setup-web.sh

backup:
	@echo "[make] backup"
	@bash $(CONFIG_DIR)scripts/backup.sh "$(dir)" "$(name)" $(if $(zip),--zip)

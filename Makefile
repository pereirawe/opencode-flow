SHELL := /bin/bash
CONFIG_DIR := $(dir $(lastword $(MAKEFILE_LIST)))

.PHONY: scan-issues review help promote close-issue bootstrap init maintain update review-external sync-issues close-merged

help:
	@echo "Targets:"
	@echo "  make scan-issues        — run static analysis + prompt /ocf:scan-issues"
	@echo "  make review             — show git diff + prompt /ocf:review-branch"
	@echo "  make promote id=<n> [base=<b>] — promote issue + create feature branch from base (default: auto-detect)"
	@echo "  make close-issue id=<n> — mark known_issues entry resolved"
	@echo "  make commit             — atomic semantic commit"
	@echo "  make maintain           — scan known_issues for stale entries + prompt /ocf:maintain"
	@echo "  make update             — check and apply updates (git pull)"
	@echo "  make bootstrap target=<path> — copy .opencode/ template to target project"
	@echo "  make init target=<path> — init project with repo context (default: current dir)"
	@echo "  make review-external   — prompt /ocf:review-external for external branch/MR review"
	@echo "  make backup dir=<path> [name=<name>] [zip=1] — create intelligent backup"

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
	@mkdir -p "$(target)/.opencode"
	@cp -r $(CONFIG_DIR).opencode/. "$(target)/.opencode/"
	@locale="$(locale)"; \
	if [ -z "$$locale" ]; then \
	  locale="en"; \
	fi; \
	echo "$$locale" > "$(target)/.opencode/locale"
	@if command -v git >/dev/null 2>&1 && git -C "$(target)" rev-parse --git-dir >/dev/null 2>&1; then \
	  origin_head=$$(git -C "$(target)" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's#refs/remotes/origin/##' || true); \
	  if [ -n "$$origin_head" ]; then \
	    default_branch=$$origin_head; \
	  else \
	    default_branch=$$(git -C "$(target)" symbolic-ref HEAD 2>/dev/null | sed 's#refs/heads/##' || echo "main"); \
	  fi; \
	  sed -i "s/__DEFAULT_BRANCH__/$$default_branch/g" "$(target)/.opencode/AGENTS.md"; \
	  git -C "$(target)" remote -v 2>/dev/null | awk '{print "  - `" $$1 "` -> `" $$2 "`"}' | sort -u > /tmp/opencode_remotes; \
	  if [ -s /tmp/opencode_remotes ]; then \
	    awk 'NR==FNR{remotes[++n]=$$0;next} /^__REMOTES__$$/{for(i=1;i<=n;i++) print remotes[i];next} 1' /tmp/opencode_remotes "$(target)/.opencode/AGENTS.md" > "$(target)/.opencode/AGENTS.md.tmp" && mv "$(target)/.opencode/AGENTS.md.tmp" "$(target)/.opencode/AGENTS.md"; \
	  else \
	    sed -i '/^__REMOTES__$$/c\  <none>' "$(target)/.opencode/AGENTS.md"; \
	  fi; \
	  rm -f /tmp/opencode_remotes; \
	else \
	  sed -i 's/__DEFAULT_BRANCH__/<not a git repo>/g' "$(target)/.opencode/AGENTS.md"; \
	  sed -i '/^__REMOTES__$$/c\  <none>' "$(target)/.opencode/AGENTS.md"; \
	fi
	@echo "[make] Bootstrapped .opencode/ in $(target)"
	@echo "Locale set to: $$(cat $(target)/.opencode/locale)"
	@echo "Includes: AGENTS.md, workflow.md, opencode.json, known_issues.md"
	@echo "Project issues go in .opencode/known_issues.md, config issues in ~/.config/opencode/known_issues.md"

commit:
	@echo "[make] Atomic semantic commit"
	@echo "Run /ocf:commit in the assistant to create a structured commit"
	@echo "Format: <type>(<scope>): <description>"
	@echo "See standards/commits.md for details"

init:
	@bash $(CONFIG_DIR)scripts/init.sh "$(target)"

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

backup:
	@echo "[make] backup"
	@bash $(CONFIG_DIR)scripts/backup.sh "$(dir)" "$(name)" $(if $(zip),--zip)

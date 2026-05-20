SHELL := /bin/bash
CONFIG_DIR := $(dir $(lastword $(MAKEFILE_LIST)))

.PHONY: scan-issues review help promote close-issue bootstrap

help:
	@echo "Targets:"
	@echo "  make scan-issues        — run static analysis + prompt /roc:scan-issues"
	@echo "  make review             — show git diff + prompt /roc:review-branch"
	@echo "  make promote id=<n>     — move known_issues entry to open"
	@echo "  make close-issue id=<n> — mark known_issues entry resolved"
	@echo "  make bootstrap target=<path> — copy .opencode/ template to target project"

scan-issues:
	@echo "[make] scan-issues"
	@chmod +x $(CONFIG_DIR)scripts/scan_issues.sh 2>/dev/null || true
	@cd $(CONFIG_DIR) && bash scripts/scan_issues.sh
	@echo "Next: run /roc:scan-issues in assistant"

review:
	@echo "[make] review"
	@cd $(CONFIG_DIR) && git status --porcelain
	@echo ""
	@cd $(CONFIG_DIR) && git diff
	@echo "Next: run /roc:review-branch in assistant"

promote:
	@cd $(CONFIG_DIR) && bash scripts/promote.sh $(id)

close-issue:
	@cd $(CONFIG_DIR) && bash scripts/close_issue.sh $(id)

bootstrap:
	@if [ -z "$(target)" ]; then echo "Usage: make bootstrap target=/path/to/project"; exit 1; fi
	@mkdir -p "$(target)"
	@cp -r $(CONFIG_DIR).opencode/* "$(target)/.opencode/"
	@echo "[make] Bootstrapped .opencode/ in $(target)"
	@echo "Add the following to your project's opencode.json:"
	@echo '  "instructions": ["./.opencode/AGENTS.md", "./.opencode/workflow.md"]'

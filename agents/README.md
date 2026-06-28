# Agents

Subagent definitions for each role in the development pipeline.

Agents are loaded via OpenCode's subagent mechanism. Each agent has a specific function and can be invoked independently.

| Agent | Function |
|-------|----------|
| `cto` | Technical vision and guidelines |
| `product-owner` | Priorities and user stories |
| `project-manager` | Coordination and task assignment |
| `quality-analyst` | Quality standards and testability |
| `developer` | Feature implementation (auto-proceeds to senior review without pausing) |
| `committer` | Pre-MR gatekeeper (verifies senior review done) |
| `publish-requester` | Merge/pull request creation |
| `close-requester` | Closes remote issues after MR merge and archives to resolved_issues.md |
| `documentation` | Docs maintenance |
| `test-automation` | Automated test suites |
| `backup` | Intelligent timestamped backups excluding junk |
| `review-external` | External branch/MR review with structured report generation |
| `senior-reviewers/` | Specialized domain reviewers (10 roles) |

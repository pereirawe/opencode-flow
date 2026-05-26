# Agents

Subagent definitions for each role in the development pipeline.

Agents are loaded via OpenCode's subagent mechanism. Each agent has a specific function and can be invoked independently.

| Agent | Function |
|-------|----------|
| `cto` | Technical vision and guidelines |
| `product-owner` | Priorities and user stories |
| `project-manager` | Coordination and task assignment |
| `quality-analyst` | Quality standards and testability |
| `developer` | Feature implementation |
| `committer` | Pre-MR gatekeeper (verifies senior review done) |
| `publish-requester` | Merge/pull request creation |
| `documentation` | Docs maintenance |
| `test-automation` | Automated test suites |
| `backup` | Intelligent timestamped backups excluding junk |
| `senior-reviewers/` | Specialized domain reviewers (10 roles) |

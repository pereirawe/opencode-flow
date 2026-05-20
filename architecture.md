## OpenCode Configuration Architecture

```
AGENTS.md        ──► agents/        Subagent definitions
opencode.json    ──► commands/      Slash command docs
                   ├── skills/      Reusable skills
                   ├── scripts/     Shell helpers
                   ├── standards/   Dev patterns
                   └── known_issues.md  Tracked work
```

All configuration is project-agnostic and designed to be reused across languages, frameworks, and scopes.

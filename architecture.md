## OpenCode Configuration Architecture

```
~/.config/opencode/         Global config (auto-loaded by OpenCode)
├── opencode.json           Global settings
├── AGENTS.md               Entrypoint instructions
├── workflow.md             Pipeline rules
├── known_issues.md         Tracked work register
├── agents/                 Global agent definitions
├── skills/                 Global skills
├── commands/               Global slash commands
├── scripts/                Shell helpers
├── standards/              Development patterns
├── conventions.md          Coding conventions (template)
├── decisions.md            Architecture decision records
└── .opencode/              ══► Project bootstrap template

.project-root/              Target project (manually bootstrapped)
└── .opencode/              Project-level overrides
    ├── opencode.json       Project-specific config
    ├── AGENTS.md           Project instructions
    ├── workflow.md         Project workflow rules
    ├── agents/             Project-specific agents
    ├── commands/           Project-specific commands
    └── skills/             Project-specific skills
```

### Scopes

| Layer | Location | Load Order |
|-------|----------|------------|
| Remote | `.well-known/opencode` | 1st (base) |
| Global | `~/.config/opencode/` | 2nd (overrides remote) |
| Project | `.opencode/` or `opencode.json` | 3rd (overrides global) |

### Key Design Decisions

- **Project-agnostic**: No language/framework assumptions in agents or standards
- **Reusable**: `.opencode/` template can be copied into any project
- **Layered config**: Global provides defaults; project overrides specifics
- **Self-contained agents**: Each agent has its own frontmatter and permissions

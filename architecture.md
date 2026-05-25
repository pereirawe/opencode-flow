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
│   ├── (en/)               English (canonical, root level)
│   ├── pt/                 Português
│   └── es/                 Español
├── locale                  Active locale (e.g., "pt", "es", "en")
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
- **Multi-locale standards**: Standards documents are translated into `pt` and `es`, selected via `locale` file
- **Locale resolution**: Project `.opencode/locale` overrides global `~/.config/opencode/locale`; falls back to English if not configured
- **Discovery-to-issue flow**: CTO → PO → Tech Lead → PM → QA pipeline refines raw ideas into typed, tracked issues with acceptance criteria and tests
- **Two-phase QA**: QA reviews stories for testability early (pre-dev), and verifies quality post-senior-review (pre-MR)
- **Prioritization proposals**: PO registers proposals in `standards/prioritization.md` before promoting to `known_issues.md`
- **Agent discovery protocol**: Each agent asks context-based questions (CTO: architecture, PO: value, TL: feasibility, QA: test scenarios) to progressively refine proposals

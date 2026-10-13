---
name: agent-frontmatter
description: Create, review, revise, and validate AI agent files that use YAML frontmatter followed by Markdown instructions. Use this skill whenever someone asks to audit an existing agent, create or improve a frontmatter agent, check agent metadata or tool permissions, or work with OpenCode agents, Claude Code subagents, GitHub Copilot custom agents, or VS Code custom agents. Identify the exact host and file format first; their schemas and defaults are not interchangeable. When an agent creator is available, use it and independently validate its output.
---

# Frontmatter Agent Authoring and Review

Handle agent definitions as executable configuration plus a behavior contract. A syntactically valid file can still be undiscoverable, over-privileged, or internally contradictory. Identify the target host before editing, consult its current authoritative documentation, and validate both the YAML metadata and Markdown instructions.

## Choose a workflow

Support these modes:

- **Review**: inspect one or more existing agent files and report findings; do not edit.
- **Create**: create the requested agent at the host-appropriate path.
- **Revise**: update only the requested behavior or metadata while preserving unrelated user-authored content.
- **Batch audit**: review all requested profiles, report each separately, then summarize repeated issues.

If the requested host is not explicit, infer it from the filename, directory, config files, and repository instructions. Treat these as useful clues, not absolute proof. Ask one focused question only when the remaining ambiguity could change the schema or destination. Continue any host-independent inspection while awaiting an answer.

## Discover and use an existing creator

Before creating an agent, inspect applicable project instructions and the available skills, agents, commands, and documented workflows for a purpose-built agent creator. Invoke it through the supported mechanism when one exists and is available in the current session. A generic skill creator is not an agent creator. Do not claim to have invoked a creator that is merely mentioned or unavailable.

After the creator returns, independently review its file against the requested host, current official references, user requirements, and the checks below. Correct clear defects when authorized by the request; otherwise present the proposed corrections. If no suitable creator exists, author the file directly from the platform's official guidance.

## Identify the host and applicable format

Use the path and project configuration to distinguish formats. In mixed-host repositories, validate a file against the host that will load it, not against whichever format looks most familiar.

| Host / format | Common locations and identification | Important distinctions |
| --- | --- | --- |
| OpenCode | Global `~/.config/opencode/agents/<name>.md`; project `.opencode/agents/<name>.md`; Markdown agent definitions | Current V2 uses fields such as `description`, `mode`, `model`, and ordered `permissions` rules. A missing `mode` defaults a new custom agent to primary. The Markdown body supplies the system prompt. Do not copy legacy V1 fields into V2 definitions. |
| Claude Code | Project `.claude/agents/` or user `~/.claude/agents/`; Markdown files with YAML frontmatter | `name` and `description` are required for normal subagent files. Field spelling and casing are significant (`disallowedTools`, `permissionMode`, `mcpServers`, `maxTurns`). The Markdown body is the system prompt. Plugin agents have additional restrictions. |
| GitHub Copilot cloud agent | Repository `.github/agents/<name>.agent.md` (some docs/examples also accept Markdown files); organization/enterprise locations vary | `description` is required; `tools` omitted enables all available tools, while `tools: []` disables them. Copilot configuration uses `mcp-servers`; this differs from Claude's `mcpServers`. Check whether each property applies to the selected Copilot product surface. |
| VS Code custom agent | Workspace `.github/agents/`; user agents commonly under `~/.copilot/agents/`; `.agent.md` | Supports VS Code-specific options including `argument-hint`, `handoffs`, and `agents`. It can also load Claude-format profiles from `.claude/agents/`. Copilot cloud support for a property may differ from VS Code support. |

These paths and fields are orientation aids, not a complete schema. Products evolve, and support can differ by version, scope, editor, and execution surface. Verify any field whose validity matters against the current official documentation. If a file is shared across hosts, identify the exact consumers and validate compatibility for each; do not silently assume a common schema.

## Consult authoritative references

Fetch the relevant current official documentation before making schema-specific claims or edits. Prefer versioned docs that match the installed host when available. Useful starting points:

- OpenCode V2 agents: <https://opencode.ai/v2/docs/agents>
- OpenCode V2 configuration: <https://opencode.ai/v2/docs/config>
- Claude Code subagents: <https://code.claude.com/docs/en/sub-agents>
- GitHub Copilot custom agent configuration: <https://docs.github.com/en/copilot/reference/custom-agents-configuration>
- GitHub Copilot cloud agent creation: <https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/customize-cloud-agent/create-custom-agents>
- VS Code custom agents: <https://code.visualstudio.com/docs/agent-customization/custom-agents>

When documentation is unclear, conflicting, or does not describe the selected product surface, state the uncertainty and avoid treating an unverified key as supported. Record the references actually consulted in the final report.

## Review procedure

1. **Read the surrounding context.** Inspect repository instructions, related config, sibling agents, references, and creator-produced output. Check whether the profile name or purpose duplicates another agent or conflicts with routing conventions.
2. **Check file framing.** Confirm frontmatter starts at the file's first line and has a valid closing delimiter; treat later Markdown content independently. Check whether the host requires a non-empty body. Detect malformed YAML, duplicate keys, unexpected YAML documents, and content accidentally placed on the wrong side of the closing delimiter.
3. **Validate metadata against the chosen host.** Check required fields, allowed keys, exact key casing, value types, enums, limits, and host/version support using official documentation. Treat unknown keys according to that host's documented behavior; do not assume they cause a visible error.
4. **Check discovery and intent.** Ensure the name is valid and unambiguous, and the description clearly states the agent's responsibility and when a parent agent or user should select it. Confirm the file location and extension are discoverable for the intended scope.
5. **Check capabilities and boundaries.** Compare declared tools, MCP servers, permission rules, model selection, and invocation settings with the task. Prefer the narrowest practical capabilities. Explain broad defaults (for example, omitted tools meaning all tools) and verify ordered allow/deny behavior, inheritance, and product-specific exceptions. A visibility flag is not a security boundary.
6. **Review the Markdown prompt.** Confirm it defines a coherent mission, inputs/context, operating workflow, scope limits, expected output, and a quality gate appropriate to the task. Look for contradictory directions, vague delegation criteria, instructions that imply unavailable tools or unsupported fields, unbounded scope, claims to perform checks without evidence, and brittle duplicated policy.
7. **Check references and integrations.** Resolve referenced files, skills, agent IDs, handoffs, tool names, model IDs, and MCP server names where possible. Flag references that are missing, misspelled, unavailable on the target host, or inconsistent with the selected scope. Never expose or copy secrets into an agent file.
8. **Validate with real tools.** Use the target product's validator, parser, CLI, or documented diagnostics when available. Otherwise run an appropriate YAML parser and perform a documented manual schema check. Distinguish parse checks from full host loading: a generic YAML parse does not prove a host will discover or accept the agent. Report checks not run as not run.
9. **Make only scoped changes.** For revisions, preserve unrelated metadata, body sections, comments, and user changes. Avoid rewriting or deleting profiles outside the request. For a review-only task, do not edit.

### Prompt quality criteria

Prefer task-specific instructions over roleplay or generic claims of expertise. Make the agent's role, trigger conditions, decision boundaries, and deliverable concrete. Include discovery before action when project context affects the answer; explain how to handle uncertainty and missing information; distinguish required checks from recommendations. Keep instructions concise enough to remain maintainable, and use examples only when they clarify a recurring edge case.

For agents that can edit, execute commands, delegate, or access external systems, make consequential actions explicit and align their permissions with the prompt. Do not rely on prompt text alone to enforce a restriction that the host can enforce through tools or permissions.

## Create or revise an agent

1. Capture the intended host, scope (project/user/org), role, expected task, allowed actions, delegation needs, and output contract from the request and repository context.
2. Find and invoke a suitable existing creator as described above. If none is available, select the host-specific path and metadata from current official docs.
3. Draft a concise description for routing, the least-privilege metadata the host supports, and a structured Markdown prompt tailored to the responsibility.
4. Preserve existing profile details when revising. Do not move a file between scopes, broaden tools, change model, or change invocation behavior unless requested or necessary to meet the stated goal; surface material tradeoffs.
5. Run the review procedure on the resulting file, including an actual parse/schema or host-level validation where available.
6. Summarize what was created or changed, the validation result and its scope, and any unresolved decisions.

## Findings and final report

Give each finding a severity: **Blocker** (file will not load or violates a required constraint), **High** (material capability/security or routing failure), **Medium** (behavior, maintainability, or compatibility issue), or **Low** (minor clarity improvement). Attach file and line numbers when available, concise evidence, why it matters, and a specific fix. Separate confirmed defects from recommendations and platform-dependent uncertainty.

Use this compact structure:

```text
Result: PASS | NEEDS CHANGES | PARTIAL
Target: <host, product surface/version if known, scope>
Files: <reviewed or created paths>
Findings:
- <severity> <file:line> — evidence; impact; recommended fix
Validation:
- <command/tool> — PASS/FAIL/NOT RUN; what it establishes
Sources: <official documentation actually consulted>
```

Use `PASS` only when the checks needed for the request passed and no unresolved blocker/high finding remains. Use `PARTIAL` if validation could not establish host-level loading or a material detail remains unverified. Never describe an unrun check as a pass.

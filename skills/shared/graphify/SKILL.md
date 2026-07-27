---
name: graphify
description: Generate Mermaid.js diagrams from code structure, architecture, agent pipeline, and tracked issues
compatibility: opencode
---

## What I do

- Analyze codebase structure and generate Mermaid diagrams
- Visualize agent pipeline and workflow from `workflow.md`
- Generate architecture diagrams from `architecture.md`
- Create dependency graphs from project structure
- Visualize issue relationships from `known_issues.md`
- Write output to `.mmd` files for rendering

## Diagram types supported

- **Flowchart** (`graph TD`) — agent pipeline, workflows, state machines
- **Class diagram** (`classDiagram`) — architecture layers, module relationships
- **Dependency graph** (`graph LR`) — module/package dependencies
- **Timeline** (`timeline`) — issue lifecycle, sprint progress
- **Gitgraph** (`gitGraph`) — branch strategy visualization
- **Mindmap** (`mindmap`) — project structure, directory tree

## Rules

- Always output valid Mermaid syntax
- Prefer concise, readable diagrams over exhaustive ones
- Write diagrams to `<name>.mmd` files in the project root or `.opencode/` directory
- When referencing files, use paths relative to the diagram file location
- Prefer `flowchart` over `graph` in Mermaid v10+ (they're equivalent but `flowchart` is recommended)
- Include a `%%` comment header with the source and generation date
- Never modify source code — only read it

## Usage examples

```
# Generate architecture diagram
skill: graphify "Generate architecture diagram from architecture.md"

# Generate agent pipeline flowchart
skill: graphify "Generate agent pipeline flowchart from workflow.md"

# Generate issue dependency graph
skill: graphify "Graph issue dependencies from known_issues.md"
```

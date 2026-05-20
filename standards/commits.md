# Commit Conventions

## Format

```
<type>: <short description> (#<issue-id>)
```

## Types

| Type | Usage |
|------|-------|
| `feat` | New feature |
| `fix` | Bug fix |
| `refactor` | Code restructuring |
| `test` | Test changes |
| `docs` | Documentation |
| `chore` | Maintenance, config, deps |

## Examples

```
feat: add analytics endpoint (#6)
fix: validate URL scheme before fetch (#3)
refactor: extract service layer from handler (#7)
docs: update API documentation (#12)
```

## Rules

- Use imperative present tense
- Keep the first line under 72 characters
- Reference the issue number in parentheses
- Body is optional but encouraged for complex changes

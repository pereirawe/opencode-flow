# Branching Strategy

## Naming Convention

```
issue-<id>-<slug>
```

- `<id>`: issue number from `known_issues.md` or remote tracker
- `<slug>`: lowercase kebab-case description

Examples:
- `issue-3-weak-url-validation`
- `issue-12-add-analytics-endpoint`

## Workflow

1. Create branch from the default branch
2. Implement changes and commit
3. Push and open PR/MR
4. After merge, delete the branch

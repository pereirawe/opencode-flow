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

1. Choose base branch (default or another existing branch chosen during PM promotion)
2. Checkout and pull the base branch
3. Create feature branch `issue-<id>-<slug>` from the base branch
4. Implement changes and commit
5. Push and open PR/MR
6. After merge, delete the branch

# Contributing

Thanks for your interest in improving the OpenCode workflow.

## How to Contribute

1. **Open an issue** — describe what you want to change and why
2. **Wait for feedback** — maintainers will review and tag the issue
3. **Submit a PR** — reference the issue and follow the conventions below

## Conventions

This project follows its own pipeline. Every change must:

- Go through the full [discovery → development → review → publish](workflow.md) lifecycle
- Document business rules for any `feat` type changes
- Pass senior review before merge
- Update `known_issues.md` status at every step
- Follow the [commit conventions](standards/commits.md)

## Local Setup

```bash
git clone https://github.com/pereirawe/opencode-flow ~/.config/opencode
make help
```

## Development Flow

```bash
# 1. Create or find an issue in known_issues.md
# 2. Promote the issue
make promote id=<n>

# 3. Start development
# Run /ocf:develop <id> in the assistant

# 4. Review
# Run /ocf:review-branch in the assistant

# 5. After merge, close the issue
make close-issue id=<n>
```

## Code Style

- Follow existing patterns in the file you're editing
- Keep documentation in sync with code changes
- Use semantic commit messages

## Questions?

Open a [GitHub Discussion](https://github.com/pereirawe/opencode-flow/discussions).

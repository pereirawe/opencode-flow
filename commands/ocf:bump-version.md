## /ocf:bump-version

---

description: Calculate and apply version bump, update changelog, commit, tag, and publish to main
---

Calculate the next version based on recent commits, update `VERSION`, `CHANGELOG.md`,
and `README.md`, then commit, tag, and publish to `main`.

### Flow

1. **Read current version** from `VERSION` file and find the last git tag
2. **Analyze commits** since the last tag — classify as major/minor/patch
3. **Suggest new version** — show the user the analysis and ask for confirmation
4. **Update files** — `VERSION`, `README.md`, `CHANGELOG.md`
5. **Commit and tag** — `chore: bump version to X.Y.Z` + `git tag vX.Y.Z`
6. **Publish** — push to origin; if not on `main`, create a PR

### Bump Classification

| Commit type | Bump |
|-------------|------|
| `feat!:` or `BREAKING CHANGE:` | Major (X+1.0.0) |
| `feat:` | Minor (x.Y+1.0) |
| `fix:`, `chore:`, `docs:`, `refactor:`, `test:` | Patch (x.y.Z+1) |

The highest classification found determines the bump.

### Usage

```
/ocf:bump-version
```

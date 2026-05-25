## Development Workflow

### Agent Pipeline

1. **CTO** defines technical vision and guidelines
2. **Product Owner** defines priorities and creates user stories
3. **Project Manager** coordinates team and assigns stories
4. **Quality Analyst** ensures stories are testable and meet quality standards
5. **Developer** implements features and writes automated tests
6. **Senior Reviewers** (2 agents, parallel, by specialty) review code and identify issues
7. **Developer** implements all corrections from senior review
8. **Publish Requester** creates merge/pull request
9. **Documentation** maintains project docs
10. **Test Automation** creates and maintains test suites

### Issue Lifecycle

1. Item captured in `known_issues.md` (Status: `backlog`)
2. Refined and approved (`ready`)
3. Promoted for execution (`open`)
4. Remote issue created, work started (`in-progress`)
5. Senior review completed, corrections applied (`in-review`)
6. MR/PR created (`in-review`)
7. MR/PR approved and merged (`resolved`)

### Branch Naming

Pattern: `issue-<id>-<slug>`

### Pre-commit

- Run tests for the project language
- Warn if `known_issues.md` not updated

### Pull/Merge Request

Must include:
- Tests passing
- Issue reference
- Updated docs

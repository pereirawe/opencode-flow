## /ocf:review-external

---
description: Review external branches/MRs with structured report generation
---

Review external code branches and merge requests from other developers,
providing a structured technical report across multiple domains.

### Input

Accepts one of:
- **MR URL** — GitHub or GitLab merge/pull request URL
  - GitHub: `https://github.com/<owner>/<repo>/pull/<number>`
  - GitLab: `https://gitlab.com/<owner>/<repo>/-/merge_requests/<number>`
- **Remote branch** — a remote branch reference (e.g., `origin/feature-branch`)

### Usage

```
/ocf:review-external <mr-url|remote-branch>
```

If invoked without arguments, the agent prompts for the MR URL or remote branch.

### Flow

1. **Parse input** — Determine if the input is an MR URL (GitHub/GitLab) or
   a remote branch reference. Extract repo owner, repo name, and PR/MR number
   from URLs.
2. **Fetch remote branch** — Run `git fetch <remote> <branch>` to retrieve
   the branch if not already local.
3. **Checkout locally** — Create a local tracking branch and check it out
   for analysis.
4. **Analyze diff** — Run `git diff HEAD...<branch>` or
   `git diff main...<branch>` to get the changes.
5. **Review across domains** — Examine the code with focus on:
   - **Backend**: API design, business logic, error handling, data flow,
     service boundaries, layering
   - **Frontend**: UI components, state management, styling, accessibility
   - **Security**: Auth, input validation, injection prevention, dependency
     vulnerabilities, secrets management
   - **Data**: Database queries, schemas, migrations, data integrity
   - **Devops**: Infrastructure, CI/CD, deployment, containerization
   - **Performance**: Optimization, caching, resource usage, algorithmic
     efficiency
   - **Runtime**: Environment configuration, build, packaging, dependencies
   - **Mobile**: Mobile-specific code, responsiveness, platform compatibility
   - **UX/UI**: User experience, accessibility, design consistency, usability
   - **QA**: Test quality, coverage, edge cases, test design
6. **Classify findings** — Each finding classified as:
   - `critical` — Security vulnerability, data loss, major logic error
   - `high` — Incorrect behavior, performance regression, broken edge case
   - `medium` — Suboptimal pattern, minor logic issue, missing validation
   - `low` — Code style, naming, minor improvements
   - `nit` — Very minor suggestion, personal preference
7. **Handle incomplete specs** — If a business rule appears violated but is
   NOT documented in the MR/issue, classify as `incomplete-spec` (not `bug`)
   and register as a new issue in `known_issues.md`.
8. **Generate report** — Save a structured report to
   `.opencode/reviews/review-<branch>-<timestamp>.md`
   (report path is under the target project's opencode directory).
9. **Post critical/high findings to MR** (if applicable):
   - Only findings classified as `critical` or `high` are eligible
   - The user is asked: "Postar os <n> comentários críticos/high no MR? (s/N)"
   - If confirmed, uses `gh pr review` (GitHub) or `glab mr comment` (GitLab)

### Classification Rules

| Finding Type | What it means | Action |
|---|---|---|
| `bug` | Code violates documented acceptance criteria or business rules from the MR/issue | Flag with severity, include in report |
| `incomplete-spec` | A business rule appears needed but is NOT documented in the MR/issue | Do NOT flag as bug. Register as new issue in `known_issues.md` |
| `improvement` | Code works but could be better | Flag as medium/low/nit |

### Report Format

The report is saved to `.opencode/reviews/review-<branch>-<timestamp>.md` and
includes: review metadata, files reviewed, diff summary, findings table,
summary statistics by severity, incomplete specs list, and recommendations.

### Restrictions

- Focus ONLY on technical aspects: correctness, security, performance,
  structure, best practices
- Do NOT assume business context not explicit in the MR or referenced issue
- Do NOT comment on subjective style choices unless they violate project
  conventions
- The review is technical only — do not evaluate business value or priority

### Responsibilities

- Accept MR URLs (GitHub/GitLab) or remote branch references
- Fetch and checkout the target branch locally for analysis
- Perform structured review across all senior-reviewer domains
- Classify findings with appropriate severity levels
- Handle incomplete specs by registering them in `known_issues.md`
- Generate and save a structured report to the target project
- Optionally post critical/high findings back to the MR
- Log errors gracefully — do not block the pipeline if posting fails

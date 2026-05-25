# Code Review Guidelines

## Principles

- Review for correctness, not style (style should be automated)
- Be constructive and specific
- Separate minor nits from blocking issues
- Approve when satisfied, request changes when not
- A missing business rule is NOT a bug — it is an incomplete spec

## Checklist

- [ ] Code is correct and handles edge cases
- [ ] Tests cover the change adequately
- [ ] No security or performance regressions
- [ ] API changes are documented
- [ ] Error paths are handled
- [ ] No dead code or commented-out code
- [ ] Follows project conventions
- [ ] Business rules from the issue are correctly implemented

## Bug vs Missing Business Rule

| Finding | What it means | Action |
|---------|---------------|--------|
| **Bug** | Code violates documented acceptance criteria or business rules | Flag as blocking issue, Developer fixes |
| **Missing business rule** | The issue did not capture a business rule that is needed | Flag as `incomplete-spec` — do NOT treat as bug. Send issue back through discovery refinement (PO → TL) to document the rule, then adjust implementation |
| **Edge case** | A scenario not covered by existing tests or logic | Check if it's in acceptance criteria. If not, add as test scenario or refinement |

Senior Reviewers must classify findings correctly:
- If the acceptance criteria say X and code does Y → `bug`
- If the code does what the issue says but a business rule was overlooked in
  discovery → `incomplete-spec` (requires refinement, not a code fix against an
  incomplete spec)

## Review Flow

1. Committer does initial review
2. Publish Requester assigns Senior Reviewers by domain
3. Senior Reviewers review in parallel
4. All reviewers must approve before merge

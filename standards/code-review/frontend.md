# Frontend Code Review Standard

Scope: UI components, state management, styling, SSR/hydration, and client
performance in React/Next.js and similar stacks.

## Checklist

- [ ] Loading, error, and empty states present for every data-driven view
- [ ] Keyboard navigation and screen-reader accessibility (WCAG AA)
- [ ] No hydration mismatch in SSR (server/client markup identical)
- [ ] State updates follow the chosen pattern (TanStack Query, context, etc.)
- [ ] Bundle impact of new dependencies justified
- [ ] Forms validate on the client AND the server
- [ ] Dark mode and theme tokens used, no hardcoded colors

## Symptom Classification

| Symptom | Classification | Action |
|---------|----------------|--------|
| Hydration mismatch warning in console | bug | Fix SSR markup divergence |
| View has no empty state but the issue never specified one | incomplete-spec | Flag for discovery refinement |
| Large list renders without virtualization | edge case | Add pagination/virtualization or test |
| Button unreachable by keyboard | bug | Fix focus order and semantics |

## Related skills

- `vendor/claude-skills/engineering-team/skills/senior-frontend`
- `vendor/lovable-skills/skills/error-states-and-empty-ui`
- `vendor/lovable-skills/skills/accessibility-pass`
- `vendor/lovable-skills/skills/tanstack-query-alternative`
- `vendor/lovable-skills/skills/performance-budget`
- `vendor/lovable-skills/skills/dark-mode-and-theming`

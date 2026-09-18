# UX/UI Code Review Standard

Scope: user experience, accessibility, visual design consistency, responsive
behavior, and interaction feedback.

## Checklist

- [ ] WCAG AA contrast and keyboard/screen-reader support
- [ ] Loading, error, empty, and success feedback for every interaction
- [ ] Visual hierarchy and spacing follow design tokens
- [ ] Responsive behavior across breakpoints; no horizontal scroll
- [ ] Error messages are clear and actionable, not technical
- [ ] Focus states visible; focus order logical
- [ ] Motion/duration consistent with the design system

## Symptom Classification

| Symptom | Classification | Action |
|---------|----------------|--------|
| Contrast ratio below WCAG AA | bug | Block; fix tokens |
| Issue never specified UX states for a flow | incomplete-spec | Flag for discovery refinement |
| Layout breaks only on a rare viewport | edge case | Add responsive test scenario |
| Focus ring invisible on dark mode | bug | Fix focus styles |

## Related skills

- `skills/design/design-tokens`
- `skills/design/visual-hierarchy`
- `skills/design/reference-library`
- `vendor/lovable-skills/skills/accessibility-pass`
- `vendor/lovable-skills/skills/error-states-and-empty-ui`
- `vendor/responsive-craft/SKILL.md`

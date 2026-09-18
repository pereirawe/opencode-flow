# Mobile Code Review Standard

Scope: mobile platform conventions, touch interaction, offline resilience,
performance on devices, and screen-size adaptation.

## Checklist

- [ ] Touch targets ≥ 44px and gestures have accessible alternatives
- [ ] Offline/error states handled; no silent failures
- [ ] List rendering performant on low-end devices
- [ ] Platform permissions requested in context with rationale
- [ ] Safe-area insets and screen-size adaptation correct
- [ ] Background work bounded (no battery/network drain)
- [ ] Deep links and navigation state handled

## Symptom Classification

| Symptom | Classification | Action |
|---------|----------------|--------|
| Tap target below minimum size | bug | Block; enlarge hit area |
| Issue never specified offline behavior | incomplete-spec | Flag for discovery refinement |
| Crash only on low-memory devices | edge case | Add device test scenario |
| Permission prompt at cold start without context | bug | Move to point of use |

## Related skills

- `vendor/lovable-skills/skills/accessibility-pass`
- `vendor/lovable-skills/skills/performance-budget`
- `vendor/lovable-skills/skills/error-states-and-empty-ui`
- `vendor/lovable-skills/skills/optimistic-updates`
- `vendor/lovable-skills/skills/realtime-and-subscriptions`

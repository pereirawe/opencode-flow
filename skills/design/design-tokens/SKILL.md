---
name: design-tokens
description: Design token system for the Adorable pipeline — palette (6 functional layers + 2 accents + semantic), typography (2 families, scale xs-4xl), spacing (4pt base), radius tiers, shadow tiers, and motion durations. Use when defining or consuming tokens so every value resolves to the canonical system. Use quando precisar dos tokens de design — "design tokens", "paleta de cores", "tipografia", "espaçamento", "sombras", "radius", "motion", "cores" also trigger this skill.
---

# Design Tokens

## Palette

The palette has 6 functional layers, 2 accents, and a semantic set. Every color in a surface MUST resolve to one of these tokens.

6 functional layers:

- Layer 1 - canvas (page background): `#f8fafc`; dark mode `#0f172a`.
- Layer 2 - surface (cards, panels): `#ffffff`; dark mode `#1e293b`.
- Layer 2.5 - hover / subtle fill (row hover, skeleton blocks, neutral badge, table dividers): `#f1f5f9`; dark mode `#334155`.
- Layer 3 - raised (headers, sticky rows): `#f8fafc`; dark mode `#334155`.
- Layer 4 - border (dividers, outlines): `#e2e8f0`; dark mode `#334155`.
- Layer 5 - text: primary `#0f172a`, muted `#64748b`, neutral `#334155`, inverse `#ffffff`; dark mode primary `#f8fafc`, muted `#94a3b8`, neutral `#94a3b8`.

2 accents:

- Accent primary: base `#4f46e5`, strong `#4338ca`, soft `#eef2ff`, fallback `#4f46e5` (avatar initials); dark mode strong `#818cf8`.
- Accent secondary: base `#0ea5e9`, strong `#0284c7`, soft `#e0f2fe`; dark mode strong `#38bdf8`.

Semantic:

- Success: base `#16a34a`, strong `#15803d`, soft `#dcfce7`.
- Warning: base `#d97706`, strong `#b45309`, soft `#fef3c7`.
- Danger: base `#dc2626`, strong `#b91c1c`, soft `#fee2e2`.
- Info: base maps to accent-secondary strong (`#0284c7`), strong `#0369a1`, soft maps to accent-secondary soft (`#e0f2fe`).

Rules:

1. A color used in a surface MUST come from this palette; a hardcoded hex outside the palette is forbidden.
2. Text on canvas and surface MUST use the text tokens; muted text MUST be reserved for secondary information.
3. Accents MUST be used sparingly - one accent per surface except where semantic colors are required.
4. Semantic colors MUST NOT be used decoratively; they carry meaning (success, warning, danger, info).
5. Contrast MUST be verified: body text 4.5:1 minimum, large text 3:1 minimum against its background (WCAG AA); large text is ≥24px regular or ≥18.66px bold (WCAG 1.4.3).

## Typography

Two families MUST be used: UI sans and mono.

- Family 1 - UI sans: `Inter`, `system-ui`, `-apple-system`, `sans-serif` (fixed fallback order).
- Family 2 - Mono: `"Geist Mono"`, `"JetBrains Mono"`, `ui-monospace`, `monospace` (numbers, code, keys).

Scale (xs to 4xl):

| Step | Size | Line-height | Weights |
|------|------|-------------|---------|
| xs | 12px | 16px | 400 / 500 / 600 |
| sm | 14px | 20px | 400 / 500 / 600 |
| base | 16px | 24px | 400 / 500 / 600 |
| lg | 18px | 28px | 500 / 600 / 700 |
| xl | 20px | 28px | 600 / 700 |
| 2xl | 24px | 32px | 600 / 700 |
| 3xl | 30px | 36px | 600 / 700 |
| 4xl | 36px | 44px | 700 |

Rules:

1. A text size MUST come from the scale; fractional or intermediate sizes are forbidden.
2. Body text MUST be base (16px/24px); small secondary text MUST be sm or xs and never below 12px.
3. Numeric data MUST use the mono family with `font-variant-numeric: tabular-nums`.
4. Headings MUST use `letter-spacing: -0.01em` at xl and above; body MUST use `letter-spacing: 0`.
5. A surface MUST NOT combine more than two text weights.

## Spacing

Spacing uses a 4pt base scale.

- Scale: 4, 8, 12, 16, 20, 24, 32, 40, 48, 64 (px).
- Gaps, margins, and paddings MUST be multiples of 4.
- Inset defaults: compact 8px, standard 16px, spacious 24px.

Rules:

1. A spacing value MUST be a multiple of 4 from the scale; arbitrary values (e.g. 13px, 18px) are forbidden.
2. Related controls MUST be spaced with 4px or 8px gaps; related groups with 16px or 24px.
3. Section padding MUST be 24px or 32px on dashboard surfaces and 48px for page-level containers.
4. Inline icon-to-label gaps MUST be 8px.

## Radius

Radius philosophy: fewer, consistent values. One radius family per surface.

- Radius sm: `4px` - small elements.
- Radius md: `8px` - inputs, buttons, menus, list items.
- Radius lg: `12px` - cards, panels, tables.
- Radius full: `999px` - badges, avatars, pills only.

Rules:

1. A radius MUST come from the tier list; a value outside it is forbidden.
2. Radius full MUST be reserved for badges, avatars, and pills - never for cards or buttons.
3. A surface MUST NOT mix more than two radius tiers without a documented rule.

## Shadows

Three shadow tiers exist; elevation MUST be expressed only through these.

- Tier 1 (sm): `0 1px 2px rgba(15, 23, 42, 0.06)` - subtle, resting elements.
- Tier 2 (md): `0 2px 8px rgba(15, 23, 42, 0.08)` - hovered interactive elements.
- Tier 3 (lg): `0 8px 24px rgba(15, 23, 42, 0.12)` - overlays, modals, command palette, dropdown menus, toasts.

Rules:

1. A shadow MUST be one of the three tiers; custom shadow values are forbidden.
2. Shadows MUST use the tinted rgba above (never pure black); dark mode overlays use `rgba(0, 0, 0, 0.5)` only.
3. Elevation MUST be monotonic: an element at a higher tier MUST NOT sit below a surface with a lower tier.

## Motion

Motion durations are fixed; easing is fixed.

- Micro: `100ms` - active press, checkbox toggles.
- Control: `150ms` - hover, focus, button transitions.
- Standard: `250ms` - panels, menus, dropdowns, toasts enter.
- Slow: `400ms` - modals, large panels.

Easing: enter `cubic-bezier(0.16, 1, 0.3, 1)`; exit `cubic-bezier(0.4, 0, 1, 1)`; linear reserved for spinners.

Rules:

1. A transition duration MUST come from the four-step scale; arbitrary durations are forbidden.
2. Motion MUST honor `prefers-reduced-motion`: transitions collapse to instant, loops stop.
3. Animatable properties MUST be limited to `transform` and `opacity`; layout properties MUST NOT animate.
4. A spinner MUST rotate `360deg` over `800ms` linear.
5. Loop durations are an explicit carve-out from the four-step scale: `800ms` (spinner) and `1000ms` (skeleton pulse) are the only permitted loop durations; a loop MUST collapse to static under `prefers-reduced-motion`.

## Token governance

1. Every value in a surface MUST resolve to a token; hardcoded values are forbidden.
2. A new token MUST be added to this file before first use, following the layer/tier structure.
3. Tokens MUST be consumed by name (e.g. surface, accent-strong, text-muted); duplicating a value is forbidden.
4. This token set MUST remain the single source of truth for `reference-library` and `component-patterns`.

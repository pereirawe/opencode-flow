---
name: reference-library
description: Concrete, testable UI patterns (Dashboard Card, Data Table, Nav Rail, Metric Display, Empty State, Command Palette) with exact CSS values for the Adorable pipeline. Use when implementing or auditing a specific UI pattern and needing the canonical values instead of prose descriptions. Use quando precisar do padrão canônico de um componente de dashboard — "dashboard card", "data table", "nav rail", "metric display", "empty state", "command palette", "padrão de UI", "componente de dashboard" also trigger this skill.
---

# Reference Library

## Usage rules

1. A UI pattern MUST match the canonical values below exactly; the values are the specification, not suggestions.
2. When a pattern is absent, an agent MUST follow `design-tokens` for values and MUST flag the missing pattern in `known_issues.md`.
3. Every value below is testable by static analysis: an implementation that deviates from a stated value MUST be corrected.
4. Patterns MUST be composed only from `component-patterns` primitives and composites; ad-hoc elements are forbidden.
5. An implementation MUST NOT introduce a color, radius, shadow, or spacing value beyond the token system in `design-tokens`.

## Dashboard Card

The Dashboard Card is the default content container for dashboard surfaces. It groups related metrics and controls with a consistent chrome.

Canonical values:

- Container: `background: #ffffff`, `border: 1px solid #e2e8f0`, `border-radius: 12px`, `padding: 16px`.
- Header row: `padding: 16px 16px 12px`, title `font-size: 14px` weight 600, action link `font-size: 12px`.
- Body: `padding: 16px`, background transparent (inherits the container).
- Footer: `border-top: 1px solid #e2e8f0`, `padding: 12px 16px`.
- Interactive hover: `box-shadow: 0 2px 8px rgba(15, 23, 42, 0.08)`, transition `150ms`.

Rules:

1. A card MUST use exactly `border-radius: 12px`; never mix radii on one card.
2. A card that is not interactive MUST NOT change elevation on hover.
3. Card padding MUST come from the 4pt spacing scale: 16px default, 24px for cards at least 480px wide, 12px for dense cards.
4. A card MUST NOT contain a nested card at the same elevation; use a flat section inside instead.
5. A card header MUST keep title and action on one row at 480px and above; the action MUST move below the title below 480px.

## Data Table

Data tables render row data in scannable columns. They are the densest pattern in the library.

Canonical values:

- Wrapper: `background: #ffffff`, `border: 1px solid #e2e8f0`, `border-radius: 12px`, `overflow: hidden`.
- Header cell: `background: #f8fafc`, `padding: 12px 16px`, `font-size: 12px` weight 600.
- Body cell: `padding: 12px 16px`, `font-size: 14px`, minimum row height 40px.
- Row divider: `border-bottom: 1px solid #f1f5f9` (layer-hover); the last row MUST NOT carry a divider.
- Numeric column: right-aligned, mono family (see `design-tokens`), `font-variant-numeric: tabular-nums`.

Rules:

1. Every column MUST have a header; a headerless column is forbidden.
2. Rows MUST be zebra-free (no alternating background) — the divider alone separates rows.
3. A numeric column MUST be right-aligned with `tabular-nums`; a text column MUST be left-aligned.
4. The row hover state MUST be `background: #f8fafc` and MUST NOT move content.
5. Sticky headers MUST use `position: sticky` with `background: #ffffff` and `border-bottom: 1px solid #e2e8f0`.
6. Sortable columns MUST show an arrow at `font-size: 12px`; the active sort MUST be weight 600.

## Nav Rail

The Nav Rail is the persistent left navigation for dashboard and app surfaces.

Canonical values:

- Rail: `background: #f8fafc`, `width: 240px` (collapsed 64px), `border-right: 1px solid #e2e8f0`.
- Item: `border-radius: 8px`, `padding: 8px 12px`, `font-size: 14px`, 4px gap between icon and label.
- Active item: `background: #eef2ff`, text `#4338ca` (accent strong), weight 600.
- Hover item: `background: #f1f5f9` (layer-hover).
- Section label: `font-size: 12px`, uppercase, `letter-spacing: 0.08em`, `color: #64748b`, `padding: 16px 12px 8px`.

Rules:

1. The rail MUST be 240px expanded and 64px collapsed; the collapse toggle MUST animate `width` over `150ms`.
2. Exactly one item MUST be active at a time, and the active item MUST use the active background.
3. Every icon MUST be 16x16px and MUST NOT change size across states.
4. Section labels MUST be 12px (xs) uppercase with 0.08em tracking; a label MUST NOT be interactive.
5. At 768px and below the rail MUST collapse to an overlay drawer with `background: #ffffff` and `box-shadow: 0 8px 24px rgba(15, 23, 42, 0.12)`.

## Metric Display

The Metric Display shows a single KPI: value, label, and optional delta.

Canonical values:

- Value: `font-size: 30px`, weight 700, `line-height: 1.2`, `font-variant-numeric: tabular-nums`.
- Label: `font-size: 12px`, `color: #64748b`, weight 500.
- Delta: `font-size: 12px`, weight 600; positive `color: #15803d`, negative `color: #b91c1c`.
- Layout: label above value with 4px gaps; container `padding: 16px`.

Rules:

1. The value MUST use `tabular-nums` so columns of metrics align.
2. The label MUST appear above the value and MUST use the muted text color.
3. A delta MUST be shown with its sign (+/-) and MUST use the semantic green/red pair; a neutral delta uses `color: #64748b`.
4. The value MUST always be a number or short string — an icon or image in the value slot is forbidden.
5. A metric MUST remain readable at 160px container width; the value MUST NOT wrap to a second line.

## Empty State

The Empty State communicates "no data yet" and tells the user how to populate the surface.

Canonical values:

- Wrapper: `padding: 48px 24px`, centered, `text-align: center`, `background: #ffffff`.
- Illustration slot: 64x64px, `border-radius: 12px`, `background: #f1f5f9` (layer-hover), `margin-bottom: 16px`.
- Title: `font-size: 16px`, weight 600, `color: #0f172a`.
- Body: `font-size: 14px`, `color: #64748b`, `max-width: 320px`, 8px auto margins.
- Action button: follows the Button primitive, `margin-top: 16px`.

Rules:

1. Every empty state MUST contain a title and a body; an icon-only empty state is forbidden.
2. The body MUST state what the user can do to populate the surface — never a bare "no data".
3. At most one primary action MUST be present; secondary actions are optional.
4. The illustration slot MUST keep `border-radius: 12px` and MUST NOT exceed 96px.

## Command Palette

The Command Palette is the keyboard-first search overlay.

Canonical values:

- Backdrop: `background: rgba(15, 23, 42, 0.5)` over the full viewport, `backdrop-filter: blur(4px)`.
- Panel: `background: #ffffff`, `border: 1px solid #e2e8f0`, `border-radius: 12px`, `box-shadow: 0 8px 24px rgba(15, 23, 42, 0.12)`, `max-width: 560px`, `width: calc(100% - 32px)`.
- Input: `padding: 16px`, `font-size: 16px`, `border-bottom: 1px solid #e2e8f0`.
- Group label: `font-size: 12px`, uppercase, `letter-spacing: 0.08em`, `color: #64748b`, `padding: 8px 16px`.
- Item: `padding: 12px 16px`, `font-size: 14px`, `border-radius: 8px`, 4px margins.
- Selected item: `background: #eef2ff`, text `#4338ca`.

Rules:

1. The palette MUST open with Ctrl/Cmd+K and MUST be dismissible with Escape.
2. Exactly one item MUST be selected at all times while open; arrow keys move the selection.
3. Every item MUST show a short hint (shortcut or description) at `font-size: 12px`, `color: #64748b`.
4. The backdrop MUST be clickable to dismiss, and page scroll MUST be locked while the palette is open.
5. Results MUST update on each keystroke without layout shift, and the input MUST keep focus.

## Conformance checklist

1. Every pattern implemented in a surface MUST match the canonical values in this file.
2. A pattern deviation MUST be either corrected or escalated as a new pattern entry; silent deviations are forbidden.
3. Values used across patterns MUST stay consistent: one card radius, one table divider, one rail width per surface.
4. All colors, radii, shadows, and spacing MUST resolve to `design-tokens` definitions.

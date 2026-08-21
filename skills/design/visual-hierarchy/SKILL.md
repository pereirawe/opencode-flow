---
name: visual-hierarchy
description: Visual hierarchy rules for the Adorable pipeline — visual weight, WCAG AA contrast ratios, density modes, and responsive patterns. Use when laying out a surface so the most important content leads the eye and every ratio passes. Use quando precisar de hierarquia visual — "hierarquia visual", "peso visual", "contraste", "densidade", "responsivo", "layout" also trigger this skill.
---

# Visual Hierarchy

## Visual weight

Visual weight is the perceived importance of an element; it MUST be driven by size, weight, and color - never by decoration.

1. A surface MUST establish one primary focus; every other element MUST be subordinate.
2. Weight MUST follow the type scale: 4xl heading over xl heading over base body over sm caption; a caption MUST NOT outrank a heading.
3. Text hierarchy MUST be expressed primarily with size and weight; color alone is insufficient (see Contrast ratios).
4. An element MUST NOT be emphasized with more than one mechanism (bold plus color plus border); one is enough.
5. Muted text MUST be reserved for secondary content; primary content MUST use text primary.
6. A surface MUST NOT contain more than two accent-colored elements; accents attract attention first.
7. A primary action MUST be visually heavier than a secondary action (filled vs. outlined); two equally weighted buttons are forbidden.
8. Disabled elements MUST lose weight (`opacity: 0.5`) and MUST NOT compete for attention.

Priority order (highest to lowest): primary action, key metric, headings, supporting metrics, captions, chrome.

## Contrast ratios

Contrast is measured against the element's background. WCAG AA is the minimum; AAA is the target for large text.

1. Body text MUST be 4.5:1 minimum against its background (WCAG AA).
2. Large text (≥24px regular, or ≥18.66px bold — WCAG 1.4.3) MUST be 3:1 minimum (WCAG AA).
3. UI component boundaries (borders, icons, focus rings) MUST be 3:1 minimum against adjacent colors.
4. Placeholder text MUST be 4.5:1 minimum, and a placeholder MUST NOT be the only label (see component-patterns Form).
5. The accent pair `#4f46e5` on white MUST be used only for text that passes 4.5:1; accent secondary `#0ea5e9` (2.77:1 on white) MUST NOT be used as text; lighter accent tints MUST NOT carry text.
6. Focus rings MUST be visible: 2px accent ring with 3:1 minimum contrast against the adjacent background.
7. Dark surfaces MUST invert the hierarchy: text `#f8fafc` on `#0f172a`, muted `#94a3b8`.
8. Every contrast ratio MUST be verified with a checker before an implementation is accepted; eyeballing is forbidden.

## Density modes

Three density modes exist, and they apply ONLY to data-dense surfaces (tables, lists, metrics grids) — never to cards or page-level containers. Non-dense surfaces MUST use the canonical values in `design-tokens` and `reference-library` (e.g. card padding 16px, body text base 16px); Comfortable is NOT the component default. A data-dense surface MUST pick one mode and apply it consistently.

- Comfortable (default for data-dense surfaces): row height 48px, cell gaps 16px, `font-size: 14px`.
- Compact: row height 40px, cell gaps 12px, `font-size: 14px` (12px for table cells).
- Dense: row height 32px, cell gaps 8px, `font-size: 12px`; numeric mono with `tabular-nums` required.

1. A data-dense surface MUST declare its density mode and MUST NOT mix modes within one view.
2. Density MUST NOT drop contrast below the AA ratios; smaller type still requires 4.5:1.
3. Dense mode MUST be reserved for data-heavy tables and command interfaces; primary flows MUST stay comfortable.
4. Switching density MUST change spacing and type size together; changing only one is forbidden.
5. Cards and page-level containers MUST ignore density modes and use their canonical values (card padding 16px default, body text base 16px; see `reference-library` and `design-tokens`).

## Responsive patterns

Layouts MUST follow the breakpoints and collapse rules.

- Breakpoints: 640, 768, 1024, 1280 (px); surface-specific breakpoints (e.g. card header 480px, nav rail collapse 768px) are defined in `reference-library`.
- Desktop to mobile: multi-column layouts MUST collapse to a single column at 768px.
- Data tables MUST become horizontally scrollable (never squeezed) below 768px.
- Nav rails MUST collapse to a drawer at 768px (see reference-library Nav Rail).
- Touch targets MUST be 32px minimum (44px preferred) on pointer-coarse devices.

1. A layout MUST be single-column below 768px; two-plus columns below 768px are forbidden.
2. A table MUST NOT shrink its columns below 120px; it MUST scroll horizontally instead.
3. A section header MUST fit within two lines on mobile; overflow MUST be solved by scaling, never clipping.
4. Breakpoints MUST be applied at 640/768/1024/1280; ad-hoc values are forbidden.
5. Full-viewport sections MUST use `min-height: 100dvh`, never `100vh`.

## Conformance checklist

1. Every data-dense surface MUST declare its density mode; other surfaces MUST use the canonical values in `design-tokens` and `reference-library`.
2. Every text element MUST pass its contrast ratio before delivery.
3. Every layout MUST be verified at 768px and 375px before delivery.
4. A hierarchy deviation MUST be corrected or escalated; silent deviations are forbidden.

---
name: component-patterns
description: Component anatomy for the Adorable pipeline — primitives (Button, Badge, Icon, Avatar, Separator, Skeleton, Spinner) and composites (Card, DataTable, Form, Dropdown, Modal, Toast, CommandPalette). Use when building or reviewing a component to apply its canonical anatomy: parts, sizes, and states. Use quando precisar da anatomia canônica de um componente — "componente", "anatomia", "button", "badge", "avatar", "modal", "dropdown", "toast", "formulário" also trigger this skill.
---

# Component Patterns

## Anatomy rules

Anatomy defines the parts of a component and the values each part uses. The rules below apply to every component.

1. A component MUST be composed only from the parts listed in this file; inventing a part is forbidden.
2. Every part MUST resolve colors, radius, spacing, and motion to `design-tokens`.
3. A component MUST implement every applicable state under State rules: default, hover, focus, active, disabled, loading.
4. A component MUST NOT hardcode a value that exists as a token; tokens are the single source of truth.
5. Primitive sizes MUST follow the scale (sm 32px / md 40px / lg 48px) unless a composite defines otherwise.

## Primitives

Primitives are the smallest building blocks. They MUST NOT contain other primitives except icons.

### Button

Parts: container, label, optional icon, optional loading spinner.

- Sizes: sm `height: 32px`, md `height: 40px`, lg `height: 48px`; `padding: 0 16px` (sm `0 12px`).
- Radius: `border-radius: 8px` for all sizes.
- Variants: primary `background: #4f46e5` with text `#ffffff`; secondary `background: #ffffff`, `border: 1px solid #e2e8f0`, text `#0f172a`; ghost `background: transparent`, text `#4f46e5`.
- Font: `font-size: 14px`, weight 600, `line-height: 1`.

Rules:

1. A button MUST use a height of 32px, 40px, or 48px; any other height is forbidden.
2. A primary button MUST use the accent background with white text (contrast 4.5:1 minimum).
3. A button label MUST NOT wrap; the label MUST truncate or the button MUST widen.
4. An icon inside a button MUST be 16x16px and MUST sit 8px from the label.

### Badge

Parts: container, label, optional dot.

- Size: `padding: 4px 8px`, `font-size: 12px`, `border-radius: 999px`.
- Variants: neutral `background: #f1f5f9` (layer-hover) text `#334155` (text-neutral); accent `background: #eef2ff` text `#4338ca`; success `background: #dcfce7` text `#15803d`; warning `background: #fef3c7` text `#b45309`; danger `background: #fee2e2` text `#b91c1c`.
- Dot: 6x6px circle, same fill as the label color.

Rules:

1. A badge MUST use `border-radius: 999px`; no other radius is allowed.
2. A badge MUST NOT be interactive; use a Button for actions.
3. A badge dot MUST be 6x6px and MUST match the label color.
4. Badge text MUST be 12px and MUST NOT wrap.

### Icon

Parts: svg glyph, optional container.

- Sizes: 16x16px default, 20x20px in controls, 24x24px standalone.
- Stroke: `stroke-width: 1.5` (linear) or solid fill; one style per surface.
- Color: inherits `currentColor`; the color MUST come from text tokens.

Rules:

1. An icon MUST come from the approved library set; hand-drawn SVG paths are forbidden.
2. Icons on a surface MUST share one stroke width.
3. An icon MUST use the 16/20/24px set; fractional sizes are forbidden.

### Avatar

Parts: image or initials, optional status dot.

- Sizes: 24px (inline), 32px (list), 40px (header), 56px (detail).
- Shape: `border-radius: 999px`; `border: 2px solid #ffffff` when placed over a colored surface.
- Initials: 12px (24/32px), 14px (40px), 18px (56px), weight 600, `color: #ffffff`, fallback `background: #4f46e5` (accent-primary-fallback).

Rules:

1. An avatar MUST be circular (`border-radius: 999px`).
2. Initials MUST derive from the entity name; random letters are forbidden.
3. A status dot MUST be 10x10px at the bottom-right with `border: 2px solid #ffffff`.

### Separator

Parts: line.

- Horizontal: `height: 1px`, `background: #e2e8f0`, full container width.
- Vertical: `width: 1px`, `background: #e2e8f0`, full container height.

Rules:

1. A separator MUST be 1px thick and MUST use the border token color.
2. A separator MUST span the full container dimension unless a composite explicitly defines an inset.

### Skeleton

Parts: block placeholders.

- Base: `background: #f1f5f9` (layer-hover), `border-radius: 8px` (text lines) or `12px` (blocks).
- Pulse: opacity from 1 to 0.5 over `1000ms` infinite; MUST collapse to static 0.6 opacity under `prefers-reduced-motion`.

Rules:

1. A skeleton MUST mirror the final layout shape; a generic rectangle grid is forbidden.
2. Skeleton text lines MUST be `height: 12px` with `border-radius: 8px`.
3. The pulse MUST animate `opacity` only and MUST disable under reduced motion.

### Spinner

Parts: ring.

- Size: 16x16px (inline), 24x24px (block). Ring: `border: 2px solid #e2e8f0` with the top arc `#4f46e5`.
- Rotation: `360deg` over `800ms` linear infinite; MUST collapse to static under `prefers-reduced-motion`.

Rules:

1. A spinner MUST be circular and MUST rotate only via `transform`.
2. A spinner MUST carry an accessible label (aria-label); a visual-only spinner is forbidden.

## Composites

Composites are built from primitives. A composite MUST NOT be nested inside another composite except where explicitly stated.

### Card

Parts: container, optional header (title + actions), body, optional footer.

- Container: `background: #ffffff`, `border: 1px solid #e2e8f0`, `border-radius: 12px`, `padding: 16px`.
- Header: `padding: 16px 16px 12px`, `border-bottom: 1px solid #e2e8f0` only when a body follows.
- Footer: `padding: 12px 16px`, `border-top: 1px solid #e2e8f0`.

Rules:

1. A Card MUST contain exactly one header, one body, and at most one footer.
2. A Card MUST NOT contain another Card; use a plain section instead.
3. A Card header title MUST be 14px at weight 600.

### DataTable

Parts: wrapper, header row, body rows, optional footer.

- Wrapper: `background: #ffffff`, `border: 1px solid #e2e8f0`, `border-radius: 12px`.
- Header row: `background: #f8fafc`, `padding: 12px 16px`, `font-size: 12px` weight 600.
- Body rows: `padding: 12px 16px`, `font-size: 14px`, `border-bottom: 1px solid #f1f5f9` (layer-hover).

Rules:

1. A DataTable MUST have one header row and at least one body row.
2. A DataTable MUST render numeric cells right-aligned with `tabular-nums`.
3. A DataTable MUST NOT use zebra striping (see reference-library).

### Form

Parts: field, label, control, hint, error.

- Field: `margin-bottom: 16px` (4pt scale x 4).
- Label: `font-size: 14px`, weight 500, `color: #0f172a`, `margin-bottom: 4px`.
- Control: `height: 40px`, `border: 1px solid #e2e8f0`, `border-radius: 8px`, `padding: 0 12px`, `font-size: 14px`.
- Hint: `font-size: 12px`, `color: #64748b`, `margin-top: 4px`.
- Error: `font-size: 12px`, `color: #b91c1c`, `margin-top: 4px`; the control border becomes `#dc2626`.

Rules:

1. A Form MUST label every control; placeholder-as-label is forbidden.
2. A text control MUST be `height: 40px` with `border-radius: 8px`.
3. An error state MUST include both a control border change and an error text below the control.
4. A focus state MUST show a 2px accent ring (`#4f46e5`) via box-shadow or outline.

### Dropdown

Parts: trigger, menu, items, optional groups.

- Trigger: secondary Button with a 16x16px chevron.
- Menu: `background: #ffffff`, `border: 1px solid #e2e8f0`, `border-radius: 8px`, `box-shadow: 0 8px 24px rgba(15, 23, 42, 0.12)`, `padding: 4px`, `min-width: 180px`.
- Item: `padding: 8px 12px`, `border-radius: 8px`, `font-size: 14px`; selected `background: #eef2ff`.

Rules:

1. A Dropdown MUST open on trigger click and MUST close on outside click and Escape.
2. Exactly one item MUST be highlighted at a time; arrow keys move the highlight.
3. A Dropdown menu MUST have `min-width: 180px` and MUST NOT exceed the viewport width.

### Modal

Parts: backdrop, panel, header, body, footer, close button.

- Backdrop: `background: rgba(15, 23, 42, 0.5)`, full viewport.
- Panel: `background: #ffffff`, `border-radius: 12px`, `box-shadow: 0 8px 24px rgba(15, 23, 42, 0.12)` (shadow Tier 3), `max-width: 480px`, `width: calc(100% - 32px)`, `padding: 24px`.
- Header: `font-size: 18px` weight 600, `margin-bottom: 8px`.
- Footer: `padding-top: 16px`, `border-top: 1px solid #e2e8f0`, actions right-aligned with 8px gaps.

Rules:

1. A Modal MUST have a visible backdrop and MUST be dismissible via backdrop click, close button, and Escape.
2. A Modal MUST lock page scroll while open.
3. A Modal MUST restore focus to the trigger on close.

### Toast

Parts: container, message, optional action, close button.

- Container: fixed bottom-right, 8px gaps, z-index above the modal layer.
- Toast: `background: #0f172a` with text `#ffffff`, `border-radius: 8px`, `padding: 12px 16px`, `max-width: 360px`, `box-shadow: 0 8px 24px rgba(15, 23, 42, 0.12)` (shadow Tier 3).
- Motion: enter `translateY(8px)` plus opacity over `250ms`; auto-dismiss after `4000ms`.

Rules:

1. A Toast MUST auto-dismiss within `4000ms` unless an action is pending.
2. At most 3 toasts MUST be visible at once; additional toasts queue.
3. Toast text MUST be 14px on `#0f172a` (contrast 12:1 minimum).

### CommandPalette

Parts: backdrop, panel, input, groups, items.

- Panel: `background: #ffffff`, `border: 1px solid #e2e8f0`, `border-radius: 12px`, `box-shadow: 0 8px 24px rgba(15, 23, 42, 0.12)`, `max-width: 560px`.
- Input: `padding: 16px`, `font-size: 16px`, `border-bottom: 1px solid #e2e8f0`.
- Item: `padding: 12px 16px`, `font-size: 14px`, `border-radius: 8px`; selected `background: #eef2ff`.

Rules:

1. A CommandPalette MUST open with Ctrl/Cmd+K and MUST keep focus in the input.
2. Results MUST filter on every keystroke without layout shift.

## State rules

Every interactive component MUST implement the full state set.

1. Default and hover states MUST be visually distinct (values per anatomy).
2. Focus MUST be visible: a 2px accent ring for controls; keyboard-only users MUST see it.
3. Disabled MUST be `opacity: 0.5` with `cursor: not-allowed` and MUST NOT respond to interaction.
4. Loading MUST replace content with the Skeleton or Spinner primitive — never blank space.
5. `:active` MUST provide feedback: `transform: scale(0.98)` or a color shift over `100ms`.
6. Every state change MUST animate with `transition: 150ms` (see `design-tokens` motion).

## Conformance checklist

1. Every component implemented MUST match the anatomy in this file.
2. A component MUST use only the parts listed; a new part MUST be added here before implementation.
3. Every color, radius, spacing, and motion value MUST resolve to `design-tokens`.
4. A deviation MUST be corrected or escalated; silent deviation is forbidden.

---
name: frontend-design
description: Frontend design system and marketing page generation — aesthetic direction, design tokens, typography, color systems, CSS architecture, responsive layout, accessibility.
---

# Frontend Design Skill

Build distinctive, conversion-optimized marketing pages.

## Aesthetic Direction

Before writing any code, commit to an explicit direction:
- **Brutalist**: Raw, typography-first, minimal color, intentional ugliness
- **Editorial**: Magazine-quality, generous whitespace, pull quotes, serif fonts
- **Retro-futuristic**: Neon gradients, geometric shapes, glassmorphism
- **Minimalist**: Max whitespace, single accent color, one visual anchor
- **Maximalist**: Rich textures, layered elements, bold patterns

## Design Tokens

### Typography
```css
--font-heading: 'Anybody', 'Instrument Serif', system-ui;
--font-body: 'Public Sans', 'Inter', system-ui;
--font-mono: 'JetBrains Mono', monospace;
--scale: 1.25; /* Major third */
```

### Color System
- Primary (main brand color)
- Secondary (supporting color)
- Accent (highlights, CTAs)
- Surface (backgrounds, cards)
- Text (headings, body, muted)
- Semantic (success, warning, error, info)
- Dark/Light variants for each

### Spacing
- Base unit: 4px or 8px
- Scale: 4, 8, 12, 16, 20, 24, 32, 40, 48, 56, 64, 80, 96

## Design Rules
- Single visual anchor per screen (hero image, illustration, key stat)
- Scannable headlines — reader gets the proposition in 3 seconds
- Motion only where it serves hierarchy (scroll reveals, hover feedback)
- No carousels without narrative purpose
- No generic SaaS card grids as default layout
- Every color choice must meet WCAG AA contrast (4.5:1 normal text)

## Related Skills
- `conversion-optimization` — CRO for pages
- `copywriting` — page copy
- `theme-factory` — design token generation

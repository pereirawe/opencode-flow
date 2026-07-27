---
name: theme-factory
description: Design token and theme generation — color palette creation, typography systems, spacing scales, light/dark themes, CSS variable systems.
---

# Theme Factory Skill

Generate consistent, reusable design tokens and theme systems.

## Color Palette Generation

### From a Single Seed Color
1. **Primary**: Your seed color
2. **Secondary**: 60° rotation on hue wheel
3. **Accent**: Complementary (180° rotation) or triadic
4. **Neutrals**: Desaturated grays from your primary

### Scale Generation
For each color, generate 50-900 scale (50 lightest, 900 darkest):
```css
--color-primary-50: hsl(220, 90%, 97%);
--color-primary-100: hsl(220, 85%, 92%);
--color-primary-200: hsl(220, 80%, 84%);
/* ... */
--color-primary-900: hsl(220, 70%, 15%);
```

### Light/Dark Theme
- Light: White or near-white backgrounds, dark text
- Dark: Near-black backgrounds, light text
- Ensure both pass WCAG AA (4.5:1 contrast)

## Typography System
| Token | Value | Usage |
|-------|-------|-------|
| --text-xs | 0.75rem | Captions, labels |
| --text-sm | 0.875rem | Secondary text |
| --text-base | 1rem | Body |
| --text-lg | 1.125rem | Large body |
| --text-xl | 1.25rem | Subheading |
| --text-2xl | 1.5rem | Section heading |
| --text-3xl | 1.875rem | Page heading |
| --text-4xl | 2.25rem | Hero heading |
| --text-5xl | 3rem | Large hero |

## CSS Variable Output

```css
:root {
  /* Colors */
  --color-primary: hsl(...);
  --color-primary-hover: hsl(...);
  --color-surface: hsl(...);
  --color-text: hsl(...);
  --color-text-secondary: hsl(...);

  /* Typography */
  --font-heading: 'Font Name', serif;
  --font-body: 'Font Name', sans-serif;
  --font-code: 'Mono Font', monospace;

  /* Spacing */
  --space-1: 0.25rem;
  --space-2: 0.5rem;
  --space-3: 0.75rem;
  /* ... */

  /* Shadows */
  --shadow-sm: 0 1px 2px rgba(0,0,0,0.05);
  --shadow-md: 0 4px 6px rgba(0,0,0,0.07);

  /* Border radius */
  --radius-sm: 4px;
  --radius-md: 8px;
  --radius-lg: 16px;
}
```

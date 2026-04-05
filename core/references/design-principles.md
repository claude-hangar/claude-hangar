# Design Principles

> Shared design reference for visual and interaction quality.
> Referenced by: `design-system` skill, `polish` skill, `frontend-design` skill, stack templates.
> Location: `core/references/design-principles.md`

## Core Philosophy

Modern, minimalist, distinctive. Every project should feel intentionally crafted, never like generic AI output.

## Icons

- **Primary:** Lucide (consistent stroke weight, tree-shakeable)
- **Alternative:** Heroicons (when Lucide lacks a needed icon)
- **Format:** Always SVG, never icon fonts
- **Usage:** Meaningful icons only — decorative icons add noise

## Fonts & GDPR

- **Self-hosted only** — No Google Fonts CDN, no external font services
- Subset fonts to used characters when possible
- Use `font-display: swap` to prevent FOIT
- DSGVO/GDPR compliance is non-negotiable

## Accessibility

- **Minimum:** WCAG AA (4.5:1 text contrast, 3:1 large text / UI elements)
- **Target:** WCAG AAA where feasible without design compromise
- Focus indicators on all interactive elements
- `prefers-reduced-motion` respected in all animations
- Semantic HTML first, ARIA only when HTML falls short

## Color

- Curated palettes with intention — every color has a role
- No random Tailwind color combos (no `bg-purple-500 text-indigo-300`)
- Dark mode: design separately, not just `invert()`
- Ensure sufficient contrast in both light and dark modes

## Typography

- **Max 2 font families** (1 heading + 1 body, or 1 for both)
- Deliberate hierarchy: clear visual distinction between heading levels
- Line height: 1.5-1.75 for body text, 1.1-1.3 for headings
- Measure: 45-75 characters per line for readability

## Spacing

- **Base grid:** 4px (use multiples: 4, 8, 12, 16, 24, 32, 48, 64)
- Consistent spacing scale across the entire project
- White space is a design tool, not wasted space
- Group related elements, separate unrelated ones

## Motion

- Subtle and purposeful — never decorative for its own sake
- Duration: 150-300ms for UI feedback, 300-500ms for transitions
- Easing: `ease-out` for entrances, `ease-in` for exits, `ease-in-out` for state changes
- Always respect `prefers-reduced-motion: reduce`

## Anti-Patterns

- No stock gradients (purple-to-pink, blue-to-indigo cliches)
- No generic card grids that look like every other SaaS landing page
- No shadows without purpose (subtle elevation hierarchy, not random depth)
- No rounded-everything (choose a border-radius strategy and stick to it)

## The "Aha Moment" Rule

Every component, page, or interaction should have at least one unexpected detail — a micro-animation, a clever layout choice, an elegant hover state, a typographic flourish. This is what separates crafted from generated.

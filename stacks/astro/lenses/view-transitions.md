---
name: view-transitions
stack: astro
category: ux
effort_min: 1
effort_max: 5
---

# Lens: View Transitions Integration

Focused audit of Astro View Transitions: directive placement, persistent state, and fallback behavior.

## What this lens checks

1. **Root `<ViewTransitions />`** — present in the base layout, not duplicated per page.
2. **`transition:animate`** — used with a named animation (fade, slide, none) — not left as default on every element.
3. **`transition:persist`** — applied only to elements that must survive navigation (audio, video, stateful widgets).
4. **`transition:name`** — unique across the page; no collision between morphing elements.
5. **Script hooks** — `document.addEventListener('astro:page-load', ...)` used instead of DOMContentLoaded in SPA-navigated pages.
6. **Fallback** — `fallback="swap"` or `animate` set deliberately for browsers without native support.

## Signals to extract

- Pages/layouts with `<ViewTransitions />`
- Elements with `transition:persist` — justify each
- Collisions in `transition:name`
- Scripts still using `DOMContentLoaded`

## Severity mapping

- HIGH — script using `DOMContentLoaded` in a View Transitions layout (breaks SPA)
- MEDIUM — `transition:persist` on non-stateful element (wasted cost)
- LOW — `transition:animate` without explicit animation

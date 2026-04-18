---
name: runes-migration
stack: sveltekit
category: migration
effort_min: 2
effort_max: 8
---

# Lens: Runes Migration (Svelte 5)

Single-concern audit of Svelte 5 runes adoption progress and legacy reactivity patterns.

## What this lens checks

1. **Runes mode declared** — `svelte.config.js` has `compilerOptions.runes: true` or
   project uses Svelte 5 default runes mode.
2. **Legacy reactive declarations** — `$:` reactive statements in `.svelte` files should
   migrate to `$derived` / `$effect`.
3. **Legacy stores in components** — `import { writable } from 'svelte/store'` inside
   components should migrate to `$state` rune (cross-component sharing OK to keep stores).
4. **`export let` props** — should migrate to `$props()` destructuring.
5. **Two-way bindings on stores** — `bind:value={$store}` patterns that should become
   `$state` with explicit handlers.
6. **`onMount` for derived values** — uses of `onMount` to compute derived state should
   become `$derived` or `$effect`.

## Signals to extract

- Count `.svelte` files using `$:`, `export let`, `writable`/`readable` imports
- Count files using runes (`$state`, `$derived`, `$effect`, `$props`)
- Migration ratio: `runes_files / total_svelte_files`

## Report template

```markdown
### Runes Migration Lens
- Total .svelte files: {N}
- Already using runes: {M} ({pct}%)
- Legacy `$:` reactive: {K} files
- Legacy `export let`: {J} files
- Legacy store imports inside components: {L}
- Top 5 migration candidates (highest payoff):
  1. {file — reason}
```

## Severity mapping

- HIGH — project mixes runes and legacy in same component (compiler warnings expected)
- MEDIUM — components with `$:` doing side effects (should be `$effect`)
- MEDIUM — `export let` in new components (style inconsistency)
- LOW — store imports inside single-use components (purely refactor opportunity)

## Notes

- Migration is non-blocking — Svelte 5 supports legacy mode indefinitely for now.
- Recommend migrating one file at a time, verifying with `npm run check` between commits.
- Reference: https://svelte.dev/docs/svelte/v5-migration-guide

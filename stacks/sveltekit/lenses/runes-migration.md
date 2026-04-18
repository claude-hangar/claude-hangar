---
name: runes-migration
stack: sveltekit
category: migration
effort_min: 2
effort_max: 8
---

# Lens: Runes Migration (Svelte 5)

Single-concern audit of Svelte 5 runes adoption progress and legacy reactivity
patterns. Read-only — flags candidates; migration is a human decision per file.

## Prerequisites

This lens checks a Svelte 5 project (svelte `^5.0.0`). For Svelte 4 projects, runes
are not available — lens exits early with `skipped: svelte-version-below-5`.

## What this lens checks

1. **Runes mode status** — detect whether the project has opted into runes:
   (a) explicit `compilerOptions.runes: true` in `svelte.config.js`, OR
   (b) individual components using any rune (Svelte 5 treats them as rune components
   on demand). Report the mix: pure-runes / pure-legacy / mixed (same component
   mixing `$:` and runes triggers compiler warnings).
2. **Legacy reactive declarations (`$:`)** — in rune-enabled files, `$:` should be
   `$derived` (for pure derivations) or `$effect` (for side effects). Distinguish
   the two — recommending `$derived` for a side effect is wrong.
3. **`export let` props** — in rune components, should migrate to `$props()`.
   Two-way-bindable props additionally need `$bindable()` on the prop (else
   migration breaks parent `bind:value` usage).
4. **Store usage — context-aware**: `writable`/`readable` stores are **still
   idiomatic** for shared cross-component state in Svelte 5. DO NOT blanket-flag
   all store imports. Only flag: (a) stores used exclusively within a single
   component file (local state — `$state` is simpler), or (b) stores used as
   props that could be runes-based state passed via `$props()`.
5. **`onMount` for derived values** — `onMount` running a pure calculation that
   only depends on reactive inputs is better expressed as `$derived`. `onMount`
   for actual lifecycle work (DOM, subscriptions, cleanup) stays as-is.
6. **`<svelte:component this={C}>` is no longer needed** — Svelte 5 accepts dynamic
   components directly: `<C />` works. Flag legacy `<svelte:component>` usage.
7. **Event handlers** — `on:click` legacy syntax migrates to `onclick` attribute
   in runes mode (both still work, but the stack is moving).

## Signals to extract

- Svelte version from `package.json` (skip if < 5)
- Count `.svelte` files using `$:`, `export let`, store-imports inside component
- Count files using runes (`$state`, `$derived`, `$effect`, `$props`, `$bindable`)
- Files mixing runes and legacy `$:` (same file) — compiler-warning candidates
- Stores used in only one component file (single-use signal)
- `<svelte:component>` occurrences
- `onMount` bodies that are pure computations (no subscriptions, no DOM)

## Report template

```markdown
### Runes Migration Lens
- Svelte version: {version}
- Runes mode: {pure-runes | pure-legacy | mixed}
- Total .svelte files: {N}
- Already using runes: {M} ({pct}%)
- Mixed-mode files (compiler warnings): {X}
- Legacy `$:` reactive: {K} files ({side-effect count} / {derived count})
- Legacy `export let`: {J} files
- Single-use store candidates: {S}
- `<svelte:component>` usage: {C}
- Top 5 migration candidates (highest payoff):
  1. {file — reason — recommended pattern}
```

## Severity mapping

- HIGH — same component mixes `$:` and rune (`$state`/`$derived`) — compiler warnings
- MEDIUM — `$:` doing side effects (should be `$effect`)
- MEDIUM — `export let` in new rune-mode files (style inconsistency blocks full migration)
- MEDIUM — bindable prop migrated to `$props()` without `$bindable()` — breaks parent
- LOW — `onMount` wrapping a pure derivation (should be `$derived`)
- LOW — `<svelte:component>` usage (idiom obsolete but not broken)
- LOW — single-component-only store (refactor opportunity, not a bug)

## Notes

- Read-only. Never modifies files.
- Migration is non-blocking — Svelte 5 supports legacy mode indefinitely (for now).
- Recommend migrating one file at a time, verifying with `npm run check` between commits.
- Stores remain idiomatic for shared state — lens does not push blanket migration.
- Reference: https://svelte.dev/docs/svelte/v5-migration-guide

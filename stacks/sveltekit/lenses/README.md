# SvelteKit Lenses

Granular, single-concern audit modules for SvelteKit projects. Each lens is a small
focused check that `/sveltekit-audit` or `/audit-orchestrator` can dispatch in parallel.

## Pattern

- **One concern per lens** — no lens checks more than one dimension.
- **Small effort envelope** — `effort_min` to `effort_max` (tool calls) declared in frontmatter.
- **Structured output** — every lens produces a report matching its template.
- **Composable** — orchestrators pick which lenses to run by `category` tag.

## Available lenses

| Lens | Category | Effort | Checks |
|------|----------|--------|--------|
| server-load-security | security | 2–6 | Auth checks in `+page.server.ts`, no secret leaks via load returns, locals usage |
| form-actions-csrf | security | 1–4 | Form action handlers, CSRF protection, validation, redirect safety |
| runes-migration | migration | 2–8 | Svelte 5 runes adoption, legacy `$:` reactivity, store migration to `$state` |

## Adding a lens

1. Create `stacks/sveltekit/lenses/<name>.md`
2. Frontmatter must include: `name`, `stack`, `category`, `effort_min`, `effort_max`
3. Body: "What this lens checks" + "Signals" + "Severity mapping"
4. Keep single-responsibility — split if more than one "Checks" section emerges.

## Related

- Pattern inspired by RepoLens (`prompts/lenses/`)
- Consumed by `/sveltekit-audit` and `/audit-orchestrator`
- See `stacks/README.md` for cross-stack lens conventions

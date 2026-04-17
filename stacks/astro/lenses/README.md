# Astro Lenses

Granular, single-concern audit modules for Astro projects. Each lens is a small focused check that `/astro-audit` or `/audit-orchestrator` can dispatch in parallel.

## Pattern

- **One concern per lens** — no lens checks more than one dimension.
- **Small effort envelope** — `effort_min` to `effort_max` (tool calls) declared in frontmatter.
- **Structured output** — every lens produces a report matching its template.
- **Composable** — orchestrators pick which lenses to run by `category` tag.

## Available lenses

| Lens | Category | Effort | Checks |
|------|----------|--------|--------|
| content-collections | data | 2–8 | Schema coverage, Zod strictness, query performance |
| view-transitions | ux | 1–5 | Directive placement, persistent state, script hooks |

## Adding a lens

1. Create `stacks/astro/lenses/<name>.md`
2. Frontmatter must include: `name`, `stack`, `category`, `effort_min`, `effort_max`
3. Body: "What this lens checks" + "Signals" + "Severity mapping"
4. Keep single-responsibility — if you're writing more than one "Checks" section, split into two lenses.

## Related

- Pattern inspired by RepoLens (`prompts/lenses/`)
- Consumed by `/astro-audit` and `/audit-orchestrator`
- See `stacks/README.md` for cross-stack lens conventions

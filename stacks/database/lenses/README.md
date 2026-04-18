# Database Lenses

Granular, single-concern audit modules for Drizzle ORM + PostgreSQL projects. Each lens is
a small focused check that `/db-audit` or `/audit-orchestrator` can dispatch in parallel.

## Pattern

- **One concern per lens** — no lens checks more than one dimension.
- **Small effort envelope** — `effort_min` to `effort_max` (tool calls) declared in frontmatter.
- **Structured output** — every lens produces a report matching its template.
- **Composable** — orchestrators pick which lenses to run by `category` tag.

## Available lenses

| Lens | Category | Effort | Checks |
|------|----------|--------|--------|
| migration-safety | safety | 2–6 | Destructive migrations, NOT NULL on populated tables, drift detection |
| index-strategy | performance | 2–6 | Foreign keys without indexes, redundant indexes, missing composite indexes |
| transaction-boundaries | correctness | 1–4 | Multi-step writes outside transactions, missing rollback paths |

## Adding a lens

1. Create `stacks/database/lenses/<name>.md`
2. Frontmatter must include: `name`, `stack`, `category`, `effort_min`, `effort_max`
3. Body: "What this lens checks" + "Signals" + "Severity mapping"
4. Keep single-responsibility — split if more than one "Checks" section emerges.

## Related

- Pattern inspired by RepoLens (`prompts/lenses/database/`)
- Consumed by `/db-audit` and `/audit-orchestrator`
- See `stacks/README.md` for cross-stack lens conventions

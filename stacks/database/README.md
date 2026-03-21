# Database Stack

Database patterns and audit extensions focused on Drizzle ORM + PostgreSQL.

## What's Included

| File | Purpose |
|------|---------|
| `SKILL.md` | Database audit skill (`/db-audit`) |
| `CLAUDE.md.snippet` | Paste-ready section for your project's CLAUDE.md |
| `fix-templates.md` | Quick-fix templates for common database findings |
| `state-schema.md` | State schema for audit persistence |

## CLAUDE.md.snippet

Copy the contents of `CLAUDE.md.snippet` into your project's `CLAUDE.md` to give Claude Code
database-specific context. This covers:

- Drizzle ORM schema patterns
- Migration workflow (generate, migrate, push)
- Connection pooling
- Seed data conventions
- Framework integration (SvelteKit, Astro, Next.js)

## Usage

```bash
# Run the database audit skill
/db-audit start

# Check for new Drizzle/PostgreSQL releases
/db-audit refresh
```

## Related Stacks

- `auth/` — User/session tables and credential storage
- `sveltekit/` — SvelteKit server-only DB patterns (`$lib/server/db`)
- `astro/` — Astro SSR endpoint DB access

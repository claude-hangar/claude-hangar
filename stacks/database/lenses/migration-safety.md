---
name: migration-safety
stack: database
category: safety
effort_min: 2
effort_max: 6
---

# Lens: Migration Safety

Single-concern audit of Drizzle migrations for production-breaking patterns.

## What this lens checks

1. **No destructive operations on populated tables** — `DROP COLUMN`, `DROP TABLE`, type
   changes (`ALTER COLUMN ... TYPE`), `RENAME COLUMN` flagged unless paired with a
   documented data-migration plan or feature flag.
2. **NOT NULL on existing columns requires backfill** — `ALTER COLUMN ... SET NOT NULL`
   on a previously nullable column without a preceding `UPDATE` is a foot-gun on tables
   with existing rows.
3. **No `CREATE INDEX` without `CONCURRENTLY` on PostgreSQL** — non-concurrent index
   creation locks writes; flag in production-bound migrations.
4. **No locking schema changes during business hours** without a deploy-window comment.
5. **Drift detection** — `drizzle-kit check` reports schema drift between code and DB
   (heuristic: compare migration journal against schema.ts modification timestamps).
6. **No silent data loss** — `DEFAULT` added to NOT NULL column has explicit value
   (not just `DEFAULT NULL` which defeats the constraint).

## Signals to extract

- Count migrations in `drizzle/` directory
- Migrations containing `DROP COLUMN`, `DROP TABLE`, `ALTER COLUMN ... TYPE`, `RENAME`
- Migrations adding NOT NULL without backfill UPDATE in same file
- Index creations missing CONCURRENTLY on PostgreSQL
- Schema files newer than latest migration (drift signal)

## Report template

```markdown
### Migration Safety Lens
- Total migrations: {N}
- Destructive operations flagged: {M}
- NOT NULL without backfill: {K}
- Non-concurrent index creation: {J}
- Drift detected: {yes|no} ({L} schema files newer than last migration)
- Top 3 risky migrations:
  1. {file — risk}
```

## Severity mapping

- BLOCKER — `DROP TABLE` of table with foreign-key dependents
- CRITICAL — `ALTER COLUMN ... TYPE` on a populated production table
- HIGH — `SET NOT NULL` without preceding backfill on populated table
- HIGH — non-concurrent `CREATE INDEX` on PostgreSQL
- MEDIUM — `RENAME COLUMN` without app-side dual-read transition
- LOW — schema drift detected (informational)

## Notes

- This lens is read-only — never modifies migration files.
- For destructive changes, recommend the expand/contract pattern in the report.
- Reference: https://orm.drizzle.team/docs/migrations

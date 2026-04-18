---
name: migration-safety
stack: database
category: safety
effort_min: 2
effort_max: 6
---

# Lens: Migration Safety

Single-concern audit of Drizzle migrations for production-breaking patterns.
Read-only — flags risky patterns; never modifies migration files.

## What this lens checks

1. **Destructive operations on populated tables** — `DROP COLUMN`, `DROP TABLE`, type
   changes (`ALTER COLUMN ... TYPE`), `RENAME COLUMN` flagged unless paired with a
   documented data-migration plan, expand/contract pattern, or feature flag.
2. **NOT NULL adoption is a multi-step process on PostgreSQL.** A naive
   `ALTER COLUMN ... SET NOT NULL` takes an `AccessExclusiveLock` and full-scans the
   table. Even with backfill, it blocks writes on large tables. Recommended pattern:
   ```sql
   ALTER TABLE t ADD CONSTRAINT t_col_not_null CHECK (col IS NOT NULL) NOT VALID;
   -- backfill in batches
   ALTER TABLE t VALIDATE CONSTRAINT t_col_not_null;  -- only ShareUpdateExclusiveLock
   ALTER TABLE t ALTER COLUMN col SET NOT NULL;        -- now fast: catalog already validated
   ALTER TABLE t DROP CONSTRAINT t_col_not_null;
   ```
3. **`CREATE INDEX CONCURRENTLY` cannot run inside a transaction** — Drizzle wraps
   migrations in transactions by default. Use `--breakpoints` to split, or write the
   index step as raw SQL outside transaction boundary. Flag any non-concurrent index
   creation on PostgreSQL in production-bound migrations.
4. **Enum modifications cannot run inside a transaction on PostgreSQL** —
   `ALTER TYPE ... ADD VALUE` requires no surrounding transaction. Drizzle migrations
   need an explicit breakpoint here. Flag enum mutations without breakpoint.
5. **`ADD COLUMN ... DEFAULT <volatile>` rewrites the entire table on PostgreSQL < 11.**
   On PG ≥ 11, non-volatile defaults are metadata-only — fast. Detect PG version from
   project context (drizzle config / docker-compose / deps) and adjust severity.
6. **No locking schema changes during business hours** without an explicit
   deploy-window comment in the migration file.
7. **Drift detection** — compare schema.ts mtimes against latest migration in
   `drizzle/meta/_journal.json`. If schema is newer, migrations are stale. For
   live-DB drift use `drizzle-kit introspect` + diff (lens flags candidates only).
8. **No silent data loss** — `DEFAULT` added to NOT NULL column has explicit value
   (not just `DEFAULT NULL` which defeats the constraint).

## Anti-pattern example

```sql
-- DON'T (locks the entire table on PG, blocks writes for minutes on large tables):
ALTER TABLE users ALTER COLUMN email SET NOT NULL;

-- DO (CHECK ... NOT VALID + backfill + validate, see check #2 above)
```

## Signals to extract

- Count migrations in `drizzle/` directory
- Migrations containing `DROP COLUMN`, `DROP TABLE`, `ALTER COLUMN ... TYPE`, `RENAME`
- Migrations adding NOT NULL without preceding backfill or NOT VALID pattern
- Index creations missing CONCURRENTLY on PostgreSQL
- Index creations using CONCURRENTLY without `--breakpoint` separator
- Enum `ADD VALUE` inside a transactional block
- `ADD COLUMN ... DEFAULT <expr>` on PG < 11 (project-context-dependent)
- Schema files newer than latest migration (drift signal)

## Report template

```markdown
### Migration Safety Lens
- Total migrations: {N}
- Destructive operations flagged: {M}
- NOT NULL without safe pattern: {K}
- Non-concurrent index creation: {J}
- CONCURRENTLY in transaction (broken): {Q}
- Enum ADD VALUE in transaction (broken): {R}
- Drift detected: {yes|no} ({L} schema files newer than last migration)
- Top 3 risky migrations:
  1. {file — risk — recommended pattern}
```

## Severity mapping

(Hangar convention: max severity is CRITICAL — no BLOCKER tier, see `core/skills/audit-orchestrator/`.)

- CRITICAL — `DROP TABLE` of table with foreign-key dependents (data loss + cascade)
- CRITICAL — `ALTER COLUMN ... TYPE` on a populated production table (lock + rewrite)
- CRITICAL — `CREATE INDEX CONCURRENTLY` inside transaction (migration silently fails)
- HIGH — `SET NOT NULL` without NOT VALID + VALIDATE pattern on populated table
- HIGH — non-concurrent `CREATE INDEX` on PostgreSQL in production-bound migration
- HIGH — Enum `ADD VALUE` inside transaction (Drizzle default behavior breaks it)
- MEDIUM — `RENAME COLUMN` without app-side dual-read transition
- MEDIUM — `ADD COLUMN ... DEFAULT <volatile>` on PG < 11 (full-table rewrite)
- LOW — schema drift detected (informational)

## Notes

- Read-only — never modifies migration files. Suggestions only.
- For destructive changes, recommend the expand/contract pattern in the report.
- Version-aware: PG < 11 has stricter rules for `ADD COLUMN DEFAULT`; lens consults
  `package.json` / `docker-compose.yml` for the target PG version.
- Reference: https://orm.drizzle.team/docs/migrations
- Reference: https://www.postgresql.org/docs/current/sql-altertable.html

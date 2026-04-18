---
name: index-strategy
stack: database
category: performance
effort_min: 2
effort_max: 6
---

# Lens: Index Strategy

Single-concern audit of index coverage for query performance and storage efficiency.
Read-only — generates `CREATE INDEX` recommendations as text, never applies.

## What this lens checks

1. **Foreign keys without indexes** — every `references()` column should have an index
   (PostgreSQL does NOT auto-create them for FKs). Joins and cascading deletes suffer
   measurably without.
2. **Frequently filtered columns indexed** — scan repository code for all Drizzle
   filter operators on each column: `eq`, `ne`, `gt`, `gte`, `lt`, `lte`, `like`,
   `ilike`, `inArray`, `notInArray`, `between`, `isNull`, `isNotNull`. Columns
   appearing in many predicates without an index are flagged. Note: `like`/`ilike`
   with leading `%` does NOT use B-tree — recommend trigram (`pg_trgm`) GIN index.
3. **JSONB / JSON columns need GIN, not B-tree** — flag `jsonb` columns queried with
   `@>`, `?`, or `jsonb_path_exists` without a GIN index. For specific path queries,
   recommend expression index on the extracted field.
4. **Composite index opportunities** — multiple single-column indexes on the same table
   used together in queries should consider a composite index. Order by selectivity
   (highest cardinality first), but respect the actual query's predicate order.
5. **Redundant indexes** — index on `(a, b)` makes a separate index on `(a)` redundant
   via left-prefix; flag for removal. Note: `(a, b)` does NOT make `(b)` or `(b, a)`
   redundant — order matters.
6. **Unused indexes (live-DB signal)** — if a connection to the target DB is available,
   query `pg_stat_user_indexes WHERE idx_scan = 0` for indexes never used since last
   stats reset. Strong candidates for removal. Without DB access, lens reports
   "needs runtime verification".
7. **Low-cardinality columns** — boolean / enum columns with skewed distribution
   (e.g., `is_active = true` for 99% of rows). B-tree on the whole column is wasted;
   recommend partial index on the rare value: `WHERE is_active = false`. Selectivity
   threshold: flag at >95% skew.
8. **Unique constraints declared as plain indexes** — should be `unique()` constraint
   so foreign keys can reference and the query planner can use it for elimination.

## Signals to extract

- Count tables in schema
- Foreign keys without an explicit index
- Columns covered by N+ filter predicates without index coverage (N=3 default)
- JSONB columns queried without GIN index
- LIKE/ILIKE leading-wildcard queries without trigram index
- Tables with 5+ single-column indexes (consolidation opportunity)
- Boolean/enum columns with B-tree-only indexes
- (Optional, with DB access) `idx_scan=0` indexes from `pg_stat_user_indexes`

## Report template

```markdown
### Index Strategy Lens
- Tables: {N}
- FKs without index: {M} (list)
- Hot WHERE columns without index: {K}
- JSONB without GIN: {J}
- Leading-wildcard LIKE without trigram: {Q}
- Redundant indexes (left-prefix overlap): {R}
- Low-cardinality B-tree indexes: {L}
- Unused indexes (live-DB signal): {U} (or "needs runtime verification")
- Top 3 index recommendations:
  1. {table.col — reason — `CREATE INDEX ...`}
```

## Severity mapping

- HIGH — foreign key on hot-path query without index
- HIGH — JSONB column queried with `@>` / `?` without GIN index
- HIGH — leading-wildcard LIKE on non-trivial table without trigram index
- MEDIUM — frequently filtered column without index
- MEDIUM — redundant index wasting write throughput + storage
- MEDIUM — unique constraint declared as plain `index()` instead of `unique()`
- LOW — low-cardinality index without partial WHERE
- LOW — unused index (idx_scan=0) — only when live-DB stats available

## Composite-index example

```ts
// Query
db.select().from(orders).where(and(
  eq(orders.userId, uid),
  gte(orders.createdAt, since)
)).orderBy(desc(orders.createdAt));

// Recommended index (userId first — high cardinality + equality predicate,
// createdAt second — supports the range + ORDER BY)
index('orders_user_created_idx').on(orders.userId, orders.createdAt)
```

## Notes

- Read-only. Generates `CREATE INDEX` recommendations only; never applies.
- For composite recommendations, suggest column order based on selectivity + predicate.
- Live-DB checks (unused indexes) are opt-in; lens reports "skipped" without DB access.
- Reference: https://orm.drizzle.team/docs/indexes-constraints
- Reference: https://www.postgresql.org/docs/current/indexes-types.html

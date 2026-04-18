---
name: index-strategy
stack: database
category: performance
effort_min: 2
effort_max: 6
---

# Lens: Index Strategy

Single-concern audit of index coverage for query performance and storage efficiency.

## What this lens checks

1. **Foreign keys without indexes** — every `references()` column should have an index
   (PostgreSQL does NOT auto-create them for FKs). Joins and cascades suffer without.
2. **Frequently filtered columns indexed** — heuristic scan of `where(eq(table.col, ...))`
   in repository code; columns appearing in many WHERE clauses without an index are flagged.
3. **Composite index opportunities** — multiple single-column indexes on the same table
   used together in queries should consider a composite index (left-prefix matters).
4. **Redundant indexes** — index on `(a, b)` makes a separate index on `(a)` redundant
   (left-prefix); flag for removal.
5. **Indexes on low-cardinality columns** — boolean / enum-only columns rarely benefit
   from a B-tree index alone; consider partial index `WHERE col = 'rare-value'`.
6. **Unique constraints declared as indexes** — should be `unique()` constraint, not
   `index()` with manual uniqueness check.

## Signals to extract

- Count tables in schema
- Foreign keys without an explicit index
- Columns in WHERE clauses without index coverage
- Tables with 5+ single-column indexes (consolidation opportunity)
- Boolean/enum columns with B-tree-only indexes

## Report template

```markdown
### Index Strategy Lens
- Tables: {N}
- FKs without index: {M} (list)
- Hot WHERE columns without index: {K}
- Redundant indexes (left-prefix overlap): {J}
- Low-cardinality B-tree indexes: {L}
- Top 3 index recommendations:
  1. {table.col — reason — `CREATE INDEX ...`}
```

## Severity mapping

- HIGH — foreign key on hot-path query without index (measurable slowdown)
- MEDIUM — frequently filtered column without index
- MEDIUM — redundant index wasting write throughput + storage
- LOW — low-cardinality index without partial WHERE
- LOW — unique constraint declared as index instead of unique

## Notes

- Lens is read-only — generates `CREATE INDEX` recommendations as text, never applies.
- For composite recommendations, suggests column order based on selectivity heuristics.
- Reference: https://orm.drizzle.team/docs/indexes-constraints

---
name: transaction-boundaries
stack: database
category: correctness
effort_min: 1
effort_max: 4
---

# Lens: Transaction Boundaries

Single-concern audit of multi-step database writes for atomicity gaps.
Read-only — flags candidates; user decides on the transaction strategy.

## What this lens checks

1. **Multi-step writes wrapped in `db.transaction()`** — sequences of two or more
   `insert` / `update` / `delete` calls on related tables should be atomic.
2. **No external side effects inside transactions** — `fetch()`, queue publishes,
   email sends inside `db.transaction(async (tx) => { ... })` are dangerous: the
   transaction holds row locks while waiting on network, rollback cannot undo external
   effects, and on PostgreSQL **long transactions block VACUUM** (causes table bloat).
3. **Error handling actually triggers rollback** — Drizzle rolls back automatically
   when the callback throws. A `try { ... } catch` inside the callback that swallows
   the error causes the transaction to **commit** instead of rollback. Re-throw
   unless you have a documented reason to suppress.
4. **No raw `tx` reference escape** — passing `tx` out of the callback (storing in a
   module-level variable, awaiting outside) leads to "transaction already closed"
   errors and split-brain state. Pass functions, not the `tx` object, across boundaries.
5. **Nested transactions are savepoints, not isolated transactions** — Drizzle's
   `tx.transaction(...)` creates a SAVEPOINT inside the outer tx. If the outer tx
   rolls back, the inner work is also gone. Flag code that assumes inner-tx isolation.
6. **Read-then-write pattern with explicit locking when needed** — patterns like
   "select balance, then update balance" race without explicit locking. Recommend
   `serializable` isolation OR `SELECT ... FOR UPDATE` (`.for('update')` — note:
   PostgreSQL/MySQL only, **not supported on SQLite**; for SQLite use the implicit
   `BEGIN IMMEDIATE` pattern).
7. **Deadlock retry wrapper** — code paths that legitimately can encounter
   serialization failures (`40001`) or deadlocks (`40P01` / SQLITE_BUSY) should be
   wrapped in a retry loop with exponential backoff. Otherwise transient failures
   crash the request.

## Anti-pattern example

```ts
// DON'T — error swallowed → transaction commits despite logical failure
await db.transaction(async (tx) => {
  await tx.insert(orders).values(o);
  try {
    await tx.insert(payments).values(p);
  } catch (err) {
    console.error('payment failed', err);  // SWALLOWED → outer commit happens
  }
});

// DO — let the error propagate so Drizzle rolls back
await db.transaction(async (tx) => {
  await tx.insert(orders).values(o);
  await tx.insert(payments).values(p);  // throws → automatic rollback
});
```

## Signals to extract

- Count repository functions with 2+ mutation calls
- Functions with mutations not wrapped in `db.transaction(...)`
- Transactions containing `fetch`, `await sendMail`, queue publishes
- Catch blocks inside transactions that don't re-throw
- Nested `tx.transaction(...)` calls (verify SAVEPOINT semantics is intended)
- Read-then-write patterns without `.for('update')` or `serializable` isolation
- Mutation paths reachable under contention without retry-on-deadlock wrapper

## Report template

```markdown
### Transaction Boundaries Lens
- Functions with multi-step writes: {N}
- Missing transaction wrapper: {M} (list)
- Side effects inside transactions: {K}
- Error swallowing inside transactions: {J}
- Nested-tx (savepoint) usage requiring review: {S}
- Hot read-then-write paths without locking: {R}
- Top 3 atomicity gaps:
  1. {file:line — gap — recommended fix}
```

## Severity mapping

- HIGH — multi-step write across related tables without transaction (data integrity risk)
- HIGH — external side effect (HTTP, email, queue) inside transaction body
- HIGH — error swallowed inside transaction (silent commit of broken state)
- MEDIUM — read-then-write pattern under contention without explicit locking
- MEDIUM — `tx` reference passed out of callback (runtime errors likely)
- MEDIUM — nested `tx.transaction(...)` where caller assumes isolation (savepoint trap)
- LOW — mutation path lacks deadlock-retry wrapper

## Notes

- Read-only. Lens never modifies code.
- Stack-aware: `.for('update')` recommendation skipped for SQLite projects (use
  `BEGIN IMMEDIATE` pattern instead).
- Reference: https://orm.drizzle.team/docs/transactions
- Reference: https://www.postgresql.org/docs/current/transaction-iso.html

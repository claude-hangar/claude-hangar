---
name: transaction-boundaries
stack: database
category: correctness
effort_min: 1
effort_max: 4
---

# Lens: Transaction Boundaries

Single-concern audit of multi-step database writes for atomicity gaps.

## What this lens checks

1. **Multi-step writes inside `db.transaction()`** — sequences of two or more `insert` /
   `update` / `delete` calls on related tables should be wrapped in a transaction.
2. **No external side effects inside transactions** — `fetch()`, queue publishes, email
   sends inside `db.transaction(async (tx) => { ... })` are dangerous (transaction holds
   row locks while waiting on network; rollback cannot undo external effects).
3. **Error handling propagates rollback** — `try { ... } catch` blocks inside transactions
   that swallow errors prevent rollback. Re-throw or rely on transaction's natural error path.
4. **No raw `tx` reference escape** — passing the `tx` object out of the callback
   (storing in module-level variable) is a leak; transaction is invalid after callback returns.
5. **Isolation level explicit when needed** — repository methods that read-then-write
   on the same row consider `serializable` isolation or `SELECT ... FOR UPDATE` (Drizzle:
   `.for('update')`).

## Signals to extract

- Count repository functions with 2+ mutation calls
- Functions with mutations not wrapped in `db.transaction(...)`
- Transactions containing `fetch`, `await sendMail`, queue publishes
- Catch blocks inside transactions that don't re-throw

## Report template

```markdown
### Transaction Boundaries Lens
- Functions with multi-step writes: {N}
- Missing transaction wrapper: {M} (list)
- Side effects inside transactions: {K}
- Error swallowing inside transactions: {J}
- Top 3 atomicity gaps:
  1. {file:line — gap}
```

## Severity mapping

- HIGH — multi-step write across related tables without transaction (data integrity risk)
- HIGH — external side effect (HTTP, email, queue) inside transaction body
- MEDIUM — error swallowed inside transaction (silent rollback failure)
- LOW — read-then-write pattern without explicit isolation/locking
- LOW — `tx` reference passed to functions outside the transaction callback

## Notes

- Lens is read-only — flags candidates; user decides on the right transaction strategy.
- Reference: https://orm.drizzle.team/docs/transactions

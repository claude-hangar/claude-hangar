# Architectural Decisions Register

Append-only log of architectural decisions for this project.
**Never edit or delete rows** — to reverse a decision, append a new row that supersedes it.

## How to Use

- Read this file before every planning or research phase
- Append a new row when making an architectural decision during execution
- Reference decision numbers in commits and PRs (e.g., "per ADR-003")
- Mark decisions as `Superseded by ADR-XXX` when reversed

## Decisions

| # | Date | Scope | Decision | Choice | Rationale | Revisable? | Made By |
|---|------|-------|----------|--------|-----------|------------|---------|
| ADR-001 | {{DATE}} | {{SCOPE}} | {{DECISION_SUMMARY}} | {{CHOSEN_OPTION}} | {{WHY_THIS_CHOICE}} | {{YES_OR_NO}} | {{AUTHOR}} |

<!-- Template row for quick copy:
| ADR-XXX | YYYY-MM-DD | module/system/global | What was decided | What was chosen | Why this choice over alternatives | Yes/No | Name |
-->

## Decision Lifecycle

```
Proposed → Accepted → [Active | Superseded | Deprecated]
```

- **Proposed**: Under discussion, not yet binding
- **Accepted**: Agreed upon, binding for implementation
- **Active**: Currently in effect
- **Superseded**: Replaced by a newer decision (reference the new ADR)
- **Deprecated**: No longer relevant due to project changes

## Good Decision Records Include

1. **Context**: What problem or question prompted this decision?
2. **Constraints**: What limits our options? (time, budget, tech, team)
3. **Options considered**: At least 2 alternatives with trade-offs
4. **Decision**: The chosen approach with clear rationale
5. **Consequences**: What this enables and what it costs
6. **Validation**: How we'll know if this was the right call

Inspired by the GSD v2 DECISIONS.md pattern and Michael Nygard's ADR format.

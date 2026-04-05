---
name: strategic-compact
description: Suggests optimal moments for /compact based on workflow state and context usage. Proactive context management to prevent quality degradation.
user_invocable: true
---

# /strategic-compact — Smart Context Management

Identifies the optimal moment to run /compact based on your current
workflow state. Proactive compaction prevents quality degradation that
happens when context fills up.

## Usage

```
/strategic-compact          # Analyze and suggest
/strategic-compact now      # Compact immediately with state preservation
```

## When to Compact

### Good Times (Low Risk)
- **After planning is complete** — exploration clutter no longer needed
- **After a commit** — implementation context can be summarized
- **After switching tasks** — previous task context is stale
- **After a long research phase** — findings are in files, not just in context
- **When token-warning fires** — 70%+ usage, quality starts degrading

### Bad Times (High Risk)
- **Mid-implementation** — lose track of what you're building
- **During debugging** — lose the error context and investigation trail
- **Before committing** — lose track of what changed and why
- **While waiting for test results** — lose context for interpreting results

## State Preservation

Before compacting, the skill ensures critical state is saved:

1. **Current task context** — What are we working on?
2. **Key decisions made** — Architecture choices, approach decisions
3. **Files modified** — What was changed in this session
4. **Pending actions** — What still needs to be done
5. **Known issues** — Problems encountered, workarounds applied

This state is passed to /compact as additional context for the summary.

## Workflow Integration

The ideal development cycle:

```
1. Plan (explore, research, design)
2. /strategic-compact → clear exploration clutter
3. Implement (write code, tests)
4. Commit
5. /strategic-compact → clear implementation details
6. Next task
```

## Output Format

```
## Compaction Analysis

**Recommendation:** COMPACT NOW

**Reason:** Planning phase complete (47 tool calls since last compact).
Implementation context is 34% of budget. Exploration results are in
STATUS.md — safe to compact.

**State to preserve:**
- Working on: ECC Phase 2 integration
- Last commit: feat(skills): add verification-loop
- Next: Create context-budget skill
- Key decision: Using skill format, not command format

**Command:** /compact
```

Inspired by ECC's strategic-compaction skill and GSD v2's fresh-context-per-task concept.

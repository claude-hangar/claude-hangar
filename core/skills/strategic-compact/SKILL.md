---
name: strategic-compact
description: Suggests optimal moments for /compact based on workflow state and context usage. Proactive context management to prevent quality degradation.
user_invocable: true
argument_hint: ""
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

## Compaction Loop Cap

To prevent infinite compact-work-compact cycles that indicate the task is too large
for a single session, strategic-compact enforces a maximum of **3 compactions per session**.

### How It Works

The skill tracks compaction count internally. On each invocation:

1. **Count < 3** — Proceed normally with compaction analysis and execution
2. **Count = 3** — Issue a warning and block further compaction:

```
## Compaction Limit Reached

You have compacted 3 times this session. This indicates context is being
consumed faster than expected.

**Recommended actions:**
1. Break the current task into smaller, independently completable sub-tasks
2. Commit current progress and start a fresh session for the next sub-task
3. Use /handoff to preserve context for the next session

Further compaction is blocked to prevent quality degradation from
repeated context loss.
```

### Why This Matters

Each compaction loses nuance — decisions, investigation trails, and subtle context
that summaries cannot fully preserve. After 3 compactions, the accumulated loss
significantly impacts quality. It is better to commit progress and start fresh than
to continue with degraded context. Reference: oh-my-opencode v3.16.0 added a similar
cap to prevent infinite compaction cycles.

Inspired by ECC's strategic-compaction skill and GSD v2's fresh-context-per-task concept.

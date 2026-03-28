# Quality Gates — Iron Laws & Verification Patterns

This document defines the quality gate philosophy used across Claude Hangar's
hooks, agents, and skills. It combines patterns from Superpowers (iron laws,
anti-rationalization), GSD (4-level verification, quality gates), and our own
pipeline evolution.

## Core Principle

> **Evidence before assertions. Always.**

No completion claim without fresh verification evidence.
No fix claim without test confirmation.
No "it works" without running the code.

## Iron Laws

Each discipline has one non-negotiable rule. Violating the letter IS
violating the spirit — there are no "technically compliant" workarounds.

| Discipline | Iron Law |
|-----------|----------|
| **Completion** | No completion claims without fresh verification evidence |
| **Testing** | No production code without a failing test first |
| **Debugging** | No fixes without root cause investigation first |
| **Review** | No approval without reading the actual code |
| **Security** | No deployment without secret scan and dependency audit |

## 4-Level Quality Gate

The `task-completed-gate.sh` hook implements a 4-level verification system:

### Level 1: Existence

The task result must exist and not be a placeholder.

**Blocks:** Empty results, error-only markers (ERROR, FAILED, TBD, TODO, N/A)

### Level 2: Error Resolution

If the result contains error indicators, it must also contain resolution
language proving the errors were addressed.

**Blocks:** Unresolved ERROR, FAILED, FATAL, PANIC, TypeError, ReferenceError,
stack traces, segfaults

**Passes with:** "fixed", "resolved", "handled", "addressed", "expected",
"intentional", "by design", "false positive"

### Level 3: Test Evidence

Tasks about testing/verification must include actual test output.

**Triggers on:** Subject/description containing "test", "verify", "validate",
"check", "assert", "spec", "e2e"

**Requires:** Pass/fail counts, test result keywords, assertion output,
coverage numbers

### Level 4: Substance

The result must be proportional to the task complexity and describe WHAT was
done, not just THAT it was done.

**Blocks:** One-word results ("Done", "Fixed", "Completed"), vague results,
suspiciously brief results for complex tasks

## Anti-Rationalization Patterns

These thought patterns signal quality gate bypass attempts:

| Thought | Reality |
|---------|---------|
| "It's obviously working" | Run the test. Observe the output. Then claim. |
| "I just made a small change" | Small changes cause big bugs. Verify anyway. |
| "The tests would catch it" | Did you run them? Show the output. |
| "It's the same pattern as before" | Similar isn't identical. Check this specific case. |
| "I'll verify later" | Later never comes. Verify now. |
| "The user is in a hurry" | Broken code wastes more time than verification. |
| "It's just a config change" | Config errors are the hardest to debug. Test it. |

## Gate Functions

A gate function is a procedural checkpoint that MUST be passed before
proceeding. The pattern is:

```
IDENTIFY → RUN → READ → VERIFY → CLAIM
```

1. **IDENTIFY** the command that would prove the claim
2. **RUN** that command
3. **READ** the actual output (not a summary)
4. **VERIFY** the output matches expectations
5. Only then **CLAIM** success

### Example: "Tests pass"

```
IDENTIFY: npm test
RUN: Execute npm test
READ: See "47 passing, 0 failing"
VERIFY: 0 failing, no skipped tests that matter
CLAIM: "All 47 tests pass"
```

### Example: "Bug is fixed"

```
IDENTIFY: Reproduce the bug scenario
RUN: Execute the reproduction steps
READ: Observe the output/behavior
VERIFY: Bug no longer occurs AND no regression
CLAIM: "Bug fixed, verified with [specific scenario]"
```

## Forensics

When things go wrong, the subagent tracker captures forensic data:

- **Duration tracking** — which agents take too long?
- **Thrashing detection** — same agent type spawning 3+ times in 2 minutes
- **Failure patterns** — which agent types fail most often?
- **Concurrency peaks** — how many agents ran simultaneously?

This data helps identify systemic issues rather than just fixing symptoms.

## Integration Points

| Component | Quality Gate |
|-----------|-------------|
| `task-completed-gate.sh` | 4-level verification on TaskCompleted |
| `plan-reviewer` agent | Spec compliance review after implementation |
| `commit-reviewer` agent | Pre-commit quality check |
| `adversarial-review` skill | Minimum 5 findings on any review |
| `verification-before-completion` | Superpowers iron law enforcement |
| `subagent-tracker.sh` | Forensics and thrashing detection |

## Related Documents

- [Hook System](hook-system.md) — How hooks intercept and validate
- [Session Continuity](session-continuity.md) — Context preservation
- [State Management](state-management.md) — Skill state lifecycle
- [Patterns](../patterns.md) — Error handling patterns

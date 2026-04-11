---
name: refactor-team
description: >
  Launch parallel refactoring agents: one restructures code in an isolated worktree,
  one writes tests to lock behavior, one reviews the result.
  Use when: "refactor team", "refactor-team", "safe refactor", "restructure code".
effort: high
user-invocable: true
argument-hint: "[what to refactor and why]"
---

# /refactor-team — Safe Parallel Refactoring

Three agents work simultaneously on the same refactoring goal — each from a different
angle. The worktree-isolated refactoring means your working tree stays clean until
you approve the changes.

## Team Composition

| Agent | Role | Isolation | Focus |
|-------|------|-----------|-------|
| **refactor-agent** | Restructurer | Worktree | Plans + executes the refactoring in isolation |
| **test-writer** | Behavior Lock | Worktree | Writes characterization tests that capture current behavior |
| **code-reviewer** | Quality Gate | Read-only | Reviews the refactored code for regressions and quality |

## Why Three Agents?

The classic refactoring mistake: changing code without tests that prove nothing broke.
This team eliminates that by running test-writing and refactoring **in parallel**:

1. `test-writer` locks current behavior with characterization tests
2. `refactor-agent` restructures the code in an isolated worktree
3. `code-reviewer` checks the diff for regressions, naming, and architecture

The characterization tests serve as a safety net: run them against the refactored code
to prove behavior is preserved.

## Instructions

### Step 1: Understand the Scope

From `$ARGUMENTS` or conversation, extract:
- **What** to refactor (files, modules, patterns)
- **Why** (too complex, duplicated, wrong abstraction, performance)
- **Constraints** (public API must stay stable, no dependency changes, etc.)

If the scope is unclear, ask ONE question:
"Which files or module should I refactor, and what's the main goal?"

### Step 2: Gather Context

Before launching agents, collect:
- List of files in scope: `git ls-files | grep [pattern]`
- Current test coverage: check for existing test files
- Recent changes: `git log --oneline -10 -- [files]`
- Dependency graph: which files import from the refactoring targets

### Step 3: Launch Parallel Agents

Launch all three agents in a **single message** (parallel execution):

```
Agent({
  subagent_type: "test-writer",
  isolation: "worktree",
  description: "Write characterization tests",
  prompt: "Write characterization tests for: [files].

Your goal is to LOCK the current behavior — not test correctness,
but capture what the code actually does right now.

Focus on:
1. All public functions/exports — call with representative inputs
2. Edge cases you discover by reading the code
3. Error paths — what happens with invalid input
4. Side effects — file writes, API calls, state mutations

Name tests descriptively: 'should [current behavior] when [condition]'
This is a safety net for refactoring — every test must pass both
before AND after the refactoring.

Output: the test file(s) you created and how to run them."
})

Agent({
  subagent_type: "refactor-agent",
  isolation: "worktree",
  description: "Refactor [target]",
  prompt: "Refactor: [files]
Goal: [why — e.g., extract shared logic, reduce complexity, improve naming]
Constraints: [e.g., public API unchanged, no new dependencies]

Process:
1. Read all files in scope and their dependents
2. Plan the refactoring as ordered steps
3. Execute each step, running existing tests after each change
4. If any test fails, revert that step and re-plan
5. Report: what changed, why, before/after metrics (lines, complexity)

Produce a clean diff that could be cherry-picked."
})

Agent({
  subagent_type: "code-reviewer",
  description: "Review refactoring",
  prompt: "You will review a refactoring of: [files].
Goal of the refactoring: [why].

Wait for the refactoring to be described, then review:
1. Does the refactored code preserve the original behavior?
2. Are there any subtle regressions (changed error messages, different order of operations, lost edge cases)?
3. Is the new structure actually simpler or just different?
4. Naming: are the new names clearer than the old ones?
5. Are there any new code smells introduced?

Read the original files first to establish a baseline, then
read the refactored files from the worktree.

Report findings by severity (CRITICAL/HIGH/MEDIUM/LOW).
Verdict: APPROVED / NEEDS REVISION."
})
```

### Step 4: Integration Report

After all three agents complete, produce a unified report:

```markdown
## Refactoring Team Report

### Scope
[files and goal]

### Characterization Tests
- Tests written: N
- Coverage of public API: X%
- Test command: `[how to run]`

### Refactoring Summary
- Files changed: N
- Lines before: X → Lines after: Y (delta: Z%)
- Complexity before: X → after: Y
- Key changes:
  1. [change description]
  2. [change description]

### Review Verdict
[from code-reviewer — APPROVED / NEEDS REVISION]
- CRITICAL: [count]
- HIGH: [count]
- MEDIUM: [count]

### Verification Plan
1. Apply characterization tests to main branch (should all pass)
2. Apply refactored code
3. Run characterization tests again (should all still pass)
4. Run existing test suite (should all pass)
```

### Step 5: Offer Next Steps

"The refactoring is ready in a worktree. Options:
1. **Merge** — Apply changes + tests to your working tree
2. **Review diff** — Show me the full diff first
3. **Revise** — Address the reviewer's findings first
4. **Discard** — Clean up the worktree, keep only the tests"

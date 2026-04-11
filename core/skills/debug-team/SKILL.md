---
name: debug-team
description: >
  Launch parallel debugging agents for systematic root-cause analysis.
  Use when: "debug team", "help me debug", "debug-team", "find the bug".
effort: high
user-invocable: true
argument-hint: "[error message or bug description]"
---

# /debug-team — Multi-Agent Debugging Team

Launch a parallel debugging team that investigates bugs from multiple angles simultaneously.
Combines deep code analysis, error pattern matching, and test-driven verification.

## Team Composition

| Agent | Role | Focus |
|-------|------|-------|
| **explorer-deep** | Code Analyst | Trace execution paths, find root cause in code |
| **build-resolver-*** | Build Expert | Resolve build/test/dependency failures (auto-detected) |
| **tdd-guide** | Test Expert | Write reproduction test, verify fix |

## Instructions

### Step 1: Capture Bug Context

From the user's `$ARGUMENTS` or conversation, extract:
- **Symptom**: What's failing? (error message, unexpected behavior, test failure)
- **Trigger**: When does it happen? (specific input, sequence, timing)
- **Scope**: Which files/modules are involved?

If insufficient context, ask: "What error or unexpected behavior are you seeing?"

### Step 2: Detect Stack

Scan the project for build tools to select the right build-resolver:
- `tsconfig.json` or `package.json` with TypeScript → `build-resolver-typescript`
- `go.mod` → `build-resolver-go`
- `pyproject.toml`, `setup.py`, `requirements.txt` → `build-resolver-python`
- None detected → skip build-resolver, use explorer-deep twice with different prompts

### Step 3: Launch Parallel Agents

Launch all applicable agents simultaneously:

```
Agent({
  subagent_type: "explorer-deep",
  description: "Root cause analysis",
  prompt: "Investigate this bug: [symptom]. Trace the execution path from [trigger point]. Find the root cause. Check: data flow, state mutations, error handling, race conditions, edge cases. Report: SYMPTOM → CONTEXT → CAUSE → FIX suggestion."
})

Agent({
  subagent_type: "build-resolver-[lang]",
  description: "Build/dependency analysis",
  prompt: "Analyze this error: [error message]. Check: dependency versions, import resolution, build configuration, type errors, missing modules. Report what's broken and how to fix it."
})

Agent({
  subagent_type: "tdd-guide",
  description: "Reproduction test",
  prompt: "Write a failing test that reproduces this bug: [symptom]. The test should: 1) Set up the minimal scenario, 2) Trigger the bug, 3) Assert the expected (correct) behavior. The test MUST fail with the current code. Report the test and where to place it."
})
```

**All agents MUST be launched in a single message (parallel execution).**

### Step 4: Synthesis

After all agents complete, synthesize findings:

```markdown
## Debug Team Report

### Bug Summary
[one-line description]

### Root Cause
[from explorer-deep findings]

### Evidence
- Code path: [file:line → file:line → failure point]
- Build/dependency factor: [from build-resolver, if applicable]

### Reproduction Test
[from tdd-guide — the failing test]

### Recommended Fix
[concrete fix based on root cause analysis]

### Prevention
[what to change so this class of bug can't recur]
```

### Step 5: Offer to Fix

Present the fix plan and ask:
"I've identified the root cause. Shall I:
1. Apply the fix and run the reproduction test to verify?
2. Just show the fix for manual review?"

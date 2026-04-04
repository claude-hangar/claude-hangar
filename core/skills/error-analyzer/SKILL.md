---
name: error-analyzer
description: >
  Systematic root-cause analysis for build failures, test errors, and runtime issues.
  Use when: "error", "failed", "broken", "debug", "why did this fail", "root cause".
---

<!-- AI-QUICK-REF
## /error-analyzer — Quick Reference
- **Modes:** analyze | auto
- **Flow:** SYMPTOM → CONTEXT → CAUSE → FIX → PREVENTION (5-step protocol)
- **Triggers:** Build failure, test failure, runtime error, deploy failure
- **Output:** Structured analysis with fix + prevention recommendation
- **Anti-Pattern:** Never guess-and-fix without completing all 5 steps
-->

# /error-analyzer — Systematic Root-Cause Analysis

Enforced 5-step protocol for analyzing errors. Prevents the "guess-and-fix" anti-pattern where symptoms are treated without understanding the root cause.

**Inspired by:** GSD v2 "Doctor" pattern, Superpowers "systematic-debugging" skill.

## Iron Law

**NO FIX WITHOUT ROOT CAUSE.** You must complete all 5 steps before suggesting a fix. Skipping steps leads to phantom fixes that mask the real problem.

## The 5-Step Protocol

### Step 1: SYMPTOM — What exactly failed?

Capture the error precisely:

```
1. Read the FULL error message (not just the first line)
2. Note the exit code
3. Note the file and line number (if available)
4. Note the command that triggered the error
5. Note WHEN it started failing (always? after a change? intermittent?)
```

**Output format:**
```
SYMPTOM: [one-line summary]
  Error: [full error message]
  Exit code: [code]
  Location: [file:line]
  Trigger: [command or action]
  Frequency: [always | after X | intermittent]
```

### Step 2: CONTEXT — What surrounds the failure?

Gather context WITHOUT changing anything:

```
1. Read the failing file/function completely
2. Check recent changes: git log --oneline -10, git diff
3. Check environment: node -v, npm ls, OS, relevant env vars
4. Check related files (imports, config, dependencies)
5. Check if this worked before: git log --oneline -- <failing-file>
```

**Questions to answer:**
- Did this ever work? When did it stop working?
- What changed between "working" and "broken"?
- Is the error environment-specific (CI vs local, Windows vs Linux)?

### Step 3: CAUSE — Why exactly does this happen?

Now diagnose the root cause:

```
1. Form a hypothesis based on Steps 1-2
2. Verify the hypothesis (don't assume — PROVE it)
3. If hypothesis is wrong, form a new one
4. Trace the causal chain: Event A → caused B → which caused C → visible as Symptom
```

**Root cause categories:**
- **Code bug:** Logic error, missing null check, wrong type
- **Config error:** Wrong path, missing env var, wrong version
- **Dependency issue:** Version conflict, missing package, breaking change
- **Environment:** OS difference, Node version, file permissions
- **Race condition:** Timing-dependent, works locally but fails in CI
- **Data issue:** Corrupt input, missing file, encoding problem

**Output format:**
```
CAUSE: [one-line root cause]
  Category: [code | config | dependency | environment | race | data]
  Causal chain: [A] → [B] → [C] → [Symptom]
  Evidence: [how you verified this]
```

### Step 4: FIX — Minimal, targeted change

Apply the smallest fix that addresses the root cause:

```
1. Change ONLY what is necessary to fix the root cause
2. Do NOT refactor surrounding code
3. Do NOT add "while we're at it" improvements
4. Verify the fix: run the failing command again
5. Verify no regressions: run related tests
```

**Verification protocol:**
```bash
# 1. Run the originally failing command
[original command that failed]

# 2. Run related tests
[test command]

# 3. Verify on both platforms if relevant
```

### Step 5: PREVENTION — How to prevent recurrence

Ensure this class of error cannot happen again:

```
1. Can a test catch this? → Write the test
2. Can a lint rule catch this? → Add the rule
3. Can a hook catch this? → Add/modify the hook
4. Can documentation prevent this? → Update docs
5. Is this a pattern? → Document in patterns.md
```

**Output format:**
```
PREVENTION:
  Test: [test added? path?]
  Lint/Hook: [rule added?]
  Docs: [updated?]
  Pattern: [documented?]
```

## Modes

### `/error-analyzer analyze`

Interactive mode. Walk through each step with user confirmation:

1. Present SYMPTOM analysis → confirm
2. Present CONTEXT findings → confirm
3. Present CAUSE hypothesis → confirm
4. Apply FIX → verify together
5. Discuss PREVENTION → implement together

### `/error-analyzer auto`

Autonomous mode. Complete all 5 steps without pausing:

1. Capture SYMPTOM from the most recent error/failure
2. Gather CONTEXT automatically (git, env, files)
3. Diagnose CAUSE with verification
4. Apply FIX and verify
5. Implement PREVENTION (test, lint rule, or doc update)

## Anti-Patterns (NEVER DO)

| Anti-Pattern | What happens | Instead |
|-------------|-------------|---------|
| **Guess-and-fix** | Change random things hoping it works | Complete all 5 steps |
| **Symptom treatment** | Suppress the error message | Find the root cause |
| **Shotgun debugging** | Change 10 things at once | One change at a time |
| **Works on my machine** | Dismiss env differences | Investigate the difference |
| **Blame the framework** | Assume the tool is broken | Verify your usage first |
| **Skip prevention** | Fix and move on | Always add a test or guard |

## Integration with Other Tools

- **Build failure:** Run the build, capture stderr, start analysis
- **Test failure:** Parse test output, identify failing test, start analysis
- **Deploy failure:** Read CI logs, identify failure step, start analysis
- **Runtime error:** Read error logs, capture stack trace, start analysis

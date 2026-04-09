---
name: error-analyzer
description: >
  Systematic root-cause analysis for build failures, test errors, and runtime issues.
  Use when: "error", "failed", "broken", "debug", "why did this fail", "root cause".
user_invocable: true
argument_hint: ""
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
- **Quota exhaustion:** API rate limit (429), quota exceeded — **classify as STOP, not retryable**

**Output format:**
```
CAUSE: [one-line root cause]
  Category: [code | config | dependency | environment | race | data | quota]
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
| **Retry quota exhaustion** | 429 retry loops, 30-min lockouts | STOP — inform user, wait or switch API keys |

## Quota Exhaustion Protocol

API quota exhaustion (HTTP 429 with "rate limit" or "quota exceeded") is a **STOP classification** — it must never be retried automatically. Retrying quota exhaustion causes cascading failures: 429 retry loops that escalate to 30-minute lockouts.

**When a 429 is detected:**

1. **STOP** — Do not retry the request
2. **Classify** — Distinguish between rate limit (temporary, wait and retry once) and quota exceeded (hard limit, no retry)
3. **Inform** — Tell the user: which API, what the limit is, when it resets (if known)
4. **Suggest** — Wait for reset window, switch API keys, or reduce request volume

**Reference:** oh-my-opencode v3.16.0 learned this the hard way — blind retries on 429s caused cascading lockouts across multiple API providers.

## Agent Introspection Debugging

When an AI agent itself causes the error (wrong code generation, hallucinated imports, incorrect assumptions), use this 4-phase self-debugging workflow:

### Phase 1: Failure Capture

Record precisely what happened:
- Exact error message and stack trace
- What the agent was attempting to do
- What code was generated or modified
- What context the agent had at the time

### Phase 2: Root-Cause Analysis

Categorize the failure:
- **Code bug:** Agent generated logically incorrect code
- **Config issue:** Agent assumed a configuration that doesn't exist
- **Environment problem:** Agent assumed a tool, path, or runtime that isn't available
- **AI hallucination:** Agent invented an API, module, flag, or behavior that doesn't exist

### Phase 3: Contained Recovery

Fix within the smallest possible scope:
- Revert the broken change, don't layer fixes on top of fixes
- Fix only the root cause, don't cascade changes to "related" code
- Verify the fix in isolation before proceeding with the original task

### Phase 4: Report

Document what happened:
```
INTROSPECTION:
  Failed action: [what was attempted]
  Root cause: [code bug | config issue | environment | hallucination]
  Recovery: [what was done to fix it]
  Prevention: [what to check next time]
```

### Common Agent Failure Patterns

| Pattern | Symptom | Root Cause | Recovery |
|---------|---------|-----------|----------|
| **Import ghost** | Module not found | AI generated import for nonexistent module | Check actual exports, use correct path |
| **Signature drift** | Type error on function call | Function signature changed but callers weren't updated | Update all callers or revert signature |
| **Test theater** | Tests pass but feature broken | Tests mock too much or test the wrong thing | Write integration test against real behavior |
| **Config phantom** | Works locally, fails in CI | Env var or config present locally but not in CI | Add to .env.example and CI config |

## Integration with Other Tools

- **Build failure:** Run the build, capture stderr, start analysis
- **Test failure:** Parse test output, identify failing test, start analysis
- **Deploy failure:** Read CI logs, identify failure step, start analysis
- **Runtime error:** Read error logs, capture stack trace, start analysis

---
name: adversarial-review
description: >
  Critical review (min. 5 findings). Modes: code, audit, plan.
  Use when: "review", "critical review", "code review", "plan review", "audit review".
---

<!-- AI-QUICK-REF
## /adversarial-review — Quick Reference
- **Modes:** code | audit | plan
- **Arguments:** `/adversarial-review $0` e.g. `/adversarial-review code`
- **Minimum:** 5 findings — 0 findings = repeat review
- **3 Tracks:** Adversarial (creatively break) | Catalog (17 modes) | Path Tracer (paths)
- **Goal-Backward:** Artifact exists? Substantial? Wired up?
- **No praise** until at least 5 problems have been named
- **Severity:** CRITICAL (~1-5%) > HIGH (~0.1-1%) > MEDIUM (~0.01%) > LOW (<0.01%)
- **Output:** Findings list with failure mode + risk + overall assessment
-->

# /adversarial-review — Critical Review

Enforces an honest, critical review instead of a courtesy review.
Minimum 5 findings — if fewer are found, look again.

**Source:** BMAD (review-adversarial-general + PromptSentinel v1.2) Community Pattern

## Problem

LLMs tend toward positive reviews: "Looks good", "Well structured",
"No problems found". This is almost never true — every codebase has room for improvement.
Courtesy reviews are worthless.

## Modes

| Mode | Trigger | What gets reviewed |
|------|---------|-------------------|
| `code` | `/adversarial-review code` | Code changes (git diff or files) |
| `audit` | `/adversarial-review audit` | Audit report for completeness and quality |
| `plan` | `/adversarial-review plan` | Implementation plan for gaps and risks |

---

## Mode: code

Critical code review focused on real problems.

### Process

1. **Determine scope:**
   - Read `git diff` (unstaged + staged)
   - Or: User specifies files/directories
   - Or: Last commit (`git diff HEAD~1..HEAD`)

2. **Apply three parallel review tracks:**

   **Track A — Adversarial:** "How does this code break under load?"
   - Concurrent access, race conditions, deadlocks
   - Network errors, timeouts, API outages
   - Unexpected inputs (null, empty, max, min, Unicode)
   - Security: Injection, XSS, CSRF, secrets

   **Track B — Failure Mode Catalog:** Systematically scan against 17 modes:

   | # | Mode | Look for... |
   |---|------|-------------|
   | 1 | Silent Exceptions | Exception caught but not propagated |
   | 2 | Missing Input Validation | Type/bounds not checked |
   | 3 | Implicit Dependencies | Assumes prior state, not verified |
   | 4 | Over/Under Validation | 1000 lines of validation OR none at all |
   | 5 | Non-Determinism | Timing, random order, unordered maps |
   | 6 | Double Negation | Complex boolean logic |
   | 7 | Implicit Initialization | Assumes prior setup |
   | 8 | Type Gaps | Parameter type assumed, not validated |
   | 9 | Unprotected Extensibility | API extensible, untested |
   | 10 | No Progress Tracking | Long tasks without logging/checkpoints |
   | 11 | Redundant Code | Re-implements stdlib |
   | 12 | Outdated Patterns | Callbacks instead of async/await, var instead of let |
   | 13 | Undocumented API | Return value unclear |
   | 14 | No Fallback | External API call without timeout/retry |
   | 15 | Unclear Completion | Function done? Exception or return? |
   | 16 | Monolithic Function | >200 lines, should be split |
   | 17 | Hardcoded Values | Should be config/ENV |

   **Track C — Path Tracer:** Walk through every execution path:
   - Entry condition unambiguous?
   - All inputs validated?
   - State consistent across branches?
   - Resources cleaned up? (Streams, connections, handles)

3. **Goal-Backward Verification:**
   - What was the goal of the change? (Commit message, PR description)
   - Was the goal achieved?
   - Are there side effects?

4. **Stub Detection:**
   - Functions that only `return null/undefined/true`?
   - Empty catch blocks or error swallowing?
   - Config files with only default values?
   - Test assertions that always pass (`expect(true).toBe(true)`)?
   - "File exists" != "Check passed" — apply 4-level verification

4. **Minimum 5 findings** — if <5 found:
   - Look again: Testability, edge cases, documentation
   - If truly <5 (very small diff): Reduce minimum to 3
   - 0 findings is NEVER acceptable

### Severity with Risk Assessment

| Severity | Definition | Defect Rate |
|----------|-----------|-------------|
| CRITICAL | System outage, data loss | ~1-5% |
| HIGH | Data corruption, security vulnerability | ~0.1-1% |
| MEDIUM | Degraded UX/performance | ~0.01-0.1% |
| LOW | Code smell, maintainability | <0.01% |

### Finding Format

```
### {ID}: {Short Title}
**Severity:** {CRITICAL|HIGH|MEDIUM|LOW}
**Failure-Mode:** {# from catalog, e.g. #1 Silent Exception}
**File:** `{path}:{line}`
**Problem:** {What is the problem}
**Suggestion:** {How to fix it}
```

---

## Mode: audit

Review of an audit report for completeness and quality.

### Process

1. Read audit report (AUDIT-REPORT-*.md or PROJECT-AUDIT-REPORT-*.md)
2. Read state file (.audit-state.json or .project-audit-state.json)
3. Check:
   - Were all phases completed? (State vs. report)
   - Are there phases with <80% mandatory checks?
   - Are severity ratings plausible? (MEDIUM that should actually be HIGH?)
   - Are obvious finding categories missing? (e.g., no security finding for a web project)
   - Are recommendations concrete and actionable?
   - Are there copy-paste findings (same problem, different IDs)?
4. **Goal-Backward:** Does the report cover the entire project?
5. **Minimum 5 findings** on the report itself

### Report Review Findings

```
### R-{ID}: {Short Title}
**Category:** Gap | Severity Error | Incomplete | Quality
**Reference:** {Phase or Finding-ID}
**Problem:** {What is missing or wrong}
**Suggestion:** {How the report can be improved}
```

### State Write-Back (Category "Gap")

When the review finds findings of category **"Gap"** (missing checks, skipped validations), these can be written back as new findings to the audit state:

1. Read audit state (`.audit-state.json` or `.project-audit-state.json`)
2. For each "Gap" finding:
   - Create new finding with next available ID (e.g., `SEC-07`)
   - `"status": "open"`, `"notes": "From adversarial-review R-{ID}"`
   - Derive phase and severity from the review finding
3. Update state file (summary + findings array)
4. Inform user: "{N} findings from review added to audit state"

**Rules:**
- ONLY category "Gap" is written back — not "Severity Error", "Incomplete", or "Quality"
- "Severity Error" — user manually corrects in state
- "Incomplete" / "Quality" — meta-findings about the report, not the project
- Write-back only after user confirmation (AskUserQuestion)

---

## Mode: plan

Review of an implementation plan for gaps and risks.

### Process

1. Read plan (Markdown, CLAUDE.md, or current plan mode)
2. Check:
   - Are all dependencies identified?
   - Is there a rollback scenario?
   - What happens if step X fails?
   - Are the estimates realistic?
   - Are steps missing? (Tests, documentation, deployment)
   - Are there unvalidated assumptions?
3. **Goal-Backward:**
   - Does the planned artifact actually exist at the end?
   - Is it substantial (not just a placeholder)?
   - Is it wired up (referenced, deployed, configured)?
4. **Minimum 5 findings** on the plan itself

---

## Rules

1. **Minimum 5 findings** — 0 = stop + review again, never "all good"
2. **No praise first** — problems first, then (optionally) positives
3. **Rate severity honestly** — when in doubt, rate higher
4. **Concrete suggestions** — not just "should be improved"
5. **Goal-Backward always** — Does it exist? Substantial? Wired up?
6. **No scope creep** — only review what was requested
7. **On re-review** after fixes: Only new/changed findings, no repetitions

## Smart Next Steps

After completing the review, suggest appropriate follow-up actions to the user:

| Mode | Condition | Recommendation |
|------|-----------|---------------|
| `audit` | Findings with category "Gap" | "Regenerate report after fixes: `/audit report` or `/project-audit report`" |
| `audit` | Findings with category "Severity Error" | "Correct severity in state, then update report" |
| `code` | >3 HIGH findings | "Implement fixes, then run `/adversarial-review code` again" |
| `plan` | Findings present | "Revise plan, then run `/adversarial-review plan` again" |

---

## When to Recommend

- Before every deploy or push
- After an audit report
- For architecture decisions
- When the user asks "does this look good?"

## Files

```
adversarial-review/
└── SKILL.md    ← This file
```

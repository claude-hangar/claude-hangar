---
name: inline-review
description: >
  Quick self-review checklist after code changes. Lightweight alternative to adversarial-review.
  Use when: "review my changes", "self-review", "quick review", "check my work", or automatically after significant edits.
user_invocable: true
argument_hint: ""
---

<!-- AI-QUICK-REF
## /inline-review — Quick Reference
- **Modes:** auto (self-review current changes) | diff (review staged changes) | file <path>
- **Checklist:** 8 items, ~30 seconds, no subagent dispatch
- **Key Difference from /adversarial-review:** Inline = fast self-check. Adversarial = deep external review with min 5 findings.
- **Inspired by:** Superpowers v5.0.6 "Inline Self-Review Replaces Subagent Review Loops"
-->

# /inline-review — Quick Self-Review

Fast, inline self-review checklist that runs after code changes. Catches the most common issues without the overhead of a full adversarial review.

**Inspired by:** Superpowers v5.0.6 removed subagent review loops (25 min overhead) and replaced them with an inline self-review checklist that produces identical quality scores.

## When to Use

- After completing a feature or fix, before committing
- After a series of edits, to catch accumulated issues
- When `/adversarial-review` feels like overkill for the change size
- As a habit after every significant code change

## The 8-Point Checklist

Run through these checks on the changed code. Each check takes ~5 seconds.

### 1. Placeholder Scan
Are there any `TODO`, `FIXME`, `HACK`, placeholder values, or stub implementations in the changes?

### 2. Internal Consistency
Do the changes contradict anything in the existing codebase? Do function signatures match their call sites? Do types match?

### 3. Scope Check
Did the changes stay within the original task scope? Were any "while we're at it" additions made that weren't requested?

### 4. Error Handling
Are error cases handled? Do new functions have appropriate error paths? Are errors logged or silenced?

### 5. Security Quick-Check
- No secrets or PII in code?
- User input validated at boundaries?
- No `eval()`, `innerHTML`, or SQL concatenation with user data?

### 6. Edge Cases
What happens with: empty input, null/undefined, very large input, concurrent access, network failure?

### 7. Test Coverage
Do the changes need tests? If tests exist, do they still pass? Are new code paths covered?

### 8. Cleanup
- No debug `console.log` or `print` statements left?
- No commented-out code blocks?
- No unused imports or variables?
- File formatting consistent?

## Modes

### `/inline-review auto`

Self-review the most recent changes in this session:

1. Identify all files changed in this session (via git diff or session context)
2. Run the 8-point checklist against each changed file
3. Report findings or "All clear"

### `/inline-review diff`

Review staged changes (`git diff --cached`):

1. Read the staged diff
2. Run the 8-point checklist
3. Report findings inline with diff context

### `/inline-review file <path>`

Review a specific file:

1. Read the file
2. Run the 8-point checklist
3. Report findings with line numbers

## Output Format

```
INLINE REVIEW — {n} file(s) checked

✓ Placeholders: None found
✓ Consistency: OK
⚠ Scope: Added error-retry logic that wasn't in the task → discuss with user
✓ Error handling: OK
✓ Security: OK
⚠ Edge cases: processItems() doesn't handle empty array
✓ Test coverage: Existing tests pass
✓ Cleanup: OK

Result: 2 items to address before committing
```

## Key Principle

**Speed over depth.** This is a 30-second checklist, not a 25-minute subagent review. If something needs deep analysis, recommend `/adversarial-review` instead.

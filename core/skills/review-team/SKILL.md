---
name: review-team
description: >
  Launch parallel code review agents for comprehensive multi-perspective review.
  Use when: "review team", "full review", "multi-review", "review-team".
effort: high
user-invocable: true
argument-hint: "[files or scope description]"
---

# /review-team — Multi-Perspective Code Review

Launch a parallel review team that examines code from multiple angles simultaneously.
The team produces a unified report with findings sorted by severity.

## Team Composition

| Agent | Role | Focus |
|-------|------|-------|
| **code-reviewer** | General Quality | Logic errors, code smells, naming, structure, DRY, edge cases |
| **security-reviewer** | Security | OWASP Top 10, injection, auth, secrets, input validation |
| **Language-specific reviewer** | Idioms | Language best practices (auto-detected from file extensions) |

## Instructions

### Step 1: Determine Scope

If the user provided `$ARGUMENTS`:
- Use that as the review scope (files, directories, or PR description)

If no arguments:
- Check `git diff --name-only HEAD~1` for recently changed files
- If no changes, ask: "Which files or feature should I review?"

### Step 2: Detect Language

Scan the files in scope for primary language:
- `.ts`, `.tsx`, `.js`, `.jsx` → use `typescript-reviewer`
- `.py` → use `python-reviewer`
- `.go` → use `go-reviewer`
- Mixed or other → skip language-specific reviewer

### Step 3: Launch Parallel Agents

Launch all applicable agents simultaneously using the Agent tool:

```
Agent({
  subagent_type: "code-reviewer",
  description: "Code quality review",
  prompt: "Review these files for code quality: [files]. Check: correctness, edge cases, error handling, naming, DRY, function size. Report findings by severity (CRITICAL/HIGH/MEDIUM/LOW). Format: file:line — issue + fix suggestion."
})

Agent({
  subagent_type: "security-reviewer",
  description: "Security review",
  prompt: "Security review these files: [files]. Check: OWASP Top 10, hardcoded secrets, injection risks, auth/authz, input validation, error message leaks. Report findings by severity."
})

Agent({
  subagent_type: "[language]-reviewer",
  description: "[Language] idiom review",
  prompt: "Review these [language] files for idiomatic patterns: [files]. Check: type safety, error handling conventions, naming conventions, framework best practices. Report findings by severity."
})
```

**All three agents MUST be launched in a single message (parallel execution).**

### Step 4: Unified Report

After all agents complete, produce a single unified report:

```markdown
## Review Team Report

### Scope
[files reviewed]

### CRITICAL
[merged from all agents, deduplicated]

### HIGH
[merged findings]

### MEDIUM
[merged findings]

### LOW
[merged findings]

### Summary
- Code Quality: X findings (Y critical/high)
- Security: X findings (Y critical/high)
- Language Idioms: X findings
- **Verdict:** APPROVED / NEEDS FIXES (N critical/high issues)
```

### Step 5: Actionable Output

If there are CRITICAL or HIGH findings:
- List specific fixes needed
- Offer to fix them: "Shall I fix the N critical/high issues?"

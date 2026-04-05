# Code Review

Centralized rules for code review process and quality.

## When to Review

| Trigger | Agent | Model |
|---------|-------|-------|
| Code written/modified | code-reviewer | Sonnet |
| TypeScript changes | typescript-reviewer | Sonnet |
| Python changes | python-reviewer | Sonnet |
| Go changes | go-reviewer | Sonnet |
| Security-sensitive changes | security-reviewer | Opus |
| Architecture decisions | architect | Opus |

## Review Severity

| Level | Definition | Action Required |
|-------|-----------|-----------------|
| **CRITICAL** | Security vulnerability, data loss risk, crash | Must fix before merge |
| **HIGH** | Logic error, missing error handling, broken functionality | Must fix before merge |
| **MEDIUM** | Code smell, poor naming, missing tests, style issue | Should fix, can defer |
| **LOW** | Nitpick, formatting preference, minor optimization | Optional |

## Review Checklist

### Correctness
- [ ] Does the code do what it's supposed to do?
- [ ] Are edge cases handled?
- [ ] Are error conditions handled properly?

### Security
- [ ] No hardcoded secrets
- [ ] Input validated at boundaries
- [ ] No SQL injection, XSS, or CSRF vulnerabilities
- [ ] Authentication/authorization checked

### Quality
- [ ] Clear, descriptive naming
- [ ] Functions under 50 lines
- [ ] No unnecessary complexity
- [ ] DRY — no duplicated logic
- [ ] Follows existing project patterns

### Testing
- [ ] New code has tests
- [ ] Tests verify behavior, not implementation
- [ ] Edge cases tested
- [ ] Coverage >= 80%

### Documentation
- [ ] Public APIs documented
- [ ] Complex logic has inline comments
- [ ] README updated if needed
- [ ] CHANGELOG updated for user-visible changes

## Review Output Format

```
## Review: [File or Feature]

### CRITICAL
- file.ts:42 — SQL injection via string concatenation
  Fix: Use parameterized query

### HIGH
- file.ts:67 — Missing null check on user lookup
  Fix: Add early return if user is null

### MEDIUM
- file.ts:15 — Function "processData" is 78 lines
  Suggestion: Extract validation into separate function

### Approved: NO (2 critical/high issues)
```

## Multi-Perspective Review

For complex changes, use parallel review agents:

1. **code-reviewer** — General quality
2. **security-reviewer** — Security vulnerabilities
3. **language-specific reviewer** — Idiomatic patterns

Results are merged by severity. All CRITICAL and HIGH issues
from any reviewer must be resolved.

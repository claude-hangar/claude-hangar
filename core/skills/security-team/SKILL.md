---
name: security-team
description: >
  Launch parallel security analysis agents for comprehensive vulnerability assessment.
  Use when: "security team", "security audit", "security-team", "pentest", "vulnerability scan".
effort: high
user-invocable: true
argument-hint: "[files, scope, or 'full' for entire project]"
---

# /security-team — Multi-Agent Security Assessment

Launch a parallel security team that examines the codebase for vulnerabilities
from multiple perspectives simultaneously.

## Team Composition

| Agent | Role | Focus |
|-------|------|-------|
| **security-reviewer** | Vulnerability Hunter | OWASP Top 10, injection, auth, access control, data exposure |
| **dependency-checker** | Supply Chain | npm audit, outdated packages, known CVEs, malicious deps |
| **explorer-deep** | Architecture Auditor | Auth flow, data flow, trust boundaries, attack surface |

## Instructions

### Step 1: Determine Scope

If the user provided `$ARGUMENTS`:
- `full` → scan entire project
- File/directory paths → scan those specifically
- Feature name → identify related files first

If no arguments:
- Check `git diff --name-only HEAD~1` for recently changed files
- If no changes, ask: "Which area should I assess? Or type 'full' for the entire project."

### Step 2: Launch Parallel Agents

Launch all three agents simultaneously:

```
Agent({
  subagent_type: "security-reviewer",
  description: "Vulnerability assessment",
  prompt: "Perform a security review of: [scope]. Check all OWASP Top 10 categories: injection (SQL, command, XSS), broken auth, sensitive data exposure, XXE, broken access control, security misconfiguration, deserialization, components with vulnerabilities, insufficient logging. Also check: CSRF protection, rate limiting, error message information leaks, hardcoded secrets. Report findings by severity (CRITICAL/HIGH/MEDIUM/LOW) with file:line references and fix suggestions."
})

Agent({
  subagent_type: "dependency-checker",
  description: "Dependency security audit",
  prompt: "Audit all project dependencies for security issues. Run npm audit (or equivalent), check for outdated packages with known CVEs, identify packages with low maintenance or suspicious characteristics. Check: lock file integrity, pinned versions, deprecated packages, transitive vulnerabilities. Report each finding with severity, CVE ID if available, and remediation steps."
})

Agent({
  subagent_type: "explorer-deep",
  description: "Security architecture analysis",
  prompt: "Analyze the security architecture of: [scope]. Map: authentication flow (login → session → authorization), data flow (user input → processing → storage → output), trust boundaries (client/server, internal/external APIs, database access), attack surface (public endpoints, file uploads, external integrations). Identify: missing auth checks, privilege escalation paths, data validation gaps, insecure defaults. Report as an architecture assessment with diagram-friendly descriptions."
})
```

**All three agents MUST be launched in a single message (parallel execution).**

### Step 3: Unified Security Report

After all agents complete, produce a consolidated report:

```markdown
## Security Team Report

### Scope
[what was assessed]

### CRITICAL Vulnerabilities
[from all agents, deduplicated, with exploit scenario]

### HIGH Vulnerabilities
[merged findings]

### MEDIUM Vulnerabilities
[merged findings]

### LOW / Informational
[merged findings]

### Dependency Health
- Vulnerabilities found: N (X critical, Y high)
- Outdated packages: N
- Action required: [list packages to update]

### Architecture Assessment
- Auth flow: [OK / CONCERNS]
- Data flow: [OK / CONCERNS]
- Trust boundaries: [OK / CONCERNS]
- Attack surface: [OK / CONCERNS]

### Summary
- Total findings: N
- Must fix before deploy: N (all CRITICAL + HIGH)
- **Security Verdict:** PASS / FAIL (N blocking issues)
```

### Step 4: Remediation Plan

If CRITICAL or HIGH findings exist:
1. List fixes in priority order (highest risk first)
2. Estimate blast radius of each fix
3. Offer: "Shall I fix the N critical/high security issues now?"

For dependency issues, suggest specific version bumps with commands.

---
name: security-scan
description: >
  Security scan for Claude Code projects (secrets, MCP permissions, hook safety, dependencies).
  Use when: "security scan", "check security", "is this secure", "scan for secrets", "security audit", "before deploy security".
---

<!-- AI-QUICK-REF
## /security-scan — Quick Reference
- **5 Phases:** Secrets, MCP Audit, Hook Safety, Dependencies, Config Review
- **Severity:** CRITICAL, HIGH, MEDIUM, LOW, INFO
- **Grade:** A-F (A = no findings, F = critical issues)
- **State:** .security-scan-state.json in project root
- **Read-only:** Analyzes only, never modifies code
- **Invocation:** `/security-scan` or `/security-scan [phase]`
-->

# Security Scan

Read-only security analysis for Claude Code projects.
Inspired by AgentShield — adapted for Claude Hangar's cross-platform approach.

---

## Modes

| Mode | Invocation | What happens |
|------|-----------|--------------|
| `full` | `/security-scan` | Run all 5 phases |
| `secrets` | `/security-scan secrets` | Phase 1 only |
| `mcp` | `/security-scan mcp` | Phase 2 only |
| `hooks` | `/security-scan hooks` | Phase 3 only |
| `deps` | `/security-scan deps` | Phase 4 only |
| `config` | `/security-scan config` | Phase 5 only |

---

## Phase 1: Secret Detection

Scan source files for hardcoded secrets.

**Checks:**

| ID | Check | Severity | Method |
|----|-------|----------|--------|
| SEC-01 | API keys in source code | CRITICAL | Grep for `sk-`, `AKIA`, `ghp_`, `gho_`, `ghs_`, `sk-ant-`, `xox[bprs]-`, `sk-proj-` patterns |
| SEC-02 | Passwords in source code | CRITICAL | Grep for `password\s*[:=]\s*['"][^'"]{8,}` patterns |
| SEC-03 | Private keys in repo | CRITICAL | Grep for `-----BEGIN.*PRIVATE KEY-----` |
| SEC-04 | Database URLs with credentials | HIGH | Grep for `(postgres\|mysql\|mongodb)://[^:]+:[^@]+@` |
| SEC-05 | .env file committed to git | HIGH | `git ls-files '*.env'` (exclude .env.example) |
| SEC-06 | .gitignore missing sensitive patterns | MEDIUM | Check .gitignore for `.env`, `*.pem`, `*.key`, `node_modules` |
| SEC-07 | Hardcoded localhost/dev URLs | LOW | Grep for `localhost`, `127.0.0.1` in non-config files |

**Process:**
1. Run each check via Grep tool on project source files
2. Exclude: `node_modules/`, `.git/`, `*.lock`, `*.min.js`, `*.map`
3. Record findings with file path and line number
4. Flag CRITICAL findings immediately

---

## Phase 2: MCP Server Audit

Analyze MCP server configurations for security risks.

**Checks:**

| ID | Check | Severity | Method |
|----|-------|----------|--------|
| MCP-01 | Servers with filesystem access | HIGH | Check MCP args for path access patterns |
| MCP-02 | Servers with network access | MEDIUM | Check for HTTP/fetch/request capabilities |
| MCP-03 | Servers running with elevated permissions | HIGH | Check for sudo, root, admin in configs |
| MCP-04 | Unknown/unverified MCP servers | MEDIUM | Cross-reference against known-safe list |
| MCP-05 | MCP server count > 10 | LOW | High count increases attack surface and token usage |

**Process:**
1. Read `.claude/settings.json` (project-level) and `~/.claude/settings.json` (global)
2. Extract all `mcpServers` entries
3. Analyze each server's `command`, `args`, and `env` fields
4. Known-safe servers: `context7`, `sequential-thinking`, `playwright`, `github`
5. Flag anything not on the known-safe list as MEDIUM

---

## Phase 3: Hook Safety

Analyze hook scripts for injection risks and data exfiltration.

**Checks:**

| ID | Check | Severity | Method |
|----|-------|----------|--------|
| HOOK-01 | eval/exec with unquoted variables | CRITICAL | Grep for `eval "$`, `eval $`, `exec $` in hook scripts |
| HOOK-02 | curl/wget to external URLs | HIGH | Grep for `curl`, `wget`, `fetch` with non-localhost URLs |
| HOOK-03 | Base64 encoded content | HIGH | Grep for `base64`, `btoa`, `atob` in hooks |
| HOOK-04 | Environment variable exfiltration | HIGH | Grep for `env` piped to external commands |
| HOOK-05 | Unquoted variable expansion | MEDIUM | Grep for `$VAR` without quotes in command context |
| HOOK-06 | Write to locations outside project | MEDIUM | Check for writes to `/tmp`, system dirs, or home dir |

**Process:**
1. Read all `.sh` files in `.claude/hooks/` (or project `.claude/hooks/`)
2. Read `settings.json` for hook configurations
3. Check each hook script against patterns
4. Verify hooks match expected patterns from Claude Hangar

---

## Phase 4: Dependency Audit

Check project dependencies for known vulnerabilities.

**Checks:**

| ID | Check | Severity | Method |
|----|-------|----------|--------|
| DEP-01 | npm audit findings | Varies | Run `npm audit --json 2>/dev/null` if package-lock.json exists |
| DEP-02 | Outdated major versions | LOW | Run `npm outdated --json 2>/dev/null` |
| DEP-03 | No lockfile present | MEDIUM | Check for package-lock.json or pnpm-lock.yaml |
| DEP-04 | Dev dependencies in production | LOW | Check if devDependencies are used in src/ |

**Process:**
1. Check if `package.json` exists
2. Run `npm audit --json` and parse results
3. Map npm severity to our severity levels
4. Report total count by severity

---

## Phase 5: Configuration Review

Check Claude Code configuration for security anti-patterns.

**Checks:**

| ID | Check | Severity | Method |
|----|-------|----------|--------|
| CFG-01 | CLAUDE.md disables security checks | HIGH | Grep for `skip`, `bypass`, `disable`, `--no-verify` |
| CFG-02 | Hooks configured to auto-approve | HIGH | Check settings.json for `autoApprove` patterns |
| CFG-03 | Debug/dev settings in production | MEDIUM | Check for `DEBUG=`, `NODE_ENV=development` in configs |
| CFG-04 | Overly permissive file permissions | MEDIUM | Check for `chmod 777` or world-readable configs |
| CFG-05 | Memory files contain sensitive data | HIGH | Run memory hygiene check (same as session-start hook) |

**Process:**
1. Read CLAUDE.md and check for security anti-patterns
2. Read settings.json and check hook configurations
3. Check for debug/development settings
4. Cross-reference with memory hygiene patterns

---

## Grading System

| Grade | Criteria |
|-------|----------|
| **A** | No findings |
| **B** | Only LOW and INFO findings |
| **C** | MEDIUM findings, no HIGH or CRITICAL |
| **D** | HIGH findings, no CRITICAL |
| **F** | Any CRITICAL finding |

---

## Output Format

```markdown
# Security Scan Report — [Project Name]

**Grade: [A-F]**
**Date:** YYYY-MM-DD
**Findings:** X total (C critical, H high, M medium, L low)

## Phase 1: Secret Detection
- [CRITICAL] SEC-01: API key found in src/config.ts:42
- [OK] SEC-02: No hardcoded passwords

## Phase 2: MCP Server Audit
- [MEDIUM] MCP-04: Unknown MCP server "custom-tool"
- [OK] MCP-01-03: Standard configuration

...

## Recommendations
1. [CRITICAL] Remove API key from src/config.ts — use environment variable
2. [HIGH] Add .env to .gitignore
3. [MEDIUM] Review custom MCP server permissions
```

---

## State Management

`.security-scan-state.json` in project root:

```json
{
  "version": "1.0",
  "lastScan": {
    "date": "2026-04-04",
    "grade": "C",
    "findings": {
      "critical": 0,
      "high": 1,
      "medium": 3,
      "low": 2,
      "info": 1
    }
  },
  "phases": {
    "secrets": { "status": "pass", "findings": 0 },
    "mcp": { "status": "warn", "findings": 2 },
    "hooks": { "status": "pass", "findings": 0 },
    "deps": { "status": "warn", "findings": 3 },
    "config": { "status": "warn", "findings": 1 }
  }
}
```

---

## Smart Next Steps

| Condition | Recommendation |
|-----------|---------------|
| CRITICAL findings | Fix immediately before any deployment |
| HIGH findings | Fix before merging to main |
| Grade D or F | Run `/security-scan` again after fixes |
| Clean scan | Run `/deploy-check` for deployment readiness |
| Dependency issues | Run `/freshness-check` for version updates |

---

## Rules

1. **Read-only** — This skill never modifies files. It only analyzes and reports.
2. **No false sense of security** — This is a baseline check, not a comprehensive penetration test.
3. **Cross-platform** — Use `node -e` for JSON parsing (not jq). Use Grep tool (not grep command).
4. **Privacy** — Never log or display actual secret values. Show only pattern match and location.
5. **Idempotent** — Running multiple times produces the same results for the same project state.

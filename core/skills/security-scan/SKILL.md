---
name: security-scan
description: >
  Security scan for Claude Code projects (secrets, MCP permissions, hook safety, dependencies).
  Use when: "security scan", "check security", "is this secure", "before deploy security", "scan for secrets".
user-invocable: true
argument-hint: "mcp|hooks|full"
---

<!-- AI-QUICK-REF
## /security-scan — Quick Reference
- **Modes:** scan (all) | secrets | mcp | hooks | deps | config
- **Arguments:** `/security-scan $0` e.g. `/security-scan`, `/security-scan mcp`
- **5 Phases:** Secret Detection, MCP Audit, Hook Safety, Dependency Audit, Config Review
- **Finding-IDs:** SEC-S-01 (secrets), SEC-M-01 (MCP), SEC-H-01 (hooks), SEC-D-01 (deps), SEC-C-01 (config)
- **Severity:** CRITICAL > HIGH > MEDIUM > LOW > INFO
- **Grade:** A-F based on weighted findings
- **State:** .security-scan-state.json
- **Read-only:** Never modifies project files
-->

# /security-scan — Security Scan

Security scanner for Claude Code projects. Checks for hardcoded secrets,
MCP server permissions, hook safety, dependency vulnerabilities, and
configuration anti-patterns. Read-only — analyzes but never modifies.

## Problem

Claude Code projects have a unique attack surface: MCP servers with broad
permissions, hook scripts that execute automatically, and configuration
files that can disable safety checks. Standard security scanners miss
these Claude Code-specific vectors entirely.

---

## Modes

| Mode | Trigger | Scope |
|------|---------|-------|
| `scan` | `/security-scan` (default) | All 5 phases |
| `secrets` | `/security-scan secrets` | Phase 1 only |
| `mcp` | `/security-scan mcp` | Phase 2 only |
| `hooks` | `/security-scan hooks` | Phase 3 only |
| `deps` | `/security-scan deps` | Phase 4 only |
| `config` | `/security-scan config` | Phase 5 only |

---

## Phase 1: Secret Detection

Scan for hardcoded secrets in source files, configs, and environment handling.

### 1.1 Hardcoded Secret Patterns

Search all tracked files (respect `.gitignore`) for these pattern categories.

> **NOTE:** Use the same detection patterns defined in the project's
> `secret-leak-check.sh` hook as a baseline. The hook file is the
> canonical source of secret patterns — do not duplicate regexes here.
> Instead, reference the hook and add these additional categories:

| Category | What to detect | Severity |
|----------|---------------|----------|
| Cloud provider access keys | AWS key ID prefixes, cloud secret key assignments | CRITICAL |
| Generic API keys | Variables named api_key/apikey assigned string values 20+ chars | HIGH |
| Generic secrets | Variables named secret/passwd assigned non-placeholder values 8+ chars | HIGH |
| Private keys | PEM-format private key headers (RSA, EC, DSA, OPENSSH) | CRITICAL |
| Platform tokens | GitHub `ghp_`/`gho_`/`ghs_`/`ghr_` prefixed tokens, Slack `xox*` prefixed tokens | CRITICAL/HIGH |
| JWTs | Base64url-encoded three-segment `eyJ...` strings | MEDIUM |
| Connection strings | Database URIs with embedded credentials (user:pass@host format) | CRITICAL |
| Bearer tokens | Literal bearer token values in code | HIGH |

**Exclusions:** Skip `node_modules/`, `.git/`, `dist/`, `build/`, lock files, and binary files.
Skip patterns inside comments that are clearly examples (e.g. `YOUR_KEY_HERE`, `xxx`, `changeme`).

Finding: `SEC-S-{NN}: Hardcoded {type} found in {file}:{line}`

### 1.2 Environment File Safety

| Check | Pass | Fail |
|-------|------|------|
| `.env` in `.gitignore` | `.gitignore` contains `.env` pattern | Missing — CRITICAL |
| `.env` not committed | `git ls-files .env` returns empty | `.env` is tracked — CRITICAL |
| `.env.example` exists | File present with placeholder values | Missing — LOW |
| `.env.local` in `.gitignore` | Pattern present | Missing — MEDIUM |

Finding: `SEC-S-{NN}: {description}`

### 1.3 Gitignore Completeness

Check `.gitignore` for these security-relevant patterns:

| Pattern | Purpose | Severity if missing |
|---------|---------|---------------------|
| `.env` | Environment variables | CRITICAL |
| `*.pem` / `*.key` | Private keys | HIGH |
| `.claude/credentials*` | Claude credentials | HIGH |
| `*.sqlite` / `*.db` | Local databases | MEDIUM |
| `.security-scan-state.json` | Scan state | INFO |

Finding: `SEC-S-{NN}: .gitignore missing pattern for {pattern}`

---

## Phase 2: MCP Server Audit

Analyze MCP server configurations for permission and trust issues.

### 2.1 Locate MCP Config

Read MCP server configs from these locations (in priority order):

1. `.claude/settings.json` (project-level)
2. `~/.claude/settings.json` (user-level)

Parse with `node -e` (cross-platform). Extract `mcpServers` object.

### 2.2 Permission Analysis

For each MCP server, check:

| Check | Condition | Severity |
|-------|-----------|----------|
| File system access | Server has `filesystem` or `fs` capabilities | HIGH |
| Network access | Server has `fetch`, `http`, or network capabilities | HIGH |
| Shell execution | Server can run `bash`, `exec`, or `command` | CRITICAL |
| Broad permissions | Server has `*` or `all` in permission list | CRITICAL |
| Write permissions | Server has write access to project files | MEDIUM |

Finding: `SEC-M-{NN}: MCP server "{name}" has {permission} — {risk description}`

### 2.3 Trust Assessment

| Check | Condition | Severity |
|-------|-----------|----------|
| Unknown source | Server not from npm/official registry, no GitHub link | HIGH |
| No version pinning | Server uses `latest` or unpinned version | MEDIUM |
| Local file server | Server points to local script (check script exists and content) | MEDIUM |
| Excessive server count | More than 10 MCP servers configured | LOW |

Finding: `SEC-M-{NN}: {description}`

### 2.4 Known Safe Servers

Maintain a list of recognized MCP servers (do not flag these as unknown):

- `@anthropic-ai/*` — Official Anthropic servers
- `@modelcontextprotocol/*` — Official MCP servers
- `playwright` — Browser automation
- `github` — GitHub integration
- `context7` — Documentation lookup

Servers not on this list get an INFO finding, not automatic HIGH.

---

## Phase 3: Hook Safety

Analyze hook scripts for dangerous patterns that could indicate
supply-chain attacks or accidental security holes.

### 3.1 Locate Hooks

Search for hook definitions in:

1. `.claude/settings.json` > `hooks` object
2. `.claude/hooks/` directory (all `.sh`, `.js`, `.mjs` files)

### 3.2 Dangerous Patterns

Scan each hook script/command for:

| Pattern | What to look for | Severity | Rationale |
|---------|-----------------|----------|-----------|
| eval usage | The `eval` keyword in shell/JS | HIGH | Arbitrary code execution |
| exec with variable | `exec` followed by unresolved variable | HIGH | Command injection |
| Unquoted variables | Shell variables expanded without quotes | MEDIUM | Word splitting, globbing |
| curl to external host | `curl` targeting non-localhost URLs | HIGH | Data exfiltration |
| wget to external host | `wget` targeting non-localhost URLs | HIGH | Data exfiltration |
| Base64 decode piped to shell | Decoded base64 piped into bash/sh/node | CRITICAL | Obfuscated payload |
| Network send with data | curl/wget with POST data flags | CRITICAL | Data exfiltration |
| Environment dumping | Commands that dump all env vars to file | HIGH | Credential leak |
| Write to system dirs | Writes to `/usr/bin/`, `/usr/sbin/`, etc. | HIGH | System modification |
| Download and execute | curl/wget piped directly into shell | CRITICAL | Remote code execution |

Finding: `SEC-H-{NN}: Hook "{name}" contains {pattern} — {risk}`

### 3.3 Hook Structure Checks

| Check | Pass | Fail |
|-------|------|------|
| Uses `node -e` for JSON parsing | Correct pattern | Uses `jq` or custom parsing — INFO |
| Hook has clear purpose | Descriptive name/comment | Unnamed or obfuscated — LOW |
| Hook modifies files | Acceptable if documented | Undocumented modification — MEDIUM |
| Hook runs external commands | Acceptable if local | Calls external services — HIGH |

Finding: `SEC-H-{NN}: {description}`

---

## Phase 4: Dependency Audit

Check project dependencies for known vulnerabilities and risk signals.

### 4.1 npm Audit (if applicable)

If `package.json` exists:

```bash
npm audit --json 2>/dev/null | node -e "
  const data = JSON.parse(require('fs').readFileSync(0,'utf8'));
  const meta = data.metadata || {};
  const vulns = meta.vulnerabilities || {};
  console.log(JSON.stringify({
    total: meta.totalDependencies || 0,
    critical: vulns.critical || 0,
    high: vulns.high || 0,
    moderate: vulns.moderate || 0,
    low: vulns.low || 0
  }));
"
```

Map results to findings:

| npm severity | Scan severity | Finding |
|-------------|---------------|---------|
| critical | CRITICAL | `SEC-D-{NN}: {count} critical vulnerabilities in dependencies` |
| high | HIGH | `SEC-D-{NN}: {count} high vulnerabilities in dependencies` |
| moderate | MEDIUM | `SEC-D-{NN}: {count} moderate vulnerabilities in dependencies` |
| low | LOW | `SEC-D-{NN}: {count} low vulnerabilities in dependencies` |

If `npm audit` is unavailable or fails, note it as INFO and continue.

### 4.2 Dependency Risk Signals

Check `package.json` for:

| Check | Condition | Severity |
|-------|-----------|----------|
| No lock file | Neither `package-lock.json` nor `yarn.lock` nor `pnpm-lock.yaml` | HIGH |
| Wildcard versions | `"*"` or `""` in dependency versions | HIGH |
| Git dependencies | `"dep": "git+..."` or `"dep": "github:..."` | MEDIUM |
| File dependencies | `"dep": "file:..."` | MEDIUM |
| Excessive dependencies | >100 direct dependencies in a single package.json | LOW |
| No dev/prod separation | All deps in `dependencies`, none in `devDependencies` | LOW |

Finding: `SEC-D-{NN}: {description}`

### 4.3 Python Audit (if applicable)

If `requirements.txt` or `pyproject.toml` exists:
- Check for pinned versions (== vs >=)
- Flag unpinned dependencies as MEDIUM
- If `pip-audit` is available, run it

### 4.4 Outdated Major Versions

If `package.json` exists, check for major version staleness:

```bash
npm outdated --json 2>/dev/null | node -e "
  const data = JSON.parse(require('fs').readFileSync(0,'utf8'));
  Object.entries(data).forEach(([pkg, info]) => {
    const curr = (info.current || '').split('.')[0];
    const latest = (info.latest || '').split('.')[0];
    if (curr && latest && curr !== latest) {
      console.log(pkg + ': ' + info.current + ' -> ' + info.latest);
    }
  });
"
```

Finding: `SEC-D-{NN}: {package} is {N} major versions behind ({current} -> {latest})` — LOW

---

## Phase 5: Configuration Review

Check Claude Code and project configuration for security anti-patterns.

### 5.1 CLAUDE.md Security Review

Read project `CLAUDE.md` (if present) and flag:

| Pattern | What to look for | Severity |
|---------|-----------------|----------|
| Disabled checks | Instructions to skip/disable/ignore/bypass security, auth, or validation | HIGH |
| Force push instructions | Mentions of force push, `--force`, or `--no-verify` | MEDIUM |
| Hardcoded credentials | Same categories as Phase 1 | CRITICAL |
| Overly permissive instructions | "always approve", "auto-approve", "no review needed" | HIGH |
| Debug mode | Debug or development mode enabled in non-dev context | MEDIUM |

Finding: `SEC-C-{NN}: CLAUDE.md contains {pattern} — {risk}`

### 5.2 Settings Security

Check `.claude/settings.json` for:

| Check | Condition | Severity |
|-------|-----------|----------|
| Allow-all permissions | Permissions set to `*` or `allow_all` | HIGH |
| Disabled safety features | Any safety/guard feature explicitly disabled | CRITICAL |
| Unrestricted file access | No file path restrictions configured | MEDIUM |

Finding: `SEC-C-{NN}: {description}`

### 5.3 Production Config Leaks

Check for development/debug settings that should not be in production:

| Check | File(s) | Condition | Severity |
|-------|---------|-----------|----------|
| Debug mode in prod config | `docker-compose.yml`, `Dockerfile` | `NODE_ENV=development` or `DEBUG=*` | HIGH |
| Source maps in production | Build config | `sourcemap: true` in prod build | MEDIUM |
| Verbose logging | App config | `LOG_LEVEL=debug` in prod | LOW |
| Dev dependencies in prod | `Dockerfile` | `npm install` without `--production` or `--omit=dev` | MEDIUM |

Finding: `SEC-C-{NN}: {description}`

---

## Grading System

After all phases complete, calculate a letter grade based on weighted findings.

### Point Deductions

| Severity | Points per finding |
|----------|-------------------|
| CRITICAL | -20 |
| HIGH | -10 |
| MEDIUM | -3 |
| LOW | -1 |
| INFO | 0 |

### Grade Thresholds

Start at 100 points, subtract per finding:

| Score | Grade | Assessment |
|-------|-------|------------|
| 95-100 | A | Excellent — minimal risk |
| 85-94 | A- | Strong — minor improvements possible |
| 75-84 | B | Good — some issues to address |
| 65-74 | B- | Acceptable — notable gaps |
| 55-64 | C | Fair — significant issues |
| 40-54 | C- | Weak — multiple serious issues |
| 25-39 | D | Poor — immediate action needed |
| 0-24 | F | Failing — critical vulnerabilities present |

### Grade Caps

Regardless of total score, the grade is capped if:

| Condition | Max grade |
|-----------|-----------|
| Any CRITICAL finding open | D |
| 3+ HIGH findings open | C |
| No .gitignore for .env | D |
| Secrets committed to git | F |

---

## Output Format

```
Security Scan: {project-name}
====================================

Grade: {letter} ({score}/100)

Phase 1: Secret Detection
  {OK | FINDINGS}
  - SEC-S-01 [CRITICAL] Hardcoded credential in src/config.ts:42
  - SEC-S-02 [HIGH] .env not in .gitignore

Phase 2: MCP Server Audit
  {OK | FINDINGS}
  - SEC-M-01 [HIGH] MCP server "custom-fs" has unrestricted file system access

Phase 3: Hook Safety
  {OK | FINDINGS}

Phase 4: Dependency Audit
  {OK | FINDINGS}
  - SEC-D-01 [CRITICAL] 2 critical vulnerabilities (npm audit)
  - SEC-D-02 [LOW] express is 2 major versions behind (4.x -> 5.x)

Phase 5: Configuration Review
  {OK | FINDINGS}
  - SEC-C-01 [HIGH] CLAUDE.md contains "skip security checks"

------------------------------------
Summary: {total} findings
  CRITICAL: {n}  HIGH: {n}  MEDIUM: {n}  LOW: {n}  INFO: {n}

{grade_explanation}
```

---

## State File (.security-scan-state.json)

Written after every scan. Enables trend tracking across sessions.

```json
{
  "version": "1.0",
  "scanDate": "2026-04-04",
  "project": "my-project",
  "grade": "B",
  "score": 78,
  "phases": {
    "secrets": { "status": "done", "findings": 2 },
    "mcp": { "status": "done", "findings": 1 },
    "hooks": { "status": "done", "findings": 0 },
    "deps": { "status": "done", "findings": 3 },
    "config": { "status": "done", "findings": 1 }
  },
  "findings": [
    {
      "id": "SEC-S-01",
      "phase": "secrets",
      "severity": "CRITICAL",
      "title": "Hardcoded credential in src/config.ts:42",
      "file": "src/config.ts",
      "line": 42,
      "status": "open"
    }
  ],
  "history": [
    { "date": "2026-03-20", "grade": "C", "score": 58, "findings": 12 },
    { "date": "2026-04-04", "grade": "B", "score": 78, "findings": 7 }
  ]
}
```

---

## Smart Next Steps

After the scan completes, recommend follow-up actions based on findings:

| Condition | Recommendation |
|-----------|---------------|
| CRITICAL secrets found | Remove secrets immediately, rotate affected credentials, add to .gitignore |
| MCP permission issues | Review `.claude/settings.json`, restrict server permissions to minimum needed |
| Hook safety concerns | Review flagged hooks, replace dangerous patterns with safe alternatives |
| Dependency vulnerabilities | Run `npm audit fix`, update outdated packages, review breaking changes |
| Config anti-patterns | Update CLAUDE.md, remove debug settings from production configs |
| Grade D or F | Run `/security-scan` again after fixes to verify improvement |
| Grade A or B | Run `/deploy-check` to verify deployment readiness |
| Any findings | Run `/adversarial-review code` for deeper code-level security review |
| Auth detected | Run `/auth-audit` for authentication-specific security checks |
| Always | Add security scan to CI pipeline (pre-commit or PR check) |

---

## Rules

1. **Read-only** — Never modify project files, only analyze and report
2. **No false confidence** — If a check cannot be performed (tool missing, file inaccessible), report as INFO, do not skip silently
3. **Cross-platform** — Use `node -e` for JSON parsing, not `jq`. Avoid platform-specific commands
4. **Respect .gitignore** — Do not scan `node_modules/`, `.git/`, `dist/`, `build/`, or other excluded directories
5. **No network calls** — Do not send project data anywhere. All analysis is local
6. **Severity accuracy** — Do not inflate or deflate severity. Follow the definitions exactly
7. **Idempotent** — Running the scan twice produces the same result (unless project changed)
8. **Example detection** — Do not flag obvious placeholder values (`YOUR_KEY_HERE`, `changeme`, `xxx`) as real secrets
9. **Privacy** — Never log or display actual secret values. Show only pattern match and file location
10. **Anti-rationalization** — Do not skip checks or reduce severity because the project "seems fine". See `_shared/anti-rationalization.md`

---

## Files

```
security-scan/
├── SKILL.md      <- This file
└── skill.json    <- Skill metadata and triggers
```

---
name: doctor
description: >
  Project health check meta-skill. Runs git-hygiene, deploy-check, and freshness-check in sequence.
  Use when: "doctor", "health check", "project health", "is everything ok", "check project".
user_invocable: true
argument_hint: ""
---

<!-- AI-QUICK-REF
## /doctor — Quick Reference
- **Modes:** quick | full
- **Runs:** /git-hygiene scan → /deploy-check → /freshness-check check
- **Output:** Consolidated health report with severity ratings
- **Inspired by:** GSD v2 "doctor" command
-->

# /doctor — Project Health Check

Meta-skill that runs multiple health checks and produces a consolidated report. Single command to answer "is this project healthy?"

**Inspired by:** GSD v2 "doctor" — stale commit safety, project health diagnostics.

## What It Checks

| Area | Skill Used | What It Checks |
|------|-----------|---------------|
| Git | `/git-hygiene` | Stale branches, large files, commit conventions, uncommitted work |
| Deploy | `/deploy-check` | Docker, CI, env vars, SSL, DNS, monitoring |
| Freshness | `/freshness-check` | Dependencies, frameworks, security standards |
| Structure | (built-in) | Missing README, LICENSE, .gitignore, CLAUDE.md |
| Dependencies | (built-in) | `npm audit`, outdated packages, lock file |

## Modes

### `/doctor quick`

Fast check (~30 seconds). Runs:

1. **Git status:** Uncommitted changes? Stale branches? Last commit age?
2. **Dependencies:** `npm audit --audit-level=high` — any critical vulnerabilities?
3. **Structure:** Missing essential files (README, .gitignore, LICENSE)?
4. **Lock file:** Present and committed?

### `/doctor full`

Comprehensive check (~2-5 minutes). Runs everything in `quick` plus:

5. **Git hygiene:** Full `/git-hygiene` scan (large files, conventions, branch age)
6. **Deploy readiness:** Full `/deploy-check` (Docker, CI, env vars, SSL)
7. **Freshness:** `/freshness-check check` (dependency versions, standards)
8. **Outdated packages:** `npm outdated` or framework-specific check

## Output Format

```
PROJECT HEALTH — {project name}

  Git:          ✓ Clean (3 stale branches, 0 large files)
  Dependencies: ⚠ 2 high-severity vulnerabilities (npm audit)
  Structure:    ✓ All essential files present
  Deploy:       ✓ Docker + CI configured
  Freshness:    ⚠ 3 outdated dependencies

  Overall: GOOD (2 warnings, 0 critical)

  Recommended actions:
    1. npm audit fix (2 high vulnerabilities)
    2. Update astro 6.1.2 → 6.1.3
    3. Delete 3 stale branches (feature/old-*, hotfix/done)
```

## Health Ratings

| Rating | Criteria |
|--------|----------|
| HEALTHY | No warnings, no critical issues |
| GOOD | Warnings only, no critical issues |
| NEEDS ATTENTION | 1-2 critical issues |
| UNHEALTHY | 3+ critical issues or security vulnerabilities |

## Rules

- **Read-only in quick mode** — never modify anything
- **Full mode may suggest commands** — but does not auto-execute destructive operations
- **No false alarms** — only report issues that actually need attention
- **Fast feedback** — quick mode completes in under 30 seconds

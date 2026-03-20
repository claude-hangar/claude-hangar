# Skill Lifecycle

This document describes the complete lifecycle of a skill execution in Claude Hangar, from initial trigger through invocation, phase execution, state persistence, and follow-up recommendations.

## 1. Trigger

A skill can be triggered in two ways:

### Direct invocation
The user types a slash command:
```
/audit start
/adversarial-review code
/polish scan
```

### Automatic suggestion
When the user types a natural language prompt (e.g., "check this website"), the `skill-suggest` hook analyzes the prompt against `skill-rules.json` and suggests a matching skill:

```
User: "check this website for issues"
Hook: "Skill suggestion: /audit matches this request. Use the skill for better results."
```

The suggestion is non-blocking -- the user can follow it or ignore it. The hook uses word boundary matching to avoid false positives (e.g., "reviewed" does not trigger the `/adversarial-review` suggestion).

**Trigger rules in skill-rules.json:**
```json
{
  "skill": "/audit",
  "triggers": ["website audit", "site audit", "check website"],
  "exclude": ["project-audit", "repo audit"]
}
```

Each rule has `triggers` (phrases that activate it) and `exclude` (phrases that prevent activation to avoid conflicts between similar skills).

## 2. Invocation

When a skill is invoked, Claude Code loads the skill's `SKILL.md` file. This file contains:

- **Frontmatter** with name, description, and optionally effort level
- **AI-QUICK-REF** block for fast context loading (modes, arguments, key rules)
- **Full instructions** for each mode

### Arguments

Most skills accept a mode as the first argument:

```
/audit start       -- begin a new audit
/audit continue    -- resume from where you left off
/audit status      -- show current progress
/audit report      -- generate a markdown report
/audit auto        -- fully autonomous run
```

## 3. Modes

Skills use standardized modes defined in the audit blueprint:

| Mode | Purpose | Session Limit |
|------|---------|---------------|
| `start` | Detect stack, create state, run first 2 phases | 2 phases |
| `continue` | Run next phases or fix up to 5 findings | 2 phases or 5 fixes |
| `status` | Read-only progress display | None |
| `report` | Generate structured markdown report | None |
| `auto` | Fully autonomous run, all phases | No phase limit |
| `refresh` | Check for new framework releases | None |

Not every skill supports every mode. `report` is only available for `/audit` and `/project-audit`. `refresh` is only for stack-specific audits that track framework versions.

## 4. Phase Execution

Each phase follows a standardized execution flow:

### Step 1 -- Load check instructions
```
Base phase:        phases/02-security.md            (~50 lines, universal)
Stack supplement:  stacks/frontend/astro.md [Sec]    (~80 lines, framework-specific)
Project override:  audit-context.md [Security]       (~20 lines, project-specific)
```

Only the relevant section of each supplement is loaded. If a supplement does not have a section for the current phase, it is skipped without error.

### Step 2 -- Check for existing findings
Read previous audit documents to avoid creating duplicate findings.

### Step 3 -- Execute checks
Work through all loaded checks systematically:
- **Source layer:** Read and analyze code, configs, file structure
- **Live/Runtime layer:** Execute tools where applicable (curl, Lighthouse, npm audit)

### Step 4 -- Document findings
Each finding gets a unique ID, severity rating, description, and location:
```
SEC-03 [HIGH] -- Missing CSP Header
  Location: docker-compose.yml:traefik-labels
  Problem:  Content-Security-Policy header is completely missing
  Impact:   XSS attacks are not restricted by browser policy
  Fix:      Configure CSP header in Traefik labels or middleware
```

### Step 5 -- Count completeness
```
Phase 02-security -- Completeness:
  MUST: 12/12 (100%)
  SHOULD: 8/10 (80%)
  COULD: 3/5 (60%)
```

### Step 6 -- Update state
Write phase status, findings, completeness counts, and layer status to the state file.

### Step 7 -- Checkpoint
```
[CHECKPOINT: verify] -- Show findings + completeness to user, get confirmation.
```

## 5. Gates Between Phases

Before moving to the next phase, the skill checks gate conditions:

- **MUST completeness gate:** Phase cannot be marked `done` with <100% MUST checks
- **Context budget gate:** Maximum 2 phases per session (except `auto` mode)
- **Critical findings gate:** If CRITICAL findings are open, the skill recommends fixing them before continuing

In `auto` mode, the context budget gate is relaxed, but findings are collected without immediate fixing.

## 6. State Persistence

State is written immediately after each phase and each fix. This ensures:

- **Crash resilience:** If a session is interrupted, all completed work is preserved
- **Multi-session continuity:** The next `continue` invocation picks up exactly where the last session left off
- **Cross-skill awareness:** Other skills can read the state to avoid duplicate work

The state file follows schema v2.1 (see [State Management](state-management.md)).

## 7. Smart Recommendations

At the end of each `continue` session, the skill generates a smart recommendation:

```
IF open CRITICAL findings > 0:
  "Recommendation: Fix 2 CRITICAL findings first (SEC-01, INFRA-05)"
IF open HIGH findings > 3:
  "Recommendation: Fix 4 HIGH findings, then continue with phases"
ELSE IF phases still pending:
  "Recommendation: Next phases (03-performance, 04-seo)"
ELSE:
  "Recommendation: Fix remaining 7 findings (3 MEDIUM, 4 LOW)"
```

The recommendation is presented as the first option in an interactive question, with a brief justification. The user can follow it or choose a different action.

## 8. Report Generation

When all phases are complete (or the user requests it), the skill generates a structured markdown report:

```
AUDIT-REPORT-2026-03-15.md
  Executive Summary
  Findings by Phase
    Phase 02-security: 5 findings (1 CRITICAL, 2 HIGH, 2 MEDIUM)
    Phase 03-performance: 3 findings (...)
  Trend Analysis (if previous reports exist)
  Recommendations
  Next Steps
```

If previous reports exist, a diff section highlights what is new and what has been resolved.

## 9. Follow-Up Recommendations

After completing an audit, the skill recommends related skills based on findings and detected stack:

| Condition | Recommendation |
|-----------|---------------|
| Astro project detected | `/astro-audit` for version-specific checks |
| >3 HIGH/CRITICAL findings | `/adversarial-review audit` to verify report quality |
| Content/design findings | `/polish scan` for design improvements |
| Audit completed | `/lesson-learned session` to extract learnings |
| No `/project-audit` state | `/project-audit start` for code/CI quality |

These recommendations are printed at the end of the last phase and included in the report under the `{NEXT_STEPS}` placeholder.

## Lifecycle Summary

```
Trigger -> Load SKILL.md -> Execute phase -> Document findings -> Update state
  -> [CHECKPOINT] -> Budget remaining? -> [yes: next phase] [no: recommend + end]
  -> Report generation -> Follow-up skill suggestions
```

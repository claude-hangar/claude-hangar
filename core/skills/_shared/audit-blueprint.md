# Audit Blueprint — Shared Architecture for All Audit Skills

Central reference document for the 6 audit skills: `/audit`, `/project-audit`, `/astro-audit`, `/sveltekit-audit`, `/db-audit`, `/auth-audit`. Defines the shared structure, modes, severity, context protection, and session strategy.

**Purpose:** Serves as a template for refactoring and creating new audit skills. Individual SKILL.md files can reference this document via "Reference: _shared/audit-blueprint.md" instead of duplicating the same sections.

**Complementary to:** `_shared/audit-patterns.md` (Verification-Depth, Fix-Protocol, Check-Priorities, Completeness-Tracking, Skill-Synergy).

---

## 1. Standard Modes

All audit skills use 4-5 modes with identical behavior:

| Mode | Trigger | Description | All Skills |
|------|---------|-------------|------------|
| `start` | `/{skill} start` | Scan project, detect stack/context, create state, first 2 areas | Yes |
| `continue` | `/{skill} continue` | Continue next areas or fix max 5 findings | Yes |
| `status` | `/{skill} status` | Show progress, statistics, open findings | Yes |
| `auto` | `/{skill} auto` | Fully autonomous run without user prompts | Yes |
| `report` | `/{skill} report` | Generate structured Markdown report | audit, project-audit |
| `refresh` | `/{skill} refresh` | Check for new releases/versions | astro-audit, sveltekit-audit, db-audit |

### Mode: start — Standard Flow

1. **Auto-Detection:** Scan project, detect stack and versions
2. **Load context:** CLAUDE.md, existing docs, state files from other skills (priorContext)
3. **Show result table:** Stack, versions, detected configuration
4. **[CHECKPOINT: decision]** — User chooses scope (complete vs. focused)
5. **Create state file** (Schema v2.1)
6. **Execute first 2 areas/phases**

### Mode: continue — Standard Flow

1. Read state file
2. Identify next pending areas
3. Generate **smart recommendation** (see Section 7)
4. Show recommendation as **first option** in AskUserQuestion
5. User chooses: follow recommendation, different phase, or fix findings
6. Write state **immediately** after each phase/fix

### Mode: status — Standard Flow

1. Read state file
2. Display table:
   - Areas/phases with status (done/in-progress/pending)
   - Findings grouped by severity (open vs. fixed)
   - Completeness (MUST/SHOULD/COULD percentages)
   - Layer status (Source/Live or Source/Runtime)
3. Next recommended action

### Mode: auto — Standard Flow

1. **Check orchestrator context** (if `.audit-orchestrator-state.json` exists):
   - Skip delegated phases
   - Read `sequencingReason`
2. Auto-detection as in `start`
3. **Run all areas/phases** (no 2-phase limit)
4. Document findings (but **do not fix immediately** — collect only)
5. Write state **immediately after each phase**
6. **Context management:** When context is running low:
   - Write state immediately
   - Create task in `.tasks.json` with handoff note
   - Recommend: "New session with `/{skill} continue`"
7. At the end: automatically generate report (if report mode is available)

### Mode: report — Standard Flow (audit, project-audit)

1. Read state file
2. Group findings by phase/area
3. Report with Executive Summary, Findings, Recommendations
4. **Include trend analysis** (if history is available)
5. Save report as `{PREFIX}-REPORT-{YYYY-MM-DD}.md`
6. Diff section if previous reports exist

### Mode: refresh — Standard Flow (astro-audit, sveltekit-audit, db-audit)

1. Check latest version (`npm view`)
2. Compare with state (last checked vs. current)
3. Show delta (breaking changes, new features)
4. Inform user + recommendation (review/migration)

---

## 2. Severity Scale

Uniform across all 6 audit skills:

| Level | Criteria | Examples |
|-------|----------|----------|
| **CRITICAL** | Security vulnerability, data loss, outage, exposed secrets | SQL Injection, open ports, secrets in repo, missing auth |
| **HIGH** | Functional bug, performance >2s, missing validation, CVEs | LCP >4s, no rate limiting, XSS, broken CI/CD |
| **MEDIUM** | Code quality, missing tests, UX issue, missing docs | Missing alt texts, no error handling, inconsistent naming |
| **LOW** | Cosmetic, best practice, nice-to-have | Outdated but secure deps, missing comments, missing docs |

**Prioritization:** CRITICAL > HIGH > MEDIUM > LOW. Security before functional before cosmetic.

### Severity-Specific Actions

| Severity | Action During Audit |
|----------|-------------------|
| CRITICAL | Immediate recommendation to fix, before further phases |
| HIGH | Recommend as next after phase completion |
| MEDIUM | Document in report, fix when convenient |
| LOW | Document, no pressure to fix |

---

## 3. Context Protection (CRITICAL)

Applies identically to all audit skills:

### Base Rules

- **Max 2 phases/areas OR 5 fixes per session** — never both (except `auto` mode)
- **Write state immediately** after each phase and each fix
- **No auto-fix** — document findings, user decides (except `auto` mode)
- **Always read existing docs first** — no duplicates from previous audits
- **On interruption:** State is always current, next session can resume seamlessly

### Completeness Requirement

- MUST-checks count; a phase with <100% MUST cannot be marked `done`
- Skipped MUST-checks must be documented with reason in `checksSkipped[]`

### Layer Tracking

- Document both layer statuses (Source + Live/Runtime) per phase
- Layer status values: `"done"`, `"pending"`, `"in-progress"`, `"not-applicable"`

### Auto Mode Context Protection

- Findings are collected but **not fixed immediately** (documented only)
- Per phase: If >10 findings, close phase and start next
- Write state **immediately after each phase**
- At context limit: clean abort with complete state
- Fixes in follow-up sessions with `/{skill} continue`

---

## 4. Session Strategy

### Checkpoints

Two checkpoint types used by all skills:

| Checkpoint | When | Purpose |
|------------|------|---------|
| `[CHECKPOINT: decision]` | At audit start, scope selection | User confirms scope/configuration |
| `[CHECKPOINT: verify]` | After each phase, after each fix | User confirms results |

### Multi-Session Strategy

1. **Session 1:** `/{skill} start` — Detection + first 2 areas
2. **Session 2+:** `/{skill} continue` — Next areas or fixes
3. **Completion:** `/{skill} report` or final fixes
4. **Anytime:** `/{skill} status`

### /compact Recommendation

When context is running low in auto mode:
1. Write state immediately (all results so far are persistent)
2. Create task in `.tasks.json` with handoff note
3. Recommend to user: "New session with `/{skill} continue`"

### Fixing Findings (within continue mode)

- Always fix highest severity first: CRITICAL > HIGH > MEDIUM > LOW
- Per fix: Show problem > Load fix template (if available) > User confirmation > Implement > Test
- Fix status in state: `"status": "fixed"`, `"fixedIn": "Session N"`
- **No auto-fix** — every fix requires user confirmation (except `auto` mode)
- **[CHECKPOINT: verify]** after each fix

---

## 5. State Schema v2.1

Standard format for all audit skills. Filename: `.{skill-name}-state.json`

### Common Fields

```json
{
  "version": "2.1",
  "skill": "{skill-name}",
  "project": "{project-name}",
  "startedAt": "YYYY-MM-DD",
  "lastUpdated": "YYYY-MM-DDTHH:MM:SSZ",
  "session": 1,
  "stack": {},
  "phaseOrder": "sequential|smart",
  "phases": [
    {
      "id": "NN-name",
      "status": "done|in-progress|pending",
      "session": 1,
      "sourceLayer": "done|pending|in-progress|not-applicable",
      "liveLayer": "done|pending|in-progress|not-applicable",
      "completeness": {
        "must": { "done": 0, "total": 0 },
        "should": { "done": 0, "total": 0 },
        "could": { "done": 0, "total": 0 }
      },
      "checksSkipped": []
    }
  ],
  "findings": [
    {
      "id": "PREFIX-NN",
      "phase": "NN-name",
      "severity": "CRITICAL|HIGH|MEDIUM|LOW",
      "title": "",
      "description": "",
      "location": "",
      "status": "open|fixed|wontfix|duplicate",
      "fixedIn": null
    }
  ]
}
```

### State Files Per Skill

| Skill | State File |
|-------|------------|
| `/audit` | `.audit-state.json` |
| `/project-audit` | `.project-audit-state.json` |
| `/astro-audit` | `.astro-audit-state.json` |
| `/sveltekit-audit` | `.sveltekit-audit-state.json` |
| `/db-audit` | `.db-audit-state.json` |
| `/auth-audit` | `.auth-audit-state.json` |

### Layer Status Migration

Old boolean values (`true`/`false`) are automatically migrated: `true` > `"done"`, `false` > `"pending"`.

### Layer Types Per Skill

| Skill | Layer 1 | Layer 2 |
|-------|---------|---------|
| `/audit` | `source` (Code/Config) | `live` (curl, Lighthouse, Playwright) |
| `/project-audit` | `source` (Code/Config) | `runtime` (npm audit, tsc, docker scout) |
| `/astro-audit` | `source` (Code/Config) | `runtime` (npm view, Build-Test) |
| `/sveltekit-audit` | `source` (Code/Config) | `runtime` (npm view, Build-Test, svelte-check) |
| `/auth-audit` | `source` (Code/Config) | `runtime` (Login-Tests, Cookie-Check) |
| `/db-audit` | `source` (Code/Config) | `runtime` (psql, Drizzle-Kit, Docker) |

---

## 6. Finding Format

Standard output for all findings across all audit skills:

### During the Audit (Console Output)

```
{ID} [{SEVERITY}] — {Title}
  Location: {file}:{line} (or {description})
  Problem:  {what is wrong}
  Impact:   {why it matters}
  Fix:      {recommended solution} (or > Fix-Template)
```

### In State (JSON)

```json
{
  "id": "SEC-03",
  "phase": "02-security",
  "severity": "HIGH",
  "title": "Missing CSP Header",
  "description": "Content-Security-Policy header is completely missing",
  "location": "docker-compose.yml:traefik-labels",
  "status": "open",
  "fixedIn": null
}
```

### In Report (Markdown)

```markdown
### SEC-03 [HIGH] — Missing CSP Header

**Location:** `docker-compose.yml:traefik-labels`
**Problem:** Content-Security-Policy header is completely missing.
**Impact:** XSS attacks are not restricted by browser policy.
**Recommendation:** Configure CSP header in Traefik labels or middleware.
**Status:** Open
```

### Finding-ID Convention

- Format: `{PREFIX}-{NN}` (two digits, ascending)
- Prefix is phase/area-specific (defined in each SKILL.md)
- IDs are stable — never renamed or reassigned
- Complete prefix registry: see `_shared/audit-patterns.md` (Finding-Prefix-Registry)

---

## 7. Smart Next Steps — Recommendation Logic

### Within the Audit (continue mode)

Analyze state before asking user:

```
IF open CRITICAL findings > 0:
  > "Recommendation: Fix {N} CRITICAL findings first ({IDs})"
IF open HIGH findings > 3:
  > "Recommendation: Fix {N} HIGH findings, then continue with phases"
ELSE IF phases/areas open:
  > "Recommendation: Next phases ({phase/area names})"
ELSE:
  > "Recommendation: Fix remaining findings ({N} open)"
```

Show recommendation as **first option** in AskUserQuestion, with brief justification.

### After Audit Completion (Follow-Up Skills)

Each audit skill recommends suitable follow-up skills based on findings and stack:

| Condition | Recommendation |
|-----------|---------------|
| >3 HIGH/CRITICAL findings | `/adversarial-review audit` |
| Audit completed | `/lesson-learned session` |
| Astro project detected | `/astro-audit` |
| SvelteKit project detected | `/sveltekit-audit` |
| PostgreSQL/Drizzle detected | `/db-audit` |
| Custom auth detected | `/auth-audit` |
| Design/content findings | `/polish scan` |
| No other audit has run | Recommend complementary audit |

**Output:** 2-3 most relevant recommendations at the end of the last phase or in the report (`{NEXT_STEPS}` placeholder).

### Skill Synergy (priorContext)

Each audit skill reads optional state files from other skills at start:

| Skill | Reads State From | Benefit |
|-------|-----------------|---------|
| `/audit auto` | `.audit-orchestrator-state.json` | Skip delegated phases |
| `/project-audit auto` | `.audit-orchestrator-state.json` | Skip delegated phases |
| `/lesson-learned` | All audit states | Extract fixing patterns |
| `/polish` | `.audit-state.json` | Severity-based prioritization |
| `/adversarial-review` | `.audit-state.json`, `.project-audit-state.json` | Write back gap findings |

Complete state-contract table: see `_shared/audit-patterns.md`.

---

## 8. Phase Execution (Template)

Standard flow for each individual phase/area:

1. **Load base:** Read phase file (universal check items)
2. **Load supplements:** Stack-specific additions (only relevant section)
3. **Project override:** Include context file (if available)
4. **Existing findings:** Check previous audit docs, no duplicates
5. **Source layer:** Systematically execute code/config-based checks
6. **Live/Runtime layer:** Execute tool-based checks (where applicable)
7. **Document findings:** ID, severity, description, location
8. **Count completeness:** MUST/SHOULD/COULD (executed vs. skipped)
   - Skipped MUST-checks: document reason
   - Phase with <100% MUST: status remains `in-progress`
9. **Update state:** Phase status, findings, completeness, layer status
10. **[CHECKPOINT: verify]** — Show findings + completeness to user

---

## Usage

This document serves as a reference. A new audit skill can reference it:

```markdown
## Modes, Severity, Context Protection, Session Strategy

> See `_shared/audit-blueprint.md` (Standard Modes, Severity Scale, Context Protection, Session Strategy).

Skill-specific deviations:
- ...
```

In future refactoring, the redundant sections in the 6 SKILL.md files can be replaced by references to this document. This saves ~600 lines of duplicated content and ensures that changes to shared logic only need to be made in one place.

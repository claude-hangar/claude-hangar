# State Management

Claude Hangar skills persist their progress using JSON state files. This allows audits to span multiple sessions, resume after interruptions, and share findings between skills.

## State File Format

Every audit skill writes a state file in the project root:

| Skill | State File |
|-------|------------|
| `/audit` | `.audit-state.json` |
| `/project-audit` | `.project-audit-state.json` |
| `/astro-audit` | `.astro-audit-state.json` |
| `/sveltekit-audit` | `.sveltekit-audit-state.json` |
| `/db-audit` | `.db-audit-state.json` |
| `/auth-audit` | `.auth-audit-state.json` |
| `/audit-orchestrator` | `.audit-orchestrator-state.json` |

All state files follow the same v2.1 schema defined in `core/skills/_shared/audit-blueprint.md`.

## Schema Structure

A state file contains these top-level fields:

```json
{
  "version": "2.1",
  "skill": "audit",
  "project": "my-website",
  "startedAt": "2026-03-15",
  "lastUpdated": "2026-03-15T14:30:00Z",
  "session": 2,
  "stack": { "frontend": "astro", "css": "tailwind-v4" },
  "phaseOrder": "smart",
  "phases": [],
  "findings": []
}
```

**Key fields:**
- `version` -- Schema version for migration compatibility
- `session` -- Incremented each time the skill is invoked with `continue`
- `stack` -- Detected technology stack (auto-populated during `start`)
- `phaseOrder` -- Either `"sequential"` (01-09) or `"smart"` (security-first)

## Schema Versioning and Migration

The state schema has evolved through three versions:

| Version | Key Changes |
|---------|-------------|
| v1 | Original format, boolean layer status |
| v2 | Added completeness tracking, finding lifecycle |
| v2.1 | String enum layer status, checksSkipped array |

**Automatic migration:** When a skill reads an older state file, it migrates in place -- v1 booleans become string enums, missing `completeness` and `checksSkipped` fields are initialized. Migration is transparent.

## Phase Tracking

Each phase entry tracks execution status, layer coverage, and check completeness:

```json
{
  "id": "02-security",
  "status": "done",
  "session": 1,
  "sourceLayer": "done",
  "liveLayer": "done",
  "completeness": {
    "must": { "done": 12, "total": 12 },
    "should": { "done": 8, "total": 10 },
    "could": { "done": 3, "total": 5 }
  },
  "checksSkipped": [
    { "check": "SSH port scan", "priority": "SHOULD", "reason": "No server access" }
  ]
}
```

### Phase status values

| Status | Meaning |
|--------|---------|
| `"pending"` | Phase not yet started |
| `"in-progress"` | Phase started but not complete (or MUST checks incomplete) |
| `"done"` | Phase complete with 100% MUST checks |

**Critical rule:** A phase with less than 100% MUST-check completion cannot be marked `"done"`. It stays `"in-progress"` with the skipped MUST checks documented in `checksSkipped`.

## Completeness Tracking

Every phase tracks three priority tiers:

| Tier | Meaning | Requirement |
|------|---------|-------------|
| MUST | Mandatory check | Phase incomplete if skipped |
| SHOULD | Standard check | Can be skipped with documented reason |
| COULD | Nice-to-have | Can be omitted freely |

The completeness count is performed at the end of each phase:

```
Phase 02-security -- Completeness:
  MUST: 12/12 (100%)
  SHOULD: 8/10 (80%) -- 2 skipped (no server access)
  COULD: 3/5 (60%)
  Total: 23/27 (85%)
```

## Layer Status

Each phase is checked from two angles:

| Skill | Layer 1 | Layer 2 |
|-------|---------|---------|
| `/audit` | `source` (code/config analysis) | `live` (curl, Lighthouse, Playwright) |
| `/project-audit` | `source` (code/config analysis) | `runtime` (npm audit, tsc, docker scout) |
| `/astro-audit` | `source` (code/config analysis) | `runtime` (npm view, build test) |

Layer status uses string enums:

| Value | Meaning |
|-------|---------|
| `"done"` | Layer fully checked |
| `"pending"` | Not yet checked |
| `"in-progress"` | Currently being checked |
| `"not-applicable"` | Not relevant for this phase |

A check is only considered complete when both applicable layers have been verified. Example: "CSP configured" (source layer) + "CSP header actually sent" (live layer) = complete.

## Finding Lifecycle

Findings progress through a defined lifecycle:

```
  discovered -----> open -----> fixed -----> verified
                     |
                     +--------> wontfix
                     |
                     +--------> duplicate
```

### Finding states

| Status | Meaning |
|--------|---------|
| `"open"` | Finding documented, not yet addressed |
| `"fixed"` | Fix implemented, `fixedIn` records which session |
| `"wontfix"` | Intentionally not fixed (documented reason) |
| `"duplicate"` | Already covered by another finding |

### Finding format in state

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

### Fix verification protocol

No fix is considered complete without verification: IDENTIFY (name finding + location), RUN (implement), READ (re-read from disk), VERIFY (test with tools), CLAIM (set status: "fixed"). Steps READ and VERIFY must never be skipped.

## Session History

The `session` counter tracks how many times a skill has been invoked. Combined with `lastUpdated` timestamps and `fixedIn` references on findings, this creates a complete history of audit progress across sessions.

## State as Inter-Skill Contract

State files serve as the interface between skills. The state contract table defines who produces and who consumes each file:

| State File | Producer | Consumers |
|------------|----------|-----------|
| `.audit-state.json` | `/audit` | `/polish`, `/lesson-learned`, `/adversarial-review` |
| `.project-audit-state.json` | `/project-audit` | `/lesson-learned`, `/adversarial-review` |
| `.audit-orchestrator-state.json` | `/audit-orchestrator` | `/audit auto`, `/project-audit auto` |
| `.freshness-state.json` | `/freshness-check` | `/audit-orchestrator` |
| `.micro-check-results.json` | micro-skills | `/polish` |

**Key principle:** Every skill works standalone. If a consumed state file does not exist, the skill proceeds without it. Synergy is a bonus, not a requirement.

## Context Protection Rules

State persistence follows strict context protection rules:

- **Write immediately:** State is written after every phase and every fix
- **Max 2 phases OR 5 fixes per session** (except `auto` mode)
- **On interruption:** State is always current, next session resumes seamlessly
- **No auto-fix:** Findings are documented, the user decides what to fix
- **Auto mode exception:** In `auto` mode, all phases run but findings are collected without fixing

These rules ensure that no progress is lost, even if a session is interrupted or context runs low.

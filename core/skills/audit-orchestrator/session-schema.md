# Audit Orchestrator — Session Directory Schema

Each `/audit-orchestrator` run creates a self-contained session directory. Any LLM or human can open this directory and understand what happened, what's happening, and what to do next.

## Layout

```
.audit-session/
  <YYYY-MM-DD>-<slug>/
    INDEX.md                       # Table of contents + navigation
    STATUS.md                      # Live session state — read first on resume
    01-prescan/
      README.md                    # Phase intent
      findings.md                  # What was detected
      project-profile.md           # Structured project profile
      TODO.md                      # Analysis tasks queued for Phase 2
    02-analysis/
      README.md
      findings.md                  # Issues with severity
      opportunities.md             # Wins / polish / tech debt
      TODO.md                      # Fix queue for Phase 3 (severity-sorted)
      packages/                    # Monorepo only: one subfolder per package
        <pkg-name>/findings.md
    03-optimization/
      README.md
      changes.md                   # Applied changes (id → commit SHA)
      TODO.md                      # Deferred / blocked / out-of-scope
      deviations.md                # Anything that went differently
    04-report/
      README.md
      REPORT.md                    # The canonical deliverable
```

Legacy state file `.audit-orchestrator-state.json` (v3) is still produced for the web-framework orchestration path — it coexists with the session directory.

## INDEX.md Template

```markdown
# Audit Session — <project-slug>

**Started:** YYYY-MM-DDTHH:MMZ
**Project type:** <detected-type>
**Tracks:** general + <specialty>

## Navigation

- `STATUS.md` — live session state (start here on resume)
- `01-prescan/` — project detection, profile, analysis queue
- `02-analysis/` — findings, opportunities, fix queue
- `03-optimization/` — applied changes, deferred items, deviations
- `04-report/REPORT.md` — final deliverable

## Phase Status

| Phase | State | Last Updated |
|-------|-------|--------------|
| 01 Pre-Scan | completed | YYYY-MM-DDTHH:MMZ |
| 02 Analysis | in_progress | YYYY-MM-DDTHH:MMZ |
| 03 Optimization | pending | — |
| 04 Report | pending | — |

## Counts

- Findings total: 0 (CRITICAL: 0, HIGH: 0, MEDIUM: 0, LOW: 0)
- Fixed: 0
- Deferred: 0
- Blocked: 0
```

INDEX.md is updated at every phase transition.

## STATUS.md Template

```markdown
# Session Status

**Last updated:** YYYY-MM-DDTHH:MMZ
**Current phase:** 02-analysis
**State:** in_progress | paused | completed | blocked
**Active instance:** <agent-id or "none">

## Next Action

<One sentence: what the next tool call should do.>

## Context for Resume

- What was the last step?
- What inputs does the next step need?
- Any open decisions awaiting user input?

## Recent Events

- YYYY-MM-DDTHH:MMZ — phase 01 completed (profile.md written)
- YYYY-MM-DDTHH:MMZ — phase 02 started
- YYYY-MM-DDTHH:MMZ — paused (user /exit)

## Blocking Issues

- None, OR: "Waiting on user decision: X vs Y for finding SEC-03"
```

**STATUS.md is the single source of truth for resume.** Every instance updates it:
- Before the first tool call of a new session (to claim it).
- After every phase transition.
- After every ~5 fix commits in Phase 3.
- On pause/exit (last action: flip state to `paused`).

## Findings Table Format

Used in `02-analysis/findings.md`:

```markdown
| ID | Severity | Area | Evidence | Recommendation |
|----|----------|------|----------|----------------|
| SEC-01 | CRITICAL | security | `src/auth.ts:42` — bcrypt cost=4 | Raise cost to 12 |
| DEP-01 | HIGH | deps | `astro@5.1.0` — 2 CVEs | Upgrade to 6.1.7 |
```

IDs follow `<AREA>-<NN>` convention (SEC, DEP, GIT, CI, TEST, DOC, INFRA, MIG, PERF, A11Y, SEO, etc.). IDs are stable across phases — the same ID appears in findings.md, TODO.md, changes.md.

## TODO Format

Used in every phase's `TODO.md`:

```markdown
## CRITICAL (must)

- [ ] SEC-01 — Fix bcrypt cost (src/auth.ts:42)
  - Context: See 02-analysis/findings.md#SEC-01
  - Verification: run auth tests

## HIGH (should)

- [ ] DEP-01 — Upgrade astro to 6.1.7

## MEDIUM

- [ ] ...

## Deferred

- [ ] DOC-03 — Rewrite contributing guide (out of scope, moved to backlog)

## Blocked

- [ ] MIG-02 — Waiting on upstream fix astro/astro#12345
```

Checkbox state is the fix-queue position. Phase 3 ticks boxes as work progresses.

## Changes Log Format

Used in `03-optimization/changes.md`:

```markdown
| ID | Commit | Files | Verification |
|----|--------|-------|--------------|
| SEC-01 | abc1234 | src/auth.ts | tests/auth.test.ts pass |
| DEP-01 | def5678 | package.json, package-lock.json | build green, tests pass |
```

## Slug Convention

`<YYYY-MM-DD>-<short-descriptor>`:
- `2026-04-16-hangar-freshness`
- `2026-04-16-homelab-infra-audit`
- `2026-04-16-monorepo-deps-sweep`

Keep the descriptor under 40 chars, lowercase, hyphen-separated, no special chars. If unsure, use `<YYYY-MM-DD>-audit`.

## Cleanup Policy

Completed session directories are not auto-deleted. The REPORT.md is the historical record. Old sessions can be archived into `.audit-session/archive/<year>/` manually or via `/gsd-cleanup`-style sweep.

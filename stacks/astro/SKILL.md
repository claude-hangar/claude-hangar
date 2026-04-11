---
name: astro-audit
description: >
  Astro Migration & Best-Practice Audit with state persistence.
  Use when: "astro-audit", "astro upgrade", "astro migration", "astro check", "astro version".
effort: high
user-invocable: true
argument-hint: "start|continue"
---

<!-- AI-QUICK-REF
## /astro-audit — Quick Reference
- **Modes:** start | continue | status | refresh | auto
- **Auto-Detection:** package.json, astro.config, Node, Dockerfile, Content Collections
- **Version Logic:** Installed vs. Latest -> matching checklist (v5-stable, v6-beta, v6-stable)
- **State:** .astro-audit-state.json
- **Finding IDs:** MIG-01 (Migration), BP-01 (Best Practice)
- **Checkpoints:** [CHECKPOINT: decision] at version/checklist selection, [CHECKPOINT: verify] after each area
- **Complementary to /audit** — this skill only checks Astro-specific topics
-->

# /astro-audit — Astro Migration & Best-Practice Audit

Version-neutral skill for all Astro projects. Automatically detects the installed version, compares with the latest available, and loads the matching checklist.

**Complementary to /audit:** This skill checks Astro-specific version and migration topics. The generic /audit checks code quality, performance, security, a11y, etc.

## Modes

Detect the mode from user input:

- **start** -> Mode 1 (Scan project, load checklist)
- **continue** -> Mode 2 (Process next areas/fixes)
- **status** -> Mode 3 (Show progress)
- **refresh** -> Mode 4 (Check for new Astro releases)
- **auto** -> Mode 5 (Fully autonomous run)

---

## Mode 1: `/astro-audit start` — Scan Project

### Auto-Detection (in this order)

1. **package.json** -> Astro version, adapter, integrations, all `@astrojs/*` packages
2. **astro.config.mjs/ts** -> experimental flags, config structure, output mode
3. **Node version** -> `node --version` (Astro 6 requires Node 22)
4. **Dockerfile** -> Node version in base image, build commands
5. **src/content/config.ts** -> Content Collections, loader type (Legacy vs Content Layer)
6. **tsconfig.json** -> TypeScript configuration, strict mode

### Version Logic

After detection:

1. Read installed version from `package.json` (e.g., `5.17.2`, `6.0.0-beta.11`)
2. Check latest version: `npm view astro versions --json` (show last 5)
3. Select matching checklist:

| Installed | Latest | Checklist | Scenario |
|-----------|--------|-----------|----------|
| 5.x | 5.x | `versions/v5-stable/` | Up to date, check best practices |
| 5.x | 6.x-beta | `versions/v6-beta/` | Migration to v6 Beta (only if user wants) |
| 5.x | 6.x (stable) | `versions/v6-stable/` | Migration to v6 Stable |
| 6.x-beta | 6.x-beta | `versions/v6-beta/` | Beta verification, check for newer betas |
| 6.x-beta | 6.x (stable) | `versions/v6-stable/` | Upgrade Beta -> Stable |
| 6.x | 6.x | `versions/v6-stable/` | Up to date, check best practices |

**Astro 6 has been stable since March 10, 2026 (latest: 6.1.5).** For migration 5->6 use the `v6-beta/` checklist (74 checks, all breaking changes). For best practices on 6.x use the `v6-stable/` checklist (31 checks).

4. **Ask user:** "Check current version OR migrate to new version?"
5. Load checklist and compare with project scan
6. Document findings with `MIG-NN` IDs + severity

### Flow After Detection

1. Display result table: Version, Node, Adapter, Collections, Flags
2. Load matching checklist (max 2 areas per session)
3. Check each checkpoint against the project
4. Save findings to `.astro-audit-state.json`
5. Display summary + prioritized list
6. Session end: "Start next session with `/astro-audit continue`"

---

## Mode 2: `/astro-audit continue` — Resume

1. Read `.astro-audit-state.json`
2. **Generate smart recommendation:**
   ```
   IF open CRITICAL findings > 0:
     -> "Recommendation: Fix {N} CRITICAL findings first ({IDs})"
   IF open HIGH findings > 3:
     -> "Recommendation: Fix HIGH findings, then continue"
   ELSE IF areas open:
     -> "Recommendation: Next areas ({area names})"
   ELSE:
     -> "Recommendation: Fix remaining findings"
   ```
3. If areas open -> process next 2 areas
4. If all areas done -> next 5 findings by priority
5. **Load fix templates** (from `fix-templates.md`) where applicable
6. Ask user: Follow recommendation? Choose different? Skip?
7. Implement fixes -> verify -> update state

---

## Mode 3: `/astro-audit status` — Progress

1. Read `.astro-audit-state.json`
2. Display table: Done/Open/Total per area + severity
3. Next recommended action

---

## Mode 4: `/astro-audit refresh` — Check New Releases

1. `npm view astro versions --json` -> latest version
2. If newer version than in state: context7 or WebSearch for release notes
3. **Show checklist delta:**
   ```
   Last checked: 6.0.0-beta.11
   Current:      6.0.0-beta.15
   New changes:  4 (2 Breaking, 2 Features)
   -> Checklist update recommended
   ```
4. Inform user + recommendation (update yes/no, breaking changes)
5. Update `versions/*/changelog.md` if needed (date stamp at end)
6. When stable release detected -> automatically recommend `v6-stable/` checklist

---

## Mode 5: `/astro-audit auto` — Autonomous Run

Fully autonomous Astro audit without prompts.

### Flow

1. Auto-detection as in `start`
2. **All areas** processed (no 2-area limitation)
3. Document findings with fix templates from `fix-templates.md`
4. **Context management:** When context runs low:
   - Write state immediately
   - Create task in `.tasks.json` with handoff note
   - "New session with `/astro-audit continue`"
5. At end: Summary with prioritized fix list

### Severity Order of Areas in Auto Mode

CRITICAL areas first:
`ENV -> CFG -> CODE -> COLL -> ADPT -> VITE -> ZOD -> DCI -> MDLK -> IMG -> CSP -> TOOL -> FONT -> NEW`

---

## Check Priorities + Completeness Tracking

> See `_shared/audit-patterns.md` (MUST/SHOULD/CAN markers, completeness counting, layer status standard).
Area with <100% MUST checks cannot be marked as `done`.

---

## State File `.astro-audit-state.json`

Save in project root (gitignored).

```json
{
  "version": 2,
  "created": "YYYY-MM-DD",
  "lastUpdated": "YYYY-MM-DD",
  "project": "Project Name",
  "installedAstroVersion": "5.17.2",
  "targetAstroVersion": "6.0.0-beta.11",
  "checklist": "v6-beta",
  "nodeVersion": "22.12.0",
  "adapter": "@astrojs/node",
  "output": "server",
  "areas": {
    "ENV": {
      "status": "pending",
      "session": null,
      "findingsCount": 0,
      "completeness": null,
      "layers": { "source": "pending", "runtime": "pending" }
    },
    "CFG": { "status": "pending", "session": null, "findingsCount": 0, "completeness": null, "layers": null },
    "CODE": { "status": "pending", "session": null, "findingsCount": 0, "completeness": null, "layers": null },
    "COLL": { "status": "pending", "session": null, "findingsCount": 0, "completeness": null, "layers": null },
    "ADPT": { "status": "pending", "session": null, "findingsCount": 0, "completeness": null, "layers": null },
    "MDLK": { "status": "pending", "session": null, "findingsCount": 0, "completeness": null, "layers": null },
    "IMG": { "status": "pending", "session": null, "findingsCount": 0, "completeness": null, "layers": null },
    "TOOL": { "status": "pending", "session": null, "findingsCount": 0, "completeness": null, "layers": null },
    "VITE": { "status": "pending", "session": null, "findingsCount": 0, "completeness": null, "layers": null },
    "ZOD": { "status": "pending", "session": null, "findingsCount": 0, "completeness": null, "layers": null },
    "NEW": { "status": "pending", "session": null, "findingsCount": 0, "completeness": null, "layers": null },
    "CSP": { "status": "pending", "session": null, "findingsCount": 0, "completeness": null, "layers": null },
    "FONT": { "status": "pending", "session": null, "findingsCount": 0, "completeness": null, "layers": null },
    "DCI": { "status": "pending", "session": null, "findingsCount": 0, "completeness": null, "layers": null }
  },
  "summary": {
    "total": 0,
    "critical": 0,
    "high": 0,
    "medium": 0,
    "low": 0,
    "fixed": 0,
    "skipped": 0
  },
  "findings": [
    {
      "id": "MIG-01",
      "area": "ENV",
      "severity": "CRITICAL",
      "title": "Short title",
      "description": "What is the problem",
      "location": "File or area",
      "status": "open|fixed|skipped",
      "fixedIn": "Session N | null",
      "notes": ""
    }
  ],
  "history": [
    {
      "date": "YYYY-MM-DD",
      "session": 1,
      "areas": ["ENV", "CFG"],
      "findingsAdded": 3,
      "findingsFixed": 0
    }
  ]
}
```

### State Migration v1 -> v2

When a `.astro-audit-state.json` with `"version": 1` is found:

1. Migrate `areas` from string enum to object:
   - `"done"` -> `{ "status": "done", "session": null, "findingsCount": 0, "completeness": null, "layers": null }`
   - `"in-progress"` -> `{ "status": "in-progress", ... }`
   - `"pending"` -> `{ "status": "pending", ... }`
   - `"skipped"` -> `{ "status": "skipped", ... }`
   - Count `findingsCount` from `findings[]` array (per area)
2. Add `history: []` array
3. Add `"notes": ""` to each finding (if not present)
4. Set `version` to `2`
5. Inform user: "State migrated from v1 to v2 (completeness tracking, history, layer status)."

---

## Rules

- **Context protection:** Max 2 areas OR 5 fixes per session. At limit: save state, recommend `/astro-audit continue`.
- **Write state immediately:** Update `.astro-audit-state.json` after every area and every fix.
- **No auto-fix:** Document findings, then ask user whether to fix.
- **Read version files:** Only read files from the relevant `versions/` directory. Don't load all.
- **Severity rules:**
  - CRITICAL: Build breaks, runtime errors, security issues
  - HIGH: Deprecation warning, functional limitation
  - MEDIUM: Best practice deviation, performance
  - LOW: Optional, nice-to-have, new features
- **Finding prefix:** Always `MIG-NN` (Migration), not CODE/SEC like /audit.
- **Fix templates:** Load matching template from `fix-templates.md` for findings.
- **npm view:** Run `npm view astro` before any version statement. Never from memory.
- **context7:** Use for Astro documentation when available.

---

## Session Strategy

| Session | Content | Context Protection |
|---------|---------|-------------------|
| 1 | start -> Detection + 2 areas (CRITICAL first) | Max 2 areas |
| 2 | continue -> next 2 areas | Max 2 areas |
| 3+ | continue -> Fixes (max 5/session) | Fix -> Test -> Next |

---

## Smart Next Steps

After completing the Astro audit, recommend relevant follow-up skills:

| Condition | Recommendation | Reason |
|-----------|---------------|--------|
| No .audit-state.json present | `/audit start` | Check website quality (SEO, a11y, performance, privacy) |
| No .project-audit-state.json present | `/project-audit start` | Check code/CI/CD quality |
| Migration findings fixed | `/lighthouse-quick` | Verify performance after migration |
| UI/Design work needed | `/design-system` | Curated palettes, fonts, styles, UX rules (CSV databases) |
| Frontend polish desired | `/polish scan` | Rate 6 design dimensions, then improve |
| All areas done | `/lesson-learned session` | Extract learnings from migration |

**Design Integration:** When building or modifying UI components in Astro projects, always consult `/design-system` first. It provides industry-matched palettes, font pairings, UX rules, and wow effects from curated CSV databases. The design-system is stack-agnostic — it provides design decisions, Astro provides the code patterns.

**Output after last area:** "Next steps:" + 2-3 most relevant recommendations.

---

## Version Directory Structure

Each directory under `versions/` contains:

| File | Content |
|------|---------|
| `checklist.md` | Checkpoints with IDs, severity, description |
| `changelog.md` | Release notes (only for Beta/Major) |
| `reference-links.md` | Official docs links, PR links |

Currently available:
- `versions/v5-stable/` — Best practices for Astro 5.x
- `versions/v6-beta/` — Migration Astro 5->6 (74 checkpoints, definitive migration guide)
- `versions/v6-stable/` — Best practices for Astro 6.x Stable (28 checkpoints)
- `versions/v7/` — (still empty, for future use)

Additionally:
- `fix-templates.md` — Quick-fix templates for common Astro findings

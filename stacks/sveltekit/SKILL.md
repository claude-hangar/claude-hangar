---
name: sveltekit-audit
description: >
  SvelteKit & Svelte 5 Migration, Best-Practice Audit with state persistence.
  Use when: "sveltekit-audit", "sveltekit upgrade", "svelte migration", "svelte check", "sveltekit version", "svelte 5 runes".
user_invocable: true
argument_hint: "start|continue"
---

<!-- AI-QUICK-REF
## /sveltekit-audit — Quick Reference
- **Modes:** start | continue | status | refresh | auto
- **Auto-Detection:** package.json (svelte, @sveltejs/kit), svelte.config.js, vite.config.ts, Node, Dockerfile, +page.svelte, Drizzle
- **Version Logic:** SvelteKit 1 vs 2, Svelte 4 vs 5 — select matching checklist
- **State:** .sveltekit-audit-state.json
- **Finding IDs:** SKT-01 (SvelteKit), BP-01 (Best Practice)
- **Checkpoints:** [CHECKPOINT: decision] at version/checklist selection, [CHECKPOINT: verify] after each area
- **Complementary to /audit** — this skill only checks SvelteKit-specific topics
-->

# /sveltekit-audit — SvelteKit & Svelte 5 Audit

Version-neutral skill for all SvelteKit projects. Automatically detects the installed version, compares with the latest available, and loads the matching checklist.

**Complementary to /audit:** This skill checks SvelteKit-specific version, migration, and best-practice topics. The generic /audit checks code quality, performance, security, a11y, etc.

## Modes

Detect the mode from user input:

- **start** -> Mode 1 (Scan project, load checklist)
- **continue** -> Mode 2 (Process next areas/fixes)
- **status** -> Mode 3 (Show progress)
- **refresh** -> Mode 4 (Check for new SvelteKit/Svelte releases)
- **auto** -> Mode 5 (Fully autonomous run)

---

## Mode 1: `/sveltekit-audit start` — Scan Project

### Auto-Detection (in this order)

1. **package.json** -> Svelte version, SvelteKit version, adapter, all `@sveltejs/*` packages, Drizzle packages
2. **svelte.config.js** -> Adapter, preprocess, aliases, kit config
3. **vite.config.ts** -> Vite plugins, server config, proxy
4. **Node version** -> `node --version` (SvelteKit 2 requires Node 18.13+)
5. **Dockerfile** -> Node version in base image, build commands
6. **src/routes/+page.svelte** -> Routing structure, layouts, groups
7. **Drizzle schema** -> `drizzle.config.ts`, `src/lib/server/db/schema.ts` or similar
8. **tsconfig.json** -> TypeScript configuration, strict mode, Svelte extends

### Version Logic

After detection:

1. Read installed version from `package.json` (Svelte + SvelteKit separately)
2. Check latest version: `npm view @sveltejs/kit version` and `npm view svelte version`
3. Select matching checklist:

| Svelte | SvelteKit | Checklist | Scenario |
|--------|-----------|-----------|----------|
| 5.x | 2.x | `versions/kit2-svelte5/` | Current stack, check best practices |
| 4.x | 1.x | Migration needed | SvelteKit 1->2 + Svelte 4->5 migration |
| 4.x | 2.x | Svelte 5 migration needed | SvelteKit 2 current, only Svelte 4->5 |
| 5.x | 1.x | SvelteKit 2 migration needed | Svelte 5 current, only Kit 1->2 |

**IMPORTANT:** For SvelteKit 1 or Svelte 4: First ask the user whether migration is desired.

4. **Ask user:** "Check current version OR migrate to new version?"
5. Load checklist and compare with project scan
6. Document findings with `SKT-NN` or `BP-NN` IDs + severity

### Flow After Detection

1. Display result table: Svelte version, SvelteKit version, Node, adapter, routing overview
2. Load matching checklist (max 2 areas per session)
3. Check each checkpoint against the project
4. Save findings to `.sveltekit-audit-state.json`
5. Display summary + prioritized list
6. Session end: "Start next session with `/sveltekit-audit continue`"

---

## Mode 2: `/sveltekit-audit continue` — Resume

1. Read `.sveltekit-audit-state.json`
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

## Mode 3: `/sveltekit-audit status` — Progress

1. Read `.sveltekit-audit-state.json`
2. Display table: Done/Open/Total per area + severity
3. Next recommended action

---

## Mode 4: `/sveltekit-audit refresh` — Check New Releases

1. `npm view @sveltejs/kit version` and `npm view svelte version` -> latest versions
2. If newer version than in state: context7 or WebSearch for release notes
3. **Show checklist delta:**
   ```
   Last checked: SvelteKit 2.15.0 / Svelte 5.10.0
   Current:      SvelteKit 2.17.0 / Svelte 5.12.0
   New changes:  N (Breaking, Features)
   -> Checklist update recommended
   ```
4. Inform user + recommendation (update yes/no, breaking changes)
5. When major release detected -> automatically recommend new checklist

---

## Mode 5: `/sveltekit-audit auto` — Autonomous Run

Fully autonomous SvelteKit audit without prompts.

### Flow

1. Auto-detection as in `start`
2. **All areas** processed (no 2-area limitation)
3. Document findings with fix templates from `fix-templates.md`
4. **Context management:** When context runs low:
   - Write state immediately
   - Create task in `.tasks.json` with handoff note
   - "New session with `/sveltekit-audit continue`"
5. At end: Summary with prioritized fix list

### Severity Order of Areas in Auto Mode

CRITICAL areas first:
`ENV -> CFG -> CODE -> ROUT -> LOAD -> FORM -> SSR -> API -> HOOK -> ADPT -> STORE -> CSP -> TOOL -> DB -> AUTH -> PERF2`

---

## Check Priorities + Completeness Tracking

> See `_shared/audit-patterns.md` (MUST/SHOULD/CAN markers, completeness counting, layer status standard).
Area with <100% MUST checks cannot be marked as `done`.

---

## State File `.sveltekit-audit-state.json`

Save in project root (gitignored).

```json
{
  "version": 2,
  "created": "YYYY-MM-DD",
  "lastUpdated": "YYYY-MM-DD",
  "project": "Project Name",
  "installedSvelteVersion": "5.10.0",
  "installedKitVersion": "2.15.0",
  "targetSvelteVersion": "5.12.0",
  "targetKitVersion": "2.17.0",
  "checklist": "kit2-svelte5",
  "nodeVersion": "22.12.0",
  "adapter": "@sveltejs/adapter-node",
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
    "ROUT": { "status": "pending", "session": null, "findingsCount": 0, "completeness": null, "layers": null },
    "LOAD": { "status": "pending", "session": null, "findingsCount": 0, "completeness": null, "layers": null },
    "FORM": { "status": "pending", "session": null, "findingsCount": 0, "completeness": null, "layers": null },
    "SSR": { "status": "pending", "session": null, "findingsCount": 0, "completeness": null, "layers": null },
    "API": { "status": "pending", "session": null, "findingsCount": 0, "completeness": null, "layers": null },
    "HOOK": { "status": "pending", "session": null, "findingsCount": 0, "completeness": null, "layers": null },
    "ADPT": { "status": "pending", "session": null, "findingsCount": 0, "completeness": null, "layers": null },
    "STORE": { "status": "pending", "session": null, "findingsCount": 0, "completeness": null, "layers": null },
    "TOOL": { "status": "pending", "session": null, "findingsCount": 0, "completeness": null, "layers": null },
    "DB": { "status": "pending", "session": null, "findingsCount": 0, "completeness": null, "layers": null },
    "AUTH": { "status": "pending", "session": null, "findingsCount": 0, "completeness": null, "layers": null },
    "CSP": { "status": "pending", "session": null, "findingsCount": 0, "completeness": null, "layers": null },
    "PERF2": { "status": "pending", "session": null, "findingsCount": 0, "completeness": null, "layers": null }
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
      "id": "SKT-01",
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

---

## Areas

| Code | Area | Description |
|------|------|-------------|
| **ENV** | Environment | Node/runtime version, package manager |
| **CFG** | Configuration | svelte.config.js, vite.config.ts |
| **CODE** | Svelte 5 Code | Runes ($state, $derived, $effect), reactivity, component patterns |
| **ROUT** | Routing | +page, +layout, +server, +error, group-based routing |
| **LOAD** | Load Functions | +page.ts vs +page.server.ts, universal vs server load |
| **FORM** | Form Actions | Progressive enhancement, use:enhance |
| **SSR** | SSR/CSR/Prerendering | SSR config, adapter, environment variables |
| **API** | API Routes | +server.ts, endpoint security, input validation |
| **HOOK** | SvelteKit Hooks | handle, handleError, handleFetch (hooks.server.ts) |
| **ADPT** | Adapter | @sveltejs/adapter-node, adapter-auto, configuration |
| **STORE** | State Management | Svelte 5 Runes vs legacy stores, Context API |
| **TOOL** | Dev Tooling | svelte-check, prettier-plugin-svelte, eslint-plugin-svelte |
| **DB** | Database | Drizzle integration, schema, migrations, server-only |
| **AUTH** | Auth Patterns | Session, cookies, protected routes via hooks |
| **CSP** | Content Security Policy | Trusted Types directives, CSP configuration |
| **PERF2** | Performance & Bundling | Treeshaking, code splitting, bundle optimization |

---

## Rules

- **Context protection:** Max 2 areas OR 5 fixes per session. At limit: save state, recommend `/sveltekit-audit continue`.
- **Write state immediately:** Update `.sveltekit-audit-state.json` after every area and every fix.
- **No auto-fix:** Document findings, then ask user whether to fix.
- **Read version files:** Only read files from the relevant `versions/` directory. Don't load all.
- **Severity rules:**
  - CRITICAL: Build breaks, runtime errors, security issues
  - HIGH: Deprecation warning, functional limitation
  - MEDIUM: Best practice deviation, performance
  - LOW: Optional, nice-to-have, new features
- **Finding prefix:** `SKT-NN` (SvelteKit-specific), `BP-NN` (Best Practice).
- **Fix templates:** Load matching template from `fix-templates.md` for findings.
- **npm view:** Run `npm view @sveltejs/kit version` and `npm view svelte version` before any version statement. Never from memory.
- **context7:** Use for SvelteKit/Svelte documentation when available.

---

## Session Strategy

| Session | Content | Context Protection |
|---------|---------|-------------------|
| 1 | start -> Detection + 2 areas (CRITICAL first) | Max 2 areas |
| 2 | continue -> next 2 areas | Max 2 areas |
| 3+ | continue -> Fixes (max 5/session) | Fix -> Test -> Next |

---

## Smart Next Steps

After completing the SvelteKit audit, recommend relevant follow-up skills:

| Condition | Recommendation | Reason |
|-----------|---------------|--------|
| No .audit-state.json present | `/audit start` | Check website quality (SEO, a11y, performance, privacy) |
| No .project-audit-state.json present | `/project-audit start` | Check code/CI/CD quality |
| DB area with findings | `/db-audit start` | Deep-dive into Drizzle schema + migration |
| AUTH area with findings | `/auth-audit start` | Deep-dive into auth patterns + security |
| Migration findings fixed | `/lighthouse-quick` | Verify performance after migration |
| UI/Design work needed | `/design-system` | Curated palettes, fonts, styles, UX rules (CSV databases) |
| Frontend polish desired | `/polish scan` | Rate 6 design dimensions, then improve |
| All areas done | `/lesson-learned session` | Extract learnings from audit |

**Design Integration:** When building or modifying UI components in SvelteKit projects, always consult `/design-system` first. It provides industry-matched palettes, font pairings, UX rules, and wow effects from curated CSV databases. The design-system is stack-agnostic — it provides design decisions, SvelteKit provides the code patterns.

**Output after last area:** "Next steps:" + 2-3 most relevant recommendations.

---

## Version Directory Structure

Each directory under `versions/` contains:

| File | Content |
|------|---------|
| `checklist.md` | Checkpoints with IDs, severity, description |

Currently available:
- `versions/kit2-svelte5/` — Best practices for SvelteKit 2 + Svelte 5 (51 checkpoints)

Additionally:
- `fix-templates.md` — Quick-fix templates for common SvelteKit findings

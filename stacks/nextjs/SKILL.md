---
name: nextjs-audit
description: >
  Next.js App Router Best-Practice Audit with state persistence.
  Use when: "nextjs-audit", "nextjs upgrade", "next check", "nextjs version", "app router".
effort: high
user-invocable: true
argument-hint: "start|continue"
---

<!-- AI-QUICK-REF
## /nextjs-audit — Quick Reference
- **Modes:** start | continue | status | refresh | auto
- **Auto-Detection:** package.json (next), next.config, app/ or pages/, Dockerfile
- **Version Logic:** App Router vs Pages Router, Next.js 15 vs 16
- **State:** .nextjs-audit-state.json
- **Finding IDs:** NXT-01 (Next.js), BP-01 (Best Practice)
- **Checkpoints:** [CHECKPOINT: decision] at version/checklist selection, [CHECKPOINT: verify] after each area
- **Complementary to /audit** — this skill only checks Next.js-specific topics
-->

# /nextjs-audit — Next.js App Router Audit

Version-neutral skill for Next.js projects. Automatically detects the installed version, compares with the latest available, and loads the matching checklist.

**Complementary to /audit:** This skill checks Next.js-specific version, migration, and best-practice topics. The generic /audit checks code quality, performance, security, a11y, etc.

## Modes

Detect the mode from user input:

- **start** → Mode 1 (Scan project, load checklist)
- **continue** → Mode 2 (Process next areas/fixes)
- **status** → Mode 3 (Show progress)
- **refresh** → Mode 4 (Check for new Next.js releases)
- **auto** → Mode 5 (Fully autonomous run)

---

## Mode 1: `/nextjs-audit start` — Scan Project

### Auto-Detection (in this order)

1. **package.json** → Next.js version, React version, all `@next/*` packages
2. **next.config.mjs/ts** → experimental flags, output mode, turbopack config
3. **app/ vs pages/** → App Router or Pages Router (or both)
4. **Node version** → `node --version` (Next.js 16 requires Node 20+)
5. **Dockerfile** → Node version in base image, build commands
6. **tsconfig.json** → TypeScript configuration, strict mode, paths

### Version Logic

After detection:

```
Is next >= 16.0?
  → Use App Router checklist (versions/app-router/checklist.md)
Is next >= 15.0 and < 16.0?
  → Use App Router checklist with Next 15 compatibility notes
Is next < 15.0?
  → Recommend upgrade, show migration path
Uses pages/ directory?
  → Add Pages Router migration notes (recommend App Router migration)
```

### State File

Create `.nextjs-audit-state.json`:
```json
{
  "nextVersion": "16.2.2",
  "reactVersion": "19.1.0",
  "router": "app",
  "turbopack": true,
  "checklist": "app-router",
  "areas": {
    "ENV": { "status": "pending", "findings": [] },
    "CFG": { "status": "pending", "findings": [] }
  }
}
```

---

## Mode 2: `/nextjs-audit continue` — Process Areas

Read state file, find next `pending` area, process it.

Per area:
1. Run all checks
2. Document findings as NXT-01, NXT-02, etc.
3. Offer fixes from fix-templates.md
4. Mark area as `done` in state

---

## Mode 3: `/nextjs-audit status`

Show progress from state file:
```
Next.js Audit — my-app
  Next.js: 16.2.2 (App Router)
  Checklist: app-router (42 checks)
  Progress: 3/10 areas done
  Findings: 5 (2 HIGH, 2 MEDIUM, 1 LOW)
```

---

## Mode 4: `/nextjs-audit refresh`

Check for new Next.js releases:
```bash
npm view next version  # Current latest
```
Compare with detected version. If major/minor difference → show upgrade notes.

---

## Mode 5: `/nextjs-audit auto`

Fully autonomous: run all areas without pausing. Report at the end.

---

## Rules

- **Check REAL state** — don't assume, verify (run commands, read files)
- **One area at a time** — don't jump between areas
- **Findings are actionable** — each finding has a concrete fix
- **[CHECKPOINT: verify]** after each area — show findings, ask to continue
- **Fix-templates over custom code** — use established patterns
- **Complementary** — don't duplicate what /audit already checks

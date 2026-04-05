---
name: freshness-check
description: >
  Pipeline source freshness check (frameworks, tools, standards).
  Use when: "freshness", "update check", "is everything current", "check versions".
user_invocable: true
argument_hint: "check|update|full"
---

<!-- AI-QUICK-REF
## /freshness-check — Quick Reference
- **Modes:** check (read-only) | update (auto-update) | full (+ WebSearch + Community + Opportunities)
- **Arguments:** `/freshness-check $0` e.g. `/freshness-check full`
- **7 Tiers:** npm packages (auto), CLI plugins (auto), security standards (semi-auto), laws (manual), ecosystem (situational), community (gh api), opportunity analysis (full only)
- **Output:** Delta report with severity (HIGH/MED/LOW/OK/SKIP) + opportunity report
- **State:** .freshness-state.json (for orchestrator integration)
- **Recommended:** Before every audit, at least weekly
- **Checkpoints:** [CHECKPOINT: verify] when updates are found
-->

# /freshness-check — Pipeline Freshness Check

Checks whether audit skills, checklists, supplements, and references are up to date.
Ideally runs **before every audit** — the orchestrator recommends it automatically.

## Problem

The pipeline contains versioned knowledge bases:
- Framework checklists (Beta + Stable)
- Tool references and documentation
- OWASP, WCAG, GDPR phases
- Stack supplements (Tailwind, Docker, etc.)

These go stale silently. Without regular checks, you audit against outdated standards.

## Solution: Automated Freshness Scan

### Flow

1. **Check all sources in parallel** (npm, WebSearch, context7)
2. **Compare against documented state** (as-of date in each file)
3. **Create delta report** (what is outdated, what is current)
4. **Auto-update** where possible (changelogs, versions)
5. **Manual review** where needed (new laws, breaking changes)

### Modes

| Mode | Trigger | Description |
|------|---------|-------------|
| `check` | `/freshness-check` or `/freshness-check check` | Check only, change nothing — delta report |
| `update` | `/freshness-check update` | Check + auto-update where possible |
| `full` | `/freshness-check full` | All tiers including community repos + update + WebSearch |

---

## Source Catalog

### Tier 1 — Frameworks & Tools (npm view, automatic)

| Source | Check Command | Compared With | Auto-Update |
|--------|--------------|---------------|-------------|
| **Astro (Stable)** | `npm view astro version` | `versions/v5-stable/` as-of date, `versions/v6-stable/` | Append changelog + checklist |
| **Astro (Beta/RC)** | `npm view astro versions --json` (filter betas) | `versions/v6-beta/` as-of date | Append changelog + checklist |
| **Tailwind CSS** | `npm view tailwindcss version` | `stacks/css/tailwind-v4.md` as-of | Update supplement |
| **Vite** | `npm view vite version` | Astro checklist VITE section | Checklist note |
| **Node.js** | `node -v` + LTS schedule (WebSearch) | `.nvmrc` recommendation, env checks | Adjust recommendation |
| **Claude Code** | `claude --version` (if available) | `docs/claude-code-reference.md` version | Update reference |
| **@astrojs/check** | `npm view @astrojs/check version` | TOOL section in checklist | Note |
| **SvelteKit** | `npm view @sveltejs/kit version` | stacks/frontend/sveltekit.md as-of | Update supplement |
| **Svelte** | `npm view svelte version` | sveltekit-audit checklist | Checklist note |
| **Drizzle ORM** | `npm view drizzle-orm version` | stacks/database/postgresql.md as-of, db-audit checklist | Update supplement + checklist |
| **Drizzle Kit** | `npm view drizzle-kit version` | db-audit TOOL section | Note |
| **PostgreSQL** | WebSearch "PostgreSQL releases" | stacks/database/postgresql.md as-of | Note |
| **bcryptjs** | `npm view bcryptjs version` | auth-audit HASH section | Note |
| **Docker** | WebSearch "Docker Engine release notes" | Phase 08 + Docker supplements | Note |
| **Python** | `python --version` + WebSearch "Python releases" | stacks/python.md as-of | Note |
| **FastAPI** | `pip index versions fastapi` | Supplement or project check | Note |
| **Flask** | `pip index versions flask` | Supplement or project check | Note |
| **Next.js** | `npm view next version` | stacks/frontend/next.md as-of | Update supplement |
| **Fastify** | `npm view fastify version` | stacks/backend/node-fastify.md as-of | Update supplement |
| **Hugo** | WebSearch "Hugo releases" | stacks/frontend/hugo.md as-of | Note |

### Tier 2 — Security & Standards (WebSearch, semi-automatic)

| Source | Check Method | Compared With | Auto-Update |
|--------|-------------|---------------|-------------|
| **OWASP Top 10** | WebSearch "OWASP Top 10 latest" | Phase 02-security.md intro | Note only (manual review) |
| **OWASP ASVS** | WebSearch "OWASP ASVS version" | Phase 08-security.md S10 | Note only |
| **CWE Top 25** | WebSearch "CWE Top 25 latest" | Phase 02-security.md | Note only |

### Tier 3 — Laws & Regulations (WebSearch, manual review)

| Source | Check Method | Compared With | Auto-Update |
|--------|-------------|---------------|-------------|
| **GDPR** | WebSearch "GDPR changes {year}" | Phase 07-privacy.md | Note only |
| **Accessibility Laws** | WebSearch "accessibility legislation updates" | Phase 05-accessibility.md | Note only |
| **DSA** | WebSearch "Digital Services Act updates" | Phase 07-privacy.md S9 | Note only |
| **EU AI Act** | WebSearch "EU AI Act timeline" | Phase 07-privacy.md S11 | Note only |
| **WCAG** | WebSearch "WCAG latest version" | Phase 05-accessibility.md | Note only (WCAG 2.2 -> 3.0?) |
| **Google Consent Mode** | WebSearch "Google Consent Mode version" | Phase 07-privacy.md S3 | Note only |

### Tier 1b — CLI Plugins (gh api + installed_plugins.json, automatic)

| Source | Check Method | Compared With | Auto-Update |
|--------|-------------|---------------|-------------|
| **superpowers** | `gh api repos/obra/superpowers/releases/latest` | `~/.claude/plugins/installed_plugins.json` version | Note + `/reload` hint |
| **Other plugins** | Parse `~/.claude/plugins/installed_plugins.json` → per plugin: `gh api repos/{owner}/{repo}/releases/latest` | Installed version | Note + `/reload` hint |

**How to update plugins:** Run `/reload` in Claude Code to pull the latest version from the marketplace. No manual install needed.

**Check logic:**
1. Read `~/.claude/plugins/installed_plugins.json` → list all installed plugins
2. Per plugin: extract `version` and git info
3. Check latest release via `gh api repos/{owner}/{repo}/releases/latest`
4. Compare installed vs. latest → delta report entry

### Tier 4 — Ecosystem (WebSearch/gh, situational)

| Source | Check Method | Compared With | Auto-Update |
|--------|-------------|---------------|-------------|
| **GitHub Actions** | WebSearch "GitHub Actions changelog" | Phase 05-cicd.md + github.md | Note only |
| **Lighthouse** | `npm view lighthouse version` | Phase 03-performance.md | Note only |
| **Playwright** | `npm view playwright version` | stacks/testing/playwright.md | Note only |
| **Zod** | `npm view zod version` | Astro checklist ZOD section | Checklist note |

### Tier 5 — Community & Inspiration (gh api, full only)

| Source | Check Method | Compared With | Auto-Update |
|--------|-------------|---------------|-------------|
| Community repos | `gh api repos/{owner}/{repo}/commits?per_page=1` | community-sources.md as-of date | Note only + as-of date |

**Reference:** `community-sources.md` — Full list with owner/repo, category, adoption history.

**Flow:**
1. Read community-sources.md (repos + as-of dates)
2. Per repo: `gh api repos/{owner}/{repo}/commits?per_page=1` -> last commit timestamp
3. Compare with as-of date: New commits? -> Calculate delta
4. If delta > 14 days: Spot-check README or relevant files via `gh api`
5. Delta report with recommendation: "Worth checking" vs. "No action needed"

### Tier 6 — Opportunity Analysis (full mode only)

Checks whether updates from Tiers 1-5 enable concrete improvements for the pipeline.
**Core question:** "Could this update improve any of our skills, hooks, agents, or workflows?"

**Pipeline inventory (matched against updates):**

| Category | Components |
|----------|------------|
| **Skills** | freshness-check, audit, project-audit, astro-audit, sveltekit-audit, db-audit, auth-audit, audit-orchestrator, capture-pdf, design-system, favicon-check, lighthouse-quick, meta-tags, deploy-check, polish, adversarial-review, lesson-learned |
| **Hooks** | secret-leak-check, checkpoint, commit-message-validator, ci-guard, token-warning, skill-suggest, statusline, session-start, session-stop |
| **Agents** | explorer, explorer-deep, security-reviewer |
| **Patterns** | CLAUDE.md rules, anti-patterns, deviation handling, root-cause analysis, session continuity |

**Flow:**

1. **Identify sources with updates** — All entries from Tiers 1-5 with status != "ok"
2. **Read changelogs/release notes:**
   - npm: `gh api repos/{owner}/{repo}/releases/latest` or WebSearch "{tool} changelog {version}"
   - Community: `gh api repos/{owner}/{repo}/commits?per_page=5` -> analyze commit messages
   - Standards: Evaluate WebSearch results from Tiers 2-3
3. **Match new features against pipeline inventory:**
   - New hook event in Claude Code? -> Check if new hook makes sense
   - New Astro feature? -> Check if astro-audit checklist needs expanding
   - New community pattern? -> Check if pipeline patterns need updating
   - New security requirement? -> Check if security-reviewer needs expanding
4. **Rate opportunities:**
   - HIGH: Direct improvement possible, concrete implementation proposal
   - MED: Potentially useful, worth a closer look
   - LOW: Nice-to-have, no urgent action needed
5. **Create opportunity report** (part of the delta report)

**Rules:**
- ONLY rate when there is a concrete connection to the pipeline — not everything is relevant
- Community repos: Only check new CLAUDE.md, skills, hooks, agents pattern files
- No speculation — only when a feature clearly matches a component
- Save opportunities in .freshness-state.json under "opportunities" array

**Output format (in delta report):**
```
OPPORTUNITIES (Tier 6 — Pipeline Improvements):
  [HIGH] {Source} v{Version}: {Feature}
         -> Affects: {Skill/Hook/Agent}
         -> Proposal: {concrete improvement proposal}
  [MED]  {Source}: {Feature/Pattern}
         -> Check if relevant for: {Area}
  [LOW]  {Source}: {Update}
         -> Nice-to-have: {Description}
```

---

## Delta Report Format

```
Freshness Check — {Date}

OUTDATED (Action Required):
  [HIGH] Astro Beta: Documented beta.14, current beta.16
         -> Update changelog.md + checklist.md
  [HIGH] Claude Code: Reference v2.1.47, installed v2.2.0
         -> Update docs/claude-code-reference.md
  [MED]  Tailwind CSS: Supplement as-of 2026-01-15, current v4.1.0
         -> Review stacks/css/tailwind-v4.md

CURRENT:
  [OK] Node.js: v22 (LTS current)
  [OK] OWASP Top 10: 2025 (current)
  [OK] WCAG: 2.2 (current, 3.0 still draft)
  [OK] Vite: v7 (documented)

NOT CHECKABLE (no internet access or tool missing):
  [SKIP] Docker Engine: WebSearch not available

COMMUNITY & INSPIRATION (Tier 5):
  | Repo                | As-of      | Last Commit    | Delta    | Severity |
  |---------------------|------------|----------------|----------|----------|
  | get-shit-done       | 2026-02-20 | 2026-02-25     | 5 days   | OK       |
  | awesome-claude-code | 2026-02-20 | 2026-03-05     | 13 days  | LOW      |
  | obsidian-skills     | 2026-02-20 | 2026-03-15     | 23 days  | MEDIUM   |

  Recommendation: obsidian-skills has new activity — check if new patterns are relevant.

OPPORTUNITIES (Tier 6 — Pipeline Improvements):
  [HIGH] Claude Code v2.2.0: New hook event "PreModelResponse"
         -> Affects: token-warning.sh
         -> Proposal: Context warning before model response instead of after — more precise control
  [MED]  GSD: New "parallel-agent" coordination pattern
         -> Check if relevant for: audit-orchestrator, team workflows
  [LOW]  Astro beta.17: middlewareMode config
         -> Nice-to-have: Deployment could benefit from this
```

### Severity in Delta Report

| Level | Criteria |
|-------|----------|
| **HIGH** | Major/minor version difference, new breaking changes, new regulations |
| **MEDIUM** | Patch version difference, new features (optional), standard updates |
| **LOW** | Cosmetic updates, new best practices |
| **OK** | Up to date |
| **SKIP** | Could not be checked |

---

## Auto-Update Logic

When mode is `update` or `full`:

### What Gets Auto-Updated

1. **Astro Changelog** (`versions/v{x}-beta/changelog.md`):
   - New betas via GitHub Releases or npm
   - Summarize release notes
   - Update as-of date

2. **Astro Checklist** (`versions/v{x}-beta/checklist.md`):
   - Adjust counters if new checks needed
   - Update as-of date
   - Add new breaking changes as checks

3. **Astro Reference Links** (`versions/v{x}-beta/reference-links.md`):
   - Add new PRs
   - Update as-of date

4. **Claude Code Reference** (`docs/claude-code-reference.md`):
   - Update version header
   - Document new features/flags (WebSearch)

### What Gets Marked as Note Only (Manual Review)

- Legal changes (GDPR, accessibility laws, DSA, EU AI Act)
- Security standards (OWASP, CWE, ASVS)
- WCAG version jump (2.2 -> 3.0)
- Major framework migrations (Tailwind v4 -> v5)

**Rule:** NEVER auto-write legal and security-relevant changes into phase files — always enforce manual review.

---

## As-of Date Convention

Every file containing versioned knowledge MUST have an as-of date at the end:

```
As of: YYYY-MM-DD (updated for {version/reason})
```

The freshness check parses this date and compares it with the current state.

**Files with as-of dates:**
- `versions/*/changelog.md`
- `versions/*/checklist.md`
- `versions/*/reference-links.md`
- `docs/claude-code-reference.md`
- `docs/beta-flags.md`
- All phase files with year references (OWASP 2025, WCAG 2.2, etc.)

---

## Integration with Orchestrator

The orchestrator recommends `/freshness-check` automatically:

```
IF last freshness check > 7 days ago OR no check documented:
  -> "Recommendation: /freshness-check before audit start (last check: {date})"
IF last check < 7 days:
  -> No hint, proceed directly to audit plan
```

Freshness state is saved in `.freshness-state.json`:

```json
{
  "lastCheck": "YYYY-MM-DD",
  "mode": "check|update|full",
  "results": {
    "astro-beta": { "status": "ok|outdated|skip", "documented": "beta.14", "current": "beta.16" },
    "astro-stable": { "status": "ok", "documented": "5.17.2", "current": "5.17.2" },
    "tailwind": { "status": "ok", "documented": "4.0.x", "current": "4.0.x" },
    "claude-code": { "status": "outdated", "documented": "2.1.47", "current": "2.2.0" },
    "node": { "status": "ok", "documented": "22", "current": "22.12.0" },
    "owasp": { "status": "ok", "documented": "2025", "current": "2025" },
    "wcag": { "status": "ok", "documented": "2.2", "current": "2.2" },
    "community": {
      "get-shit-done": { "status": "ok", "asOf": "2026-02-20", "latestCommit": "2026-02-19" },
      "obsidian-skills": { "status": "medium", "asOf": "2026-02-20", "latestCommit": "2026-03-15", "note": "23 new commits" }
    }
  },
  "opportunities": [
    { "severity": "high", "source": "claude-code", "feature": "PreModelResponse hook event", "target": "token-warning.sh", "suggestion": "More precise context warning control" },
    { "severity": "med", "source": "get-shit-done", "feature": "Parallel-agent pattern", "target": "audit-orchestrator", "suggestion": "Check if orchestrator logic can be improved" }
  ],
  "summary": {
    "total": 12,
    "ok": 9,
    "outdated": 2,
    "skip": 1,
    "opportunities": 2
  }
}
```

---

## Context Protection

- **Tier 1** (npm): Fast, low context usage — always check
- **Tier 2+3** (WebSearch): More context — only in `full` mode
- **Tier 4** (Ecosystem): Optional — only if relevant for the current project
- **Tier 5** (Community): gh api + optional WebSearch — `full` only
- **Tier 6** (Opportunities): Analyzes changelogs of updates — `full` only, after Tiers 1-5
- Write state immediately after each source
- When context is low: Finish Tier 1, mark rest as "SKIP"

---

## Rules

- **No blind auto-update of laws/standards** — always manual review
- **npm view ALWAYS live** — never from memory
- **Update as-of date in every updated file**
- **Show delta report to user** before auto-updates are applied
- **Freshness check is optional** — audits work without it, but with potentially outdated data
- **Meaningful max once per week** — daily would be overkill (unless a known release is expected)

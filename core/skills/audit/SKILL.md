---
name: audit
description: >
  Systematic website audit (stack detection, 9 phases).
  Use when: "audit", "website audit", "site audit", "check website".
---

<!-- AI-QUICK-REF
## /audit — Quick Reference
- **Modes:** start | continue | status | report | auto
- **Arguments:** `/audit $0` where $0 = mode (e.g. `/audit auto`, `/audit status`)
- **Three-layer:** phases/*.md + stacks/**/*.md + audit-context.md
- **Dual-Layer:** Source (read code) + Live (curl, Lighthouse, Playwright)
- **Check-Priorities:** MUST (mandatory) | SHOULD (standard) | COULD (nice-to-have)
- **9 Phases:** Baseline, Security, Performance, SEO, A11Y, Code, Privacy, Infra, Content
- **Finding-IDs:** IST-01, SEC-01, PERF-01, SEO-01, A11Y-01, CODE-01, GDPR-01, INFRA-01, CD-01
- **Severity:** CRITICAL > HIGH > MEDIUM > LOW
- **Context Protection:** Max 2 phases OR 5 fixes per session (except auto)
- **State:** .audit-state.json (v2.1)
- **Checkpoints:** [CHECKPOINT: verify] after each phase, [CHECKPOINT: decision] at audit scope
-->

# Skill: audit

Systematic website audit with a three-layer depth model.
Automatically detects the stack, loads relevant supplements, and performs
structured checks — for any web project.

---

## Architecture: Three-Layer Model

```
Layer 1: Base Phase (phases/*.md)           ~50 lines, universal
Layer 2: Stack Supplement (stacks/*/*.md)   ~80 lines, framework-specific
Layer 3: Project Override (audit-context.md) ~20-40 lines, project-specific
```

Per phase, only the relevant supplements are loaded.
Result: ~100-140 lines of check instructions per phase — comparable to a dedicated skill.

---

## Dual-Layer: Source + Live

Each phase has two check levels:

| Layer | Method | Example |
|-------|--------|---------|
| **Source-Layer** | Read code/config, grep, AST | Check `package.json`, read CSP in config |
| **Live-Layer** | Browser/tool-based | `curl -sI`, Lighthouse, Playwright, axe-core |

**Rule:** A check is only considered complete when BOTH layers have been verified (where applicable).
Example: "CSP configured" (Source) + "CSP header is actually sent" (Live) = complete.

Not all checks have both layers — e.g. "TypeScript strict mode" is purely source.
During phase execution, document which layer was checked per check.

---

## Check Priorities + Completeness Tracking

> See `_shared/audit-patterns.md` (MUST/SHOULD/COULD markers, completeness counting).
Phase with <100% MUST-checks can NOT be marked as `done`.

---

## 5 Modes

| Mode | Trigger | Description |
|------|---------|-------------|
| `start` | `/audit start` | Detect stack, create phase plan, execute first 2 phases |
| `continue` | `/audit continue` | Continue next phases or fix max 5 findings |
| `status` | `/audit status` | Show progress, statistics, open findings |
| `report` | `/audit report` | Generate structured Markdown report |
| `auto` | `/audit auto` | Fully autonomous run — all phases + fixes without prompts |

---

## Mode: start

### Step 1 — Auto-Detection (no user input needed)

Scan files and detect stack:

| File/Pattern | Detects | Stack-Key |
|-------------|---------|-----------|
| `package.json` > `astro` | Astro | `frontend: "astro"` |
| `package.json` > `@sveltejs/kit` | SvelteKit | `frontend: "sveltekit"` |
| `package.json` > `svelte` (without Kit) | Svelte (standalone) | `frontend: "svelte"` |
| `package.json` > `next` | Next.js | `frontend: "next"` |
| `package.json` > `nuxt` | Nuxt | `frontend: "nuxt"` |
| `hugo.toml` / `config.toml` with Hugo | Hugo | `frontend: "hugo"` |
| `package.json` > `fastify` | Fastify | `backend: "node-fastify"` |
| `package.json` > `express` | Express | `backend: "node-express"` |
| `svelte.config.js` + `@sveltejs/adapter-node` | SvelteKit Server | `backend: "node-sveltekit"` |
| `package.json` > `tailwindcss` | Tailwind CSS | `css: "tailwind"` |
| `tailwind.config.*` OR `@import "tailwindcss"` | Tailwind v4 | `css: "tailwind-v4"` |
| `Dockerfile` / `docker-compose.*` | Docker | `deployment: ["docker"]` |
| `traefik.*` / Labels with `traefik` | Traefik | `deployment: +["traefik"]` |
| `nginx.conf` / `/etc/nginx/` | nginx | `deployment: +["nginx"]` |
| `*.db` / `better-sqlite3` / `sqlite3` | SQLite | `database: "sqlite"` |
| `package.json` > `drizzle-orm` / `pg` / `postgres` | PostgreSQL + Drizzle | `database: "postgresql"` |
| `docker-compose.*` > `postgres` image | PostgreSQL (Docker) | `database: "postgresql"` |
| `package.json` > `bcryptjs` / `bcrypt` / `argon2` | Auth (Custom) | `auth: "custom"` |
| `playwright.config.*` | Playwright | `testing: ["playwright"]` |
| `.github/workflows/` | GitHub Actions | `ci: "github-actions"` |

**Version Detection:** For each detected stack, extract version from package.json or config.
Tailwind v4 detection: `@import "tailwindcss"` in CSS OR tailwindcss >= 4.0 in package.json.

### Step 2 — Context Enrichment

1. **Project CLAUDE.md** read (if available) — architecture, conventions
2. **audit-context.md** load (if in project root) — project-specific context
3. **Existing docs** scan: `AUDIT-FINDINGS*.md`, `TODO*.md`, `GO-LIVE*.md`
4. **{{REGISTRY_FILE}}** match: If project name is in project registry > identify assigned servers
5. **Existing state file** (.audit-state.json) check > auto-migrate if v1 (see State-Migration)

### Step 3 — User Query

Show detection result as table:

```
Stack Detection:
+-------------+------------------+---------+
| Category    | Detected         | Version |
+-------------+------------------+---------+
| Frontend    | Astro            | 6.x     |
| CSS         | Tailwind CSS v4  | 4.x     |
| Deployment  | Docker, Traefik  | —       |
| Testing     | Playwright       | —       |
+-------------+------------------+---------+

Detected servers: {{SERVER_NAMES}}
Project context: audit-context.md found
Existing docs: AUDIT-FINDINGS-2026-02-13.md, TODO-SEO.md
```

Then ask user (AskUserQuestion):
- **Audit scope:** Complete (all 9 phases) vs. focused (specific phases)
- **External repos:** Include related projects? (if defined in audit-context.md)
- **Server access:** Enable SSH checks? (if servers detected)
- **Phase order:** Sequential (01>08, default) vs. Smart Order (Security>Performance>Code>Rest, recommended)

**[CHECKPOINT: decision]** — User selects audit scope and phase order.

### Step 4 — Create state file and start first 2 phases

Create state file `.audit-state.json` (schema see below).
Then execute the first 2 phases according to phase execution flow.

---

## Mode: continue

1. Read `.audit-state.json`
2. Identify next pending phase(s)
3. Generate **smart recommendation** (see below)
4. User chooses: follow recommendation, different phase, or fix findings
5. Write state immediately after each phase/fix

### Smart Recommendation

> Decision logic: See `_shared/audit-patterns.md` (CRITICAL>HIGH>Phases>Remaining).
Show recommendation as **first option** in AskUserQuestion.

### Fixing Findings

- Always fix highest severity first: CRITICAL > HIGH > MEDIUM > LOW
- Per fix: Show problem > **Load fix template** (if in `fix-templates.md`) > User confirmation > Implement > Test
- Update fix status in state (`"status": "fixed"`, `"fixedIn": "Session N"`)
- **No auto-fix** — every fix requires user confirmation (except `auto` mode)

**[CHECKPOINT: verify]** — After each fix: show result, user confirms.

---

## Mode: status

Read state file and display:

```
Audit: Project Name (started YYYY-MM-DD)
Stack: Astro 6, Tailwind v4, Docker, Traefik

Phases:
  [done] 01 Baseline Analysis (Session 1, 3 Findings, MUST 100%)
  [done] 02 Security (Session 1, 5 Findings, MUST 100%)
  [wip]  03 Performance (in progress)
  [wait] 04 SEO
  [wait] 05 Accessibility
  [wait] 06 Code Quality
  [wait] 07 Privacy/GDPR
  [wait] 08 Infrastructure
  [wait] 09 Content & Design

Findings: 8 total
  CRITICAL: 1 (open: 1)
  HIGH: 3 (open: 2, fixed: 1)
  MEDIUM: 3 (open: 3)
  LOW: 1 (open: 1)

Completeness:
  MUST-Checks: 28/28 (100%)
  Total: 42/50 (84%)
  Layer: Source done, Live done (2 phases)
```

---

## Mode: report

Generate structured Markdown report based on `templates/report.md`.

1. Read state file
2. Group all findings by phase
3. Report with Executive Summary, Findings per Phase, Recommendations
4. **Include trend analysis** (if history available):
   ```
   Trend (recent audits):
     CRITICAL: 5 > 2 > 0  (resolved)
     HIGH:     8 > 6 > 4  (declining)
     MEDIUM:  12 > 10 > 7  (declining)
     Total:   25 > 18 > 11
   Assessment: Project is steadily improving.
   ```
5. Save report as `AUDIT-REPORT-{YYYY-MM-DD}.md` in project root
6. If previous reports exist: Diff section (new/resolved since last report)

---

## Mode: auto

Fully autonomous audit run without prompts. For experienced users who
want the entire audit in one go.

### Flow

1. **Check orchestrator context:** If `.audit-orchestrator-state.json` exists:
   - Read `phaseMapping.audit.delegated` > skip delegated phases
   - Read `sequencingReason` > understand context
   - **Example:** If `code-quality` delegated to `/project-audit` > skip Phase 06
2. Auto-detection as in `start`
3. **All phases** run through (no 2-phase limit, skip delegated phases)
4. Document findings with fix templates from `fix-templates.md`
5. **Context management:** When context is running low:
   - Write state immediately
   - Create task in `.tasks.json` with handoff note
   - Recommend: "New session with `/audit continue`"
5. At the end: automatically generate report

### Context Protection in Auto Mode

- Findings are collected but **not fixed immediately** (documented only)
- Per phase: If >10 findings > close phase, start next
- Write state after EVERY phase immediately
- At context limit: clean abort with complete state
- Fixes can be done in follow-up sessions with `/audit continue`

### When to Recommend Auto Mode

- User says "check everything", "fully autonomous", "full audit"
- Auditing multiple projects in sequence
- First overview of a new project

---

## Phase Execution

For each phase:

1. **Load base:** Read `phases/{NN}-{name}.md` — universal check items
2. **Load supplements:** For each detected stack, load the matching file, ONLY the section relevant to the current phase

   | Phase | Supplement Sections |
   |-------|-------------------|
   | 01-baseline-analysis | §Baseline-Analysis |
   | 02-security | §Security |
   | 03-performance | §Performance |
   | 04-seo | §SEO |
   | 05-accessibility | §Accessibility |
   | 06-code-quality | §Code-Quality |
   | 07-privacy | §Privacy |
   | 08-infrastructure | §Infrastructure |
   | 09-content-design | §Content-Design |

3. **Project override:** If `audit-context.md` exists > include relevant section
4. **Existing findings:** Check previous audit docs, do not create duplicates
5. **Execute checks:** Systematically work through all loaded checks
   - Source layer: Read and analyze code/config
   - Live layer: Execute tools (curl, Lighthouse, Playwright, axe) where applicable
6. **Document findings:** Each finding with ID, severity, description, location
7. **Count completeness:** MUST/SHOULD/COULD checks (executed vs. skipped)
   - Skipped MUST-checks: document reason
   - Phase with <100% MUST-checks: status remains `in-progress`
8. **Update state:** Set phase status to `done`, enter findings + completeness

**[CHECKPOINT: verify]** — After each phase: show findings + completeness to user, get confirmation.

### Finding-IDs

| Phase | Prefix | Example |
|-------|--------|---------|
| 01-baseline-analysis | `IST` | IST-01 |
| 02-security | `SEC` | SEC-01 |
| 03-performance | `PERF` | PERF-01 |
| 04-seo | `SEO` | SEO-01 |
| 05-accessibility | `A11Y` | A11Y-01 |
| 06-code-quality | `CODE` | CODE-01 |
| 07-privacy | `GDPR` | GDPR-01 |
| 08-infrastructure | `INFRA` | INFRA-01 |
| 09-content-design | `CD` | CD-01 |

### Severity Definitions

| Level | Criteria | Examples |
|-------|----------|----------|
| **CRITICAL** | Security vulnerability, data loss, outage | Open port, missing auth, SQL Injection |
| **HIGH** | Functional bug, performance >2s, missing validation | LCP >4s, no rate limiting, XSS |
| **MEDIUM** | Code quality, missing tests, UX issue | Missing alt texts, no error handling |
| **LOW** | Cosmetic, best practice, nice-to-have | Outdated dependency, missing docs |

**Prioritization:** CRITICAL > HIGH > MEDIUM > LOW. Security before functional before visual.

---

## State Schema v2.1 (.audit-state.json)

> Complete state schema (JSON example) + migrations v1>v2 and v2>v2.1: See **state-schema.md**

---

## Supplement Loading Logic

Per phase, the skill loads only relevant stack supplements.
Each stack file is structured by sections.

**Example Phase 02-security:**
```
> Always: phases/02-security.md (base)
> If frontend=astro: + stacks/frontend/astro.md §Security
> If css=tailwind-v4: (no Security section > load nothing)
> If deployment includes docker: + stacks/deployment/docker.md §Security
> If deployment includes traefik: + stacks/deployment/traefik.md §Security
> If backend=node-fastify: + stacks/backend/node-fastify.md §Security
> If database=sqlite: + stacks/database/sqlite.md §Security
> If testing includes playwright: + stacks/testing/playwright.md §Security
```

**Supplement file locations:**

| Stack-Key | Supplement Path |
|-----------|----------------|
| `frontend: "astro"` | `stacks/frontend/astro.md` |
| `frontend: "sveltekit"` | `stacks/frontend/sveltekit.md` |
| `frontend: "next"` | `stacks/frontend/next.md` |
| `frontend: "hugo"` | `stacks/frontend/hugo.md` |
| `backend: "node-fastify"` | `stacks/backend/node-fastify.md` |
| `backend: "node-sveltekit"` | `stacks/backend/node-sveltekit.md` |
| `css: "tailwind-v4"` | `stacks/css/tailwind-v4.md` |
| `deployment: "docker"` | `stacks/deployment/docker.md` |
| `deployment: "traefik"` | `stacks/deployment/traefik.md` |
| `deployment: "nginx"` | `stacks/deployment/nginx.md` |
| `database: "sqlite"` | `stacks/database/sqlite.md` |
| `database: "postgresql"` | `stacks/database/postgresql.md` |
| `testing: "playwright"` | `stacks/testing/playwright.md` |

If a stack is detected but no supplement exists > use base phase only, no error.

---

## Phase Order

Two modes for the order of phases:

### Sequential (Default)
`01-baseline-analysis > 02-security > 03-performance > 04-seo > 05-accessibility > 06-code-quality > 07-privacy > 08-infrastructure > 09-content-design`

### Smart Order (Recommended)
Prioritized by impact — finds critical issues first:
`02-security > 03-performance > 08-infrastructure > 01-baseline-analysis > 06-code-quality > 04-seo > 05-accessibility > 07-privacy > 09-content-design`

**Logic:** Security issues are most urgent, followed by performance (user impact),
then infrastructure (stability). SEO/A11y/Privacy are important but less time-critical.

User chooses at `start`. Store in state as `"phaseOrder": "sequential"` or `"smart"`.

---

## Fix Templates

For common findings there are ready-made fix templates in `fix-templates.md`.
Per finding type: code snippet, config change, verify step.

**Usage:** When a finding matches a template:
1. Load template from `fix-templates.md`
2. Adapt to project
3. Get user confirmation
4. Implement and verify

---

## Verification-Depth + Fix Protocol

> See `_shared/audit-patterns.md` (4-Level Verification, Stub-Detection, 5-Step Fix-Protocol).
Level 4 (Functional) is mandatory when live layer is available. READ + VERIFY never skip.

---

## Context Protection (CRITICAL)

> Base rules: See `_shared/audit-patterns.md` (Max 2 phases, state immediately, no auto-fix).

**Website audit specific:**
- **SSH readonly** during audit — write only during explicit fix with user confirmation
- **Dual-Layer:** Per phase, document whether source layer, live layer, or both were checked

---

## Smart Next Steps

After completing the audit (report generated or all phases done), recommend suitable follow-up skills to user. Recommendations based on findings and detected stack:

| Condition | Recommendation | Justification |
|-----------|---------------|---------------|
| Astro project detected | `/astro-audit` | Check version-specific migration/best-practices |
| SvelteKit project detected | `/sveltekit-audit` | SvelteKit/Svelte 5 version checks + best practices |
| PostgreSQL/Drizzle detected | `/db-audit` | Database schema, migrations, security, performance |
| Custom auth detected (bcryptjs etc.) | `/auth-audit` | Auth security, session management, OWASP ASVS |
| >3 HIGH/CRITICAL findings | `/adversarial-review audit` | Check report for completeness |
| Phase 09 (Content) findings >0 | `/polish scan` | Design improvements based on findings |
| Audit completed | `/lesson-learned session` | Extract learnings from audit process |
| No /project-audit state present | `/project-audit start` | Check code/CI/CD quality |

**Output in report:** Replace `{NEXT_STEPS}` placeholder with concrete recommendation list.

**Output after last phase:** "Next steps:" + 2-3 most relevant recommendations.

---

## Files in This Skill

```
audit/
├── SKILL.md                    <- This file
├── state-schema.md             # State Schema v2.1 + Migrations
├── fix-templates.md            # Quick-Fix templates for common findings
├── phases/
│   ├── 01-baseline-analysis.md # Versions, Config, Architecture
│   ├── 02-security.md          # OWASP, Headers, Secrets, Auth
│   ├── 03-performance.md       # Lighthouse, CWV, Caching, Images
│   ├── 04-seo.md               # Meta, Structured Data, Sitemap
│   ├── 05-accessibility.md     # WCAG AA, Contrast, ARIA, Keyboard
│   ├── 06-code-quality.md      # Linting, Types, Dependencies
│   ├── 07-privacy.md           # Cookies, Fonts, Analytics
│   ├── 08-infrastructure.md    # VPS, Docker, Proxy, Backup
│   └── 09-content-design.md    # Content, Typography, Colors, Consistency
├── stacks/
│   ├── frontend/astro.md       # Astro-specific checks
│   ├── frontend/sveltekit.md   # SvelteKit-specific checks
│   ├── frontend/next.md        # Next.js-specific checks
│   ├── frontend/hugo.md        # Hugo-specific checks
│   ├── backend/node-fastify.md # Fastify-specific checks
│   ├── backend/node-sveltekit.md # SvelteKit server-side checks
│   ├── css/tailwind-v4.md      # Tailwind v4-specific checks
│   ├── deployment/docker.md    # Docker-specific checks
│   ├── deployment/traefik.md   # Traefik-specific checks
│   ├── deployment/nginx.md     # nginx-specific checks
│   ├── database/sqlite.md      # SQLite-specific checks
│   ├── database/postgresql.md  # PostgreSQL + Drizzle checks
│   └── testing/playwright.md   # Visual & E2E testing checks
└── templates/
    └── report.md               # Markdown report template
```

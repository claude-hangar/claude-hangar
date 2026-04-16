---
name: audit-orchestrator
description: >
  Universal Pre-Scan → Analysis → Optimization → Report orchestrator for ANY project type —
  web apps (Astro/SvelteKit/Next), infrastructure/homelab repos, CLI tools, libraries,
  backend services, monorepos, data/ML projects, docs. Self-detects project type and runs
  the matching analysis track. Session state lives in `.audit-session/<date>-<slug>/` with
  INDEX.md + STATUS.md so any instance (or a different LLM) can resume after a crash.
  Delegates to /audit + /project-audit + /astro-audit + /sveltekit-audit + /db-audit +
  /auth-audit for web projects. Use when: "full audit", "audit everything", "complete audit",
  "infra audit", "homelab audit", "repo audit", "orchestrate audit", "pre-scan analysis
  optimization report".
effort: high
user-invocable: true
argument-hint: "report | resume | <session-slug>"
---

<!-- AI-QUICK-REF
## /audit-orchestrator — Quick Reference
- **Universal mode (default)** — works for any project type via self-detection
- **Four phases:** 01-prescan → 02-analysis → 03-optimization → 04-report (each with its own folder)
- **Session directory:** `.audit-session/<YYYY-MM-DD>-<slug>/` with INDEX.md + STATUS.md
- **Resume protocol:** any instance reads STATUS.md → continues where prior stopped
- **Project-type detection:** web (astro/sveltekit/next), infra (docker/iac/homelab), lang (py/go/rust/node), monorepo, docs, data-ml, generic
- **Web specialization:** delegates to /audit, /{framework}-audit, /project-audit, /db-audit, /auth-audit
- **Execution Modes:** Team (parallel) | Manual (sequential) | Runner (autonomous)
- **Legacy state:** .audit-orchestrator-state.json (v3) still written for web-framework path
-->

# /audit-orchestrator — Universal Orchestrator

Meta-skill that runs a project through **Pre-Scan → Analysis → Optimization → Report** on any kind of codebase. Self-detects the project type, picks the right analysis track, and writes all state into a resumable session directory.

## Two Modes

| Mode | When | What runs |
|------|------|-----------|
| **Universal (default)** | Any project — infra, homelab, CLI, library, monorepo, docs, data/ML, web, generic | Four-phase workflow, project-profile-driven analysis track (see `universal-workflow.md`) |
| **Web Orchestration (specialization)** | Project detected as `web-astro`, `web-sveltekit`, or `web-nextjs` | Same four phases, but Phase 2 delegates to `/audit` + `/{framework}-audit` + `/project-audit` + optional `/db-audit` / `/auth-audit` per the rules below |

The universal mode is always entered first. If Phase 1 (Pre-Scan) detects a supported web framework, Phase 2 activates the web orchestration path. For any other project type, Phase 2 runs the general + specialty analysis tracks described in `universal-workflow.md`.

## Session Directory

Every run creates `.audit-session/<YYYY-MM-DD>-<slug>/` with:

```
INDEX.md                 # TOC + navigation
STATUS.md                # Live session state — read first on resume
01-prescan/              # detection + project profile
02-analysis/             # findings + opportunities + fix queue
03-optimization/         # applied changes + deferred + deviations
04-report/REPORT.md      # canonical deliverable
```

- Full directory schema + file templates: **`session-schema.md`**.
- Phase-by-phase execution (inputs, actions, outputs, exit criteria): **`universal-workflow.md`**.
- Legacy web-specific state (`.audit-orchestrator-state.json` v3): **`state-schema.md`** (still written when the web orchestration path is active; coexists with the session directory).

## Resume Protocol (Crash / Handoff / New Instance)

A fresh LLM or a different AI (or the same instance after a crash) picks up a session like this:

1. `ls .audit-session/` → find the target session directory.
2. Read `INDEX.md` — understand the structure.
3. Read `STATUS.md` — learn the current phase, state, and "next action".
4. Claim the session: update STATUS.md `active instance` and `last updated` before the first tool call.
5. Continue from the next-action line.

**STATUS.md is always current.** It is updated at every phase transition and after every ~5 fix commits in Phase 3, and flipped to `paused` on exit. Because findings/TODOs/changes live in phase folders as plain Markdown, the entire session is portable — another LLM, or the user reading by hand, can pick it up without running any tool.

## Problem solved by this skill

An Astro project needs:
- `/audit` for performance, SEO, a11y, privacy compliance, security
- `/astro-audit` for version-specific migration/best practices
- `/project-audit` for Git, CI/CD, testing, maintenance

Without orchestration: user must decide manually, duplicate work on security/infra.

An infra/homelab repo needs different things again (Docker hygiene, Compose V2, Traefik, service inventory vs. running services, backup state, cert expiry) — the orchestrator detects this and runs the infra track instead.

## Problem

An Astro project needs:
- `/audit` for performance, SEO, a11y, privacy compliance, security
- `/astro-audit` for version-specific migration/best practices
- `/project-audit` for Git, CI/CD, testing, maintenance

Without orchestration: user must decide manually, duplicate work on security/infra.

## Solution: Auto-Detection + Audit Plan

### Step 0 — Session Init (always)

Before any detection, create the session directory:

1. Slug = `<YYYY-MM-DD>-<short-descriptor>` (see `session-schema.md`).
2. Create `.audit-session/<slug>/` with empty phase folders.
3. Write initial `INDEX.md` (phases all `pending`) and `STATUS.md` (`state: in_progress`, `phase: 01-prescan`, `next action: detect project type`).
4. From this point on, **every phase transition and every ~5 fixes updates STATUS.md**. This is what makes the session crash-resilient.

### Step 1 — Scan Project

Same detection as `/audit` + `/project-audit`, plus universal signals:
- package.json, pyproject.toml, go.mod, Cargo.toml, Dockerfile, docker-compose*.yml, .tf, ansible.cfg, .github/, .claude/, registry.json
- Detect frontend framework (Astro, Next, SvelteKit, Hugo, etc.)
- Detect backend (Fastify, Express, FastAPI, etc.)
- Detect **project type** using the universal decision table in `universal-workflow.md`:
  web-astro | web-sveltekit | web-nextjs | node-app | node-lib | python | go | rust |
  infra-docker | infra-iac | infra-homelab | meta-automation | monorepo | docs | data-ml | generic
- **Detect output mode:** `output: "static"` vs. `output: "server"` (from astro.config.*) — web only
- **Related projects:** `audit-context.md` → check `relatedProjects` (e.g., forms backend)
- **Detect beta/unstable version:** Version with `-beta`, `-rc`, `-alpha` suffix → prioritize migration audit

Write the result to `01-prescan/project-profile.md` using the profile template (see `session-schema.md`). The profile drives Phase 2 track selection:

| Detected project type | Phase 2 tracks |
|-----------------------|----------------|
| web-astro / web-sveltekit / web-nextjs | general + web-framework (delegates to existing /audit orchestration below) |
| infra-docker | general + infra (Docker hygiene, Compose V2, rootless, secrets) |
| infra-iac | general + infra (tf/tofu/ansible state, drift, secrets) |
| infra-homelab | general + infra + ops (inventory vs. live, certs, backups, disk, retention) |
| python / go / rust / node-app / node-lib | general + language-specific (lint, types, tests, CVEs, build repro) |
| monorepo | general + per-package loop (each package under `02-analysis/packages/<name>/`) |
| docs | general + docs (link rot, meta, freshness, structure) |
| data-ml | general + data-ml (deps, notebooks, reproducibility, dataset provenance) |
| meta-automation | general + ci (workflow sanity, pinned actions, secret scopes) |
| generic | general only |

**Rule:** The general track (git hygiene, CI sanity, secret scan, dependency freshness, license posture, docs freshness) runs for every project. Specialty tracks are additive.

### Step 1b — Infrastructure Scan (Pre-Audit)

Before starting project audits, check infrastructure level:

**Detect GitHub:**
- `.github/` directory present → `github: true`
- `git remote -v` → github.com → extract repo owner + name
- Detect organization: `gh api repos/{owner}/{repo}` → `owner.type == "Organization"`

**Detect VPS:**
- `audit-context.md` → server section present?
- `registry.json` → server assignment for the project?
- Dockerfile/docker-compose present → deployment on server likely

**Pre-Audit Recommendation:**

| Detected | Recommendation | Reason |
|----------|---------------|--------|
| GitHub + VPS | "Infra first: check GitHub settings + VPS hardening" | Insecure platform makes code audit pointless |
| GitHub only | "Check GitHub settings in /project-audit (github.md supplement)" | Branch protection, secret scanning etc. |
| VPS only | "VPS deep security in /audit Phase 08" | Open ports, users, logging etc. |
| Neither | Standard process | No infra check needed |

**Freshness Check + Opportunities:**

| Condition | Recommendation |
|-----------|---------------|
| Last `/freshness-check` > 7 days | "Recommendation: `/freshness-check` before audit start" |
| Last check < 7 days | No hint, proceed to audit plan |
| No check documented | "Recommendation: `/freshness-check full` (first run)" |

**Prior Context — Freshness Opportunities:**
If `.freshness-state.json` exists, read `opportunities[]` array:
- Include HIGH opportunities as "Pre-Audit Notes" in the audit plan
- **Example:** Opportunity `{ severity: "high", target: "audit/phases/02-security.md" }` → "Note: Security phase has new best practices since last freshness check"
- Opportunities are NOT automatically fixed — only provided as context for the audits

**Rule:** With GitHub + VPS, the **first session** is recommended for infra checks:
1. GitHub org settings (once per org, not per repo)
2. GitHub repo settings (branch protection, secret scanning)
3. VPS quick check (ports, users, SSH, fail2ban)
4. Only then: regular audit sessions

Infra findings are documented with prefix `INFRA-` (VPS) or `SEC-` / `GIT-` (GitHub) — in the respective audit state files, not in the orchestrator state.

### Step 1c — Security Pre-Scan (Claude Code Projects)

When `.claude/` directory is detected in the project:

| Check | Action |
|-------|--------|
| `.claude/settings.json` exists | Recommend `/security-scan mcp` before audit |
| `.claude/hooks/` has custom hooks | Recommend `/security-scan hooks` before audit |
| Both present | Recommend `/security-scan` (full) as Pre-Audit step |

**Rationale:** Compromised hooks or MCP servers could manipulate audit results.
Verify the Claude Code environment is clean before trusting audit output.

**Integration:** Security scan findings feed into the audit plan:
- CRITICAL security-scan findings → address before starting audit
- MCP permission issues → note in audit report context
- Hook safety issues → fix before running automated audit modes

### Step 2 — Determine Audit Combination

| Project Type | Recommended Audits | Reason |
|-------------|-------------------|--------|
| Astro Website (static) | `/audit` + `/astro-audit` (reduced) | Web quality + Astro specifics, skip ADPT section |
| Astro Website (SSR) | `/audit` + `/astro-audit` | Web quality + Astro specifics (all sections) |
| Astro + Backend (e.g., Fastify) | `/audit` + `/astro-audit` + `/project-audit` | Everything — backend needs its own checks |
| SvelteKit App (SSR) | `/audit` + `/sveltekit-audit` + `/project-audit` | Web quality + SvelteKit specifics + code/CI |
| SvelteKit App (prerendered) | `/audit` + `/sveltekit-audit` (reduced) | Skip SSR sections when `prerender = true` |
| SvelteKit + Drizzle/PostgreSQL | `/audit` + `/sveltekit-audit` + `/db-audit` + `/project-audit` | Full stack — DB needs its own checks |
| SvelteKit + Auth | Above + `/auth-audit` | Custom auth always check separately |
| Next.js Website | `/audit` + `/project-audit` (reduced) | Web quality + code/CI/CD |
| Hugo Website | `/audit` | Web quality only (static, little code) |
| Backend Service (no web) | `/project-audit` + `/db-audit` (if DB) | No SEO/a11y needed |
| CLI Tool / Library | `/project-audit` | Code/Git/CI/CD only |
| Management Repo | `/project-audit` | Structure/docs/scripts only |
| Monorepo | `/project-audit` + per sub-project | Each package individually |

**Always add when detected:**

| Condition | Additional Audit | Reason |
|-----------|-----------------|--------|
| `.claude/` directory present | `/security-scan` (pre-audit) | Verify Claude Code environment before audit |
| Phase 09 content findings expected | `/design-system` reference | Use curated palette/typography/UX databases for content checks |

### Step 2b — Static Site Filter (Astro)

When `output: "static"` is detected, certain checks are irrelevant:

| Section/Check | Reason for Skip |
|--------------|-----------------|
| ADPT-01 to ADPT-04 (Adapter) | Static needs no adapter |
| Session Driver Checks | No server sessions with static |
| SSR-specific Security Checks | No server-side code |
| `allowedDomains` Checks | SSR-only relevant |

**Rule:** Mark skipped checks in state file as `"status": "skipped", "reason": "static-output"`.

### Step 2c — Related Projects (Cross-Repo)

When `audit-context.md` references related projects (e.g., forms backend):

1. **Recommend separate audit:** Related projects have their own codebase → separate `/audit` or `/project-audit`
2. **Check interfaces:** In the main audit, check integration:
   - API communication (CORS, auth, timeouts)
   - Shared infrastructure (same server, reverse proxy routing)
   - Credential management (shared secrets)
3. **Cross-references in state:** `relatedProjects` array with status ("audited", "open", "not in scope")

### Step 2d — Checkpoint Gates between Audit Phases

In team mode and complex multi-audit runs: use checkpoint gates to ensure quality between phases.

| Gate | Timing | Check | Action on Failure |
|------|--------|-------|--------------------|
| **Pre-Audit Gate** | Before audit start | Freshness check current? Infra scan done? | Postpone audit until pre-audit done |
| **Migration Gate** | After framework audit | All CRITICAL MIG findings fixed? Build OK? | Don't start /audit until build is green |
| **Security Gate** | After /audit Phase 02 | No CRITICAL SEC findings open? | Warning to team lead, prioritize fixing |
| **Compliance Gate** | After /audit Phase 07 | Privacy/accessibility mandatory checks passed? | CRITICAL finding → fix immediately |
| **Pre-Report Gate** | Before combined report | All audits completed? State files consistent? | Report only after completeness |

**Checkpoint Logic in Team Mode:**
1. Teammate reports audit phase as done
2. Orchestrator checks gate conditions for next phase
3. Gate passed → next audit/phase is released
4. Gate not passed → orchestrator informs user + blocks next phase

**Rules:**
- Gates are recommendations, not hard blocks — user can skip gates
- CRITICAL findings in security/compliance gates are always reported
- Migration gate is HARD — with a broken build, no web audit is worthwhile
- Pre-report gate is HARD — incomplete reports are misleading

### Step 3 — Manage Phase Overlap

Some phases exist in both audits but check **different aspects**.
Do not delegate wholesale — instead clearly separate the focus:

| Phase | `/audit` Focus | `/project-audit` Focus | Recommendation |
|-------|---------------|------------------------|---------------|
| Security | Web security: OWASP, headers, SRI, SSRF, security.txt, CORP/COOP | Supply chain: SBOM, ASVS, Sigstore, npm provenance, container signing | **Both run** — complementary |
| Infra / Deployment | VPS, Docker, Compose V2, rootless, proxy, monitoring | Container signing, SBOM in image, OCI annotations | **Both run** — complementary |
| Code Quality | Linting, types (basic) | Patterns, complexity, dead code, coverage (thorough) | `/project-audit` leads, `/audit` skips |
| Dependencies | Version check in status analysis (basic) | Lockfiles, package managers, corepack, provenance (thorough) | `/project-audit` leads, `/audit` status stays (version overview only) |

**Rule:** Phases with different focus BOTH run. Only with true duplicates (same checks) does the more thorough one lead.

### Step 4 — Intelligent Sequencing

The order of audits depends on the detected project:

| Condition | Recommended Order | Reason |
|-----------|-------------------|--------|
| Framework beta/RC version | Framework audit → `/audit` → `/project-audit` | Migration breaking changes first — a broken build blocks everything |
| Framework stable (major upgrade needed) | Framework audit → `/audit` → `/project-audit` | Upgrade before quality audit |
| Framework stable (current) | `/audit` → framework audit → `/project-audit` | Web quality first, then framework best practices |
| SvelteKit + Drizzle + Auth | `/db-audit` → `/auth-audit` → `/sveltekit-audit` → `/audit` → `/project-audit` | DB foundation → auth security → framework → web quality → code |
| SvelteKit (without DB/Auth) | `/sveltekit-audit` → `/audit` → `/project-audit` | Framework checks → web quality → code |
| No framework-specific audit | `/audit` → `/project-audit` | Standard order |
| Backend only + DB | `/db-audit` → `/project-audit` | DB foundation → code |
| Backend only | `/project-audit` | Single audit |

**Rule:** With beta/RC versions ALWAYS run the migration audit first — a build that doesn't compile makes any other audit pointless.

### Step 5 — Show Audit Plan to User

Dynamic plan based on detection. Example for different scenarios:

**Scenario A: Framework Beta + Static + Docker + GitHub + VPS**
```
Audit Plan for: {{PROJECT_NAME}}

Detected: {{FRAMEWORK}} {{VERSION}} (Beta) + Tailwind v4 + Docker + Reverse Proxy
Output: static (no SSR)
GitHub: {{ORG}}/{{REPO}} (Organization)
Server: {{SERVER_LIST}}
Related Projects: {{RELATED_NAME}} ({{RELATED_STACK}})
Recommendation: Pre-audit infra → Framework migration → Web quality → Code/CI

Pre-Audit: Freshness + Security + Infrastructure (1 session)
  /freshness-check        ← Pipeline knowledge current? Versions, standards, regulations
  /security-scan           ← Claude Code environment: MCP permissions, hook safety, secrets
  GitHub Org Settings     ← 2FA, base permissions, third-party access
  GitHub Repo Settings    ← Branch protection, secret scanning, CodeQL
  VPS Quick Check         ← Ports, users, SSH, fail2ban, services
  → Secure foundation before checking code

Audit 1: /{{FRAMEWORK}}-audit (migration checks) ← PRIORITY
  {N} sections, of which {M} relevant (ADPT section skip: static)
  Ensure breaking changes and build compatibility
  → Must run before web audit — broken build blocks everything

Audit 2: /audit (9 phases — web quality)
  01 Status Analysis      ← Baseline (version overview)
  02 Security             ← Web security (OWASP, headers, SRI, SSRF)
  03 Performance          ← Exclusive (CWV, Lighthouse, caching)
  04 SEO                  ← Exclusive (meta, structured data, sitemap)
  05 Accessibility        ← Exclusive (WCAG 2.2, accessibility regulations)
  07 Privacy              ← Exclusive (consent, cookie regulations)
  08 Infrastructure       ← VPS deep security + Docker + proxy
  09 Content & Design     ← Content, typography, colors, consistency
  (06 Code Quality       → delegated to /project-audit)

Audit 3: /project-audit (10 phases — code/CI/CD)
  02 Dependencies         ← Leads (lockfiles, corepack, provenance)
  03 Code Quality         ← Leads (patterns, coverage, complexity)
  04 Git & Versioning     ← Exclusive (+ GitHub supplement)
  05 CI/CD & Automation   ← Exclusive (OIDC, attestation, SLSA, + GitHub supplement)
  07 Testing & QA         ← Exclusive (coverage, E2E)
  08 Security             ← Supply chain (SBOM, ASVS, Sigstore, + GitHub supplement)
  09 Deployment           ← Container signing, SBOM in image, OCI (+ GitHub environments)
  10 Maintenance          ← Exclusive (+ GitHub supplement)
  (01 Structure          → status in /audit)

Related Projects:
  {{RELATED_NAME}}: Separate /project-audit recommended, check interfaces in main audit

Estimated Sessions: {calculated}
Shall I start?
```

**Scenario B: Framework Stable + SSR (without VPS access)**
```
...
Recommendation: Security scan → GitHub check → Web quality → Framework best practices

Pre-Audit: /security-scan + GitHub settings (in session 1)
Audit 1: /audit (8 phases) ← FIRST
Audit 2: /{{FRAMEWORK}}-audit (all sections incl. ADPT)
Audit 3: /project-audit (10 phases, with GitHub supplement)
...
```

### Step 5b — Choose Execution Mode

After the audit plan, the orchestrator asks how the audits should be executed.

**Offer options:**

| Mode | Prerequisite | Description |
|------|-------------|-------------|
| **Team (parallel)** (Recommendation) | `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` set | Orchestrator spawns teammates, audits run in parallel as team |
| **Manual (sequential)** | Always available | User starts each audit individually in separate sessions |
| **Runner (external)** | `/audit-runner` available | Autonomous run via audit-runner.sh (separate process) |

**Rules:**
- Team option ONLY shown when `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` is set as env var
- With available team mode: mark as recommendation (faster, less manual work)
- Without team flag: manual as default, mention runner as alternative
- User can always abort and switch to manual mode

**Check Team Availability:**
```bash
# Check in orchestrator:
echo $CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS
# If "1" → offer team option
```

### Step 6 — Calculate Session Estimate

Not hardcoded — dynamically based on phase count:

```
Session Formula:
  framework_sessions = ceil(relevant_sections / 2) + ceil(expected_findings / 5)
  audit_sessions     = ceil(active_phases / 2)     + ceil(expected_findings / 5)
  project_sessions   = ceil(active_phases / 2)     + ceil(expected_findings / 5)

  planning_session   = 1  (orchestrator plan)
  fixing_sessions    = ceil(estimated_total_findings / 5)

  TOTAL = planning + framework + audit + project + fixing
```

**Benchmarks for expected findings:**
- First audit: ~5-8 findings per skill
- After previous audit: ~2-4 new findings
- Beta migration: ~8-15 findings (more breaking changes)

### Step 7 — Combined State

→ Full state schema (v3) + JSON example + backward compatibility: See **state-schema.md**

---

## Session Strategy

The order adapts to the project. Variants:

### Variant A: Beta/Migration + GitHub + VPS

| Session | Recommendation |
|---------|---------------|
| 1 | `/audit-orchestrator` → Plan + **`/freshness-check` + `/security-scan` + Pre-Audit: GitHub + VPS** |
| 2 | `/{{FRAMEWORK}}-audit start` (2 sections — CRITICAL first) |
| 3 | `/{{FRAMEWORK}}-audit continue` (2 sections) |
| 4 | `/{{FRAMEWORK}}-audit continue` (remaining sections) |
| 5 | `/audit start` (2 phases) |
| 6 | `/audit continue` (2 phases) |
| 7 | `/audit continue` (remaining phases incl. VPS deep security) |
| 8 | `/project-audit start` (2 phases, with GitHub supplement) |
| 9 | `/project-audit continue` (2 phases) |
| 10 | `/project-audit continue` (remaining phases) |
| 11+ | Fix findings (highest severity first, cross-audit) |

### Variant B: Standard + GitHub (Stable, Current)

| Session | Recommendation |
|---------|---------------|
| 1 | `/audit-orchestrator` → Plan + **`/security-scan` + Pre-Audit: GitHub Settings** |
| 2 | `/audit start` (2 phases) |
| 3 | `/audit continue` (2 phases) |
| 4 | `/audit continue` (remaining phases) + `/{{FRAMEWORK}}-audit start` |
| 5 | `/{{FRAMEWORK}}-audit continue` (2 sections) |
| 6 | `/project-audit start` (2 phases, with GitHub supplement) |
| 7+ | Continue as needed |

### Variant C: No Framework-Specific Audit (Backend, CLI, Library)

| Session | Recommendation |
|---------|---------------|
| 1 | `/audit-orchestrator` → Plan + **`/security-scan` + Pre-Audit: GitHub + optionally VPS** |
| 2 | `/project-audit start` (2 phases, with GitHub supplement) |
| 3+ | Continue as needed |

### Variant D: SvelteKit Full-Stack (+ Drizzle + Auth + GitHub + VPS)

| Session | Recommendation |
|---------|---------------|
| 1 | `/audit-orchestrator` → Plan + **`/freshness-check` + `/security-scan` + Pre-Audit: GitHub + VPS** |
| 2 | `/db-audit start` (2 sections — schema + security first) |
| 3 | `/db-audit continue` (remaining sections) |
| 4 | `/auth-audit start` (2 sections — hashing + sessions first) |
| 5 | `/auth-audit continue` (remaining sections) |
| 6 | `/sveltekit-audit start` (2 sections — ENV + CODE first) |
| 7 | `/sveltekit-audit continue` (2 sections) |
| 8 | `/sveltekit-audit continue` (remaining sections) |
| 9 | `/audit start` (2 phases) |
| 10 | `/audit continue` (2 phases) |
| 11 | `/audit continue` (remaining phases) |
| 12 | `/project-audit start` (2 phases, with GitHub supplement) |
| 13 | `/project-audit continue` (remaining phases) |
| 14+ | Fix findings (highest severity first, cross-audit) |

### Automation: /audit-runner

For automated runs, the `/audit-runner` skill can be used.
It runs all audits unattended in separate sessions — no context limit.

```
/audit-runner setup    → Configuration and audit plan
/audit-runner start    → Start autonomous run
/audit-runner status   → Check progress
```

**When to use /audit-runner instead of manual:**
- First overview of a new project (collect findings, fix later)
- Audit multiple projects sequentially
- Overnight run: audit runs, review results in the morning

---

## Team Mode (Parallel Audit Execution)

→ Full team mode documentation (T1-T8, pre-audit, error handling): See **team-modus.md**

---

## Cross-Audit Findings

When findings are fixed, check if the fix is also relevant in another audit:
- Web security fix in `/audit` (e.g., SRI, CSP) → check if `/project-audit` security is affected
- Supply chain fix in `/project-audit` (e.g., SBOM, Sigstore) → check if `/audit` infra is affected
- Docker fix (e.g., Compose V2) → mark as fixed in BOTH audits (infra + deployment)
- Container signing in `/project-audit` → also relevant in `/audit` infrastructure
- Framework migration fix (e.g., Node 22) → also relevant in `/audit` status analysis + `/project-audit` dependencies
- `/security-scan` findings (MCP, hooks) → relevant for `/audit` Phase 02 (security) and `/project-audit` Phase 08 (security)
- `/audit` Phase 09 content/design findings → feed into `/polish scan` + `/design-system` for resolution

---

## Post-Audit Recommendations

After all audits complete, the orchestrator recommends follow-up actions:

| Condition | Recommendation | Reason |
|-----------|---------------|--------|
| Content/Design findings in Phase 09 | `/polish scan` → `/design-system` | Use curated design databases for improvements |
| `/security-scan` not run as pre-audit | `/security-scan` | Claude Code environment should be verified |
| Security findings across audits | `/security-scan` + `/adversarial-review` | Cross-check security posture |
| All audits clean, deployment target exists | `/deploy-check` | Verify deployment readiness |
| Significant learnings from audit | `/lesson-learned session` | Persist audit insights |

---

## Status Display

```
Audit Orchestrator: {{PROJECT_NAME}}
Mode: {Team|Manual|Runner}
Order: {Reason} → {Audit 1} → {Audit 2} → {Audit 3}

Pre-Audit:
/security-scan:       ██████████ Grade: B (1 HIGH, 2 MEDIUM)
/freshness-check:     ██████████ done (2 opportunities)

Audits:
/{{FRAMEWORK}}-audit: ████████░░ 5/13 sections (8 findings, 1 skipped)
/audit:               ████████░░ 5/8 phases (12 findings)
/project-audit:       ████░░░░░░ 4/10 phases (5 findings)

Total: 25 findings (2 CRITICAL, 5 HIGH, 12 MEDIUM, 6 LOW)
Fixed: 3 | Open: 22 | Skipped: 1

Related Projects:
  {{RELATED_NAME}}: {Status}

Recommendation: Fix 2 CRITICAL findings first (MIG-03 from framework audit, SEC-01 from /audit)
Session Estimate: {N} remaining (of {M} planned)
```

**Addition for Team Mode** (`executionMode: "team"`):
```
Team: audit-{{PROJECT_NAME}}
  [audit-worker-1] /audit            → running (Phase 5/8)
  [audit-worker-2] /{{FRAMEWORK}}-audit → done (8 findings)
  [audit-worker-3] /project-audit    → waiting (blocked by /audit)
Runtime: 12 min
```

---

## Combined Report

→ Report format, categories, regulatory standards + generation: See **combined-report.md**

---

## Rules

- **Session directory is canonical** — `.audit-session/<date>-<slug>/` holds INDEX.md, STATUS.md, and four phase folders. STATUS.md must stay current (update at phase transitions and every ~5 fix commits).
- **Any instance can resume** — because state is plain Markdown in the session directory, a crashed session can be continued by a new instance, a different model, or a human. The resume protocol is: read INDEX.md → read STATUS.md → claim the session → continue from the "next action" line.
- **Four phases always run** — Pre-Scan, Analysis, Optimization, Report. Empty phases are documented, not skipped.
- **Project type drives the track** — Phase 1 writes `project-profile.md`; Phase 2 picks tracks from `universal-workflow.md`. Web projects additionally activate the web-orchestration specialization below.
- **Orchestrator plans + coordinates** — the actual audits run via their own skills (manually or as teammates)
- **Team mode optional** — only if `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` is set AND user chooses
- **Teammates use /auto** — autonomous run, no manual start/continue
- **Legacy state coexists** — each sub-skill keeps its own state file, and the web-specific `.audit-orchestrator-state.json` (v3) is still written when the web orchestration path is active; universal Markdown state is the primary surface for resume.
- **Orchestrator state** tracks overview + phase mapping + sequencing + team status
- **Pre-audit by orchestrator** — freshness check + GitHub/VPS checks done by orchestrator itself, not by teammate
- **Beta/RC always first** — migration audit before quality audit for unstable versions
- **Static filter active** — automatically skip SSR-specific checks for `output: "static"`
- **Crash not fatal + self-healing** — teammate crash does not end the overall audit, state survives, manual fallback possible. In team mode: detect stalled workers (no state update > 5 min), restart once automatically before falling back to manual. Guard concurrent state file writes to prevent corruption (inspired by GSD v2 parallel worker patterns).
- **Combined report** via `/audit-orchestrator report` or naturally as the Phase 4 output (`04-report/REPORT.md`).
- **Regulatory standards** — explicitly check applicable privacy, accessibility, and compliance regulations — separate section in combined report

## Reference Files

- `universal-workflow.md` — the four-phase workflow, project-type tracks, severity scale, exit criteria.
- `session-schema.md` — session directory layout, INDEX.md / STATUS.md / findings / TODO / changes templates, ID conventions.
- `state-schema.md` — legacy `.audit-orchestrator-state.json` v3 schema (web-orchestration path).

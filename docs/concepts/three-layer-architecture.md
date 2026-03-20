# Three-Layer Audit Architecture

Claude Hangar organizes its audit capabilities into three distinct layers. Each layer serves a different purpose, and together they provide comprehensive project coverage from generic best practices down to adversarial stress testing.

## Overview

```
Layer 1: Generic Audits        /audit (websites) + /project-audit (repos)
Layer 2: Stack-Specific Audits /astro-audit, /sveltekit-audit, /db-audit, /auth-audit
Layer 3: Adversarial Review    /adversarial-review (critical review, min. 5 findings)
         Orchestration         /audit-orchestrator (coordinates all layers)
```

## Layer 1 -- Generic Audits

Generic audits apply universally. They check things every project needs regardless of the technology stack.

### /audit (Website Audit)

Systematic 9-phase website audit covering baseline analysis, security, performance, SEO, accessibility, code quality, privacy/GDPR, infrastructure, and content/design. Works with any web framework.

**When to use:** Any website or web application with a publicly accessible URL.

**Phases:** IST (Baseline), SEC (Security), PERF (Performance), SEO, A11Y (Accessibility), CODE (Code Quality), GDPR (Privacy), INFRA (Infrastructure), CD (Content & Design).

### /project-audit (Repository Audit)

Systematic 10-phase repository audit for non-website projects. Covers structure, dependencies, code quality, Git hygiene, CI/CD, documentation, testing, security (supply chain), deployment, and maintenance.

**When to use:** CLI tools, libraries, backend services, management repos, monorepos -- any codebase that is not primarily a website.

**Key difference from /audit:** No SEO, accessibility, or privacy checks. Instead, thorough Git workflow, CI/CD pipeline, and supply-chain security analysis.

## Layer 2 -- Stack-Specific Audits

Stack-specific audits go deeper into framework-specific patterns, migrations, and best practices that generic audits cannot cover.

| Skill | Detects | Focus |
|-------|---------|-------|
| `/astro-audit` | Astro projects | Version migration, content collections, adapter config, Astro-specific security |
| `/sveltekit-audit` | SvelteKit projects | Svelte 5 runes, load functions, adapter patterns, SSR vs. prerender |
| `/db-audit` | PostgreSQL/Drizzle/SQLite | Schema design, migrations, connection pooling, query security, backups |
| `/auth-audit` | Custom auth (bcryptjs, sessions) | Password hashing, session management, CSRF protection, OWASP ASVS |

Stack-specific audits have a `refresh` mode that checks for new framework releases and breaking changes -- something generic audits do not do.

## Layer 3 -- Adversarial Review

The adversarial review operates differently from audits. Instead of working through a checklist, it actively tries to break things.

### /adversarial-review

Three review modes:

| Mode | Target | Method |
|------|--------|--------|
| `code` | Code changes (git diff) | Three parallel tracks: adversarial attack, failure mode catalog (17 modes), path tracing |
| `audit` | Audit reports | Check for gaps, severity errors, missing categories, copy-paste findings |
| `plan` | Implementation plans | Dependency analysis, rollback scenarios, unrealistic estimates, missing steps |

**Core rule:** Minimum 5 findings. Zero findings is never acceptable. If fewer than 5 are found on the first pass, the reviewer must look again at testability, edge cases, and documentation.

**Gap write-back:** In `audit` mode, findings categorized as "Gap" (missing checks) are written back to the original audit state file as new open findings.

## How the Layers Complement Each Other

Each layer catches what the others miss:

```
Layer 1: "Does this project follow web/code best practices?"
Layer 2: "Does this project follow Astro/SvelteKit/DB-specific best practices?"
Layer 3: "What did both layers miss? Where can this actually break?"
```

**Example flow for an Astro website:**

1. `/audit` finds missing CSP headers (SEC-03), slow LCP (PERF-02), missing alt texts (A11Y-01)
2. `/astro-audit` finds outdated content collection schema (MIG-04), missing adapter config (BP-02)
3. `/adversarial-review audit` reviews both reports, finds that the security phase missed rate limiting on the contact form (Gap), and that a MEDIUM finding should actually be HIGH

## When to Use Which Layer

| Scenario | Recommended Approach |
|----------|---------------------|
| Quick check before deploy | Layer 1 only: `/audit start` or `/project-audit start` |
| New project onboarding | All layers: orchestrator plans the sequence |
| Framework major upgrade | Layer 2 first: framework audit to check migration |
| Before going live | Layer 1 + 2, then Layer 3 for final review |
| After major refactoring | Layer 3: `/adversarial-review code` on the diff |
| Routine maintenance | Layer 1: `/audit auto` for a full sweep |

## The Audit Orchestrator

The `/audit-orchestrator` is a meta-skill that coordinates all layers. It does not perform audits itself -- it plans and sequences them.

### What it does

1. **Scans the project** to detect which audits are needed
2. **Determines the sequence** (beta/RC versions always get framework audit first)
3. **Manages phase overlap** (security is checked by both `/audit` and `/project-audit`, but from different angles)
4. **Calculates session estimates** based on phase count and expected findings
5. **Tracks combined state** across all running audits

### Sequencing logic

The orchestrator sequences audits based on detected conditions:

| Condition | Order | Reason |
|-----------|-------|--------|
| Framework beta/RC | Framework audit first | Broken build blocks everything |
| Framework stable, current | `/audit` first | Web quality before framework specifics |
| SvelteKit + DB + Auth | `/db-audit` > `/auth-audit` > `/sveltekit-audit` > `/audit` > `/project-audit` | Foundation up |
| Backend only | `/project-audit` only | No web-specific checks needed |

### Execution modes

| Mode | Description |
|------|-------------|
| Team (parallel) | Spawns teammates for parallel audit execution (requires experimental flag) |
| Manual (sequential) | User starts each audit individually in separate sessions |
| Runner (autonomous) | Unattended batch run via `/audit-runner` |

## Phase Overlap Management

Some concerns are checked by multiple audits. The orchestrator prevents duplicate work:

| Area | /audit Focus | /project-audit Focus |
|------|-------------|---------------------|
| Security | Web security (OWASP, headers, XSS) | Supply chain (SBOM, npm provenance, container signing) |
| Infrastructure | VPS, Docker Compose, reverse proxy | Container signing, OCI annotations |
| Code Quality | Basic linting and types | Patterns, complexity, coverage (leads) |
| Dependencies | Version overview in baseline | Lockfiles, corepack, provenance (leads) |

Both audits run for areas with different focus. Only when checks are truly identical does the more thorough audit lead.

## Shared Infrastructure

All audit skills share common architecture defined in `core/skills/_shared/`:

- **audit-blueprint.md** -- Standard modes, severity scale, context protection, state schema v2.1
- **audit-patterns.md** -- Verification depth, fix protocol, check priorities, completeness tracking, skill synergy

This shared infrastructure ensures consistent behavior across all 6 audit skills: same modes, same severity levels, same state format, same finding IDs.

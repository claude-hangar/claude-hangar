# Audit Orchestrator — Universal Workflow

Project-type-agnostic orchestration pattern. Works for web apps, infrastructure repos, homelab configs, CLI tools, libraries, backend services, monorepos, data/ML projects, documentation repos — anything.

The universal mode is the **default entry point** of `/audit-orchestrator`. Use it when the project doesn't fit a pre-defined web-framework track, or when you want the orchestrator to self-detect and adapt.

## The Four Phases

Every session flows through four phases. Each phase owns a directory with its own README, findings, and TODO — so any LLM or human can resume mid-flight.

```
01-prescan    →  detect what we have
02-analysis   →  identify issues/opportunities
03-optimization → apply fixes
04-report     →  summarize outcome
```

No phase is skipped. If a phase has nothing to do, it documents that explicitly (findings: "no blockers detected") and moves on. Empty TODOs are valid.

## Phase 1 — Pre-Scan (Detection)

**Goal:** Answer "what kind of project is this, and what does it need?"

**Inputs:** Repo working directory.

**Actions:**
1. Detect project type (see decision table below).
2. Enumerate key signals: language/runtime, build system, CI config, deployment target, test setup, dependencies, docs presence.
3. Detect infrastructure context (Docker, k8s, systemd, Traefik, cloud provider, VPS inventory, homelab services).
4. Record `.claude/` environment if present (hooks/MCP need pre-verification before any audit).
5. Flag beta/RC dependencies that block downstream work.

**Outputs:**
- `01-prescan/README.md` — phase goal + how to read the other files.
- `01-prescan/findings.md` — what was detected (signals, project type, scope boundaries).
- `01-prescan/TODO.md` — analysis tasks queued for Phase 2.
- `01-prescan/project-profile.md` — structured profile (type, stack, infra, risk flags).

**Exit criteria:** Project type is set, infra context is recorded, Phase 2 TODO has at least one actionable item (or explicit "no analysis needed — documented in findings.md").

### Project Type Decision

| Signals | Project Type | Default Analysis Track |
|---------|--------------|------------------------|
| `astro.config.*` | web-astro | web-framework + general |
| `svelte.config.*` / `@sveltejs/kit` | web-sveltekit | web-framework + general |
| `next.config.*` | web-nextjs | web-framework + general |
| `package.json` + no framework | node-app / node-lib | general + deps/ci |
| `pyproject.toml` / `setup.py` / `requirements.txt` | python | general + py-specific |
| `go.mod` | go | general + go-specific |
| `Cargo.toml` | rust | general + rust-specific |
| `Dockerfile` + `docker-compose*.yml` + no app code | infra-docker | infra + deployment |
| `.tf` / `.tofu` / `ansible.cfg` / inventory files | infra-iac | infra + security |
| `registry.json` / server inventory / no source tree | infra-homelab | infra + ops |
| `.github/workflows/` only (meta repo) | meta-automation | ci + docs |
| Multi-package workspace (pnpm/turbo/nx/yarn workspaces) | monorepo | per-package loop |
| Only `.md` files + maybe static site build | docs | docs + links + meta |
| Notebooks / `dvc.yaml` / `mlflow` | data-ml | data-ml + deps |
| Anything else not covered | generic | general |

**Rule:** "general" track covers Git hygiene, CI sanity, secrets scan, dependency health, license posture, docs freshness — runs for every project.

**Rule:** Specialty tracks (web-framework, infra, py-specific, …) are additive on top of general.

## Phase 2 — Analysis

**Goal:** Identify what to change and why.

**Inputs:** `01-prescan/project-profile.md`, `01-prescan/TODO.md`.

**Actions (track-dependent):**
- **General track (always):** git hygiene, CI sanity, secret scan, dependency freshness, license posture, docs freshness, missing README sections, TODO/FIXME debt.
- **Web-framework track:** delegate to `/audit`, `/{framework}-audit`, `/project-audit` per existing SKILL.md orchestration — findings land in this phase.
- **Lens dispatch (any stack with lenses):** discover `stacks/{stack}/lenses/*.md` matching detected stack, dispatch one sub-agent per lens by category. See "Lens Dispatch Protocol" below.
- **Infra track:** Docker image hygiene, Compose V2 compliance, Traefik routing sanity, rootless/user separation, secret mounting, port exposure, TLS config, backup state, monitoring coverage.
- **Python/Go/Rust tracks:** type coverage, lint config, test coverage, dependency CVEs, build reproducibility.
- **Monorepo track:** iterate packages — each package is its own analysis sub-block under `02-analysis/packages/{name}/`.
- **Homelab track:** service inventory vs. running services, cert expiry, disk budgets, backup recency, log retention.

### Lens Dispatch Protocol

When the detected stack has a `stacks/{stack}/lenses/` directory, the orchestrator
dispatches lenses as parallel sub-agents instead of executing analysis monolithically.
Pattern adapted from RepoLens lens-based-auditing — narrow specialists outperform a
single broad reviewer.

**Discovery:**
1. After Phase 1 sets project type, list `stacks/{stack}/lenses/*.md` (skip `README.md`).
2. Parse each lens frontmatter for `name`, `category`, `effort_min`, `effort_max`.
3. Build a dispatch plan grouped by `category` (security, performance, migration, ...).

**Dispatch:**
- Selection: by default run all lenses for the detected stack. User may pass
  `--lens <name>` (single) or `--category <cat>` (filter) to scope.
- Concurrency: parallel via `superpowers:dispatching-parallel-agents`, capped by
  `HANGAR_LENS_MAX_PARALLEL` (default 4) — same semaphore pattern as the
  RepoLens-inspired done-streak helper in `core/lib/done-streak.sh`.
- Per lens: spawn an Explorer agent with the lens body as task brief, project path
  as scope. Lens body already declares its own report template + severity mapping.
- Cost gate: orchestrator sums `effort_max` across selected lenses, multiplies by
  `HANGAR_COST_PER_CALL_USD`, compares to `HANGAR_BUDGET_USD`. Aborts with a plan
  preview if budget would be exceeded.

**Aggregation:**
- Each lens writes its report to `02-analysis/lenses/{lens-name}.md`.
- Findings extracted from lens reports merge into `02-analysis/findings.md` with
  `id` prefixed by lens (e.g., `LENS-SVK-SLS-01` for sveltekit/server-load-security).
- Severities preserved from the lens; orchestrator does not re-rank.

**Stacks currently providing lenses:**
- `stacks/astro/lenses/` — content-collections, view-transitions
- `stacks/sveltekit/lenses/` — server-load-security, form-actions-csrf, runes-migration
- `stacks/database/lenses/` — migration-safety, index-strategy, transaction-boundaries

When a stack has no lens directory, fall back to the legacy track's monolithic audit.

**Outputs:**
- `02-analysis/README.md` — phase goal + track(s) executed.
- `02-analysis/findings.md` — issues table (id, severity, area, file/line, evidence, recommendation).
- `02-analysis/TODO.md` — fix queue, severity-sorted.
- `02-analysis/opportunities.md` — non-issues worth doing (wins, polish, tech-debt reduction).

**Exit criteria:** Each finding has a severity + recommendation. TODO is the canonical fix queue for Phase 3.

### Severity Scale

| Level | Definition | Phase 3 Handling |
|-------|------------|------------------|
| CRITICAL | Security vulnerability, data loss, broken CI, production outage risk | Fix immediately in Phase 3 |
| HIGH | Logic bug, missing auth, broken behavior, outdated security-relevant dep | Fix in Phase 3 |
| MEDIUM | Code smell, missing test, stale doc, outdated non-critical dep | Fix if time allows; otherwise defer |
| LOW | Nitpick, style, cosmetic | Document only, no fix unless trivial |

## Phase 3 — Optimization

**Goal:** Apply fixes from Phase 2 TODO.

**Inputs:** `02-analysis/TODO.md` (the fix queue).

**Actions:**
1. Work the TODO top-down (CRITICAL → HIGH → MEDIUM → LOW).
2. For each fix: read context, apply change, verify (tests/build/lint), commit atomically.
3. For deviations (scope grew, fix not possible, blocked): record in `03-optimization/TODO.md` under "deferred" or "blocked".
4. Update STATUS.md after every 3–5 fixes so a crashed session resumes cleanly.

**Outputs:**
- `03-optimization/README.md` — phase goal + what was applied.
- `03-optimization/changes.md` — log of applied changes (id → commit SHA, touched files, verification).
- `03-optimization/TODO.md` — remaining items: deferred / blocked / out-of-scope.
- `03-optimization/deviations.md` — anything that went differently than planned and why.

**Exit criteria:** No open CRITICAL or HIGH items in the fix queue without an entry in deviations.md explaining why.

## Phase 4 — Report

**Goal:** Produce one readable document summarizing the session.

**Inputs:** All prior phase artifacts.

**Actions:**
1. Assemble `04-report/REPORT.md` with these sections: Executive Summary, Project Profile, Findings (by severity), Applied Changes, Deviations, Follow-ups.
2. Include commit SHA range, test/build status, time cost if tracked.
3. Flag post-audit recommendations (e.g., "run /deploy-check", "schedule /freshness-check in 7 days").

**Outputs:**
- `04-report/README.md` — one-paragraph abstract for the TOC.
- `04-report/REPORT.md` — the canonical deliverable.

**Exit criteria:** REPORT.md is self-contained. A reviewer can understand the session without reading any other phase file.

## Session Lifecycle

1. **Start:** Orchestrator creates `.audit-session/{YYYY-MM-DD-slug}/` (slug = short project descriptor) and writes INDEX.md + STATUS.md.
2. **Work:** Phases run in order; each phase folder is populated; STATUS.md is updated after every phase transition and every ~5 fix commits.
3. **Pause/crash:** STATUS.md + INDEX.md are always current enough for any instance to resume. Last-updated timestamp is ISO-8601.
4. **Resume:** A new instance reads INDEX.md (structure) + STATUS.md (current position) and continues.
5. **Finalize:** When Phase 4 is done, STATUS.md flips to `state: completed`, INDEX.md gains the final REPORT.md pointer.

## Resume Protocol (for new instances)

A fresh LLM or user picking up the session does exactly this:

1. `ls .audit-session/` → find the most recent session dir (or the one named in the request).
2. Read `INDEX.md` → learn the structure.
3. Read `STATUS.md` → learn where work stopped.
4. Look at the "next action" line in STATUS.md and continue.
5. Update STATUS.md before the first tool call to claim the session.

## Relationship to Web-Framework Track

The pre-existing web-audit orchestration (see SKILL.md §§ "Step 2 — Determine Audit Combination" onward) is a **specialization of Phase 2** for web projects. When Phase 1 detects `web-astro`, `web-sveltekit`, or `web-nextjs`, Phase 2 delegates to that orchestration. Findings and TODOs still land in the Phase 2 folder of the universal session directory, but the execution logic, sub-audits, and gating come from the web-specific rules.

For non-web projects, Phase 2 uses the general + specialty tracks listed above directly, without the web-audit machinery.

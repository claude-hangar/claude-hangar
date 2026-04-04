---
name: project-audit
description: >
  Repository audit for non-website projects (CLI, libs, backend, monorepo).
  Use when: "project-audit", "project audit", "repo audit", "code audit".
---

<!-- AI-QUICK-REF
## /project-audit — Quick Reference
- **Modes:** start | continue | status | report | auto
- **Arguments:** `/project-audit $0` e.g. `/project-audit auto`, `/project-audit status`
- **Three-layer:** phases/*.md + stacks/*.md + project-audit-context.md
- **Dual-Layer:** Source (read code) + Runtime (npm audit, tsc, docker scout)
- **Check-Priorities:** MUST (mandatory) | SHOULD (standard) | COULD (nice-to-have)
- **10 Phases:** Structure, Dependencies, Code, Git, CI/CD, Docs, Testing, Security, Deploy, Maintenance
- **Finding-IDs:** STRUC-01, DEP-01, QUAL-01, GIT-01, CICD-01, DOC-01, TEST-01, SEC-01, DEPLOY-01, MAINT-01
- **Severity:** CRITICAL > HIGH > MEDIUM > LOW
- **Context Protection:** Max 2 phases OR 5 fixes per session (except auto)
- **State:** .project-audit-state.json (v2.1)
- **Checkpoints:** [CHECKPOINT: verify] after each phase, [CHECKPOINT: decision] at audit scope
-->

# Skill: project-audit

Systematic project audit for any repository — with a three-layer depth model.
Automatically detects the stack, loads relevant supplements, and performs
structured checks — for management repos, CLI tools, libraries,
backend services, monorepos, Python projects, and shell collections.

**Distinction from `/audit`:** No SEO, no accessibility, no privacy/GDPR, no Lighthouse.
Instead, more thorough checking of Git, CI/CD, code quality, deployment, and maintenance.

---

## Check Layers

Each phase has two check levels:

| Layer | Method | When |
|-------|--------|------|
| **Source Layer** | Read code, analyze configs, scan files | Always (offline possible) |
| **Runtime Layer** | `npm audit`, `tsc --noEmit`, `docker scout`, run tests, check CI logs | When tools are available |

**Rule:** Source layer is mandatory. Runtime layer supplements with tool-based checks.
Both layers are tracked in state per phase.

**Runtime layer per phase:**

| Phase | Runtime Tools |
|-------|--------------|
| 02 Dependencies | `npm audit`, `pip-audit`, `npm outdated` |
| 03 Code Quality | `tsc --noEmit`, `npx biome check`, `pylint` |
| 05 CI/CD | `gh run list`, check CI logs |
| 07 Testing | `npm test`, coverage reports |
| 08 Security | `npm audit`, `docker scout`, `git log --all -p -- .env` |
| 09 Deployment | `docker scout cves`, container health check |

---

## Check Priorities + Completeness Tracking

> See `_shared/audit-patterns.md` (MUST/SHOULD/COULD markers, completeness counting).
Phase with <100% MUST-checks can NOT be marked as `done`.

---

## Architecture: Three-Layer Model

```
Layer 1: Base Phase (phases/*.md)                    ~70-100 lines, universal
Layer 2: Stack Supplement (stacks/*.md §-sections)   ~10-15 lines per phase, stack-specific
Layer 3: Project Override (project-audit-context.md)  ~20-40 lines, project-specific
```

Per phase, only the relevant supplements are loaded.
Result: ~100-150 lines of check instructions per phase — comparable to a dedicated skill.

---

## 5 Modes

| Mode | Trigger | Description |
|------|---------|-------------|
| `start` | `/project-audit start` | Detect stack + project type, create phase plan, first 2 phases |
| `continue` | `/project-audit continue` | Continue next phases or fix max 5 findings |
| `status` | `/project-audit status` | Show progress + statistics |
| `report` | `/project-audit report` | Generate structured Markdown report |
| `auto` | `/project-audit auto` | Fully autonomous run — all phases without prompts |

---

## Mode: start

### Step 1 — Detect Project Type

| Detected | Project Type |
|----------|-------------|
| `global/`, `projects/`, `setup.sh`, no src/ | `management-repo` |
| `bin` in package.json | `cli-tool` |
| `main`/`exports` in package.json, no `bin`, no framework | `library` |
| `fastify`/`express`/`koa` without frontend framework | `backend-service` |
| `workspaces` in package.json or `pnpm-workspace.yaml` | `monorepo` |
| Python project (`setup.py`, `pyproject.toml`, `requirements.txt`) | `python-project` |
| Shell scripts dominant (*.sh), no package.json | `scripts-collection` |
| Fallback | `generic` |

### Step 2 — Stack Detection

Scan files and detect stack:

| File/Pattern | Detects | Stack-Key |
|-------------|---------|-----------|
| `package.json` present | Node.js | `node: true` |
| `pyproject.toml`, `setup.py`, `requirements.txt` | Python | `python: true` |
| Majority `*.sh` files, no package.json | Shell/Bash | `shell: true` |
| `Dockerfile`, `docker-compose.*` | Docker | `docker: true` |
| `workspaces` in package.json, `pnpm-workspace.yaml` | Monorepo | `monorepo: true` |
| `.claude/` directory or `CLAUDE.md` in root | Claude Code | `claude-code: true` |
| `go.mod` present | Go | `go: true` |
| `*.tf` files, `terraform.tfvars` | Terraform | `terraform: true` |
| `.github/` directory or `git remote` shows github.com | GitHub | `github: true` |

**Version detection:** For each detected stack, extract version:
- Node: `engines.node` or `.nvmrc` / `.node-version`
- Python: `python_requires` or `.python-version`
- Docker: Base image tag in Dockerfile

### Step 3 — Load Context

1. **Project CLAUDE.md** read (architecture, conventions)
2. **project-audit-context.md** load (if in project root) — project-specific context
3. **README.md** read (purpose, setup instructions)
4. **Existing docs** scan: TODO.md, STATUS.md, CHANGELOG.md
5. **package.json** / `pyproject.toml` analyze (if present)
6. **Existing state file** (.project-audit-state.json) check > auto-migrate if v1

### Step 4 — User Query

Show detection result:

```
Project Detection:
+-------------+------------------+---------+
| Category    | Detected         | Version |
+-------------+------------------+---------+
| Project Type| management-repo  | —       |
| Stack       | Shell/Bash       | —       |
| Docker      | Yes              | —       |
| Monorepo    | No               | —       |
+-------------+------------------+---------+

Project context: project-audit-context.md found
Existing docs: TODO.md, STATUS.md
```

Ask user (AskUserQuestion):
- **Audit scope:** Complete (all 10 phases) vs. focused (specific phases)
- **Phase order:** Sequential (01>10, default) vs. Smart Order (Security>Dependencies>Code>Rest, recommended)

**[CHECKPOINT: decision]** — User selects audit scope and phase order.

### Step 5 — Create state, start first 2 phases

---

## Mode: continue

1. Read `.project-audit-state.json`
2. Identify next pending phase(s)
3. Generate **smart recommendation** (> logic in `_shared/audit-patterns.md`)
4. Show recommendation as first option in AskUserQuestion, user chooses
5. Write state immediately after each phase/fix

### Fixing Findings

- Always fix highest severity first: CRITICAL > HIGH > MEDIUM > LOW
- Per fix: Show problem > **Load fix template** (from `fix-templates.md`) > User confirmation > Implement > Test
- Update fix status in state (`"status": "fixed"`, `"fixedIn": "Session N"`)
- **No auto-fix** — every fix requires user confirmation (except `auto` mode)

---

## Mode: status

Read state file and display:

```
Project Audit: {{PROJECT_NAME}} (management-repo)
Stack: Shell/Bash, Docker

Phases:
  [done] 01 Structure & Architecture (Session 1, 2 Findings, MUST 100%)
  [done] 02 Dependencies & Ecosystem (Session 1, 1 Finding, MUST 100%)
  [wip]  03 Code Quality (in progress)
  [wait] 04 Git & Versioning
  [wait] 05 CI/CD & Automation
  [wait] 06 Documentation & Onboarding
  [wait] 07 Testing & QA
  [wait] 08 Security & Secrets
  [wait] 09 Deployment & Operations
  [wait] 10 Maintenance & Hygiene

Findings: 3 total
  CRITICAL: 0
  HIGH: 1 (open: 1)
  MEDIUM: 2 (open: 2)
  LOW: 0

Completeness: 2/10 phases completed
  Layer: Source done | Runtime done (2/2 phases)
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
     CRITICAL: 3 > 1 > 0  (resolved)
     HIGH:     5 > 3 > 2  (declining)
     Total:   12 > 8 > 5
   Assessment: Project is steadily improving.
   ```
5. Save report as `PROJECT-AUDIT-REPORT-{YYYY-MM-DD}.md` in project root
6. If previous reports exist: Diff section (new/resolved since last report)

---

## Mode: auto

Fully autonomous project audit without prompts.

### Flow

1. **Check orchestrator context:** If `.audit-orchestrator-state.json` exists:
   - Read `phaseMapping.project-audit.delegated` > skip delegated phases
   - Read `sequencingReason` > understand context
   - **Example:** If `structure` delegated to `/audit` > skip Phase 01
2. Auto-detection as in `start`
3. **All 10 phases** run through (no 2-phase limit, skip delegated phases)
4. Document findings with fix templates from `fix-templates.md`
5. **Context management:** When context is running low:
   - Write state immediately
   - Create task in `.tasks.json` with handoff note
   - Recommend: "New session with `/project-audit continue`"
5. At the end: automatically generate report

### Context Protection in Auto Mode

- Findings are collected but **not fixed immediately** (documented only)
- Write state after EVERY phase immediately
- At context limit: clean abort with complete state
- Fixes in follow-up sessions with `/project-audit continue`

---

## 10 Phases

| # | Phase | Prefix | Checks |
|---|-------|--------|--------|
| 01 | Structure & Architecture | STRUC | Folder structure, patterns, coupling, layering |
| 02 | Dependencies & Ecosystem | DEP | Packages, versions, ecosystem health, licenses |
| 03 | Code Quality | QUAL | Patterns, complexity, dead code, types, linting |
| 04 | Git & Versioning | GIT | .gitignore, commits, branches, tags, history |
| 05 | CI/CD & Automation | CICD | Workflows, actions security, deploy pipelines, hooks |
| 06 | Documentation & Onboarding | DOC | README, CLAUDE.md, ADRs, API docs, runbooks |
| 07 | Testing & QA | TEST | Test pyramid, coverage, E2E, mutation testing |
| 08 | Security & Secrets | SEC | Secrets, supply chain, container security, SAST |
| 09 | Deployment & Operations | DEPLOY | Docker, server, monitoring, rollback, health checks |
| 10 | Maintenance & Hygiene | MAINT | Tech debt, cleanup, lifecycle, deprecations |

Details in the phase files under `phases/`.

---

## Phase Execution

For each phase:

1. **Load base:** Read `phases/{NN}-{name}.md` — universal check items
2. **Load supplements:** For each detected stack, load the matching file, ONLY the section relevant to the current phase

   | Phase | Supplement Section |
   |-------|-------------------|
   | 01-structure | §Structure |
   | 02-dependencies | §Dependencies |
   | 03-code-quality | §Code |
   | 04-git | §Git |
   | 05-cicd | §CICD |
   | 06-documentation | §Documentation |
   | 07-testing | §Testing |
   | 08-security | §Security |
   | 09-deployment | §Deployment |
   | 10-maintenance | §Maintenance |

3. **Project override:** If `project-audit-context.md` exists > include relevant section
4. **Existing findings:** Check previous audit docs, do not create duplicates
5. **Source layer:** Systematically execute all code/config-based checks
6. **Runtime layer:** Execute tool-based checks (when tools are available)
   - Unavailable tools: document, no error
7. **Document findings:** Each finding with ID, severity, description, location
8. **Count completeness:** MUST/SHOULD/COULD checks (executed vs. skipped)
   - Skipped MUST-checks with reason in `checksSkipped[]`
   - Phase with <100% MUST = NOT markable as `done`
9. **Update state:** Phase status + completeness + layer status

**[CHECKPOINT: verify]** — After each phase: show findings + completeness to user, get confirmation.

### Supplement Loading Logic

Per phase, the skill loads only relevant stack supplements.
Each stack file is structured by sections.

**Example Phase 08-security:**
```
> Always: phases/08-security.md (base)
> If node=true: + stacks/node.md §Security
> If docker=true: + stacks/docker.md §Security
> If python=true: + stacks/python.md §Security
> If project-audit-context.md exists: + relevant section
```

**Supplement files:**

| Stack-Key | Supplement Path |
|-----------|----------------|
| `node: true` | `stacks/node.md` |
| `python: true` | `stacks/python.md` |
| `shell: true` | `stacks/shell.md` |
| `docker: true` | `stacks/docker.md` |
| `monorepo: true` | `stacks/monorepo.md` |
| `claude-code: true` | `stacks/claude-code.md` |
| `go: true` | `stacks/go.md` |
| `terraform: true` | `stacks/terraform.md` |
| `github: true` | `stacks/github.md` |

If a stack is detected but no supplement exists > use base phase only, no error.

---

## Finding-IDs

| Phase | Prefix | Example |
|-------|--------|---------|
| 01-structure | `STRUC` | STRUC-01 |
| 02-dependencies | `DEP` | DEP-01 |
| 03-code-quality | `QUAL` | QUAL-01 |
| 04-git | `GIT` | GIT-01 |
| 05-cicd | `CICD` | CICD-01 |
| 06-documentation | `DOC` | DOC-01 |
| 07-testing | `TEST` | TEST-01 |
| 08-security | `SEC` | SEC-01 |
| 09-deployment | `DEPLOY` | DEPLOY-01 |
| 10-maintenance | `MAINT` | MAINT-01 |

---

## Severity Definitions

| Level | Criteria | Examples |
|-------|----------|----------|
| **CRITICAL** | Security vulnerability, data loss, exposed secrets | Secrets in repo, SQL injection, open ports |
| **HIGH** | Missing tests for critical paths, broken CI/CD, CVEs | No tests, outdated deps with CVE, broken pipelines |
| **MEDIUM** | Missing docs, style inconsistencies, missing .gitignore | No README, inconsistent naming, missing types |
| **LOW** | Cosmetic, nice-to-have, best practice | Outdated but secure deps, missing comments |

**Prioritization:** CRITICAL > HIGH > MEDIUM > LOW. Security before functional before cosmetic.

---

## State Schema v2.1 (.project-audit-state.json)

> Complete state schema (JSON example) + migrations v1>v2 and v2>v2.1: See **state-schema.md**

---

## Phase Order

### Sequential (Default)
`01 > 02 > 03 > 04 > 05 > 06 > 07 > 08 > 09 > 10`

### Smart Order (Recommended)
Prioritized by impact:
`08-security > 02-dependencies > 03-code-quality > 05-cicd > 09-deployment > 04-git > 07-testing > 01-structure > 06-documentation > 10-maintenance`

**Logic:** Security and dependencies are most urgent (CVEs, secrets).
Code quality and CI/CD have high impact. Structure/docs/maintenance are important but less time-critical.

User chooses at `start`. Store in state as `"phaseOrder": "sequential"` or `"smart"`.

---

## Fix Templates

For common findings there are ready-made fix templates in `fix-templates.md`.
Per finding type: code snippet, config change, verify step.

---

## Verification-Depth + Fix Protocol

> See `_shared/audit-patterns.md` (4-Level Verification, Stub-Detection, 5-Step Fix-Protocol).
Level 4 (Functional) is mandatory when runtime layer is available. READ + VERIFY never skip.

---

## Context Protection (CRITICAL)

> Base rules: See `_shared/audit-patterns.md` (Max 2 phases, state immediately, no auto-fix).

**Project audit specific:**
- **Layer tracking:** Document source layer and runtime layer status per phase

---

## Smart Next Steps

After completing the project audit, recommend suitable follow-up skills to user:

| Condition | Recommendation | Justification |
|-----------|---------------|---------------|
| >3 HIGH/CRITICAL findings | `/adversarial-review audit` | Check report for completeness |
| Claude Code project (.claude/ present) | `/security-scan` | MCP permissions, hook safety, secret detection |
| Audit completed | `/lesson-learned session` | Extract learnings from audit process |
| Web project detected AND no .audit-state.json | `/audit start` | Check website quality (SEO, A11y, privacy) |
| Astro project detected AND no .astro-audit-state.json | `/astro-audit start` | Astro-specific checks |

**Output in report:** Replace `{NEXT_STEPS}` placeholder with concrete recommendation list.

---

## Files in This Skill

```
project-audit/
├── SKILL.md                       <- This file
├── state-schema.md                # State Schema v2.1 + Migrations
├── fix-templates.md               # Quick-Fix templates for common findings
├── phases/
│   ├── 01-structure.md            # Folder structure, architecture, coupling
│   ├── 02-dependencies.md         # Packages, ecosystem, licenses
│   ├── 03-code-quality.md         # Patterns, complexity, dead code
│   ├── 04-git.md                  # .gitignore, commits, branches, tags
│   ├── 05-cicd.md                 # Workflows, actions security, pipelines
│   ├── 06-documentation.md        # README, ADRs, API docs, onboarding
│   ├── 07-testing.md              # Test pyramid, coverage, E2E
│   ├── 08-security.md             # Secrets, supply chain, SAST
│   ├── 09-deployment.md           # Docker, server, monitoring, rollback
│   └── 10-maintenance.md          # Tech debt, cleanup, deprecations
├── stacks/
│   ├── node.md                    # Node.js-specific checks
│   ├── python.md                  # Python-specific checks
│   ├── shell.md                   # Shell/Bash-specific checks
│   ├── docker.md                  # Docker-specific checks
│   ├── monorepo.md                # Monorepo-specific checks
│   ├── claude-code.md             # Claude Code config/skills/agents/hooks checks
│   ├── go.md                      # Go-specific checks
│   ├── terraform.md               # Terraform/IaC-specific checks
│   └── github.md                  # GitHub repo/org security checks
└── templates/
    └── report.md                  # Markdown report template
```

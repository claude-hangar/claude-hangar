# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0] — 2026-03-28

### Added

**New Agent:**
- plan-reviewer — Spec/plan compliance reviewer inspired by Superpowers SDD two-stage review. Verifies implementation matches plan (nothing more, nothing less). Sonnet model, 15 maxTurns.

**New Skill:**
- /handoff — Structured session handoff for seamless context continuity. Creates HANDOFF.md with what was done, key decisions, files modified, known issues, and next steps. Inspired by GSD HANDOFF.json pattern.

**New Documentation:**
- docs/concepts/quality-gates.md — Iron laws, 4-level verification, anti-rationalization patterns, gate functions, forensics. Combines Superpowers + GSD + Hangar quality patterns.

### Changed

**Hook Enhancements (Superpowers + GSD patterns adopted):**

- **task-completed-gate** — Upgraded from simple error check to 4-level quality gate:
  - L1: Existence (empty, placeholder markers like TBD/TODO)
  - L2: Error Resolution (unresolved errors require resolution language)
  - L3: Test Evidence (test tasks must include pass/fail output)
  - L4: Substance (vague one-word results rejected, proportional detail required)
  - Iron Law: "No completion claims without evidence"

- **post-compact** — Smart context preservation replacing generic reminder:
  - Detects active tasks from .tasks.json (in-progress/pending)
  - Finds active plans in docs/superpowers/plans/
  - Detects HANDOFF.md for session continuity
  - Includes branch context for feature work
  - Adds verification reminder (IDENTIFY → RUN → READ → VERIFY → CLAIM)
  - Saves richer recovery snapshots

- **model-router** — Smart complexity analysis replacing simple keyword matching:
  - Structural complexity signals (multi-file scope, multi-step descriptions)
  - Security/audit language detection
  - Prompt length as complexity proxy (>300 chars)
  - Signal weighting (opus signals override haiku keywords)
  - Better false-positive prevention

- **subagent-tracker** — Forensics capabilities added:
  - Duration tracking per agent (warns on >5 min)
  - Thrashing detection (same type 3+ spawns in 2 min)
  - Failure pattern logging (error detection in results)
  - Peak concurrency tracking
  - Session forensics log file for post-mortem analysis
  - Per-type spawn frequency counting

- **skill-rules.json** — CSO-optimized triggers:
  - Added /handoff and /freshness-check rules
  - Better exclusion patterns to prevent false matches
  - Additional trigger keywords per skill (18 total rules)

**Test Suite Expansion:**
- 39 tests total (was 24), added 15 new tests for enhanced hooks:
  - 4-level quality gate: 10 tests (L1-L4 reject + allow paths)
  - Model router: 2 tests
  - Subagent tracker: 3 tests (start, stop, non-event)

**Freshness Opportunity Implementations (10 of 14):**
- Astro v6 checklist: Added V6-PERF-04 (Sharp codec defaults), V6-PERF-05 (SmartyPants), V6-NEW-05 (i18n fallback) — 31 checks total (was 28)
- deploy-check: Added DEPLOY-07 (EU AI Act compliance) and DEPLOY-08 (DSA platform obligations) as conditional checks
- claude-code-referenz: Updated to v2.1.86 with Session-ID header, Jujutsu/Sapling, VS Code plan view, MCP dialog, Opus 4.6 default
- CI template (ci-node.yml): Added timezone-aware cron schedule documentation (March 2026 GH Actions feature)
- audit-runner: Added Verbose/Headless Streaming section for `--verbose` real-time monitoring

### Freshness Check Results (2026-03-28)

| Package | Version |
|---------|---------|
| Claude Code | 2.1.86 |
| Astro | 6.1.1 |
| SvelteKit | 2.55.0 |
| Svelte | 5.55.0 |
| Tailwind CSS | 4.2.2 |
| Vite | 8.0.3 |
| Drizzle ORM | 0.45.2 |
| Drizzle Kit | 0.31.10 |
| bcryptjs | 3.0.3 |
| Next.js | 16.2.1 |
| Zod | 4.3.6 |
| Node.js | 25.8.1 |
| Playwright | 1.58.2 |
| Lighthouse | 13.0.3 |
| @anthropic-ai/sdk | 0.80.0 |

---

## [1.1.1] — 2026-03-26

### Changed

**Documentation Updates (Claude Code 2.1.84):**
- claude-code-referenz — Updated from v2.1.45 to v2.1.84 with all new features:
  - New hook events: TaskCreated, WorktreeCreate
  - New hook type: `http` (for WorktreeCreate and remote integrations)
  - New CLI flags: `--bare` (scripted calls), `--channels` (permission relay)
  - New env vars: CLAUDE_STREAM_IDLE_TIMEOUT_MS, ANTHROPIC_DEFAULT_{OPUS,SONNET,HAIKU}_MODEL_SUPPORTS
  - MCP: 2KB description cap, local/remote deduplication
  - Skills: `paths:` YAML glob list in frontmatter
  - Token display: >=1M shown as "1.5m" instead of "1512.6k"
- writing-hooks — Added TaskCreated + WorktreeCreate events, HTTP hook type documentation
- writing-skills — Added `paths:` frontmatter field documentation
- configuration — Added TaskCreated, WorktreeCreate events, HTTP hook type, CLAUDE_STREAM_IDLE_TIMEOUT_MS
- hook-system — Updated event timeline with all 14 events, registered hooks table
- session-continuity — Added idle-return prompt documentation (75+ min inactivity)

**Stack Version Updates:**
- Astro v6-stable/beta: Updated Vite 8.0.1 → 8.0.3 in as-of dates

### Freshness Check Results (2026-03-26)

| Package | Version |
|---------|---------|
| Claude Code | 2.1.84 |
| Astro | 6.0.8 |
| SvelteKit | 2.55.0 |
| Svelte | 5.55.0 |
| Tailwind CSS | 4.2.2 |
| Vite | 8.0.3 |
| Drizzle ORM | 0.45.1 |
| Drizzle Kit | 0.31.10 |
| bcryptjs | 3.0.3 |
| Next.js | 16.2.1 |
| Zod | 4.3.6 |
| Node.js | 25.8.1 |

---

## [1.1.0] — 2026-03-22

### Added

**New Hooks (3):**
- model-router — Suggests optimal model tier (haiku/opus) based on task complexity keywords (UserPromptSubmit)
- task-completed-gate — Quality gate that rejects tasks with errors or empty results (TaskCompleted)
- subagent-tracker — Tracks subagent lifecycle for observability (SubagentStart/SubagentStop)

**New Hook Events in settings.json:**
- TaskCompleted — Quality gate hook support
- SubagentStart / SubagentStop — Subagent observability

### Changed

**Hook Improvements:**
- post-compact — Now injects context reload reminder after compaction (re-read CLAUDE.md, STATUS.md, .tasks.json). Based on community pattern from Dicklesworthstone/post_compact_reminder
- settings.json.template — Added model-router to UserPromptSubmit hooks

**Stack Version Updates:**
- Astro v6-stable: Updated Vite 7 → 8 references (Vite 8.0.1)
- Astro v6-stable/beta: Updated as-of dates for Astro 6.0.8, Vite 8.0.1, Zod 4.3.6
- Astro audit supplement: Fixed outdated `output: 'hybrid'` reference (removed since Astro 5)
- Auth fix-templates: Updated bcryptjs verify command for ESM (bcryptjs 3.0.3)
- Astro fix-templates: Updated Vite section header to Vite 8

**Documentation:**
- README — Updated hooks table (10 → 13), added Event column, added companion tools (claude-mem, Everything Claude Code)
- Companion tools — Updated star counts

### Freshness Check Results (2026-03-22)

| Package | Version |
|---------|---------|
| Claude Code | 2.1.81 |
| Astro | 6.0.8 |
| SvelteKit | 2.55.0 |
| Svelte | 5.54.1 |
| Tailwind CSS | 4.2.2 |
| Vite | 8.0.1 |
| Drizzle ORM | 0.45.1 |
| Drizzle Kit | 0.31.10 |
| bcryptjs | 3.0.3 |
| Next.js | 16.2.1 |
| Zod | 4.3.6 |
| Node.js | 25.8.1 |

---

## [1.0.0] — 2026-03-20

### Added

**Core Hooks (10):**
- secret-leak-check — Block writes containing API keys, tokens, credentials
- bash-guard — Block destructive commands, validate commits, CI guard
- checkpoint — Git stash snapshots before file edits
- token-warning — Context utilization alerts at 70%/80%
- session-start — STATUS.md/tasks context loading, memory hygiene check
- session-stop — Temp file cleanup, cost logging
- post-compact — Token tracking reset after compaction
- config-change-guard — Log and warn on critical settings changes
- skill-suggest — Suggest matching skills based on user prompts
- stop-failure — Error logging on session failures

**Core Agents (5):**
- explorer — Read-only codebase analysis (Sonnet, fast)
- explorer-deep — Deep architecture analysis (Opus, worktree isolation)
- security-reviewer — OWASP Top 10 + Agentic Top 10 checks (Opus, worktree)
- commit-reviewer — Pre-commit staged changes review (Sonnet)
- dependency-checker — npm audit + outdated + CVE research (Sonnet)

**Core Skills (17):**
- scan — Project tech stack detection and profiling
- consult — Interactive project improvement consultant
- audit — Three-layer website audit (9 phases)
- project-audit — Repository audit (10 phases)
- adversarial-review — Critical review with min. 5 findings
- polish — Frontend enhancement (6 dimensions, 7 modes)
- deploy-check — Docker/Traefik deployment readiness
- git-hygiene — Repository health checks
- lesson-learned — Learning extraction to memory system
- capture-pdf — Multi-page website PDF capture
- favicon-check — Icon and favicon completeness
- meta-tags — SEO meta-tag validation
- lighthouse-quick — Core Web Vitals performance check
- design-system — Tailwind v4 design reference
- freshness-check — Framework version currency tracking
- audit-orchestrator — Multi-audit coordination
- audit-runner — Autonomous batch audit execution

**Stack Extensions (4):**
- astro — Astro v5/v6 migration checklists and audit
- sveltekit — SvelteKit 2 + Svelte 5 runes migration
- database — Drizzle ORM + PostgreSQL audit
- auth — bcryptjs + sessions security audit

**Infrastructure:**
- Interactive setup wizard (setup.sh) with --check, --verify, --rollback, --update
- One-liner installer (install.sh)
- CLAUDE.md template engine with {{PLACEHOLDER}} system
- 4 project templates (minimal, web, fullstack, management)
- 5 CI/CD templates (Node.js, Python, VPS/GHCR, GitHub Pages, Cloudflare Pages)
- Multi-project registry with JSON schema validation
- Statusline with OAuth usage tracking, context bar, burn rate
- Shared lib (common.sh) with OS detection, logging, path conversion

**Documentation (18 files):**
- Getting started, configuration, multi-project guides
- Writing guides: skills, hooks, agents
- Architecture overview with system flow diagrams
- 5 concept docs: three-layer audit, state management, skill lifecycle, hook system, session continuity
- 4 tutorials: first audit, custom skill, multi-project setup, statusline customization
- Patterns reference (anti-patterns, root cause analysis)
- FAQ (15+ questions)

**Community:**
- Issue templates (bug report, feature request, skill request)
- Contributing guide, Code of Conduct, Security policy
- Release and welcome workflows
- i18n structure with German placeholder

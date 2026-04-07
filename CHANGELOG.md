# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased] — 2026-04-08

### Updated — Full Freshness Check (Vite 8.0.7, Svelte 5.55.2, Lighthouse 13.1.0, SDK 0.85.0, Community Sync)

#### Version Updates
| Package | Previous | Current |
|---------|----------|---------|
| Vite | 8.0.3 | 8.0.7 |
| Svelte | 5.55.1 | 5.55.2 |
| Lighthouse | 13.0.3 | 13.1.0 |
| Claude Code | 2.1.92 | 2.1.94 |
| Anthropic SDK | 0.82.0 | 0.85.0 |
| GSD v1 | 1.33.0 | 1.34.2 |
| GSD v2 | 2.64.0 | 2.65.0 |
| oh-my-opencode | 3.15.2 | 3.15.3 |

#### Checklist & Reference Updates
- **Astro v6-stable** — Updated as-of dates for Vite 8.0.7
- **Astro v6-beta** — Updated as-of dates for Vite 8.0.7
- **SvelteKit checklist** — Updated as-of for Svelte 5.55.2
- **.freshness-state.json** — Full sync: all 37 sources current, 12 open opportunities

#### New Documentation
- **capability-surface-guide.md** — Decision tree for Rule vs Skill vs MCP vs Hook vs Agent (inspired by ECC)
- **skill-adaptation-policy.md** — Governance for adopting patterns from community repos (inspired by ECC)
- **troubleshooting.md** — Added "Known Upstream Bugs" section (stdin consumption, hook hot-reload, MCP auth, 529 errors)

#### Community Sync
- GSD v2.65.0: Pre-execution plan verification, post-execution consistency checks, intent+phase guards
- oh-my-opencode v3.15.3: Session origins tracking, lineage-aware continuation
- ECC v1.10.0: Capability surface selection, skill adaptation policy, hook troubleshooting patterns adopted
- All 19 community repos checked and as-of dates updated

---

## [Unreleased] — 2026-04-07

### Updated — Astro 6.1.4 & GSD v1.34 Freshness

#### Astro Stack
- **v6-stable/checklist.md** — Updated for Astro 6.1.4 (Cloudflare miniflare restart, React 19 Float fix, dotted filenames, barrel file cleanup)
- **v6-stable/reference-links.md** — Version bump to 6.1.4
- **v6-beta/changelog.md** — Added full 6.1.x section (6.1.0 features: Sharp codec config, SmartyPants, i18n fallback routes; patch releases 6.1.1–6.1.4)
- **SKILL.md** — Updated latest version reference (6.0.8 → 6.1.4, checklist count 28 → 31)
- **audit/stacks/frontend/astro.md** — Updated as-of to 6.1.4

#### Companion Tools
- **docs/companion-tools.md** — GSD v1 section rewritten for v1.34 (60+ commands, 19+ agents, 12+ runtimes, GSD SDK, Workstreams, Advisor Mode, Global Learnings Store, Codebase Intel, Autonomous Mode, Execution Profiles)

---

## [Unreleased] — 2026-04-05

### Added — ECC Integration Phase 2c (Could-Haves)

#### New Skills (4)
- **safety-guard** — 3-mode write protection (Careful/Freeze/Guard) for autonomous agent runs
- **rules-distill** — Meta-governance: scans skills to extract cross-cutting principles as shared rules
- **skill-stocktake** — Skill quality audit across 4 dimensions (actionability, scope, uniqueness, currency)
- **prompt-optimizer** — 6-phase advisory pipeline: project detection, intent analysis, skill matching

#### New Agents (2)
- **harness-optimizer** (Opus) — Self-optimization of hooks, skills, rules, context modes, agent routing
- **performance-optimizer** (Opus) — Active analysis: bundle size, Core Web Vitals, memory leaks, DB queries

#### New Hooks (1)
- **config-protection** — Blocks weakening of linter/formatter/compiler configs (tsconfig strict, eslint rules, biome, etc.)

#### New Templates (1)
- **DECISIONS.md** — Append-only Architectural Decision Register (ADR) inspired by GSD v2

#### Inspired By
- [Everything Claude Code](https://github.com/affaan-m/everything-claude-code) — config-protection, rules-distill, skill-stocktake, safety-guard, prompt-optimizer, harness-optimizer
- [GSD v2](https://github.com/gsd-build/gsd-2) — DECISIONS.md append-only ADR pattern

---

### Added — ECC Integration Phase 2

#### New Skills (3)
- **verification-loop** — Pre-PR 6-phase quality pipeline (build, types, lint, test, security, diff)
- **context-budget** — Token spending analysis and optimization opportunities
- **strategic-compact** — Smart /compact timing based on workflow state

#### New Agents (2)
- **tdd-guide** — TDD enforcement (RED-GREEN-REFACTOR cycle, 80%+ coverage)
- **doc-updater** — Documentation maintenance and staleness detection

#### New Rules (4)
- `rules/common/development-workflow.md` — Structured 5-phase dev workflow
- `rules/common/hooks.md` — Hook design principles and governance
- `rules/common/patterns.md` — Positive design patterns (repository, service layer, API format)
- `rules/common/code-review.md` — Centralized review process and severity classification

#### Documentation
- `docs/token-optimization.md` — 7 strategies for context budget management
- `docs/agentic-security.md` — Security guide (Lethal Trifecta, threat model, production checklist)

---

### Added — ECC Integration Phase 1

#### Rules System (7 common + 8 language-specific rule files)
- `rules/common/` — coding-style, security, testing, git-workflow, agents, performance, governance
- `rules/typescript/` — patterns and testing
- `rules/python/` — patterns and testing
- `rules/go/` — patterns and testing
- `rules/rust/` — patterns
- `rules/java/` — patterns

#### Context Modes (3 modes)
- `core/contexts/dev.md` — active development focus
- `core/contexts/research.md` — exploration and understanding
- `core/contexts/review.md` — PR review and code analysis

#### New Agents (9)
- **planner** — Implementation planning (Opus)
- **architect** — System design and architecture (Opus)
- **loop-operator** — Autonomous workflow with safety guardrails (Sonnet)
- **typescript-reviewer** — TypeScript code review (Sonnet)
- **python-reviewer** — Python code review (Sonnet)
- **go-reviewer** — Go code review (Sonnet)
- **build-resolver-typescript** — TS build error resolution (Sonnet)
- **build-resolver-python** — Python build error resolution (Sonnet)
- **build-resolver-go** — Go build error resolution (Sonnet)

#### Learning System
- **continuous-learning hook** — Captures command patterns and outcomes
- **instinct-evolve hook** — Extracts session learnings with confidence scores
- **pattern-extractor skill** — Analyzes patterns for reusable workflows

#### Enhanced Hooks
- **cost-tracker** — Session metrics and tool usage tracking
- **desktop-notify** — OS-native notifications (macOS, Linux, Windows)
- **hook-profiles** — Environment-based hook strictness (minimal/standard/strict)

### Inspired By

- [Everything Claude Code](https://github.com/affaan-m/everything-claude-code)

---

## [1.2.1] — 2026-03-28

### Fixed

**Bug Fixes (4):**
- **secret-leak-check** — `grep` misinterpreted patterns starting with `-----` as options, causing private key detection to silently fail. Fixed with `grep -- "$PATTERN"`.
- **registry.schema.json** — Schema rejected its own example because `$schema` was not declared as an allowed root property. Added `$schema` to schema properties.
- **audit-runner.sh** — Replaced `new Function()` eval (security risk) with safe dot-path property accessor for JSON config reading.
- **statusline-command.sh** — `stat -c %Y` (GNU syntax) failed silently on macOS. Added fallback to `stat -f %m` for cross-platform file mtime.

**Security Hardening (2):**
- **CI secret-scan** — Was excluding `--exclude-dir=core --exclude-dir=hooks --exclude-dir=stacks` etc., effectively scanning only ~5% of the repo. Removed overly broad exclusions, now scans all code files. Added allowlists for known documentation patterns.
- **mcp/install.sh** — Fixed path injection risk where file paths were interpolated directly into Node.js `eval` strings. Paths are now passed via `process.env` environment variables.

### Changed

**CI/CD Improvements:**
- **Test execution in CI** — Added new `tests` job to ci.yml that runs `test-hooks.sh` and `test-setup.sh`. Previously, CI only ran static analysis (ShellCheck, JSON, markdown lint, secret scan) but never executed the test suites.
- **release.yml** — Updated `actions/checkout` from v4 SHA to v6 SHA (consistent with ci.yml).
- **All 5 CI templates** — Added `timeout-minutes` and `concurrency` blocks. Updated `actions/checkout` and `actions/setup-node` from v4 to v6 SHAs.

**Shell Script Optimization:**
- **common.sh** — Fixed logging functions (`$1` → `$*`) to preserve multi-argument messages. Removed dead `jq` prerequisite from `check_prereqs()` (project philosophy: no jq dependency). Added `file_mtime()` cross-platform helper.
- **statusline-command.sh** — Changed shebang from `#!/bin/bash` to `#!/usr/bin/env bash` for consistency.

**Consistency & Completeness:**
- **skill-rules.json** — Added 4 missing stack audit skills (`/astro`, `/sveltekit`, `/database`, `/auth`) with trigger keywords. These were previously absent and would never be auto-suggested.
- **Skill frontmatter** — Added missing `name` field to `/consult` and `/scan` SKILL.md. Added complete frontmatter block to `/handoff` SKILL.md (was missing entirely).
- **MCP configs** — Standardized `@latest` tag usage: removed from `@playwright/mcp`, `snyk`, and `@upstash/context7-mcp` (redundant with `npx -y` default behavior).
- **docs/architecture.md** — Fixed agent count (5 → 6), skill count (17 → 18), added missing stacks (github, security, web) to directory tree.

**Test Suite Expansion (121 tests, was 39):**
- **test-hooks.sh** (56 tests, was 35):
  - bash-guard: +12 tests covering all 15 blocking patterns (chmod 777, git push --force, git reset --hard, npm publish, DROP TABLE, rm -rf ~, rm -rf ., mkfs, dd)
  - secret-leak-check: +6 tests (AWS keys, private keys, database URLs, Slack tokens, Stripe keys, .env files)
- **test-setup.sh** (65 tests, was 16):
  - +18 skill frontmatter validation tests (verifies all 18 skills have proper frontmatter)
  - +6 agent frontmatter validation tests (verifies all 6 agents have model field)
  - +22 skill-rules cross-reference tests (verifies every rule points to an existing skill directory)
  - +3 registry validation tests (schema exists, example exists, example is valid JSON)

**Documentation Updates:**
- README.md — Fixed setup output (Agents: 5 → 6, Skills: 17 → 18)
- docs/getting-started.md — Fixed agent count (5 → 6), skill count (14+ → 18), added plan-reviewer to agent listing
- docs/architecture.md — Added github/security/web stacks to directory tree
- docs/awesome-claude-code-submission.md — Updated component counts in description and verification script
- docs/tutorials/setup-und-scripts.md — Updated summary counts

---

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

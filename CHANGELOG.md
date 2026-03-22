# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

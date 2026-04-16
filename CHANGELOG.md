# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

#### Audit-Orchestrator — Universal Mode + Resumable Session Directory (2026-04-16)
- **`core/skills/audit-orchestrator/universal-workflow.md`** (NEU) — Project-type-agnostischer Pre-Scan -> Analyse -> Optimierung -> Report Workflow. Entscheidungstabelle fuer 16 Project-Types (web-astro/sveltekit/nextjs, infra-docker/iac/homelab, python/go/rust/node-app/node-lib, monorepo, docs, data-ml, meta-automation, generic). Jede Phase mit Inputs/Actions/Outputs/Exit-Criteria. Severity-Skala CRITICAL/HIGH/MEDIUM/LOW. Resume-Protokoll fuer neue Instanzen.
- **`core/skills/audit-orchestrator/session-schema.md`** (NEU) — Session-Directory-Layout `.audit-session/<YYYY-MM-DD>-<slug>/` mit INDEX.md + STATUS.md + 4 Phase-Ordnern (01-prescan, 02-analysis, 03-optimization, 04-report). Templates fuer INDEX.md, STATUS.md, findings-Tabelle (ID-Konvention SEC-/DEP-/GIT-/CI-/INFRA-/MIG-...), TODO.md mit Severity-Gruppen, changes.md. Resume-Konventionen: STATUS.md last-updated ISO-8601, "next action"-Zeile, "active instance"-Claim vor erstem Tool-Call.
- **`core/skills/audit-orchestrator/SKILL.md`** — Umgeschrieben als Universal-Orchestrator. Neuer Intro mit "Two Modes" (Universal default / Web Orchestration Specialization). Session-Directory und Resume-Protokoll als erste Abschnitte. Step 0 "Session Init" ergaenzt (legt Directory + INDEX.md + STATUS.md an). Step 1 erweitert um universal Project-Type-Decision. Rules-Sektion erweitert um Session-Directory-Regeln und "Any instance can resume". Reference-Files-Abschnitt verweist auf alle 3 Markdown-Schemas.
- **`core/skills/audit-orchestrator/skill.json`** — Version `2.0.0`. Description spiegelt Universal-Modus wider (nutzt die neue 1536-Zeichen-Description-Cap aus v2.1.105). Triggers ergaenzt um `infra audit`, `homelab audit`, `repo audit`, `orchestrate audit`, `pre-scan analysis optimization report`, `resume audit session`. `dataFiles` verweist auf `universal-workflow.md`, `session-schema.md`, `state-schema.md`.
- **Crash-Resilienz:** Session-State lebt in Plain-Markdown statt JSON — jede fremde Instanz (auch anderes LLM) liest INDEX.md + STATUS.md und macht weiter. Legacy `.audit-orchestrator-state.json` bleibt fuer Web-Path erhalten (Koexistenz).

#### Freshness Sync — Claude Code v2.1.111 + Opus 4.7 (2026-04-16)
- **`core/lib/defaults.json`** — `models.opus` auf `claude-opus-4-7` gehoben (neues Flagship-Modell, 16. April 2026). Alias-Chain `opus` -> `claude-opus-4-7` greift in allen Agents automatisch.
- **`tests/test-models.sh`** — `VALID_FULL_IDS` enthaelt jetzt `claude-opus-4-7` (zusaetzlich zu 4-6, Sonnet 4-6, Haiku 4-5-20251001). Test validiert weiterhin Defaults + Agent-Frontmatter.
- **`core/statusline-command.sh`** — Effort-Case erweitert um neue Level aus v2.1.111: `xhigh` -> `xhi`, `max` -> `max`. Vorher faelschlich als `hi` gerendert. Strip-Comment auf "Opus 4.7 (1M context)" aktualisiert.
- **`docs/claude-code-referenz.md`** — Header auf v2.1.111 (16. April 2026); vollstaendiger Aenderungs-Abschnitt fuer v2.1.111 mit Features (Opus 4.7, `xhigh` Effort, `/effort`-Slider, Auto-Mode, `/less-permission-prompts` Built-in, `/ultrareview`, "Auto (match terminal)" Theme, PowerShell-Tool Windows, `OTEL_LOG_RAW_API_BODIES`), Verbesserungen und Fixes. Modell-Tabelle ergaenzt (Opus 4.7 als Flagship), Context-Window-Abschnitt zeigt 1M fuer 4.6+4.7, neuer Effort-Levels-Block, Commands-Tabelle erweitert um `/effort`, `/ultrareview`, `/less-permission-prompts`, `/theme`.
- **`docs/configuration.md` + `docs/tutorials/statusline-customization.md`** — Beispiel-Statuslines auf `Opus 4.7` + `xhi` Effort aktualisiert; Effort-Level-Liste auf `low/med/hi/xhi/max` erweitert.
- **`templates/ci/ci-claude-review.yml`** — Model-Hint-Kommentar zeigt aktuelle Optionen (`claude-sonnet-4-6`, `claude-opus-4-7`); stale `sonnet-4-5-20250514` Referenz entfernt.

#### Freshness Opportunities — Claude Code v2.1.105 follow-through (2026-04-14)
- **`core/hooks/pre-compact.sh`** — Opt-in Block-Gate via `HANGAR_BLOCK_COMPACT=1`: blockiert `/compact` wenn aktive `in_progress`-Tasks + uncommitted Changes + kein `HANDOFF.md`. Exit 2 mit erklaerender stderr-Nachricht (Resolve-Optionen). Nutzt die neue Block-Semantik aus Claude Code v2.1.105 PreCompact-Hook.
- **`core/settings.json.template`** — `permissions.deny` Sektion mit 8 destruktiven Bash-Patterns (rm -rf, rm -r /, git reset --hard, git push --force, git push -f, npm publish, docker system prune, docker rmi). Deklarative Defense-in-Depth zusaetzlich zu `permission-denied-retry.sh`. Nutzt v2.1.101-Fix: deny-Rules ueberschreiben Hook `permissionDecision: "ask"`.
- **`docs/monitors.md`** — Migrations-Guide fuer das neue `monitors` Plugin-Manifest-Feld aus v2.1.105. Kandidaten-Liste (cost-tracker, token-warning, batch-format-collector) fuer spaetere Migration, sobald Schema-Beispiele stabilisieren.
- **`docs/troubleshooting.md`** — Neuer Abschnitt "Network / TLS": Corporate TLS/MITM-Proxy loest sich mit v2.1.101 OS-CA-Store-Trust ohne Extra-Config; Opt-out `CLAUDE_CODE_CERT_STORE=bundled`. Slow-Stream-Abschnitt zu v2.1.105 5-min-timeout.
- **`tests/test-hooks.sh`** — 3 neue Tests fuer pre-compact Block-Gate (default disabled, empty input, enabled without wip markers).
- **`TODO.md`** — Neuer Nice-to-have N1: Migration continuous-poll-Hooks zu Plugin-Monitors sobald Schema stabilisiert.

#### Full Audit & Upgrade — Session 2 (2026-04-11)
- **5 new skills** — `/review-team`, `/debug-team`, `/security-team` (team presets with parallel agents), `/hook-gen` (natural language to hook configs), `/export-rules` (Cursor/Windsurf/Copilot format export)
- **`core/lib/merge-settings.js`** — Deep-merge engine for settings.json: appends missing hooks per event (deduplicates by command), adds missing MCP servers, preserves all user configuration
- **`tests/hangar-lint.sh`** — Configuration linter validating 180+ checks across 7 categories
- **`--lite` install mode** — 5-minute setup with safety essentials only (5 hooks, 3 skills, 1 MCP)
- **4 remote HTTP MCP servers** — Notion (`mcp.notion.com/mcp`), Sentry (`mcp.sentry.dev/mcp`), Stripe (`mcp.stripe.com`), Linear (`mcp.linear.app/mcp`) — all OAuth, zero local install
- **`.claude-plugin/marketplace.json`** — Marketplace descriptor compatible with `obra/superpowers-marketplace`
- **`AGENTS.md`** template — Cross-tool agent configuration (Cursor, Windsurf, Copilot)
- **`DESIGN.md`** template — Comprehensive design system documentation
- **`HANGAR_TERSE`** env var — Token-efficient hook output mode (~60% savings)
- **`session-dashboard.sh`** — Session metrics summary (costs, subagents, patterns, instincts)
- **`memory-optimization.md`** — 3-layer retrieval strategy guide
- **Instinct confidence scoring** — Accumulative confidence with auto-promotion at threshold
- **8 hook profile switching tests** + HTTP server validation in MCP tests

#### Full Audit & Upgrade — Session 1 (2026-04-11)
- **`.claude-plugin/plugin.json`** — Plugin manifest enabling installation via `/plugin install`. Declares 34 skills (6 paths including stacks), 21 agents, hooks config.
- **`hooks/hooks.json`** — Centralized hook event mapping for plugin system. Maps all 30 hooks across 14 event types with `${CLAUDE_PLUGIN_ROOT}` paths.
- **`AUDIT.md`** — Complete inventory of all 100+ components with status, versions, and issues
- **`RESEARCH.md`** — External findings: CLI v2.1.101, MCP spec 2025-11-25, SDKs, 20+ competitor analyses
- **`TODO.md`** — 5 Must + 10 Should + 14 Nice-to-have prioritized upgrade tasks
- **3 new hooks** — `post-tool-failure.sh` (PostToolUseFailure), `session-end.sh` (SessionEnd), `pre-compact.sh` (PreCompact) for recently added Claude Code lifecycle events
- **CI template** — `ci-claude-review.yml` using official `anthropics/claude-code-action` for automated PR reviews
- **`effort` field** — Added to 29 skills and 10 agents (low for quick checks, high for deep analysis)

### Changed

#### Freshness Sync — Claude Code v2.1.105 + Astro 6.1.6 + SvelteKit 2.57.1 (2026-04-14)
- **`docs/claude-code-referenz.md`** — Header auf v2.1.105 (13. April 2026) aktualisiert; neue Abschnitte fuer v2.1.101 und v2.1.105 (EnterWorktree path-Param, blockierende PreCompact-Hooks, `monitors` Plugin-Manifest-Feld, `/proactive` Alias, `/team-onboarding`, OS-CA-Store-Trust, CRITICAL command-injection fix im LSP `which`-Fallback, zahlreiche Resume/Permission/MCP/Plugin-Fixes)
- **`stacks/astro/versions/v6-beta/changelog.md`** — Eintrag fuer Astro 6.1.6 ergaenzt (Actions `ActionsWithoutServerOutputError` bei `output: 'static'` + Adapter, Special-Chars in inline `<script>`, SCSS/CSS-Module HMR statt Full-Reload); As-of-Date auf 2026-04-14 gesetzt
- **`stacks/astro/versions/v6-beta/reference-links.md`** + **`stacks/astro/versions/v6-stable/checklist.md`** + **`stacks/astro/versions/v6-stable/reference-links.md`** — As-of auf 2026-04-14 (Astro 6.1.6)
- **`stacks/sveltekit/versions/kit2-svelte5/checklist.md`** — As-of auf 2026-04-14 (SvelteKit 2.57.1 Patch: strictere `redirect()`-Validation, `BODY_SIZE_LIMIT` auf chunked requests, Default-Values als Fallbacks, Form-Typings fuer Union-Types relaxed; Svelte 5.55.3 Patch: HMR fuer dynamische Components, @const-Blockers, Derived-Freeze nach Effect-Destroy, deferred Error-Boundary in Forks, Reactivity-Loss-False-Positives reduziert)
- **`core/skills/design-system/SKILL.md`** — Description erweitert um spezifischere Trigger-Terms (layout, spacing, shadow, gradient, animation, theme, dark mode, cta, section, landing page, hero section). Profitiert vom neuen v2.1.105 Skill-Description-Cap (250 -> 1536 Zeichen).

#### Full Audit & Upgrade — Session 2 (2026-04-11)
- **setup.sh** — Smart settings merge + `--lite` install mode
- **`plugin.json`** — Updated to superpowers-marketplace schema (v1.1.0)
- **hook-profiles.md** — Updated counts, added HANGAR_TERSE documentation
- **`batch-format-collector.sh` + `stop-batch-format.sh`** — Profile corrected strict → standard
- **`skills_index.json`** — 36 skills total, new categories (teams, cross-ide, devops)
- **`skill-rules.json`** — Trigger rules for 5 new skills
- **`skill-suggest.sh` + `model-router.sh`** — Terse output mode support
- **`instinct-evolve.sh`** — Confidence scoring + auto-promotion
- **`test-mcp.sh`** — HTTP server validation, fixed stack config test
- **`writing-skills.md`** — Skill-scoped hooks documentation

#### Full Audit & Upgrade — Session 1 (2026-04-11)
- **All 14 Sonnet agents → Opus** — build-resolver-go/python/typescript, commit-reviewer, dependency-checker, doc-updater, explorer, go-reviewer, loop-operator, plan-reviewer, python-reviewer, tdd-guide, test-writer, typescript-reviewer
- **GitHub MCP** — Deprecated `@modelcontextprotocol/server-github` → remote HTTP `https://api.githubcopilot.com/mcp/` (OAuth)
- **PostgreSQL MCP** — Broken `@crystaldba/postgres-mcp` → `@bytebase/dbhub` (supports PostgreSQL, MySQL, SQLite)
- **Skill frontmatter** — Standardized 35 SKILL.md files to official hyphenated format (`user-invocable`, `argument-hint`, `disable-model-invocation`)
- **settings.json.template** — Added PostToolUseFailure, PreCompact, SessionEnd hook events
- **Documentation** — Updated writing-skills.md (9 new fields, variables), writing-hooks.md (7 new events, hookSpecificOutput format), writing-agents.md (new fields, model table), mcp-guide.md (HTTP transport, OAuth, .mcp.json, scopes)

#### Freshness Check & Community Sync (2026-04-08)

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

- All 37 freshness sources current, 19 community repos synced
- New docs: capability-surface-guide.md, skill-adaptation-policy.md, troubleshooting.md (upstream bugs)

#### Astro Stack Updates (2026-04-07)
- **v6-stable/checklist.md** — Updated for Astro 6.1.4 (Cloudflare miniflare restart, React 19 Float fix, dotted filenames, barrel file cleanup)
- **v6-stable/reference-links.md** — Version bump to 6.1.4
- **v6-beta/changelog.md** — Added full 6.1.x section (6.1.0–6.1.4)
- **SKILL.md** — Updated latest version reference (6.0.8 → 6.1.4, checklist count 28 → 31)
- **docs/companion-tools.md** — GSD v1 section rewritten for v1.34

### Fixed

#### Full Audit & Upgrade (2026-04-11)
- **Deprecated hook output format** — Migrated `bash-guard.sh` (5 outputs) and `secret-leak-check.sh` (1 output) from `{"decision":"block","reason":"..."}` to `{"hookSpecificOutput":{"permissionDecision":"block","permissionDecisionReason":"..."}}` (deprecated since v2.1.77+)
- **Hook profile mismatch** — `batch-format-collector` and `stop-batch-format` had `HOOK_MIN_PROFILE="strict"` but belonged to standard profile per documentation

#### Infrastructure Fixes (2026-04-08)
- **settings.json.template** — Synced with hook-profiles.md: added 5 missing standard hooks (db-query-guard, design-quality-check, mcp-health-check, batch-format-collector, stop-batch-format), removed 2 strict-only hooks from standard template
- **skill.json** — Added missing metadata files for 4 governance skills (prompt-optimizer, rules-distill, safety-guard, skill-stocktake)
- **README.md** — Corrected Node.js minimum version from >= 22.12.0 to >= 18 LTS

---

#### ECC Integration Phase 2c — Skills, Agents, Hooks (2026-04-05)
- **safety-guard** skill — 3-mode write protection (Careful/Freeze/Guard) for autonomous agent runs
- **rules-distill** skill — Meta-governance: scans skills to extract cross-cutting principles as shared rules
- **skill-stocktake** skill — Skill quality audit across 4 dimensions (actionability, scope, uniqueness, currency)
- **prompt-optimizer** skill — 6-phase advisory pipeline: project detection, intent analysis, skill matching
- **harness-optimizer** agent (Opus) — Self-optimization of hooks, skills, rules, context modes, agent routing
- **performance-optimizer** agent (Opus) — Active analysis: bundle size, Core Web Vitals, memory leaks, DB queries
- **config-protection** hook — Blocks weakening of linter/formatter/compiler configs (tsconfig strict, eslint rules, biome, etc.)
- **DECISIONS.md** template — Append-only Architectural Decision Register (ADR) inspired by GSD v2

#### ECC Integration Phase 2 — Skills, Agents, Rules, Docs (2026-04-05)
- **verification-loop** skill — Pre-PR 6-phase quality pipeline (build, types, lint, test, security, diff)
- **context-budget** skill — Token spending analysis and optimization opportunities
- **strategic-compact** skill — Smart /compact timing based on workflow state
- **tdd-guide** agent — TDD enforcement (RED-GREEN-REFACTOR cycle, 80%+ coverage)
- **doc-updater** agent — Documentation maintenance and staleness detection
- 4 governance rules: development-workflow, hooks, patterns, code-review
- `docs/token-optimization.md` — 7 strategies for context budget management
- `docs/agentic-security.md` — Security guide (Lethal Trifecta, threat model, production checklist)

#### ECC Integration Phase 1 — Rules, Contexts, Agents, Learning (2026-04-05)
- **Rules system** — 7 common + 8 language-specific rule files (TypeScript, Python, Go, Rust, Java)
- **Context modes** — dev, research, review (3 modes)
- 9 new agents: planner, architect, loop-operator, 3 language reviewers, 3 build resolvers
- **Learning system** — continuous-learning hook, instinct-evolve hook, pattern-extractor skill
- **Enhanced hooks** — cost-tracker, desktop-notify, hook-profiles (minimal/standard/strict)

### Inspired By
- [Everything Claude Code](https://github.com/affaan-m/everything-claude-code)
- [GSD v2](https://github.com/gsd-build/gsd-2)

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

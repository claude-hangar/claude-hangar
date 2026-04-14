# Claude Hangar — Upgrade Plan

**Date:** 2026-04-11
**Source:** AUDIT.md + RESEARCH.md
**Format:** Each task is self-contained for follow-up sessions.

---

## NICE-TO-HAVE — Pending Schema Stabilization

### N1: Migrate continuous Hangar scripts to Plugin Monitors (v2.1.105+)
- **What:** Migrate `cost-tracker.sh` and `token-warning.sh` from PostToolUse hooks to background monitors declared in `monitors/monitors.json`. These scripts are continuous (poll state each tick), not event-driven, so a monitor matches their shape better.
- **Where:** `.claude-plugin/plugin.json` (add `"monitors": "./monitors/monitors.json"`), new `monitors/monitors.json`
- **Why:** Claude Code v2.1.105 introduces a `monitors` top-level manifest key that auto-arms at session start or on skill invoke. A monitor streams stdout lines back to the model as events — the natural fit for polling/tailing scripts.
- **Blocker:** The schema of entries inside `monitors.json` is referenced in the plugins-reference but not yet shown in a stable example. Migrate once the official docs or an authoritative plugin publishes a concrete example.
- **Tracking doc:** `docs/monitors.md`

---

## MUST — Broken/Deprecated (fix now)

### M1: Fix deprecated MCP server references
- **What:** Replace `@modelcontextprotocol/server-github` with `github/github-mcp-server` Go binary or remote HTTP
- **Where:** `core/mcp/registry.json`, `stacks/github/mcp.json`
- **Why:** Package is deprecated, development moved to official GitHub MCP server
- **Action:** Update `package` field, add `transport: "http"` option with OAuth URL

### M2: Fix broken PostgreSQL MCP reference
- **What:** Replace `@crystaldba/postgres-mcp` (doesn't exist on npm) with working alternative
- **Where:** `core/mcp/registry.json`, `stacks/database/mcp.json`
- **Why:** Package name doesn't resolve — users get install failures
- **Action:** Switch to `postgres-mcp` (npm v1.0.4) or `@bytebase/dbhub`

### M3: Fix deprecated PreToolUse hook output format
- **What:** Migrate all PreToolUse hooks from top-level `decision`/`reason` to `hookSpecificOutput.permissionDecision`/`hookSpecificOutput.permissionDecisionReason`
- **Where:** `core/hooks/bash-guard.sh`, `config-change-guard.sh`, `config-protection.sh`, `db-query-guard.sh`, `secret-leak-check.sh`
- **Why:** Top-level fields are deprecated since v2.1.77+
- **Action:** Audit each hook's stdout JSON, update output format

### M4: Update all agent models to Opus
- **What:** Change `model: sonnet` → `model: opus` on all 13 affected agents
- **Where:** `core/agents/`: build-resolver-go, build-resolver-python, build-resolver-typescript, commit-reviewer, dependency-checker, doc-updater, explorer, go-reviewer, loop-operator, plan-reviewer, python-reviewer, tdd-guide, test-writer, typescript-reviewer
- **Why:** User preference requires all subagents use Opus (see `feedback_always_opus.md`)
- **Action:** Simple find-and-replace in frontmatter

### M5: Create `.claude-plugin/plugin.json`
- **What:** Add plugin manifest so Hangar can be installed via `/plugin install`
- **Where:** New directory `.claude-plugin/` with `plugin.json`
- **Why:** The official plugin ecosystem is now the primary distribution channel. Without this, Hangar is invisible to the marketplace. This is an existential gap.
- **Action:** Create `plugin.json` with skills, agents, hooks, MCP references. Test with `/plugin install`.

---

## SHOULD — Clear Improvement Value

### S1: Standardize skill frontmatter naming
- **What:** Change `user_invocable` → `user-invocable`, `argument_hint` → `argument-hint` in all skills
- **Where:** All 31 `core/skills/*/SKILL.md` files
- **Why:** Official Claude Code docs use hyphenated format
- **Action:** sed/replace across all SKILL.md files, verify skills still load

### S2: Add `effort` field to all skills and agents
- **What:** Set appropriate effort levels on all components
- **Where:** All SKILL.md and agent .md files
- **Mapping:**
  - `effort: low` — favicon-check, lighthouse-quick, meta-tags, codebase-map, inline-review, explorer, commit-reviewer
  - `effort: high` — adversarial-review, verification-loop, audit, security-scan, planner, security-reviewer, architect
  - Default (medium) — everything else
- **Why:** Controls model reasoning effort, improves cost efficiency

### S3: Add missing hook events
- **What:** Create hooks for `PostToolUseFailure`, `SessionEnd`, `PreCompact`
- **Where:** `core/hooks/`
- **Details:**
  - `post-tool-failure.sh` — Capture tool failure patterns, feed to learning system
  - `session-end.sh` — Replace/supplement `session-stop.sh` with richer data (`end_reason`, `session_duration_seconds`)
  - `pre-compact.sh` — Save critical state before context compaction
- **Why:** New lifecycle events provide better observability and state management

### S4: Add `if` conditionals to guard hooks
- **What:** Move command matching from shell scripts to settings.json `if` field
- **Where:** settings.json hook definitions for `bash-guard`, `db-query-guard`, `config-protection`
- **Example:** `"if": "Bash(rm -rf *)"` instead of parsing JSON in bash
- **Why:** Simpler, faster, less error-prone than manual command parsing in shell

### S5: Add CI template with `anthropics/claude-code-action`
- **What:** Create CI workflow template using official GitHub Action
- **Where:** `templates/ci/ci-claude-review.yml`
- **Why:** Official action (7K stars) is the standard approach for CI integration
- **Action:** Create template with PR review + code change workflows

### S6: Update documentation for new CLI features
- **What:** Update writing-skills.md, writing-hooks.md, writing-agents.md, mcp-guide.md
- **Where:** `docs/`
- **Details:**
  - `writing-skills.md` — Add `effort`, `paths`, `hooks`, `shell`, `${CLAUDE_SKILL_DIR}` docs
  - `writing-hooks.md` — Add new events, `if` conditionals, `type: "http"`, `once`, `async`
  - `writing-agents.md` — Add `effort`, `maxTurns`, `disallowedTools`, `initialPrompt`
  - `mcp-guide.md` — Remote HTTP transport, OAuth, deprecated SSE, .mcp.json standard
- **Why:** Current docs don't cover capabilities available since v2.1.69+

### S7: Add `maxTurns` and `disallowedTools` to agents
- **What:** Set safety limits on all agents
- **Where:** All `core/agents/*.md` files
- **Mapping:**
  - Reviewer agents: `disallowedTools: [Edit, Write]`, `maxTurns: 15`
  - Build resolvers: `maxTurns: 25`
  - Planner/architect: `maxTurns: 20`
  - Explorer: `maxTurns: 10`
- **Why:** Prevents runaway agent execution, enforces read-only for reviewers

### ~~S8: Implement runtime hook profile switching~~ DONE
Fixed profile mismatch (batch-format strict→standard), added 8 tests. hook-gate.sh was already implemented.

### ~~S9: Add remote HTTP MCP servers to registry~~ DONE
Added Notion, Sentry, Stripe, Linear as remote HTTP servers with OAuth.

### ~~S10: Smart settings merge in setup.sh~~ DONE
Implemented merge-settings.js deep-merge engine. Preserves all user config.

---

## NICE-TO-HAVE — Inspiration & Future

### ~~N1: Agent team presets~~ DONE
Created /review-team, /debug-team, /security-team with parallel agent execution.

### ~~N2: Natural language to hook generation~~ DONE
Created /hook-gen skill that converts plain English to hook configurations.

### ~~N3: AGENTS.md generation~~ DONE
Created templates/project/AGENTS.md with all 21 agents and team presets.

### ~~N4: Configuration linter~~ DONE
Created hangar-lint.sh with 171 checks across 7 categories.

### ~~N5: "Lite" install mode~~ DONE
Added --lite flag to setup.sh: 5 safety hooks + 3 skills + lite settings template.

### ~~N6: Instinct confidence scoring~~ DONE
Added accumulative confidence scoring to instinct-evolve.sh with auto-promotion at threshold 8+.

### ~~N7: Progressive memory retrieval~~ DONE
Created docs/memory-optimization.md with 3-layer strategy and token budgets.

### ~~N8: Observability dashboard~~ DONE
Created core/lib/session-dashboard.sh parsing cost, subagent, pattern, and instinct logs.

### ~~N9: Token-efficient hook profile~~ DONE
Added HANGAR_TERSE env var to hook-gate.sh, applied to skill-suggest and model-router.

### ~~N10: Cross-IDE skill generation~~ DONE
Created /export-rules skill for Cursor .mdc, Windsurf, and GitHub Copilot formats.

### ~~N11: MCP Inspector in test pipeline~~ DONE
Enhanced test-mcp.sh with HTTP server validation (url, auth, HTTPS checks).

### ~~N12: Skill-scoped hooks~~ DONE
Added documentation with example in docs/writing-skills.md.

### ~~N13: Publish to superpowers-marketplace~~ DONE (prepared)
Updated plugin.json to marketplace schema, created marketplace.json. Ready for submission PR.

### ~~N14: DESIGN.md integration~~ DONE
Created templates/project/DESIGN.md with colors, typography, spacing, components, accessibility.

---

## Execution Order

```
Phase 4a: M1, M2, M3, M4, M5              ✓ DONE (session 1)
Phase 4b: S1, S2, S3, S4, S5, S6, S7      ✓ DONE (session 1)
Phase 4c: S8, S9, S10                      ✓ DONE (session 2)
Phase 5a: N1, N4, N13                      ✓ DONE (session 2)
Phase 5b: N2, N3, N5-N12, N14              ✓ DONE (session 2 continued)
```

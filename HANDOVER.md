# Handover — Full Audit & Upgrade

**Date:** 2026-04-11
**Branch:** `chore/full-audit-upgrade-2026-04`
**Status:** Phase 4a (Must-fixes) complete, Should-fixes pending

---

## What Was Done

### Phase 1: Audit (AUDIT.md)
Complete inventory of all 100+ components: 32 skills, 21 agents, 27 hooks, 10 stacks, 19 rules, 10 templates, 4 test suites, 20+ docs.

### Phase 2: Research (RESEARCH.md)
- Claude Code CLI v2.1.101 changelog analysis (new hook events, frontmatter fields, settings)
- MCP spec 2025-11-25 analysis (Tasks, OAuth, deprecated SSE)
- Community/competitor scan: 20+ projects analyzed (affaan-m/everything-claude-code 150K stars, anthropics/skills 114K, etc.)
- Anthropic SDK state: Node v0.88.0, Python v0.87.0, new Claude Agent SDK

### Phase 3: Plan (TODO.md)
5 Must + 10 Should + 14 Nice-to-have tasks, prioritized and execution-ordered.

### Phase 4a: Must-Fixes (implemented)
- **M1:** GitHub MCP → remote HTTP with OAuth
- **M2:** PostgreSQL MCP → @bytebase/dbhub
- **M3:** Hook output format → hookSpecificOutput.permissionDecision
- **M4:** All 14 Sonnet agents → Opus (verified: 43 tests, 0 failures)
- **M5:** Created `.claude-plugin/plugin.json` + `hooks/hooks.json`

---

## Key Decisions

1. **GitHub MCP: HTTP over stdio** — Remote HTTP transport is now recommended. No local install needed, OAuth handles auth. Alternative: Go binary from `github/github-mcp-server` for self-hosted.

2. **PostgreSQL MCP: DBHub over postgres-mcp** — `@crystaldba/postgres-mcp` npm package doesn't exist. DBHub (`@bytebase/dbhub`) supports PostgreSQL, MySQL, SQLite via DSN parameter.

3. **Plugin structure: Custom paths** — Plugin uses `"skills": ["./core/skills/", "./stacks/..."]` to point to existing non-standard directory structure instead of restructuring the entire repo.

4. **Hooks mapping approach** — Created separate `hooks/hooks.json` (not inline in plugin.json) for maintainability. Uses `${CLAUDE_PLUGIN_ROOT}` for portable paths. Background hooks marked with `"async": true`.

---

## Open Tasks (next session)

### Phase 4b: Should-Fixes (S1-S5)

| Task | Effort | Notes |
|------|--------|-------|
| **S1:** Standardize skill frontmatter naming (`user_invocable` → `user-invocable`) | Small | sed across 31 SKILL.md files, verify still loads |
| **S2:** Add `effort` field to all skills and agents | Small | See mapping in TODO.md |
| **S3:** Add missing hook events (PostToolUseFailure, SessionEnd, PreCompact) | Medium | 3 new hook scripts |
| **S4:** Add `if` conditionals to guard hooks in settings.json | Medium | Simplifies bash-guard, db-query-guard |
| **S5:** CI template with `anthropics/claude-code-action` | Small | New template file |

### Phase 4c: Should-Fixes (S6-S10)

| Task | Effort | Notes |
|------|--------|-------|
| **S6:** Update docs for new CLI features | Large | 4 doc files need significant updates |
| **S7:** Add `maxTurns` and `disallowedTools` to agents | Small | Safety limits |
| **S8:** Runtime hook profile switching via env var | Medium | Implement `HANGAR_HOOK_PROFILE` |
| **S9:** Add remote HTTP MCP servers to registry | Small | Notion, Sentry, Stripe, Linear |
| **S10:** Smart settings merge in setup.sh | Large | Backup + deep merge |

### Phase 5: Nice-to-Have (N1-N14)
See TODO.md for full backlog. Top priorities:
- **N1:** Agent team presets (`/review-team`, `/debug-team`)
- **N5:** "Lite" install mode
- **N13:** Publish to superpowers-marketplace

---

## Files Modified

| File | Change |
|------|--------|
| `core/hooks/bash-guard.sh` | Hook output format migration (5 outputs) |
| `core/hooks/secret-leak-check.sh` | Hook output format migration (1 output) |
| `core/mcp/registry.json` | GitHub + PostgreSQL MCP server updates |
| `stacks/github/mcp.json` | Stdio → HTTP transport |
| `stacks/database/mcp.json` | Package replacement |
| `core/agents/*.md` (14 files) | model: sonnet → opus |
| `.claude-plugin/plugin.json` | NEW — Plugin manifest |
| `hooks/hooks.json` | NEW — Hook event mapping |
| `AUDIT.md` | NEW — Full audit report |
| `RESEARCH.md` | NEW — External research report |
| `TODO.md` | NEW — Prioritized upgrade plan |
| `CHANGELOG.md` | Updated with all changes |
| `HANDOVER.md` | NEW — This file |

---

## Context for Decisions

- **User preference: All agents Opus** — Documented in `~/.claude/projects/.../memory/feedback_always_opus.md`
- **Plugin ecosystem is critical** — anthropics/claude-plugins-official (16K stars) is now the primary distribution channel. Projects without `plugin.json` are invisible.
- **MCP transport shift** — SSE deprecated, remote HTTP is recommended. Local stdio still works but adds install friction.
- **Competitor landscape** — everything-claude-code (150K), claude-mem (47K), anthropics/skills (114K). Hangar's unique strengths: stacks system, registry, testing. Weakness: no plugin support (now fixed), no cross-IDE, no observability dashboard.

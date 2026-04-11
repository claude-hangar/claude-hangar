# Handover — Full Audit & Upgrade

**Date:** 2026-04-11
**Branch:** `chore/full-audit-upgrade-2026-04`
**Status:** Phase 4a (Must-fixes) + Phase 4b (Should-fixes) complete

---

## What Was Done (11 commits)

### Must-Fixes (M1-M5)
- **M1:** GitHub MCP → remote HTTP with OAuth
- **M2:** PostgreSQL MCP → @bytebase/dbhub
- **M3:** Hook output format → hookSpecificOutput.permissionDecision (2 hooks, 6 outputs)
- **M4:** All 14 Sonnet agents → Opus (verified: 43 tests, 0 failures)
- **M5:** Created `.claude-plugin/plugin.json` + `hooks/hooks.json`

### Should-Fixes (S1-S7)
- **S1:** Frontmatter standardized to hyphens (`user-invocable`) — 35 files
- **S2:** Added `effort` field to 29 skills + 10 agents
- **S3:** 3 new hooks: `post-tool-failure.sh`, `session-end.sh`, `pre-compact.sh`
- **S4:** New hook events added to `settings.json.template`
- **S5:** CI template `ci-claude-review.yml` with `anthropics/claude-code-action`
- **S6:** Updated 4 doc files (writing-skills, writing-hooks, writing-agents, mcp-guide)
- **S7:** Already complete — all agents have `maxTurns` and reviewers have `disallowedTools`

---

## Open Tasks (next session)

### Should-Fixes (remaining)

| Task | Effort | Notes |
|------|--------|-------|
| **S8:** Runtime hook profile switching via `HANGAR_HOOK_PROFILE` env var | Medium | hook-gate.sh needs implementation |
| **S9:** Add remote HTTP MCP servers to registry (Notion, Sentry, Stripe, Linear) | Small | New entries in registry.json |
| **S10:** Smart settings merge in setup.sh | Large | Backup + deep merge of existing configs |

### Nice-to-Have (N1-N14)

See `TODO.md` for full backlog. Top priorities:
- **N1:** Agent team presets (`/review-team`, `/debug-team`)
- **N5:** "Lite" install mode (5-minute path)
- **N13:** Publish to superpowers-marketplace

---

## Files Modified (total)

| Category | Files | Changes |
|----------|-------|---------|
| Hooks | 5 modified + 3 new | Output format, new events |
| Agents | 14 modified | Model upgrade, effort fields |
| Skills | 35 modified | Frontmatter standardization, effort fields |
| MCP | 3 modified | Server reference fixes |
| Config | 2 modified + 2 new | settings.json.template, plugin.json, hooks.json |
| Docs | 4 modified | CLI feature updates |
| Templates | 1 new | CI Claude review template |
| Reports | 5 new | AUDIT.md, RESEARCH.md, TODO.md, CHANGELOG.md, HANDOVER.md |

---

## Commit History

```
9048839 docs: add audit report, research findings, upgrade plan, and handover
3a79d74 feat(plugin): add .claude-plugin/plugin.json for ecosystem compatibility
1b9d56e chore(agents): upgrade all 14 Sonnet agents to Opus model
f3ddc35 fix(mcp): replace deprecated/broken MCP server references
4dacbc9 fix(hooks): migrate PreToolUse output to hookSpecificOutput format
25a78ea refactor(skills): standardize frontmatter to official hyphenated format
a2f94ea feat(config): add effort field to 29 skills and 10 agents
16d5e4d feat(hooks): add PostToolUseFailure, SessionEnd, PreCompact hooks
7101bb4 feat(templates): add Claude Code PR review CI template
e92bc1b feat(config): add new hook events to settings.json.template
35eed70 docs: update guides for new CLI features and MCP ecosystem
```

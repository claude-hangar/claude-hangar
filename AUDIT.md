# Claude Hangar — Full Audit Report

**Date:** 2026-04-11
**Branch:** `chore/full-audit-upgrade-2026-04`
**Scope:** Complete inventory of all components with version status and improvement opportunities

---

## 1. Skills (32 total)

### Core Skills (31 user-invocable + 1 shared library)

| Skill | Purpose | Effort | Issues |
|-------|---------|--------|--------|
| `_shared` | Shared library for skills | — | No SKILL.md, helper only |
| `adversarial-review` | Critical review (min. 5 findings) | — | Uses `user_invocable` (underscore) instead of `user-invocable` (hyphen) |
| `audit` | Website audit (9 phases) | — | Same frontmatter naming issue |
| `audit-orchestrator` | Combines multiple audit types | — | Same |
| `audit-runner` | Background autonomous audit | — | Not user-invocable, helper skill |
| `capture-pdf` | Website-to-PDF capture | — | Same frontmatter issue |
| `codebase-map` | Structural codebase overview | — | Same |
| `consult` | Interactive project consultant | — | Same |
| `context-budget` | Token spending analysis | — | Same |
| `deploy-check` | Docker/Traefik deployment readiness | — | Same |
| `design-system` | Curated design intelligence | — | Same |
| `doctor` | Meta health check | — | Same |
| `error-analyzer` | Root-cause analysis | — | Same |
| `favicon-check` | Favicon completeness | `low` | One of 3 skills using `effort` field |
| `freshness-check` | Framework version freshness | — | Missing `effort` field |
| `git-hygiene` | Git repo hygiene | — | Same |
| `handoff` | Session handoff preservation | — | Same |
| `inline-review` | Quick self-review checklist | — | Same |
| `lesson-learned` | Learning extraction to memory | — | Same |
| `lighthouse-quick` | Core Web Vitals check | `low` | Correctly uses `effort` |
| `meta-tags` | OG/Twitter/structured data | `low` | Correctly uses `effort` |
| `pattern-extractor` | Continuous learning analysis | — | Missing `effort` field |
| `polish` | Frontend quick wins | — | Same |
| `project-audit` | Non-website repo audit | — | Same |
| `prompt-optimizer` | Prompt gap analysis | — | Same |
| `rules-distill` | Cross-cutting rule extraction | — | Same |
| `safety-guard` | 3-mode protection system | — | Same |
| `scan` | Tech stack detection | — | Same |
| `security-scan` | Security scanning | — | Same |
| `skill-stocktake` | Skill quality audit | — | Same |
| `strategic-compact` | Context management advisor | — | Same |
| `verification-loop` | Pre-PR verification pipeline | — | Same |

### Systematic Issues

1. **Frontmatter naming**: All skills use `user_invocable` (underscore) — official Claude Code docs use `user-invocable` (hyphen). Both may work but should be standardized to official format.
2. **Missing `effort` field**: Only 3/32 skills set `effort`. Heavy skills like `adversarial-review`, `verification-loop`, `audit` should have `effort: high`.
3. **Missing `paths` field**: New frontmatter field for conditional activation by file glob — not used by any skill.
4. **Missing `hooks` field**: New frontmatter field for skill-scoped hooks — not used.
5. **No `shell` field**: New field for bash/powershell selection — not used.

---

## 2. Agents (21 total)

| Agent | Model | Tools | Issues |
|-------|-------|-------|--------|
| `architect` | opus | Read, Grep, Glob, WebSearch, WebFetch | OK |
| `build-resolver-go` | **sonnet** | Read, Grep, Glob, Bash, Edit, Write | Should be opus per user preference |
| `build-resolver-python` | **sonnet** | Read, Grep, Glob, Bash, Edit, Write | Should be opus |
| `build-resolver-typescript` | **sonnet** | Read, Grep, Glob, Bash, Edit, Write | Should be opus |
| `commit-reviewer` | **sonnet** | Bash, Read, Grep, Glob | Should be opus |
| `dependency-checker` | **sonnet** | Bash, Read, Grep, Glob, WebSearch | Should be opus |
| `doc-updater` | **sonnet** | Read, Grep, Glob, Bash, Edit, Write | Should be opus |
| `explorer` | **sonnet** | Read, Glob, Grep, Bash, WebFetch | Should be opus |
| `explorer-deep` | opus | Read, Glob, Grep, Bash, WebFetch, WebSearch, Write, Edit | OK |
| `go-reviewer` | **sonnet** | Read, Grep, Glob, Bash | Should be opus |
| `harness-optimizer` | opus | Read, Grep, Glob, Bash, WebSearch | OK |
| `loop-operator` | **sonnet** | Read, Grep, Glob, Bash, Edit, Write, Agent | Should be opus |
| `performance-optimizer` | opus | Read, Grep, Glob, Bash, WebSearch, WebFetch | OK |
| `planner` | opus | Read, Grep, Glob | OK |
| `plan-reviewer` | **sonnet** | Read, Glob, Grep, Bash | Should be opus |
| `python-reviewer` | **sonnet** | Read, Grep, Glob, Bash | Should be opus |
| `refactor-agent` | opus | Read, Write, Edit, Glob, Grep, Bash, LSP | OK |
| `security-reviewer` | opus | Read, Glob, Grep, Bash, WebFetch, WebSearch, Write, Edit | OK |
| `tdd-guide` | **sonnet** | Read, Grep, Glob, Bash, Edit, Write | Should be opus |
| `test-writer` | **sonnet** | Read, Write, Glob, Grep, Bash | Should be opus |
| `typescript-reviewer` | **sonnet** | Read, Grep, Glob, Bash | Should be opus |

### Systematic Issues

1. **Model assignment**: 13/21 agents use `sonnet` — user preference (memory: `feedback_always_opus.md`) requires ALL agents use opus.
2. **Missing `effort` field**: No agents use the new `effort` frontmatter field. Light agents (explorer, commit-reviewer) should use `effort: low`, heavy agents (security-reviewer, planner) should use `effort: high`.
3. **Missing `maxTurns` field**: Only architect uses `maxTurns` — should be set for all agents to prevent runaway execution.
4. **Missing `disallowedTools` field**: Only architect uses this — reviewer agents should disallow Edit/Write.

---

## 3. Hooks (27 .sh files + 1 .json + 1 .md)

| Hook | Type | Purpose | Issues |
|------|------|---------|--------|
| `bash-guard.sh` | PreToolUse | Block dangerous bash commands | May use deprecated `decision` field; could use `if` conditional |
| `batch-format-collector.sh` | PostToolUse | Collect format changes | OK |
| `checkpoint.sh` | Stop | Checkpoint state on stop | OK |
| `config-change-guard.sh` | PreToolUse | Protect config files | May use deprecated output format |
| `config-protection.sh` | PreToolUse | Protect config files | Duplicate of config-change-guard? |
| `continuous-learning.sh` | PostToolUse | Capture learning patterns | OK |
| `cost-tracker.sh` | PostToolUse | Track API costs | OK |
| `db-query-guard.sh` | PreToolUse | Block dangerous DB queries | Could use `if` conditional |
| `design-quality-check.sh` | PostToolUse | Check design quality | OK |
| `desktop-notify.sh` | Stop | Desktop notification | OK |
| `instinct-capture.sh` | PostToolUse | Capture instinct patterns | Lacks confidence scoring |
| `instinct-evolve.sh` | Stop | Evolve instincts to skills | Lacks promotion gates |
| `mcp-health-check.sh` | SessionStart | Check MCP server health | Doesn't check for deprecated packages |
| `model-router.sh` | SubagentStart | Route model selection | OK |
| `permission-denied-retry.sh` | PermissionDenied | Auto-retry on permission denial | Check if compatible with new hook semantics |
| `post-compact.sh` | PostCompact | Restore state after compact | OK |
| `secret-leak-check.sh` | PreToolUse | Block secret exposure | Critical safety hook — OK |
| `session-start.sh` | SessionStart | Initialize session | OK |
| `session-stop.sh` | Stop | Cleanup on session end | Should migrate to `SessionEnd` event |
| `skill-suggest.sh` | UserPromptSubmit | Suggest relevant skills | OK |
| `stop-batch-format.sh` | Stop | Batch format on stop | OK |
| `stop-failure.sh` | StopFailure | Handle stop failures | Could use granular matchers (rate_limit, etc.) |
| `subagent-tracker.sh` | SubagentStart/Stop | Track subagent lifecycle | OK |
| `task-completed-gate.sh` | TaskCompleted | Gate on task completion | OK |
| `task-created-init.sh` | TaskCreated | Initialize new tasks | OK |
| `token-warning.sh` | PostToolUse | Warn on high token usage | OK |
| `worktree-init.sh` | WorktreeCreate | Initialize worktrees | OK |
| `skill-rules.json` | — | Skill routing rules | OK |
| `hook-profiles.md` | — | Profile documentation | No runtime implementation |

### Systematic Issues

1. **Deprecated output format**: PreToolUse hooks may use top-level `decision`/`reason` fields — must migrate to `hookSpecificOutput.permissionDecision`/`hookSpecificOutput.permissionDecisionReason`.
2. **Missing hook events**: No hooks for `PostToolUseFailure`, `SessionEnd`, `PreCompact`, `CwdChanged`.
3. **No `if` conditional usage**: Several guards (bash-guard, db-query-guard, config-protection) parse commands manually in shell — the new `if` field in settings.json could simplify these.
4. **No HTTP hooks**: All hooks are command-type — `type: "http"` is available but unused.
5. **Possible duplication**: `config-change-guard.sh` and `config-protection.sh` may overlap.
6. **Hook profiles**: Documented in `hook-profiles.md` but no runtime switching via env var.

---

## 4. Library (core/lib/)

| File | Purpose | Issues |
|------|---------|--------|
| `common.sh` | Shared shell functions | Needs review for deprecated patterns |
| `defaults.json` | Default configuration values | OK |
| `hook-gate.sh` | Hook profile gating logic | OK |

**Gap**: No hook SDK/helper for standardized JSON parsing, allow/deny responses.

---

## 5. Stacks (10 total)

| Stack | Framework | Contents | Issues |
|-------|-----------|----------|--------|
| `astro` | Astro | hooks, skills, rules | OK |
| `auth` | Custom auth | hooks, skills, rules | OK |
| `database` | Drizzle/PostgreSQL | hooks, skills, mcp.json | MCP references `@crystaldba/postgres-mcp` — package doesn't resolve on npm |
| `docker` | Docker/Traefik | hooks, skills, rules | OK |
| `github` | GitHub | hooks, skills, mcp.json | MCP references deprecated `@modelcontextprotocol/server-github` |
| `nextjs` | Next.js | hooks, skills, rules | OK |
| `security` | Security scanning | hooks, skills, mcp.json | OK |
| `sveltekit` | SvelteKit/Svelte 5 | hooks, skills, rules | OK |
| `web` | General web | hooks, skills, mcp.json | OK |
| — | README.md | Documentation | OK |

### Critical MCP Issues

1. **`stacks/github/mcp.json`**: References `@modelcontextprotocol/server-github` which is **deprecated** — should use `github/github-mcp-server` Go binary or remote HTTP `https://api.githubcopilot.com/mcp/`.
2. **`stacks/database/mcp.json`**: References `@crystaldba/postgres-mcp` which **doesn't exist on npm** — should use `postgres-mcp` or `@bytebase/dbhub`.

---

## 6. Rules (19 files)

### Common (11 files)
agents, code-review, coding-style, development-workflow, git-workflow, governance, hooks, patterns, performance, security, testing

### Language-Specific (8 files)
- Go: patterns, testing
- Java: patterns
- Python: patterns, testing
- Rust: patterns
- TypeScript: patterns, testing

**Gap**: No rules for Java testing, Rust testing, or C#/.NET.

---

## 7. Templates (10 files)

### CI Templates (6)
- `ci-node.yml`, `ci-python.yml`
- `deploy-cfpages.yml`, `deploy-docker-compose.yml`, `deploy-ghpages.yml`, `deploy-vps-ghcr.yml`

**Gap**: No CI template using official `anthropics/claude-code-action`.

### Project Templates (4)
- `CLAUDE.md.fullstack`, `CLAUDE.md.management`, `CLAUDE.md.minimal`, `CLAUDE.md.web`
- `DECISIONS.md`

---

## 8. MCP Server (core/mcp-server/)

| File | Purpose |
|------|---------|
| `server.js` | Custom MCP server implementation |
| `README.md` | Documentation |

### MCP Registry (core/mcp/)

| File | Purpose | Issues |
|------|---------|--------|
| `registry.json` | Server catalog (6 entries) | 2 broken references (see Stacks section) |
| `install.sh` | MCP installation script | OK |
| `README.md` | Documentation | OK |

---

## 9. Tests (4 files)

| Test | Purpose | Issues |
|------|---------|--------|
| `test-hooks.sh` | Hook pattern validation | OK |
| `test-mcp.sh` | MCP config validation | Should check for deprecated packages |
| `test-models.sh` | Agent model reference validation | OK |
| `test-setup.sh` | Setup script validation | OK |

**Gap**: No automated test for skill frontmatter validation.

---

## 10. Documentation (20+ files)

| Doc | Purpose | Issues |
|-----|---------|--------|
| `getting-started.md` | Quickstart guide | OK |
| `architecture.md` | System architecture | OK |
| `configuration.md` | Configuration reference | May need update for new settings |
| `mcp-guide.md` | MCP integration guide | Needs update for remote HTTP, OAuth, deprecated SSE |
| `writing-skills.md` | Skill authoring guide | Needs update for new frontmatter fields |
| `writing-hooks.md` | Hook authoring guide | Needs update for new hook types and `if` conditionals |
| `writing-agents.md` | Agent authoring guide | Needs update for `effort`, `initialPrompt` |
| `patterns.md` | Error patterns | OK |
| `token-optimization.md` | Token efficiency | OK |
| `troubleshooting.md` | Common issues | OK |
| `faq.md` | FAQ | OK |
| `migration.md` | Migration guide | OK |
| `multi-project.md` | Multi-project setup | OK |
| `task-system.md` | Task system docs | OK |

### Subdirectories
- `docs/concepts/` — Conceptual documentation
- `docs/tutorials/` — Step-by-step tutorials
- `docs/superpowers/` — Superpowers plugin docs
- `docs/assets/` — Documentation assets

---

## 11. Contexts (core/contexts/)

| File | Purpose |
|------|---------|
| `dev.md` | Development context mode |
| `research.md` | Research context mode |
| `review.md` | Review context mode |
| `README.md` | Documentation |

---

## 12. Registry (registry/)

| File | Purpose |
|------|---------|
| `deploy.sh` | Multi-project deployment script |
| `example-registry.json` | Example configuration |
| `registry.schema.json` | JSON Schema for validation |

---

## 13. Internationalization (i18n/)

| File | Purpose |
|------|---------|
| `de/README.md` | German translation |
| `i18n.md` | i18n documentation |

---

## 14. Root Configuration

| File | Purpose | Issues |
|------|---------|--------|
| `setup.sh` | Installation wizard | Monolithic, no smart merge of existing configs |
| `CLAUDE.md` | Project instructions | OK |
| `LICENSE` | MIT License | OK |
| `README.md` | Project documentation | OK |

---

## Summary of Critical Issues

### MUST FIX (broken/deprecated)
1. MCP registry: `@modelcontextprotocol/server-github` is deprecated
2. MCP registry: `@crystaldba/postgres-mcp` doesn't resolve on npm
3. Hook output format: PreToolUse hooks may use deprecated `decision`/`reason` fields
4. Agent models: 13/21 agents use Sonnet instead of Opus (violates user preference)

### SHOULD FIX (clear improvement)
5. Skill frontmatter: Standardize to hyphenated format (`user-invocable`)
6. Add `effort` field to all skills and agents
7. Add missing hook events: `PostToolUseFailure`, `SessionEnd`, `PreCompact`
8. No `.claude-plugin/plugin.json` — can't be installed via `/plugin install`
9. Docs need update for new CLI features

### NICE TO HAVE
10. Hook `if` conditionals to simplify guard hooks
11. HTTP hooks for external integrations
12. Skill-scoped hooks
13. `paths` field for conditional skill activation
14. Agent team presets

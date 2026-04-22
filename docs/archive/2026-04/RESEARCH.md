# Claude Hangar — External Research Report

**Date:** 2026-04-11
**Scope:** Claude CLI, MCP ecosystem, Anthropic SDK, community repos, competitor analysis

---

## 1. Claude Code CLI (v2.1.101, 2026-04-10)

### New Hook Events (not yet used by Hangar)

| Event | Version | Purpose | Priority |
|-------|---------|---------|----------|
| `PostToolUseFailure` | v2.1.76+ | Fires on tool failure — feed error patterns to learning | HIGH |
| `SessionEnd` | recent | Session termination with `end_reason` + `session_duration_seconds` | HIGH |
| `PreCompact` | v2.1.76+ | Fires before compaction — save state before context loss | MEDIUM |
| `PermissionRequest` | v2.1.85+ | Intercept permission dialogs programmatically | MEDIUM |
| `CwdChanged` | v2.1.83 | Working directory changes with `CLAUDE_ENV_FILE` access | MEDIUM |
| `FileChanged` | v2.1.83 | File watch with literal matcher | LOW |
| `InstructionsLoaded` | v2.1.69 | CLAUDE.md/rules loaded event | LOW |
| `TeammateIdle` | v2.1.84+ | Agent team teammate about to idle | LOW |

### New Hook Capabilities

| Feature | Version | Impact |
|---------|---------|--------|
| **`if` conditional field** | v2.1.85 | Simplify guard hooks: `"if": "Bash(rm *)"` instead of manual parsing |
| **`type: "http"` hooks** | v2.1.85+ | HTTP endpoint hooks alongside command hooks |
| **`type: "prompt"` / `type: "agent"` hooks** | recent | LLM-based hooks for complex analysis |
| **`once: true` field** | recent | Run hook once per session only |
| **`async: true` field** | recent | Non-blocking background hooks |
| **`"defer"` permission decision** | v2.1.89 | Pause headless sessions for external UI |
| **`hookSpecificOutput.sessionTitle`** | v2.1.94 | Auto-generate session titles in UserPromptSubmit |
| **`agent_id` / `agent_type` in events** | v2.1.69 | Track which subagent triggered a hook |

### Deprecated (MUST FIX)

- **PreToolUse**: Top-level `decision` and `reason` fields → Use `hookSpecificOutput.permissionDecision` and `hookSpecificOutput.permissionDecisionReason`

### Breaking Changes

| Change | Version | Impact |
|--------|---------|--------|
| Effort levels: `max` removed | v2.1.72 | Check agents/skills for `max` usage |
| Agent tool `resume` param removed | v2.1.69 | Use `SendMessage({to: agentId})` |
| Default effort → `high` for API users | v2.1.94 | Cost implications |
| Plugin skill naming uses frontmatter `name` | v2.1.94 | Check skill naming consistency |
| PreToolUse `allow` no longer bypasses `deny` | v2.1.77 | May affect `permission-denied-retry.sh` |

### New Agent/Skill Frontmatter Fields

| Field | Type | Purpose |
|-------|------|---------|
| `effort` | agent/skill | Set effort level per component |
| `maxTurns` | agent | Limit agent execution turns |
| `disallowedTools` | agent | Restrict tool access |
| `initialPrompt` | agent | Auto-submit prompt on start |
| `paths` | skill | Conditional activation by file glob (YAML list) |
| `hooks` | skill | Skill-scoped hooks |
| `shell` | skill | `bash` or `powershell` |
| `${CLAUDE_SKILL_DIR}` | variable | Reference skill's own directory |

### New Settings

| Setting | Purpose |
|---------|---------|
| `modelOverrides` | Custom provider model IDs |
| `autoMemoryDirectory` | Custom memory location |
| `disableSkillShellExecution` | Disable `!command` in skills |
| `worktree.sparsePaths` | Sparse checkout for worktrees |
| `managed-settings.d/` | Drop-in policy fragments directory |
| `CLAUDE_CODE_NO_FLICKER=1` | Flicker-free rendering |
| `CLAUDE_CODE_SUBPROCESS_ENV_SCRUB` | Credential stripping |

### New Commands

`/loop`, `/effort`, `/powerup`, `/reload-plugins`, `/color`, `/team-onboarding`, `/ultraplan`, `--bare` flag

---

## 2. Anthropic SDKs

### Node SDK: `@anthropic-ai/sdk` v0.88.0

- v0.86.0: Claude Managed Agents support
- v0.84.0: `claude-mythos-preview` model, AbortSignal for tool runner
- v0.82.0: Structured `stop_details`, Bedrock API key support
- No breaking changes in 2026

### Python SDK: `anthropic` v0.87.0

- v0.78.0: Opus 4.6 with adaptive thinking
- v0.79.0: Fast-mode for Opus 4.6
- No breaking changes in 2026

### Claude Agent SDK (NEW)

- **TypeScript:** `@anthropic-ai/claude-agent-sdk` v0.2.101
- **Python:** `claude-agent-sdk` v0.1.56
- Claude Code as a library — provides Read, Write, Edit, Bash, Glob, Grep, WebSearch, WebFetch, Monitor, AskUserQuestion
- **Relevant:** Hangar's `/claude-api` skill should reference this SDK

---

## 3. MCP Protocol

### Current Spec: `2025-11-25`

**Major additions:**
1. Tasks primitive (async long-running operations)
2. URL mode elicitation (OAuth/credential flows)
3. Sampling with tools
4. OAuth Client ID Metadata Documents
5. OpenID Connect Discovery
6. Icons on tools/resources/prompts
7. JSON Schema 2020-12 as default

**Breaking:** JSON-RPC batching removed. SSE transport officially deprecated → Streamable HTTP.

### 2026 Roadmap

- Stateless Streamable HTTP for horizontal scaling
- `.well-known` server discovery (Server Cards)
- Tasks retry semantics, expiry policies
- Enterprise audit trails, SSO, gateway behavior

### SDK: `@modelcontextprotocol/sdk` v1.29.0

TypeScript SDK v2 anticipated Q1-Q2 2026.

---

## 4. MCP Server Ecosystem

### Scale: 440+ servers, 34 categories, 930K+ combined GitHub stars

### Critical Findings for Hangar's Registry

| Current Entry | Status | Replacement |
|---------------|--------|-------------|
| `@modelcontextprotocol/server-github` | **DEPRECATED** | Remote HTTP: `https://api.githubcopilot.com/mcp/` with OAuth, or Go binary from `github/github-mcp-server` (28.3K stars) |
| `@crystaldba/postgres-mcp` | **NPM NOT FOUND** | `postgres-mcp` (npm v1.0.4) or `@bytebase/dbhub` |
| `@modelcontextprotocol/server-sequential-thinking` | OK | v2025.12.18 |
| `@upstash/context7-mcp` | OK | v2.1.7, 50K+ stars |
| `@playwright/mcp` | OK | v0.0.70 |
| `snyk` | OK | Verify `npx -y snyk mcp` still works |

### Top New MCP Servers Worth Adding

| Server | Stars | Category | Why |
|--------|-------|----------|-----|
| `github/github-mcp-server` | 28.3K | DevTools | Official GitHub replacement |
| MetaMCP | 2.2K | Middleware | MCP management layer |
| Pipedream | 11K | Integration | 2,500 API connectors |
| Anyquery | 1.7K | Data | SQL across 40+ apps |

### Remote HTTP Servers (no local install)

| Provider | URL | Auth |
|----------|-----|------|
| GitHub | `https://api.githubcopilot.com/mcp/` | OAuth |
| Notion | `https://mcp.notion.com/mcp` | OAuth |
| Sentry | `https://mcp.sentry.dev/mcp` | OAuth |
| Stripe | `https://mcp.stripe.com` | OAuth |

### Registries & Discovery

| Registry | Status |
|----------|--------|
| Official MCP Registry (`registry.modelcontextprotocol.io`) | Preview, API freeze v0.1 |
| GitHub MCP Registry | 44 servers, one-click VS Code install |
| `mcp-get` CLI | Package manager for MCP servers |
| `mcpm.sh` | CLI with profiles and client integration |
| ToolHive (Stacklok) | OCI + Git distribution |

### .mcp.json Standard

Emerging cross-client standard for project-level MCP configuration. Claude Code supports: `local` (per-project), `project` (.mcp.json, version-controlled), `user` (global). Supports `${VAR}` environment variable expansion.

---

## 5. Community & Competitor Analysis

### Direct Competitors

| Project | Stars | Key Differentiator | What to Learn |
|---------|-------|-------------------|---------------|
| `affaan-m/everything-claude-code` | 150K | Instinct system with confidence scoring, cross-IDE, manifest-driven install | Runtime hook profiles, confidence scoring, cross-IDE |
| `wshobson/agents` | 33K | PluginEval framework, agent team presets, conductor pattern | Team presets, quality metrics |
| `Yeachan-Heo/oh-my-claudecode` | 27K | Mission-based work, Socratic interview, persistent execution | Goal system, deep interviews |
| `thedotmack/claude-mem` | 47K | 3-layer progressive memory retrieval, SQLite + vector DB | Progressive retrieval pattern |
| `JuliusBrussee/caveman` | 15K | 65% token reduction via terse style | Token efficiency as hook profile |
| `jarrodwatts/claude-code-config` | 1K | Minimal, approachable | "Lite" install mode |

### Official Anthropic Ecosystem (CRITICAL)

| Project | Stars | Impact on Hangar |
|---------|-------|-----------------|
| `anthropics/skills` | 114K | Official skill marketplace — Hangar skills already compatible |
| `anthropics/claude-plugins-official` | 16K | **Hangar lacks `.claude-plugin/plugin.json`** — can't be installed via `/plugin install` |
| `anthropics/claude-code-action` | 7K | Official GitHub Action — Hangar should include CI template |

### Cross-Agent Standards

| Project | Stars | Relevance |
|---------|-------|-----------|
| `agentsmd/agents.md` | 20K | Open standard for coding agents — generate alongside CLAUDE.md |
| `FrancyJGLisboa/agent-skill-creator` | 690 | Universal SKILL.md for 14+ tools — auto-adapt for Cursor/Windsurf |
| `iannuttall/dotagents` | 666 | Unified `.agents` folder with symlinks to multiple tools |
| `VoltAgent/awesome-design-md` | 42K | DESIGN.md for visual design systems — natural fit for design-system skill |

### Hook Innovations

| Project | Stars | Innovation |
|---------|-------|------------|
| `disler/claude-code-hooks-mastery` | 3.5K | Meta-agent pattern, TTS, environment persistence |
| `disler/claude-code-hooks-multi-agent-observability` | 1.3K | Real-time monitoring dashboard (Bun + Vue + SQLite + WebSocket) |
| `zxdxjtu/claudecode-rule2hook` | 403 | Natural language to hook generation |
| `GowayLee/cchooks` | 127 | Python SDK for hooks with type-safe context |

### Plugin Ecosystem

| Project | Stars | Relevance |
|---------|-------|-----------|
| `obra/superpowers-marketplace` | 817 | Curated plugin marketplace — Hangar should be listed |
| `agent-sh/agentsys` | 710 | Marketplace + `agnix` linter (385 validation rules) |

---

## 6. Competitive Positioning

### Where Claude Hangar Leads
- **Stacks system** (framework-specific extensions) — unique in ecosystem
- **Registry** for multi-project management — no competitor has this
- **Comprehensive testing** (4 test scripts covering hooks, MCP, models, setup)
- **Clean separation** of concerns (core/stacks/rules/templates/registry)
- **Strong governance rules** (common + 5 language-specific rule sets)

### Where Claude Hangar Trails
- **Not plugin-installable** (no `.claude-plugin/plugin.json`) — existential risk
- **No cross-IDE support** (Claude-Code-only vs. multi-tool competitors)
- **No visual observability** (dashboard/HUD)
- **Basic memory system** compared to claude-mem (47K stars)
- **No agent team presets** for parallel orchestration
- **No marketplace presence** (not in superpowers-marketplace or official directory)
- **Setup is monolithic** — no smart merge, no selective install

### Strategic Priority

> The biggest existential risk is that users will install configurations via `/plugin install` from the official marketplace, bypassing projects without plugin compatibility entirely. Adding plugin support is not optional — it is survival.

---

## Sources

- [Claude Code Changelog](https://code.claude.com/docs/en/changelog)
- [Claude Code Hooks Reference](https://code.claude.com/docs/en/hooks)
- [Claude Code Skills Documentation](https://code.claude.com/docs/en/skills)
- [Claude Code Settings](https://code.claude.com/docs/en/settings)
- [Claude Agent SDK](https://code.claude.com/docs/en/agent-sdk/overview)
- [Claude Models Overview](https://platform.claude.com/docs/en/about-claude/models/overview)
- [MCP Specification](https://modelcontextprotocol.io)
- [MCP Registry](https://registry.modelcontextprotocol.io)
- [Official MCP Servers](https://github.com/modelcontextprotocol/servers)
- [@anthropic-ai/sdk on npm](https://www.npmjs.com/package/@anthropic-ai/sdk)
- [anthropic on PyPI](https://pypi.org/project/anthropic/)
- [GitHub MCP Server](https://github.com/github/github-mcp-server)

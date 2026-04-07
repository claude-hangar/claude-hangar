# Capability Surface Guide

When adding a new capability to Claude Hangar, choose the right surface.
This decision tree prevents misplaced functionality and keeps the architecture clean.

Inspired by [Everything Claude Code](https://github.com/affaan-m/everything-claude-code).

## Decision Tree

Ask these questions in order. The first "yes" determines the surface.

### 1. Is it deterministic and always active?

**Use a Rule** (`rules/`)

Rules are loaded into every session. They enforce behavior unconditionally.

Examples:
- "Always use conventional commits"
- "Never hardcode secrets"
- "Prefer immutable patterns"

Rules must be:
- Short (under 100 lines)
- Unconditional (no "if this project uses X")
- Enforceable without tools

### 2. Is it a workflow or playbook, invoked on demand?

**Use a Skill** (`core/skills/`)

Skills are multi-step procedures triggered by user commands or hook suggestions.

Examples:
- `/freshness-check` — version currency audit
- `/deploy-check` — deployment readiness scan
- `/audit` — full website audit

Skills must be:
- Self-contained (one SKILL.md per skill)
- Idempotent (safe to run multiple times)
- Focused (one clear purpose)

### 3. Is it a structured tool interface for multiple clients?

**Use an MCP Server** (`core/mcp-server/`)

MCP servers expose structured APIs that Claude Code (and other MCP clients) can call.

Examples:
- Read-only project state queries
- External service integrations
- Data lookups that benefit from structured input/output

MCP servers must be:
- Stateless per request
- Cross-platform (no OS-specific dependencies)
- Well-typed (clear input/output schema)

### 4. Is it an automated response to a specific event?

**Use a Hook** (`core/hooks/`)

Hooks fire on Claude Code events (PreToolUse, PostToolUse, Stop, etc.).

Examples:
- Secret leak detection (PreToolUse)
- Cost tracking (Stop)
- Config protection (PreToolUse)

Hooks must be:
- Fast (< 10s sync, < 30s async)
- Silent on success (no stdout on allow path)
- Resilient (never crash the session)

### 5. Is it a specialized analysis perspective?

**Use an Agent** (`core/agents/`)

Agents are dispatched as subagents with specific expertise.

Examples:
- Security reviewer
- Performance optimizer
- Code reviewer (language-specific)

Agents must be:
- Model-appropriate (Opus for deep analysis, Sonnet for fast review)
- Scoped (clear tools list)
- Independent (work without conversation context)

## Quick Reference

| Surface | Trigger | Persistence | Scope |
|---------|---------|-------------|-------|
| Rule | Always loaded | Permanent | All sessions |
| Skill | User command / suggestion | On-demand | Single session |
| MCP Server | Tool call | Running process | Cross-session |
| Hook | Claude Code event | Event-driven | Per-event |
| Agent | Dispatched by parent | Task-scoped | Single task |

## Anti-Patterns

- **Rule that needs tools** → Should be a Skill
- **Skill that always runs** → Should be a Rule
- **Hook with complex logic** → Should delegate to a Skill
- **Agent that modifies config** → Should be a Hook or Skill
- **MCP server with side effects** → Should be a Hook

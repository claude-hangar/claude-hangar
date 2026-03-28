# MCP Integration Design — Claude Hangar

**Date:** 2026-03-28
**Status:** Approved
**Approach:** Hybrid (Core + Stack MCPs)

## Overview

Integrate MCP (Model Context Protocol) server management into Claude Hangar. Core MCPs are always deployed, stack MCPs activate with their respective stacks. A central registry catalogs all supported servers.

## Architecture

```
core/mcp/
├── registry.json          # Catalog of all supported MCP servers
├── install.sh             # MCP installer (called by setup.sh)
└── README.md              # Contributor documentation

stacks/github/mcp.json     # GitHub MCP config
stacks/web/mcp.json        # Playwright MCP config
stacks/database/mcp.json   # PostgreSQL Pro + Drizzle MCP config
stacks/security/mcp.json   # Snyk MCP config (optional)

docs/mcp-guide.md          # User guide
tests/test-mcp.sh          # MCP validation tests
```

## Modified Files

| File | Change |
|------|--------|
| `core/settings.json.template` | Add `mcpServers` block with core MCPs |
| `setup.sh` | Add MCP deployment section |
| `registry/registry.schema.json` | Add `mcpServers` field per project |
| `registry/example-registry.json` | Add MCP example configuration |

## Core MCPs (Always Installed)

These are deployed automatically via `settings.json.template`:

| Server | Purpose |
|--------|---------|
| **Sequential Thinking** | Structured step-by-step reasoning for complex problems |
| **Context7** | Live documentation lookup for any library/framework |

Configuration in `settings.json.template`:

```json
"mcpServers": {
  "sequential-thinking": {
    "type": "stdio",
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"]
  },
  "context7": {
    "type": "stdio",
    "command": "npx",
    "args": ["-y", "@upstash/context7-mcp@latest"]
  }
}
```

## Stack MCPs (Activated Per Stack)

Each stack can define MCP servers in a `mcp.json` file. These are merged into the user's `settings.json` when the stack is activated.

### stacks/github/mcp.json

```json
{
  "github": {
    "type": "stdio",
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-github"],
    "env": {
      "GITHUB_PERSONAL_ACCESS_TOKEN": "{{GITHUB_TOKEN}}"
    }
  }
}
```

### stacks/web/mcp.json

```json
{
  "playwright": {
    "type": "stdio",
    "command": "npx",
    "args": ["-y", "@playwright/mcp@latest"]
  }
}
```

### stacks/database/mcp.json

```json
{
  "postgres": {
    "type": "stdio",
    "command": "npx",
    "args": ["-y", "@crystaldba/postgres-mcp"],
    "env": {
      "DATABASE_URL": "{{POSTGRES_URL}}"
    }
  }
}
```

### stacks/security/mcp.json

```json
{
  "snyk": {
    "type": "stdio",
    "command": "npx",
    "args": ["-y", "snyk@latest", "mcp"]
  }
}
```

## Central Registry (core/mcp/registry.json)

Single source of truth for all supported MCP servers. Used by setup.sh for validation and by documentation for reference.

```json
{
  "version": "1.0.0",
  "servers": {
    "sequential-thinking": {
      "name": "Sequential Thinking",
      "category": "core",
      "description": "Structured step-by-step reasoning for complex problems",
      "source": "https://github.com/modelcontextprotocol/servers",
      "package": "@modelcontextprotocol/server-sequential-thinking",
      "required": true
    },
    "context7": {
      "name": "Context7",
      "category": "core",
      "description": "Live documentation lookup for any library/framework",
      "source": "https://github.com/upstash/context7",
      "package": "@upstash/context7-mcp",
      "required": true
    },
    "github": {
      "name": "GitHub",
      "category": "stack",
      "stack": "github",
      "description": "GitHub repos, PRs, issues, code search",
      "source": "https://github.com/github/github-mcp-server",
      "package": "@modelcontextprotocol/server-github",
      "credentials": ["GITHUB_TOKEN"]
    },
    "playwright": {
      "name": "Playwright",
      "category": "stack",
      "stack": "web",
      "description": "Browser automation and UI verification",
      "source": "https://github.com/microsoft/playwright-mcp",
      "package": "@playwright/mcp"
    },
    "postgres": {
      "name": "PostgreSQL Pro",
      "category": "stack",
      "stack": "database",
      "description": "Database schema inspection, queries, performance analysis",
      "source": "https://github.com/crystaldba/postgres-mcp",
      "package": "@crystaldba/postgres-mcp",
      "credentials": ["POSTGRES_URL"]
    },
    "snyk": {
      "name": "Snyk",
      "category": "stack",
      "stack": "security",
      "description": "Security scanning (SCA, code, IaC, containers)",
      "source": "https://docs.snyk.io/integrations/snyk-studio-agentic-integrations",
      "package": "snyk",
      "credentials": []
    }
  }
}
```

## Setup Flow (setup.sh Extension)

After the existing stack deployment, a new MCP section:

1. **Validate prerequisites:** Check `npx --version` is available
2. **Deploy core MCPs:** Ensure `mcpServers` block exists in `~/.claude/settings.json` with sequential-thinking and context7
3. **Deploy stack MCPs:** For each activated stack with a `mcp.json`, merge its servers into `~/.claude/settings.json`
4. **Credential check:** Warn if any `{{PLACEHOLDER}}` values remain unresolved in MCP environment variables
5. **Summary:** Print which MCP servers were configured

The installer script (`core/mcp/install.sh`) handles the JSON merging logic, called by `setup.sh`.

## Registry Schema Extension

Add to `registry/registry.schema.json`:

```json
"mcpServers": {
  "type": "array",
  "items": { "type": "string" },
  "description": "MCP server IDs from core/mcp/registry.json to activate for this project"
}
```

Example in `registry/example-registry.json`:

```json
{
  "name": "my-app",
  "repo": "my-org/my-app",
  "defaultPath": "~/projects/my-app",
  "mcpServers": ["github", "postgres", "playwright"],
  "skills": ["db-audit.md", "auth-audit.md"],
  "hooks": ["secret-leak-check.sh", "bash-guard.sh"]
}
```

## Testing

New test file `tests/test-mcp.sh`:

- Validate `core/mcp/registry.json` is valid JSON with required fields
- Validate all `stacks/*/mcp.json` files are valid JSON
- Verify placeholder format: all credential values match `{{UPPER_SNAKE_CASE}}`
- Verify every stack MCP referenced in registry has a corresponding `mcp.json`
- Verify `settings.json.template` mcpServers block references match registry core servers

## Out of Scope

- Building custom MCP servers (we consume, not build)
- Docker MCP Toolkit (overhead for most users)
- Productivity MCPs (Notion, Slack, Linear — too personal)
- Automatic credential prompting in wizard (too complex for v1)
- Drizzle MCP server (community package, not stable enough for v1 — revisit later)

## Security Considerations

- All MCP servers from official/verified sources only
- Credentials via environment variable placeholders, never hardcoded
- Database MCP defaults to read-only configuration
- Setup warns about unresolved credential placeholders
- Registry documents source URLs for audit

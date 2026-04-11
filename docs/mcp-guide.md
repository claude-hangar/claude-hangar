# MCP Server Guide

Claude Hangar manages MCP (Model Context Protocol) servers that extend what Claude Code can do. MCP servers give Claude access to external tools and services.

## What Gets Installed

### Core MCP Servers (Always Active)

These are installed automatically with every Claude Hangar setup:

| Server | What It Does |
|--------|-------------|
| **Sequential Thinking** | Helps Claude reason through complex problems step by step |
| **Context7** | Fetches live documentation for any library (React, Astro, SvelteKit, Tailwind, Drizzle, etc.) |

### Stack MCP Servers (Per Stack)

These activate when you use the corresponding stack:

| Stack | Server | Transport | What It Does | Credentials |
|-------|--------|-----------|-------------|-------------|
| GitHub | GitHub MCP | **HTTP (remote)** | Repos, PRs, issues, code search | OAuth (browser flow) |
| Web | Playwright | stdio (local) | Browser automation, screenshots, UI testing | None |
| Database | DBHub | stdio (local) | Schema inspection, queries, performance analysis | `POSTGRES_URL` |
| Security | Snyk | stdio (local) | Vulnerability scanning (deps, code, containers) | OAuth via `snyk auth` |

## Transport Types

MCP supports two main transport types:

| Transport | How It Works | Best For |
|-----------|-------------|----------|
| **HTTP (remote)** | Server runs remotely, accessed via URL + OAuth | Cloud services (GitHub, Notion, Sentry, Stripe) |
| **stdio (local)** | Server runs locally as child process | Local tools (Playwright, databases, file systems) |

**Note:** SSE transport is **deprecated**. Use Streamable HTTP instead.

## Setting Up Credentials

### HTTP Servers (OAuth)

Remote HTTP servers use OAuth. Authenticate via the Claude Code CLI:

```bash
# GitHub — authenticate via browser OAuth flow
claude mcp add --transport http github https://api.githubcopilot.com/mcp/

# Then authenticate:
/mcp
```

### stdio Servers (Environment Variables)

Local servers use environment variables for credentials:

```bash
# PostgreSQL — Connection string
export POSTGRES_URL=postgresql://user:pass@localhost:5432/mydb
```

## Adding More MCP Servers

### Via CLI (recommended)

```bash
# Remote HTTP server (cloud services)
claude mcp add --transport http notion https://mcp.notion.com/mcp

# Local stdio server
claude mcp add my-server -- npx -y package-name

# With scope (project-level, version-controlled)
claude mcp add --scope project my-server -- npx -y package-name
```

### Via settings.json

```json
{
  "mcpServers": {
    "my-server": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "package-name"]
    }
  }
}
```

### Via .mcp.json (project-level, shareable)

Create `.mcp.json` in project root for team-shared MCP config:

```json
{
  "my-server": {
    "type": "stdio",
    "command": "npx",
    "args": ["-y", "package-name"],
    "env": {
      "API_KEY": "${MY_API_KEY}"
    }
  }
}
```

Supports `${VAR}` and `${VAR:-default}` environment variable expansion.

### MCP Configuration Scopes

| Scope | Flag | Storage | Shared |
|-------|------|---------|--------|
| Local | `--scope local` (default) | `~/.claude.json` per project | No |
| Project | `--scope project` | `.mcp.json` in project root | Yes (VCS) |
| User | `--scope user` | `~/.claude.json` global | No |

## Security

- Only install MCP servers from trusted sources (official repos, verified packages)
- Never give MCP servers write access to production databases
- Use read-only modes where available (e.g., PostgreSQL restricted mode)
- Review the source code of community MCP servers before installing
- Bind local servers to `127.0.0.1`, never `0.0.0.0`
- Use TLS 1.3 for transit, AES-256 for data at rest
- 43% of community MCP servers have command injection vulnerabilities — vet carefully
- See `SECURITY.md` for the full security policy

## Useful Remote MCP Servers

These can be added without local installation:

| Provider | URL | Auth |
|----------|-----|------|
| GitHub | `https://api.githubcopilot.com/mcp/` | OAuth |
| Notion | `https://mcp.notion.com/mcp` | OAuth |
| Sentry | `https://mcp.sentry.dev/mcp` | OAuth |
| Stripe | `https://mcp.stripe.com` | OAuth |

## MCP Registry

The official MCP Registry at `registry.modelcontextprotocol.io` catalogs 440+ servers across 34 categories. Claude Hangar's own registry (`core/mcp/registry.json`) tracks the servers relevant to our stacks.

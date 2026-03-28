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

| Stack | Server | What It Does | Credentials Needed |
|-------|--------|-------------|-------------------|
| GitHub | GitHub MCP | Repos, PRs, issues, code search | `GITHUB_TOKEN` |
| Web | Playwright | Browser automation, screenshots, UI testing | None |
| Database | PostgreSQL Pro | Schema inspection, queries, performance analysis | `POSTGRES_URL` |
| Security | Snyk | Vulnerability scanning (deps, code, containers) | OAuth via `snyk auth` |

## Setting Up Credentials

Some MCP servers need credentials. Set them as environment variables before running Claude Code:

```bash
# GitHub — Personal Access Token
export GITHUB_TOKEN=ghp_your_token_here

# PostgreSQL — Connection string
export POSTGRES_URL=postgresql://user:pass@localhost:5432/mydb
```

After setting up credentials, the `{{PLACEHOLDER}}` values in your `~/.claude/settings.json` will be replaced by the environment variables at runtime.

## Adding More MCP Servers

You can manually add MCP servers to `~/.claude/settings.json`:

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

Or use the Claude Code CLI:

```bash
claude mcp add my-server -- npx -y package-name
```

## Security

- Only install MCP servers from trusted sources (official repos, verified packages)
- Never give MCP servers write access to production databases
- Use read-only modes where available (e.g., PostgreSQL restricted mode)
- Review the source code of community MCP servers before installing
- See `SECURITY.md` for the full security policy

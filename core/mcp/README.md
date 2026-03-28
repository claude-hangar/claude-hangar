# MCP Server Management

This directory contains the MCP (Model Context Protocol) server registry and installer for Claude Hangar.

## Architecture

- **Core MCPs** are defined in `settings.json.template` and always deployed
- **Stack MCPs** live in `stacks/*/mcp.json` and are merged on setup
- **registry.json** is the single source of truth for all supported servers

## Files

| File | Purpose |
|------|---------|
| `registry.json` | Catalog of all supported MCP servers with metadata |
| `install.sh` | Merges stack MCP configs into user's settings.json |

## Adding a New MCP Server

1. Add the server entry to `registry.json` with all required fields
2. If it belongs to a stack, create or update `stacks/<stack>/mcp.json`
3. If it's a core server, add it to `core/settings.json.template`
4. Add a test case or verify `tests/test-mcp.sh` covers the new entry
5. Update `docs/mcp-guide.md` with setup instructions

### Registry Entry Format

```json
{
  "server-id": {
    "name": "Human-Readable Name",
    "category": "core|stack",
    "stack": "stack-name",
    "description": "What this server does",
    "source": "https://github.com/...",
    "package": "npm-package-name",
    "required": true,
    "credentials": ["ENV_VAR_NAME"]
  }
}
```

### Stack MCP Config Format

```json
{
  "server-id": {
    "type": "stdio",
    "command": "npx",
    "args": ["-y", "package-name"],
    "env": {
      "CREDENTIAL_NAME": "{{PLACEHOLDER}}"
    }
  }
}
```

Credential placeholders must use `{{UPPER_SNAKE_CASE}}` format.

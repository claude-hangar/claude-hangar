# Hangar State MCP Server

Exposes Claude Hangar configuration state via the Model Context Protocol.
Read-only — provides project context to AI tools without modifying state.

## Tools

| Tool | Description |
|------|-------------|
| `hangar_hooks` | List installed hooks with profiles and status |
| `hangar_skills` | List available skills with invocability and argument hints |
| `hangar_agents` | List configured agents with models |
| `hangar_config` | Read defaults.json and current profile settings |
| `hangar_freshness` | Read .freshness-state.json summary |

## Usage

Add to your Claude Code settings.json or MCP client:

```json
{
  "mcpServers": {
    "hangar-state": {
      "command": "node",
      "args": ["~/.claude/mcp-server/server.js"]
    }
  }
}
```

## Design

- **Read-only** — never modifies state files
- **Lightweight** — pure Node.js, no dependencies
- **Cross-platform** — works on Linux, macOS, Windows
- **MCP stdio transport** — standard stdin/stdout JSON-RPC

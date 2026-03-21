# Configuration Reference

All settings, hooks, environment variables, and statusline options in Claude Hangar.

---

## settings.json

Deployed from `core/settings.json.template` to `~/.claude/settings.json` on first run. Not overwritten on subsequent runs.

```json
{
  "hooks": { ... },
  "language": "English",
  "alwaysThinkingEnabled": true,
  "autoUpdatesChannel": "latest",
  "includeGitInstructions": false,
  "effortLevel": "high",
  "env": {
    "CLAUDE_CODE_MAX_OUTPUT_TOKENS": "128000",
    "MAX_THINKING_TOKENS": "128000",
    "CLAUDE_AUTOCOMPACT_PCT_OVERRIDE": "80"
  },
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/statusline-command.sh"
  }
}
```

### Top-Level Settings

| Key | Default | Description |
|-----|---------|-------------|
| `language` | `"English"` | Response language (template placeholder `{{LANGUAGE}}`) |
| `alwaysThinkingEnabled` | `true` | Extended thinking for all responses |
| `autoUpdatesChannel` | `"latest"` | Update channel |
| `includeGitInstructions` | `false` | Disable if CLAUDE.md has custom git rules |
| `effortLevel` | `"high"` | Reasoning depth: `"low"`, `"medium"`, `"high"` |

---

## Hook Configuration

Hooks are registered in the `hooks` section. Each event contains an array of matcher-hook pairs:

```json
{
  "PreToolUse": [
    {
      "matcher": "Write|Edit",
      "hooks": [
        { "type": "command", "command": "bash ~/.claude/hooks/secret-leak-check.sh" },
        { "type": "command", "command": "bash ~/.claude/hooks/checkpoint.sh" }
      ]
    },
    {
      "matcher": "Bash",
      "hooks": [
        { "type": "command", "command": "bash ~/.claude/hooks/bash-guard.sh" }
      ]
    }
  ]
}
```

### Hook Events

| Event | When | Matcher | Hooks |
|-------|------|---------|-------|
| `PreToolUse` | Before tool executes | `"Write\|Edit"` | secret-leak-check, checkpoint |
| `PreToolUse` | Before tool executes | `"Bash"` | bash-guard |
| `PostToolUse` | After tool completes | `""` (all) | token-warning |
| `UserPromptSubmit` | User sends prompt | `""` | skill-suggest |
| `PostCompact` | After `/compact` | `""` | post-compact |
| `ConfigChange` | Settings modified | `""` | config-change-guard |
| `SessionStart` | Session begins | `""` | session-start (`once: true`) |
| `Stop` | Session ends normally | `""` | session-stop |
| `StopFailure` | Session ends with error | `""` | stop-failure |

### Entry Fields

| Field | Description |
|-------|-------------|
| `matcher` | Regex against tool names. Empty string = match all tools |
| `type` | Always `"command"` |
| `command` | Shell command to execute |
| `once` | If `true`, run only once per session (SessionStart) |

### Exit Codes

| Code | Meaning |
|------|---------|
| `0` | Allow — no stdout output on this path (Git Bash constraint) |
| `2` | Block — output `{"decision":"block","reason":"..."}` as JSON |

---

## Environment Variables

### In settings.json

| Variable | Default | Description |
|----------|---------|-------------|
| `CLAUDE_CODE_MAX_OUTPUT_TOKENS` | `"128000"` | Maximum output tokens per response |
| `MAX_THINKING_TOKENS` | `"128000"` | Maximum extended thinking tokens |
| `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` | `"80"` | Auto-compaction trigger (default without override: 95%) |

### External (Set Outside settings.json)

| Variable | Description |
|----------|-------------|
| `CLAUDE_CODE_OAUTH_TOKEN` | OAuth token for usage API (auto-detected from `~/.claude/.credentials.json`) |
| `CLAUDE_CODE_EFFORT_LEVEL` | Override effort level for current session |
| `CLAUDE_SESSION_ID` | Session identifier used by hooks for state tracking |

---

## Statusline

The statusline script (`~/.claude/statusline-command.sh`) displays real-time session info:

```
Opus 4.6 | my-project@main * | ████████░░ 80k/1m 80% | hi | 5h 45% | 7d 23% | $0.42 | 12k/min | 23m
```

| Segment | Description |
|---------|-------------|
| Model | Active model name |
| Session name | Custom name if set via `/rename` |
| Dir@branch | Directory, git branch, `*` if dirty |
| Context bar | Visual fill + used/total tokens + percentage |
| Effort | `hi` / `med` / `low` |
| 5h / 7d | Rate limit utilization + reset time |
| Extra | Extra credit usage (if enabled) |
| Cost | Session cost in USD |
| Rate | Token burn rate/min + estimated turns until compaction |
| Duration | Session duration |

### Color Coding

| Usage | Color |
|-------|-------|
| 0-49% | Green |
| 50-69% | Yellow |
| 70-89% | Orange |
| 90-100% | Red |

The statusline receives JSON from Claude Code via stdin. It requires `jq` for JSON parsing. Without jq, it shows a fallback "Claude" label.

---

## Effort Levels

| Level | Best For |
|-------|----------|
| `low` | Quick questions, fast agents (explorer, dependency-checker) |
| `medium` | Standard development tasks |
| `high` | Audits, architecture decisions, complex debugging |

Override per session: `CLAUDE_CODE_EFFORT_LEVEL=low claude`

---

## Next Steps

- [Getting Started](getting-started.md) — installation walkthrough
- [Writing Hooks](writing-hooks.md) — create custom hooks
- [Multi-Project Setup](multi-project.md) — manage multiple repos

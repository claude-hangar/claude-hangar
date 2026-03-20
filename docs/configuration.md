# Configuration Reference

Detailed reference for all Claude Hangar configuration files, settings, and customization options.

---

## settings.json

The main configuration file at `~/.claude/settings.json` controls hooks, environment variables, effort level, and the statusline. Claude Hangar deploys this from the template at `core/settings.json.template`.

### Structure Overview

```json
{
  "hooks": { ... },
  "language": "English",
  "alwaysThinkingEnabled": true,
  "autoUpdatesChannel": "latest",
  "includeGitInstructions": false,
  "effortLevel": "high",
  "env": { ... },
  "statusLine": { ... }
}
```

### Top-Level Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `language` | string | `"English"` | Language for Claude Code responses |
| `alwaysThinkingEnabled` | boolean | `true` | Enable extended thinking for all responses |
| `autoUpdatesChannel` | string | `"latest"` | Update channel (`"latest"`, `"stable"`) |
| `includeGitInstructions` | boolean | `false` | Include built-in git instructions (disable if CLAUDE.md has custom git rules) |
| `effortLevel` | string | `"high"` | Default reasoning effort: `"low"`, `"medium"`, `"high"` |

---

## Hooks Configuration

Hooks are shell scripts that run at specific points in the Claude Code lifecycle. They are configured in the `hooks` section of `settings.json`.

### Hook Events

| Event | When It Fires | Use Cases |
|-------|---------------|-----------|
| `PreToolUse` | Before a tool is executed | Block dangerous operations, validate inputs |
| `PostToolUse` | After a tool completes | Track usage, warn on high context |
| `UserPromptSubmit` | When user sends a prompt | Suggest skills, validate input |
| `PostCompact` | After context compaction | Update session tracking, remind about state |
| `ConfigChange` | When settings are modified | Guard against unwanted config changes |
| `SessionStart` | When a session begins | Initialize tracking, load state |
| `Stop` | When a session ends normally | Cleanup, save state, final report |
| `StopFailure` | When a session ends with an error | Error recovery, cleanup, state preservation |

### Hook Entry Structure

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/hooks/secret-leak-check.sh"
          }
        ]
      }
    ]
  }
}
```

Each hook event contains an array of entries. Each entry has:

| Field | Type | Description |
|-------|------|-------------|
| `matcher` | string | Regex pattern to match tool names (empty string = match all) |
| `hooks` | array | List of hook commands to execute |
| `hooks[].type` | string | Always `"command"` for shell hooks |
| `hooks[].command` | string | Shell command to execute |
| `hooks[].once` | boolean | If `true`, run only once per session (used by SessionStart) |

### Matcher Patterns

The `matcher` field uses regex to match tool names:

| Pattern | Matches |
|---------|---------|
| `""` (empty) | All tools (catch-all) |
| `"Write\|Edit"` | Write or Edit tool calls |
| `"Bash"` | Bash tool calls only |
| `"Read"` | Read tool calls only |
| `"Glob\|Grep"` | File search tools |

### Included Hooks

| Hook | Event | Matcher | Purpose |
|------|-------|---------|---------|
| `secret-leak-check.sh` | PreToolUse | `Write\|Edit` | Scans file content for API keys, passwords, tokens |
| `checkpoint.sh` | PreToolUse | `Write\|Edit` | Creates git checkpoint before file modifications |
| `bash-guard.sh` | PreToolUse | `Bash` | Blocks `rm -rf /`, `git push --force`, and other destructive commands |
| `token-warning.sh` | PostToolUse | (all) | Warns at 70%, 85%, 95% context usage with cooldown |
| `skill-suggest.sh` | UserPromptSubmit | (all) | Analyzes prompts and suggests matching skills |
| `post-compact.sh` | PostCompact | (all) | Handles context compaction events |
| `config-change-guard.sh` | ConfigChange | (all) | Protects settings from unwanted modifications |
| `session-start.sh` | SessionStart | (all) | Initializes session tracking (runs once) |
| `session-stop.sh` | Stop | (all) | Cleanup on normal session end |
| `stop-failure.sh` | StopFailure | (all) | Cleanup on error session end |

### Hook Exit Codes

| Code | Meaning |
|------|---------|
| `0` | Allow — tool execution proceeds |
| `2` | Block — tool execution is prevented, message shown to user |

> **Important:** Hooks must produce no stdout on the allow path (exit 0). On Windows Git Bash, stdout is redirected to stderr, which Claude Code interprets as an error. Output only when blocking (exit 2).

---

## CLAUDE.md Template

The CLAUDE.md template at `core/CLAUDE.md.template` generates a personalized global instructions file. It uses `{{PLACEHOLDER}}` syntax for configurable values.

### Available Placeholders

| Placeholder | Description | Example |
|-------------|-------------|---------|
| `{{USER_NAME}}` | Your name for commit attribution | `Jane Smith` |
| `{{USER_EMAIL}}` | Your email for commit attribution | `jane@example.com` |
| `{{LANGUAGE_SECTION}}` | Language and communication preferences | English, result-first, no filler |
| `{{OS_SECTION}}` | OS-specific environment details | Windows 11 + Git Bash, Linux, macOS |
| `{{QUALITY_SECTION}}` | Design and quality standards | WCAG AA, OWASP, SEO basics |
| `{{TECH_STACK_SECTION}}` | Default technology stack preferences | Framework, database, auth choices |
| `{{GIT_SECTION}}` | Git and CI/CD conventions | Conventional commits, no auto-push |
| `{{SESSION_SECTION}}` | Session continuity rules | STATUS.md, MEMORY.md, /compact |

### Template Sections

The template produces a structured CLAUDE.md with these sections:

1. **Language & Communication** — how Claude should communicate
2. **Identity** — name and email for commits
3. **Environment** — OS, shell, paths
4. **Design & Quality** — coding standards
5. **Versions** — never hardcode, always check live
6. **Tech Defaults** — preferred frameworks and tools
7. **Git & CI/CD** — commit conventions and CI rules
8. **Error Handling** — root cause analysis pattern
9. **Cleanup** — workspace hygiene
10. **Deviation Handling** — when to auto-fix vs ask
11. **Work Approach** — task sizing and multi-scope handling
12. **Session & Continuity** — STATUS.md and MEMORY.md rules
13. **Code Protection & Anti-Patterns** — what to avoid
14. **Skills & Plugins** — using the skill system

---

## Environment Variables

Set in the `env` section of `settings.json`:

```json
{
  "env": {
    "CLAUDE_CODE_MAX_OUTPUT_TOKENS": "128000",
    "MAX_THINKING_TOKENS": "128000",
    "CLAUDE_AUTOCOMPACT_PCT_OVERRIDE": "80"
  }
}
```

| Variable | Default | Description |
|----------|---------|-------------|
| `CLAUDE_CODE_MAX_OUTPUT_TOKENS` | `"128000"` | Maximum output tokens per response |
| `MAX_THINKING_TOKENS` | `"128000"` | Maximum tokens for extended thinking |
| `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` | `"80"` | Context percentage at which auto-compaction triggers (default without override: 95%) |

### Additional Environment Variables (Set Externally)

| Variable | Description |
|----------|-------------|
| `CLAUDE_CODE_OAUTH_TOKEN` | OAuth token for API usage queries (auto-detected from `~/.claude/.credentials.json` if not set) |
| `CLAUDE_CODE_EFFORT_LEVEL` | Override effort level for current session |
| `CLAUDE_SESSION_ID` | Session identifier used by token-warning hook |

---

## Statusline

The statusline displays real-time information at the bottom of the Claude Code terminal. It is powered by `~/.claude/statusline-command.sh`.

### What It Shows

```
Opus 4.6 | my-project@main * | ████████░░ 80k/1m 80% | hi | 5h 45% @14:30 | 7d 23% @Mar 25 | $0.42 | 12k/min ~8t | 23m
```

| Segment | Description |
|---------|-------------|
| Model name | Current model (e.g., Opus 4.6) |
| Session name | Custom session name if set via `/rename` |
| Directory@branch | Current directory and git branch, `*` if dirty |
| VIM | Shown only if vim mode is active |
| Context bar | Visual fill bar + used/total tokens + percentage |
| Effort | `hi` / `med` / `low` |
| 5h usage | 5-hour rate limit utilization + reset time |
| 7d usage | 7-day rate limit utilization + reset time |
| Extra usage | Extra credit usage (if enabled on your plan) |
| Cost | Session cost in USD |
| Rate | Token burn rate per minute + estimated turns until compaction |
| Duration | Session duration |

### Color Coding

The statusline uses color to indicate urgency:

| Usage | Color |
|-------|-------|
| 0-49% | Green |
| 50-69% | Yellow |
| 70-89% | Orange |
| 90-100% | Red |

### Customizing the Statusline

Edit `~/.claude/statusline-command.sh` to modify segments. The script receives JSON input from Claude Code via stdin with these fields:

- `model.display_name` — current model name
- `context_window.context_window_size` — total context window
- `context_window.total_input_tokens` — cumulative input tokens
- `context_window.total_output_tokens` — cumulative output tokens
- `context_window.used_percentage` — actual window fill percentage
- `cwd` — current working directory
- `cost.total_cost_usd` — session cost
- `cost.total_duration_ms` — session duration in milliseconds
- `vim_mode` — whether vim mode is active
- `session.name` — custom session name

---

## Effort Levels

The effort level controls how much reasoning Claude applies to each response.

| Level | Setting | Best For |
|-------|---------|----------|
| `low` | Quick, concise responses | Simple questions, fast agents (explorer, dependency-checker) |
| `medium` | Balanced depth | Standard development tasks |
| `high` | Deep analysis, extended thinking | Audits, architecture decisions, complex debugging |

Set globally in `settings.json`:

```json
{ "effortLevel": "high" }
```

Override per-session via environment variable:

```bash
CLAUDE_CODE_EFFORT_LEVEL=low claude
```

Skills can specify their own effort level via frontmatter:

```markdown
---
name: explorer
effort: low
---
```

---

## Next Steps

- [Getting Started](getting-started.md) — installation walkthrough
- [Multi-Project Setup](multi-project.md) — manage multiple repos
- [FAQ](faq.md) — common questions

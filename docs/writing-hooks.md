# Writing Hooks

How to create custom hooks for Claude Hangar.

---

## What Is a Hook?

A hook is a shell script that Claude Code executes at specific lifecycle events. Hooks can **allow** actions silently, **block** them with a reason, or **inject context** into the conversation. They are the guardrails layer.

---

## Hook Events

| Event | When It Fires | Typical Use |
|-------|---------------|-------------|
| `PreToolUse` | Before a tool executes | Block dangerous commands, catch secrets |
| `PostToolUse` | After a tool completes | Token tracking, context warnings |
| `PostToolUseFailure` | When a tool call fails | Error pattern capture, recovery context |
| `UserPromptSubmit` | User sends a prompt | Skill suggestions, model routing, input validation |
| `PreCompact` | Before context compaction | Save critical state before context loss |
| `PostCompact` | After `/compact` runs | Reset tracking, re-inject context |
| `ConfigChange` | Settings modified | Warn on critical changes |
| `SessionStart` | Session begins | Load project state |
| `Stop` | Session ends normally | Cleanup, save state |
| `SessionEnd` | Session terminates (any reason) | Rich cleanup with `end_reason`, `session_duration_seconds` |
| `StopFailure` | Session ends with error | Log errors, cleanup |
| `PermissionDenied` | User denies a tool | Auto-retry with alternative approach |
| `PermissionRequest` | Permission dialog appears | Auto-approve/deny programmatically |
| `TaskCompleted` | Task marked as done | Quality gates, validation checks |
| `TaskCreated` | Task created via TaskCreate | Logging, task policies, naming conventions |
| `SubagentStart` | Subagent spawned | Observability, resource tracking |
| `SubagentStop` | Subagent finished | Observability, completion tracking |
| `WorktreeCreate` | Git worktree created | Path control, setup (supports `type: "http"`) |
| `CwdChanged` | Working directory changes | Environment adaptation |
| `InstructionsLoaded` | CLAUDE.md/rules loaded | Observability |

---

## Input / Output

### Stdin (Input)

Hooks receive JSON on stdin. Fields depend on the event:

- **PreToolUse / PostToolUse:** `{ "tool_name": "Bash", "tool_input": { "command": "..." } }`
- **UserPromptSubmit:** `{ "user_prompt": "check my site" }`
- **SessionStart / Stop / StopFailure:** `{ "cwd": "/path/to/project" }`

Always use fallback defaults — never assume a field exists.

### Stdout (Output)

| Action | JSON | Exit Code |
|--------|------|-----------|
| Block (PreToolUse) | `{"hookSpecificOutput":{"permissionDecision":"block","permissionDecisionReason":"..."}}` | 2 |
| Reject (TaskCompleted) | `{"result":"reject","reason":"..."}` | 2 |
| Inject context | `{"additionalContext":"..."}` | 0 |
| Suggest (UserPromptSubmit) | `{"result":"message","message":"..."}` | 0 |
| Set session title | `{"hookSpecificOutput":{"sessionTitle":"..."}}` | 0 |
| Allow silently | No output | 0 |

**Important:** The top-level `{"decision":"block","reason":"..."}` format is **deprecated** since v2.1.77. Always use the `hookSpecificOutput` wrapper for PreToolUse blocking decisions.

### Hook Definition Fields (settings.json)

| Field | Type | Purpose |
|-------|------|---------|
| `type` | `"command"` / `"http"` / `"prompt"` / `"agent"` | Hook execution type |
| `command` | string | Shell command to execute (for `type: "command"`) |
| `matcher` | string | Tool name pattern to match (e.g. `"Bash"`, `"Write\|Edit"`) |
| `if` | string | Conditional using permission rule syntax (e.g. `"Bash(rm *)"`, `"Bash(git push *)"`) — more granular than `matcher` |
| `once` | boolean | Run hook once per session only |
| `async` | boolean | Non-blocking background execution |

---

## Cross-Platform Rules

These are mandatory. Ignoring them causes failures on Windows Git Bash.

### 1. No stdout on the allow path

Git Bash redirects stdout to stderr (Issue #20034). Claude Code shows stderr as hook errors.

```bash
# WRONG — triggers error on Windows
echo '{"decision":"allow"}'
exit 0

# CORRECT — silent allow
exit 0
```

### 2. No set -euo pipefail

Causes silent failures on Git Bash. Use explicit error handling instead.

```bash
# CORRECT
INPUT=$(cat 2>/dev/null) || true
[ -z "$INPUT" ] && INPUT='{}'
```

### 3. Use Node.js for JSON, not jq

Node.js is required by Hangar (hooks use `node -e` for JSON parsing). jq may not be installed.

```bash
COMMAND=$(echo "$INPUT" | node -e "
  const d = JSON.parse(require('fs').readFileSync(0,'utf8'));
  console.log(d.tool_input?.command || '');
" 2>/dev/null || echo "")
```

### 4. Use ${TEMP:-/tmp} for temp files

Windows Git Bash has no `/tmp`. Always use `${TEMP:-/tmp}`.

### 5. Pass large data via env vars, not CLI args

Hook input can exceed 32KB (OS argument limit). Use `export HOOK_INPUT="$INPUT"`.

---

## Minimal Example

A PreToolUse hook blocking `console.log` in file writes. Create `core/hooks/no-console-log.sh`:

```bash
#!/usr/bin/env bash
# Hook: No Console Log — PreToolUse (Write, Edit)
# IMPORTANT: No stdout on the allow path (Git Bash Issue #20034).

INPUT=$(cat 2>/dev/null) || true
[ -z "$INPUT" ] && INPUT='{}'

CONTENT=$(echo "$INPUT" | node -e "
  const d = JSON.parse(require('fs').readFileSync(0,'utf8'));
  console.log(d.tool_input?.content || d.tool_input?.new_string || '');
" 2>/dev/null || echo "")

[ -z "$CONTENT" ] && exit 0

FILE_PATH=$(echo "$INPUT" | node -e "
  const d = JSON.parse(require('fs').readFileSync(0,'utf8'));
  console.log(d.tool_input?.file_path || '');
" 2>/dev/null || echo "")

# Allow in logger files
case "$FILE_PATH" in *logger*|*debug*) exit 0 ;; esac

if echo "$CONTENT" | grep -qE '\bconsole\.(log|debug)\b'; then
  node -e "console.log(JSON.stringify({
    decision: 'block',
    reason: 'console.log detected in ' + process.argv[1]
  }))" "$FILE_PATH"
  exit 2
fi

exit 0
```

---

## Registration

Add your hook to `core/settings.json.template`:

```json
{
  "PreToolUse": [
    {
      "matcher": "Write|Edit",
      "hooks": [
        { "type": "command", "command": "bash ~/.claude/hooks/no-console-log.sh" }
      ]
    }
  ]
}
```

The `matcher` is a regex against tool names. Empty string matches all tools. Use `"once": true` for SessionStart hooks.

### Conditional Hooks with `if` (v2.1.85+)

Add an `if` field using permission rule syntax to filter when a hook runs. This avoids spawning a process for every tool call:

```json
{
  "PreToolUse": [
    {
      "matcher": "Bash",
      "hooks": [
        {
          "type": "command",
          "command": "bash ~/.claude/hooks/secret-leak-check.sh",
          "if": "Bash(git *)"
        }
      ]
    }
  ]
}
```

The hook only fires for `Bash` calls matching `git *`. Without `if`, the hook fires for every `Bash` call. Use this to reduce process spawning overhead on frequently-called tools.

### Hook Types

| Type | Description |
|------|-------------|
| `command` | Shell command (default, cross-platform) |
| `http` | HTTP request to external service — returns JSON with `hookSpecificOutput` |

**HTTP hooks** are useful for `WorktreeCreate` (return `worktreePath` via `hookSpecificOutput.worktreePath`) and remote integrations:

```json
{
  "WorktreeCreate": [
    {
      "matcher": "",
      "hooks": [
        {
          "type": "http",
          "url": "https://internal-api.example.com/worktree-setup",
          "method": "POST"
        }
      ]
    }
  ]
}
```

---

## Testing

Pipe JSON directly to your hook:

```bash
# Should block (exit 2)
echo '{"tool_name":"Bash","tool_input":{"command":"rm -rf /"}}' \
  | bash core/hooks/bash-guard.sh
echo "Exit: $?"

# Should allow (exit 0, no output)
echo '{"tool_name":"Bash","tool_input":{"command":"ls -la"}}' \
  | bash core/hooks/bash-guard.sh
echo "Exit: $?"
```

Always test: empty input (`echo ''`), malformed JSON, and large input (>32KB). All should exit 0 without crashing.

---

## Headless AskUserQuestion (v2.1.85+)

PreToolUse hooks can intercept `AskUserQuestion` and provide answers programmatically — useful for CI/CD pipelines or custom UIs:

```bash
#!/usr/bin/env bash
# Hook: Auto-answer AskUserQuestion — PreToolUse (AskUserQuestion)

INPUT=$(cat 2>/dev/null) || true
[ -z "$INPUT" ] && INPUT='{}'

TOOL=$(echo "$INPUT" | node -e "
  const d = JSON.parse(require('fs').readFileSync(0,'utf8'));
  console.log(d.tool_name || '');
" 2>/dev/null || echo "")

[ "$TOOL" != "AskUserQuestion" ] && exit 0

# Provide answer via your own UI, API, or default
ANSWER="yes"

node -e "console.log(JSON.stringify({
  permissionDecision: 'allow',
  updatedInput: process.argv[1]
}))" "$ANSWER"
exit 0
```

---

## Best Practices

1. **Silent on allow** — no stdout when action is permitted
2. **Fail open** — if the hook crashes, exit 0 (action proceeds)
3. **Fast** — hooks run synchronously; slow hooks degrade UX
4. **Use `if` conditions** — reduce process spawning with permission rule syntax (v2.1.85+)
5. **Consolidate** — combine related checks (see bash-guard.sh: command guard + commit validator + CI guard)
6. **Cooldown for PostToolUse** — avoid hundreds of invocations per session
7. **Defensive parsing** — `2>/dev/null || true` everywhere

---

## Advanced Hook Patterns

The following patterns demonstrate more sophisticated hook designs beyond simple block/allow logic.

### MCP Health Check (Advisory PreToolUse)

The `mcp-health-check` hook monitors MCP server reliability. Instead of blocking tool calls, it tracks failures in a temp file and warns when a server has repeated failures. This is an **advisory** hook — it never blocks, only injects context.

Key techniques:
- Maintains a failure counter per MCP server in `${TEMP:-/tmp}/claude-mcp-health-{session}.json`
- Uses `additionalContext` to warn the user when a server exceeds the failure threshold
- Resets counters on successful calls
- Always exits 0 — never blocks MCP tool usage

```bash
# Advisory pattern: track failures, warn on threshold
FAILURES=$(node -e "
  const state = require(process.argv[1]);
  const server = process.argv[2];
  console.log(state[server]?.failures || 0);
" "$STATE_FILE" "$SERVER_NAME" 2>/dev/null || echo "0")

if [ "$FAILURES" -ge "$THRESHOLD" ]; then
  node -e "console.log(JSON.stringify({
    additionalContext: 'MCP server ' + process.argv[1] + ' has failed ' + process.argv[2] + ' times. Consider restarting it.'
  }))" "$SERVER_NAME" "$FAILURES"
fi
exit 0
```

### Batch Format: Collector + Runner (PostToolUse + Stop)

This is a **two-hook pattern** where one hook collects data and another acts on it at session end. It avoids running formatters after every file edit (which would be slow and disruptive).

**`batch-format-collector` (PostToolUse):** Watches for Write/Edit tool calls and appends each edited file path to a temp file. Silent on the allow path — no stdout, no blocking.

**`stop-batch-format` (Stop):** Reads the collected file paths, deduplicates them, detects which formatters are available (Prettier, Biome, Black, etc.), and runs them once in batch. Logs results but never blocks session end.

Key techniques:
- Collector writes to `${TEMP:-/tmp}/claude-batch-format-{session}.txt` (one path per line)
- Runner reads, deduplicates with `sort -u`, groups by file extension
- Runner detects formatters from project config files (`package.json`, `pyproject.toml`)
- Both hooks fail open — collector errors are ignored, runner errors are logged

```bash
# Collector (PostToolUse): append edited file path
FILE_PATH=$(echo "$INPUT" | node -e "
  const d = JSON.parse(require('fs').readFileSync(0,'utf8'));
  console.log(d.tool_input?.file_path || '');
" 2>/dev/null || echo "")

[ -z "$FILE_PATH" ] && exit 0
echo "$FILE_PATH" >> "${TEMP:-/tmp}/claude-batch-format-${SESSION_ID}.txt"
exit 0
```

```bash
# Runner (Stop): format all collected files
COLLECTED="${TEMP:-/tmp}/claude-batch-format-${SESSION_ID}.txt"
[ ! -f "$COLLECTED" ] && exit 0

FILES=$(sort -u "$COLLECTED")
# Detect formatters and run in batch...
rm -f "$COLLECTED"
exit 0
```

### Design Quality Check (PostToolUse Content Analysis)

The `design-quality-check` hook analyzes the **content** of frontend file edits, not just the tool call metadata. It detects patterns that indicate generic AI UI drift — overly symmetric grids, default blue/indigo color schemes, generic placeholder text, and other signals.

Key techniques:
- Filters on file extension first (`.tsx`, `.svelte`, `.astro`, `.html`, `.css`)
- Extracts the written content from `tool_input.content` or `tool_input.new_string`
- Runs pattern matching for known AI aesthetic anti-patterns
- Uses `additionalContext` to nudge — never blocks, only advises
- Has a cooldown to avoid firing on every small edit

```bash
# Content analysis: check for AI aesthetic patterns
CONTENT=$(echo "$INPUT" | node -e "
  const d = JSON.parse(require('fs').readFileSync(0,'utf8'));
  console.log(d.tool_input?.content || d.tool_input?.new_string || '');
" 2>/dev/null || echo "")

# Check for generic AI patterns
AI_PATTERNS="grid-cols-3.*grid-cols-3|bg-blue-500|bg-indigo-600|Lorem ipsum|rounded-lg shadow-md p-6"
if echo "$CONTENT" | grep -qE "$AI_PATTERNS"; then
  node -e "console.log(JSON.stringify({
    additionalContext: 'Design drift detected: this looks like generic AI output. Review design-principles.md for project standards.'
  }))"
fi
exit 0
```

---

## Hook Count Summary

Claude Hangar ships with **27 hooks** across all lifecycle events:

| Event | Count | Hooks |
|-------|------:|-------|
| PreToolUse | 7 | secret-leak-check, bash-guard, checkpoint, config-protection, mcp-health-check, db-query-guard, permission-denied-retry |
| PostToolUse | 6 | token-warning, design-quality-check, batch-format-collector, continuous-learning, cost-tracker, instinct-capture |
| UserPromptSubmit | 2 | skill-suggest, model-router |
| SessionStart | 1 | session-start |
| Stop | 5 | session-stop, stop-batch-format, stop-failure, desktop-notify, instinct-evolve |
| PostCompact | 1 | post-compact |
| ConfigChange | 1 | config-change-guard |
| TaskCompleted | 1 | task-completed-gate |
| TaskCreated | 1 | task-created-init |
| SubagentStart/Stop | 1 | subagent-tracker |
| WorktreeCreate | 1 | worktree-init |

---

## Next Steps

- [Writing Skills](writing-skills.md) — create skill workflows
- [Writing Agents](writing-agents.md) — create sub-agents
- [Configuration Reference](configuration.md) — hook registration details

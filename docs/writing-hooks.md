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
| `UserPromptSubmit` | User sends a prompt | Skill suggestions, model routing, input validation |
| `PostCompact` | After `/compact` runs | Reset tracking, re-inject context |
| `ConfigChange` | Settings modified | Warn on critical changes |
| `SessionStart` | Session begins | Load project state |
| `Stop` | Session ends normally | Cleanup, save state |
| `StopFailure` | Session ends with error | Log errors, cleanup |
| `TaskCompleted` | Task marked as done | Quality gates, validation checks |
| `SubagentStart` | Subagent spawned | Observability, resource tracking |
| `SubagentStop` | Subagent finished | Observability, completion tracking |

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
| Block | `{"decision":"block","reason":"..."}` | 2 |
| Reject (TaskCompleted) | `{"result":"reject","reason":"..."}` | 2 |
| Inject context | `{"additionalContext":"..."}` | 0 |
| Suggest (UserPromptSubmit) | `{"result":"message","message":"..."}` | 0 |
| Allow silently | No output | 0 |

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

Node.js is guaranteed (Claude Code dependency). jq may not be installed.

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

## Best Practices

1. **Silent on allow** — no stdout when action is permitted
2. **Fail open** — if the hook crashes, exit 0 (action proceeds)
3. **Fast** — hooks run synchronously; slow hooks degrade UX
4. **Consolidate** — combine related checks (see bash-guard.sh: command guard + commit validator + CI guard)
5. **Cooldown for PostToolUse** — avoid hundreds of invocations per session
6. **Defensive parsing** — `2>/dev/null || true` everywhere

---

## Next Steps

- [Writing Skills](writing-skills.md) — create skill workflows
- [Writing Agents](writing-agents.md) — create sub-agents
- [Configuration Reference](configuration.md) — hook registration details

# Writing Hooks

A guide to creating custom hooks for Claude Hangar.

## What Is a Hook?

A hook is a shell script that Claude Code executes at specific lifecycle events. Hooks can inspect what Claude Code is about to do (or just did), and either **allow** the action silently, **block** it with a reason, or **inject context** into the conversation.

Hooks are the guardrails layer: they prevent destructive commands, catch secret leaks, enforce commit conventions, and suggest skills -- all without requiring user intervention.

## Hook Events

Claude Code provides eight hook events. Each fires at a specific point in the lifecycle:

| Event | When It Fires | Typical Use |
|-------|---------------|-------------|
| `PreToolUse` | Before a tool call executes | Block dangerous commands, catch secrets |
| `PostToolUse` | After a tool call completes | Token tracking, context warnings |
| `UserPromptSubmit` | When the user submits a prompt | Skill suggestions, input validation |
| `PostCompact` | After `/compact` runs | Re-inject critical context |
| `ConfigChange` | When settings are modified | Prevent accidental config changes |
| `SessionStart` | When a new session begins | Load project state, show status |
| `Stop` | When Claude Code finishes a response | Session cleanup, state persistence |
| `StopFailure` | When Claude Code fails to complete | Error recovery, state preservation |

## Input Format

Hooks receive JSON on **stdin**. Fields depend on the event:

- **PreToolUse / PostToolUse:** `{ "tool_name": "Bash", "tool_input": { "command": "..." } }`
- **PostToolUse (extended):** Also includes `tool_result` and `used_percentage`
- **UserPromptSubmit:** `{ "user_prompt": "check if my site is running" }`
- **SessionStart / Stop / StopFailure / PostCompact / ConfigChange:** Minimal or empty JSON

Always use fallback defaults -- do not depend on specific fields existing.

## Output Format

Hooks communicate back via **stdout JSON**:

| Action | JSON | When |
|--------|------|------|
| Block | `{"decision":"block","reason":"..."}` | PreToolUse only |
| Inject context | `{"additionalContext":"..."}` | Any event |
| Show message | `{"result":"message","message":"..."}` | UserPromptSubmit |
| Allow silently | No output, just `exit 0` | Default |

## Exit Codes

| Code | Meaning | When to Use |
|------|---------|-------------|
| `0` | Allow / success | Action proceeds normally |
| `2` | Block | Action is prevented, reason shown to user |

Any other exit code is treated as a hook error. Avoid exit code `1` -- it signals a script failure, not a deliberate block.

## Cross-Platform Gotchas

These are hard-won lessons. Ignore them at your peril.

### Git Bash stdout-to-stderr (Issue #20034)

On Windows Git Bash, stdout output is sometimes redirected to stderr. Claude Code interprets stderr as a "hook error" and shows a warning in the TUI.

**Rule:** Never produce stdout output on the "allow" path. Only output JSON when blocking (exit 2) or providing context.

```bash
# WRONG -- produces stdout on allow path, triggers error on Windows
echo '{"decision":"allow"}'
exit 0

# CORRECT -- silent on allow, output only on block
exit 0
```

### No set -euo pipefail

On Windows Git Bash, `set -euo pipefail` causes hooks to fail silently on harmless errors. Hooks must be resilient.

```bash
# WRONG
set -euo pipefail

# CORRECT -- no strict mode, explicit error handling
INPUT=$(cat 2>/dev/null) || true
[ -z "$INPUT" ] && INPUT='{}'
```

### JSON Parsing: Use Node, Not jq

`jq` may not be installed. Node.js is a guaranteed dependency (required by Claude Code itself).

```bash
# WRONG -- jq may not exist
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command')

# CORRECT -- node is always available
COMMAND=$(echo "$INPUT" | node -e "
  const d = JSON.parse(require('fs').readFileSync(0,'utf8'));
  console.log(d.tool_input?.command || '');
" 2>/dev/null || echo "")
```

### Temp Files: Use $TEMP, Not /tmp

Windows Git Bash does not have `/tmp`. Use `${TEMP:-/tmp}` for cross-platform compatibility.

```bash
TRACK_FILE="${TEMP:-/tmp}/my-hook-state-${SESSION_ID}"
```

### No $INPUT as CLI Argument

Hook input JSON can exceed 32KB (the OS argument length limit). Always pass data via environment variables or files.

```bash
# WRONG -- fails silently if JSON > 32k
node -e "..." "$INPUT"

# CORRECT -- pass via environment variable
export HOOK_INPUT="$INPUT"
node -e "const input = JSON.parse(process.env.HOOK_INPUT || '{}');"
```

## Minimal Example: no-console-log

A PreToolUse hook that blocks Write/Edit calls containing `console.log`. Create `core/hooks/no-console-log.sh`:

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
case "$FILE_PATH" in *logger*|*debug*|*console*) exit 0 ;; esac

if echo "$CONTENT" | grep -qE '\bconsole\.(log|debug|warn)\b'; then
  node -e "console.log(JSON.stringify({
    decision: 'block',
    reason: 'NO-CONSOLE-LOG: console.log detected in ' + process.argv[1]
  }))" "$FILE_PATH"
  exit 2
fi

exit 0
```

## Testing Hooks

### Simulating JSON Input

Pipe JSON directly to your hook script:

```bash
# Test PreToolUse (Bash) -- should block
echo '{"tool_name":"Bash","tool_input":{"command":"rm -rf /"}}' \
  | bash core/hooks/bash-guard.sh
echo "Exit code: $?"
# Expected: JSON block output, exit code 2

# Test PreToolUse (Bash) -- should allow
echo '{"tool_name":"Bash","tool_input":{"command":"ls -la"}}' \
  | bash core/hooks/bash-guard.sh
echo "Exit code: $?"
# Expected: no output, exit code 0
```

### Edge Cases to Test

Always test these: empty input (`echo ''`), malformed JSON (`echo 'not json'`), and large input (>32KB). All should exit 0 without crashing. Add tests to `tests/test-hooks.sh` covering both the allow path (exit 0, no stdout) and the block path (exit 2, valid JSON).

## Registration in settings.json

After creating your hook, register it in `core/settings.json.template`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/hooks/no-console-log.sh"
          }
        ]
      }
    ]
  }
}
```

### Configuration Fields

| Field | Purpose | Example |
|-------|---------|---------|
| `matcher` | Regex matching tool names (empty = all tools) | `"Write\|Edit"`, `"Bash"`, `""` |
| `type` | Always `"command"` | `"command"` |
| `command` | Shell command to execute | `"bash ~/.claude/hooks/my-hook.sh"` |
| `once` | Run only once per session (optional) | `true` |

Matcher is a regex against tool names. `"Bash"` matches Bash only, `"Write|Edit"` matches both, `""` matches everything (use sparingly). For events without tools (UserPromptSubmit, PostCompact, ConfigChange, Stop, StopFailure), matcher is always `""`. For SessionStart, use `"once": true`.

## Best Practices

1. **Silent on allow** -- no stdout when the action is permitted
2. **Fail open** -- if your hook crashes, the action should proceed (exit 0)
3. **Fast execution** -- hooks run synchronously; slow hooks degrade UX
4. **Consolidate** -- combine related checks into one hook to reduce stdin reads
5. **Defensive parsing** -- `2>/dev/null || true` for reads, `|| echo ""` for extractions
6. **Cooldown for PostToolUse** -- implement cooldown to avoid hundreds of invocations
7. **Use node -e for JSON** -- never rely on jq, grep -P, or other optional tools

## Contributing

1. Naming: `core/hooks/{kebab-case-name}.sh`
2. Header comment with trigger event, purpose, platform notes
3. Registration entry in `core/settings.json.template`
4. Tests in `tests/test-hooks.sh`
5. Test on Linux and Git Bash (Windows)
6. Conventional Commit: `feat(hooks): add no-console-log hook`

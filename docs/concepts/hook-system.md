# Hook System

Hooks are shell scripts that run automatically at specific points during a Claude Code session. They act as guardrails -- blocking dangerous operations, injecting context, tracking usage, and maintaining session continuity.

## Event Timeline

A typical session triggers hook events in this order:

```
SessionStart          -- session begins (once)
  |
  v
UserPromptSubmit      -- user sends a message
  |
  v
PreToolUse            -- before a tool executes (Write, Edit, Bash, etc.)
  |
  v
[Tool executes]
  |
  v
PostToolUse           -- after a tool completes
  |
  v
TaskCreated           -- when a task is created via TaskCreate
  |
  v
  ... (repeat for each tool call)
  |
  v
SubagentStart         -- when a subagent is spawned
  |
  v
SubagentStop          -- when a subagent finishes
  |
  v
TaskCompleted         -- when a task is marked done
  |
  v
WorktreeCreate        -- when a git worktree is created
  |
  v
PostCompact           -- after context compaction (if triggered)
  |
  v
Stop                  -- session ends normally
  or
StopFailure           -- session ends with an error
  |
  v
ConfigChange          -- when Claude Code config is modified (any time)
```

## Registered Hooks

Claude Hangar registers hooks via `settings.json`:

| Event | Hook | Purpose |
|-------|------|---------|
| `SessionStart` | `session-start.sh` | Load STATUS.md, .tasks.json, check MEMORY.md hygiene |
| `UserPromptSubmit` | `skill-suggest.sh` | Suggest matching skill based on prompt |
| `UserPromptSubmit` | `model-router.sh` | Suggest optimal model tier based on task complexity |
| `PreToolUse (Write\|Edit)` | `secret-leak-check.sh` | Block writes containing secrets/API keys |
| `PreToolUse (Write\|Edit)` | `checkpoint.sh` | Create git stash checkpoint before edits |
| `PreToolUse (Bash)` | `bash-guard.sh` | Block dangerous commands, validate commits, CI checks |
| `PostToolUse` | `token-warning.sh` | Track context utilization, warn at 70%/80% |
| `PostCompact` | `post-compact.sh` | Reset token tracking, save context snapshot |
| `ConfigChange` | `config-change-guard.sh` | Log config changes, warn on critical settings |
| `Stop` | `session-stop.sh` | Check for leftover temp files, log session cost |
| `StopFailure` | `stop-failure.sh` | Log error details for tracking |
| `TaskCompleted` | `task-completed-gate.sh` | Quality gate — rejects tasks with errors/empty results |
| `SubagentStart` | `subagent-tracker.sh` | Track subagent lifecycle for observability |
| `SubagentStop` | `subagent-tracker.sh` | Track subagent lifecycle for observability |

## Hook Chain

Multiple hooks can be registered for the same event. When an event fires:

1. All registered hooks for that event execute
2. Each hook receives the same JSON input via stdin
3. For `PreToolUse`, all hooks must pass (allow) for the tool to execute
4. If any hook blocks (`exit 2` with a `decision: "block"` JSON response), the tool call is rejected

**Example:** When a `Write` tool call fires, both `secret-leak-check.sh` and `checkpoint.sh` run. The secret check might block the write, while the checkpoint creates a safety snapshot.

## Decision Flow

Hooks communicate their decision via exit codes and stdout:

### Allow (silent)
```bash
# No output, exit 0
exit 0
```

### Block
```bash
# Output JSON with block decision and reason
echo '{"decision":"block","reason":"SECRET-LEAK: API key detected in file.js"}'
exit 2
```

### Provide context (non-blocking)
```bash
# Output informational message (additionalContext or message)
echo "STATUS.md found: Currently working on auth refactor"
exit 0
```

### Important: The silent allow path

On Windows Git Bash, stdout is redirected to stderr due to a known issue (GitHub Issue #20034). Claude Code interprets stderr output as a hook error. Therefore, hooks must produce **no stdout output** on the allow path. Output only on block or when providing context.

## Hook Architecture

### Input format

Every hook receives JSON via stdin with event-specific data:

```json
{
  "tool_name": "Write",
  "tool_input": {
    "file_path": "/path/to/file.js",
    "content": "const x = 42;"
  },
  "cwd": "/project/root"
}
```

### JSON parsing

Hooks use `node -e` for JSON parsing instead of `jq` to ensure cross-platform compatibility. Large inputs (up to 32KB) are passed via environment variables rather than CLI arguments to avoid shell limits.

## Cross-Platform Considerations

Hooks must work on both Linux and Windows (Git Bash). Key constraints:

| Concern | Linux | Windows Git Bash |
|---------|-------|-----------------|
| `set -euo pipefail` | Standard practice | Causes failures -- do not use |
| Temp directory | `/tmp/` | `${TEMP:-/tmp}` |
| stdin from pipe | Works | Use `cat 2>/dev/null \|\| true` |
| stdout on allow | Works fine | Redirected to stderr -- keep silent |
| `/dev/stdin` | Available | Not available -- use environment variables |
| File paths | Forward slashes | Mixed slashes -- normalize with `${path//\\//}` |

**Universal rule:** Every hook starts with a resilience header:

```bash
#!/usr/bin/env bash
# No set -euo pipefail -- hooks must be resilient on Windows
INPUT=$(cat 2>/dev/null) || true
[ -z "$INPUT" ] && INPUT='{}'
```

## Performance Patterns

### Cooldown

The `token-warning` hook fires on every `PostToolUse` event -- potentially hundreds of times per session. A cooldown file limits evaluation to once every 30 seconds, saving approximately 400 process starts per session.

### One-time hooks

The `session-start` hook uses the `"once": true` flag in settings.json to ensure it runs only at session start, not on every tool call.

### Consolidated hooks

The `bash-guard.sh` hook consolidates three formerly separate hooks (bash command guard, commit message validator, CI guard) into a single script. This means one stdin read and one JSON parse instead of three.

## Security Model

Hooks serve as guardrails, not gates. They are a safety net that catches common mistakes, not a security boundary that prevents determined misuse.

### What hooks prevent

- **Secret leaks:** Patterns for 20+ secret types (AWS, GitHub, Anthropic, Stripe, etc.)
- **Destructive commands:** `rm -rf /`, `rm -rf ~`, fork bombs, `mkfs`
- **Remote code execution:** `curl | bash`, `eval $(curl ...)`, process substitution
- **Dangerous git operations:** `push --force`, `reset --hard origin`, `--no-verify`
- **Critical config changes:** Modifications to permission-bypassing settings

### What hooks do not prevent

- **Intentional bypasses:** A user who knows the system can work around hooks
- **Novel attack patterns:** Only known patterns are detected
- **Runtime security:** Hooks check tool calls, not the running application

### Memory hygiene (ASI06)

The `session-start` hook includes a memory hygiene check that scans MEMORY.md for:
- Suspicious control overrides ("skip security", "bypass verification")
- Accidentally stored secrets (API keys, private keys)
- Suspicious links to external executables
- Injected eval/exec calls

This protects against context poisoning attacks where a compromised memory file could influence future sessions.

## Adding a New Hook

1. Create the script in `core/hooks/` following the resilience header pattern
2. Register it in `core/settings.json.template` under the appropriate event
3. Add a test in `tests/test-hooks.sh`
4. Run `bash setup.sh` to deploy

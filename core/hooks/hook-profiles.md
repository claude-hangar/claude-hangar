# Hook Profiles

Control hook strictness via the `HANGAR_HOOK_PROFILE` environment variable.
Each hook declares its minimum profile level — hooks below the active level
are silently skipped at runtime via `hook-gate.sh`.

## Available Profiles

| Profile | Behavior | Use When |
|---------|----------|----------|
| `minimal` | Safety hooks only (3 hooks) | Quick prototyping, minimal overhead |
| `standard` | Safety + quality hooks (21 hooks, **default**) | Normal development |
| `strict` | All hooks active (27 hooks) | Production/CI, learning enabled |

## Usage

```bash
# Set profile for current session
export HANGAR_HOOK_PROFILE=minimal

# Set profile permanently in shell profile
echo 'export HANGAR_HOOK_PROFILE=standard' >> ~/.bashrc
```

## Disabling Individual Hooks

```bash
# Comma-separated list of hooks to disable (overrides profile)
export HANGAR_DISABLED_HOOKS=token-warning,desktop-notify
```

## How It Works

Each hook includes a 3-line gate at the top:

```bash
HOOK_NAME="bash-guard"; HOOK_MIN_PROFILE="minimal"
source "${HOME}/.claude/lib/hook-gate.sh" 2>/dev/null || true
```

The gate script (`core/lib/hook-gate.sh`) checks:
1. Is this hook in `HANGAR_DISABLED_HOOKS`? → skip
2. Is the current profile level >= hook's minimum level? → run, else skip
3. If `hook-gate.sh` is missing → hook runs normally (graceful fallback)

## Profile Mapping

### minimal (3 hooks — safety only)

| Hook | Event | Purpose |
|------|-------|---------|
| `bash-guard` | PreToolUse/Bash | Block destructive commands |
| `secret-leak-check` | PreToolUse/Write,Edit | Block secret leaks |
| `config-protection` | PreToolUse/Write,Edit | Block config weakening |

### standard (18 additional hooks — default)

| Hook | Event | Purpose |
|------|-------|---------|
| `checkpoint` | PreToolUse/Write,Edit | Git stash before edits |
| `config-change-guard` | ConfigChange | Warn on critical settings |
| `db-query-guard` | PreToolUse/Bash | Warn on direct DB access |
| `design-quality-check` | PostToolUse/Write,Edit | Detect generic AI UI patterns |
| `mcp-health-check` | PreToolUse | MCP server health monitoring |
| `model-router` | UserPromptSubmit | Smart model tier suggestion |
| `permission-denied-retry` | PermissionDenied | Auto-retry safe denials |
| `post-compact` | PostCompact | Context recovery |
| `batch-format-collector` | PostToolUse/Write,Edit | Collect paths for batch format |
| `stop-batch-format` | Stop | Run formatters on all edited files |
| `session-start` | SessionStart | Load status, tasks, memory |
| `session-stop` | Stop | Cleanup, log session |
| `skill-suggest` | UserPromptSubmit | Suggest matching skills |
| `stop-failure` | StopFailure | Log session errors |
| `task-completed-gate` | TaskCompleted | 4-level quality gate |
| `task-created-init` | TaskCreated | Initialize task metadata |
| `token-warning` | PostToolUse | Alert at 70%/80% context |
| `worktree-init` | WorktreeCreate | Initialize worktree |

### strict (6 additional hooks — everything)

| Hook | Event | Purpose |
|------|-------|---------|
| `continuous-learning` | PostToolUse | Capture success patterns |
| `instinct-capture` | PostToolUse | Record tool call observations |
| `instinct-evolve` | Stop | Extract session learnings |
| `cost-tracker` | PostToolUse | Token/cost tracking |
| `desktop-notify` | Stop | OS-native notifications |
| `subagent-tracker` | SubagentStart/Stop | Lifecycle forensics |

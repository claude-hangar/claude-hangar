# Hooks

Rules for how hooks should be used and governed in the Claude Hangar ecosystem.

## Hook Types

| Type | When | Purpose |
|------|------|---------|
| **PreToolUse** | Before tool execution | Block dangerous actions, validate inputs |
| **PostToolUse** | After tool execution | Audit, track, learn from outcomes |
| **UserPromptSubmit** | When user sends message | Route, suggest, capture intent |
| **Stop** | When agent stops | Persist state, notify, clean up |
| **SessionStart** | Session begins | Load context, initialize state |
| **SessionEnd** | Session ends | Save state, generate summary |

## Hook Design Principles

1. **Hooks must be resilient** — No `set -euo pipefail` on Windows Git Bash
2. **Hooks must be fast** — Max 10s for sync hooks, 30s for async
3. **Hooks must be silent on success** — No stdout on the allow path
4. **Hooks parse JSON via node** — Not jq (cross-platform compatibility)
5. **Hooks exit cleanly** — Always `exit 0` unless blocking

## Hook Profiles

Use `HANGAR_HOOK_PROFILE` to control strictness:

- **minimal** — Safety hooks only (bash-guard, secret-leak)
- **standard** — Safety + quality (default)
- **strict** — Everything enabled, blocking mode

## Best Practices

- **Auto-accept hook guidance** — When a hook suggests an action, follow it
- **Don't fight hooks** — If a hook blocks an action, fix the cause, don't bypass
- **Use hooks for enforcement** — Hooks are more reliable than prompt instructions
- **Keep hooks focused** — One hook, one responsibility
- **Test every hook** — Every hook must have a test in tests/test-hooks.sh

## Anti-Patterns

- **Silent swallowing** — Catching errors without logging
- **Blocking on optional checks** — Use `exit 0` for advisory hooks
- **Heavy computation** — Keep hooks lightweight, delegate to skills for analysis
- **State mutation** — Hooks should observe and report, not modify project state

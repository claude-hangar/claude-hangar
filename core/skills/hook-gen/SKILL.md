---
name: hook-gen
description: >
  Generate Claude Code hook configurations from natural language descriptions.
  Use when: "create hook", "add hook", "hook for", "when X happens do Y", "hook-gen".
effort: medium
user-invocable: true
argument-hint: "[description of desired behavior]"
---

# /hook-gen — Natural Language Hook Generator

Convert plain English behavior descriptions into ready-to-use Claude Code hook configurations.

## Instructions

### Step 1: Parse the Request

From `$ARGUMENTS` or user message, extract:
- **Trigger**: When should this hook fire? (tool use, prompt submit, session events)
- **Condition**: What pattern to match? (file types, commands, content)
- **Action**: What should happen? (block, warn, log, transform, suggest)

If the description is ambiguous, ask ONE clarifying question with a recommended answer.

### Step 2: Map to Hook Event

| User Intent | Hook Event | Matcher |
|-------------|-----------|---------|
| "before editing/writing files" | PreToolUse | `Write\|Edit` |
| "before running commands" | PreToolUse | `Bash` |
| "after file changes" | PostToolUse | `Write\|Edit` |
| "when user types/asks" | UserPromptSubmit | `""` |
| "at session start" | SessionStart | `""` |
| "at session end" | Stop | `""` |
| "when task completes" | TaskCompleted | `""` |
| "when tool fails" | PostToolUseFailure | `""` |
| "before context compaction" | PreCompact | `""` |

### Step 3: Generate Hook Script

Create a shell script following this template:

```bash
#!/usr/bin/env bash
# Hook: {{HOOK_NAME}}
# Trigger: {{EVENT}} ({{MATCHER}})
# {{DESCRIPTION}}

# No set -euo pipefail — hooks must be resilient on Windows

# Hook profile gate
export HOOK_NAME="{{hook-name}}"; export HOOK_MIN_PROFILE="standard"
source "${HOME}/.claude/lib/hook-gate.sh" 2>/dev/null || true

INPUT=$(cat 2>/dev/null) || true
[ -z "$INPUT" ] && exit 0

# Parse input via node (cross-platform, no jq)
{{PARSING_LOGIC}}

# {{ACTION_LOGIC}}

exit 0
```

### Step 4: Generate settings.json Entry

Output the hook configuration in settings.json format:

```json
{
  "hooks": {
    "{{EVENT}}": [
      {
        "matcher": "{{MATCHER}}",
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/hooks/{{hook-name}}.sh"
          }
        ]
      }
    ]
  }
}
```

### Step 5: Output

Present both the script and settings.json entry. Then ask:
1. "Save to `~/.claude/hooks/{{hook-name}}.sh`?"
2. "Add to `~/.claude/settings.json`?"

## Examples

| Input | Generated Hook |
|-------|---------------|
| "warn me before deleting files" | PreToolUse/Bash: detect `rm` commands, output warning message |
| "log all file edits" | PostToolUse/Write,Edit: append file path + timestamp to log |
| "suggest /deploy-check before pushing" | PreToolUse/Bash: detect `git push`, suggest skill |
| "block writes to production configs" | PreToolUse/Write,Edit: check file path, block if matches prod pattern |

## Rules

- Always use `node -e` for JSON parsing (no jq)
- Always include the hook-gate.sh integration
- Never use `set -euo pipefail` (breaks on Windows Git Bash)
- Output must be valid JSON for the blocking path (hookSpecificOutput format)
- Default profile level: `standard` (suggest `minimal` only for safety-critical hooks)

#!/usr/bin/env bash
# Hook: DB Query Guard — PreToolUse (Bash)
# Advisory hook that warns when the agent attempts to directly access
# internal databases or state files via CLI commands.
# Forces awareness of proper API/tool usage over raw queries.
#
# IMPORTANT: No stdout output on the "allow" path!
# Git Bash redirects stdout to stderr (Issue #20034) → "hook error" in TUI.
# Output ONLY when a warning is issued (additionalContext).

# No set -euo pipefail — hooks must be resilient on Windows

# Hook profile gate
export HOOK_NAME="db-query-guard"; export HOOK_MIN_PROFILE="standard"
source "${HOME}/.claude/lib/hook-gate.sh" 2>/dev/null || true

# === Read stdin once ===

INPUT=$(cat 2>/dev/null) || true
[ -z "$INPUT" ] && INPUT='{}'

# Extract tool name and command
RESULT=$(echo "$INPUT" | node -e "
  const d = JSON.parse(require('fs').readFileSync(0, 'utf8'));
  const tool = d.tool_name || '';
  const cmd = d.tool_input?.command || '';
  console.log(JSON.stringify({ tool, cmd }));
" 2>/dev/null || echo '{"tool":"","cmd":""}')

TOOL_NAME=$(echo "$RESULT" | node -e "
  const d = JSON.parse(require('fs').readFileSync(0, 'utf8'));
  console.log(d.tool);
" 2>/dev/null || echo "")

COMMAND=$(echo "$RESULT" | node -e "
  const d = JSON.parse(require('fs').readFileSync(0, 'utf8'));
  console.log(d.cmd);
" 2>/dev/null || echo "")

# Only trigger on Bash tool
[ "$TOOL_NAME" != "Bash" ] && exit 0

# Empty command → allow
[ -z "$COMMAND" ] && exit 0

# === Pattern detection ===

WARNING=""

# 1. sqlite3 commands targeting .claude/ or state files
if echo "$COMMAND" | grep -qE 'sqlite3\s+.*\.claude[/\\]'; then
  WARNING="sqlite3 targeting .claude/ state"
fi

# 2. sqlite3 targeting .db or .sqlite files in state directories
if echo "$COMMAND" | grep -qE 'sqlite3\s+.*\.(db|sqlite)\b'; then
  WARNING="sqlite3 targeting database file"
fi

# 3. Direct SELECT/INSERT/UPDATE/DELETE via sqlite3
if echo "$COMMAND" | grep -qiE 'sqlite3\s+.*\b(SELECT|INSERT|UPDATE|DELETE)\b'; then
  WARNING="direct SQL query via sqlite3"
fi

# 4. cat or less on .jsonl state files in .claude/
if echo "$COMMAND" | grep -qE '(cat|less)\s+.*\.claude[/\\].*\.jsonl\b'; then
  WARNING="reading .claude/ state file directly"
fi

# 5. cat or less on generic .jsonl state files
if echo "$COMMAND" | grep -qE '(cat|less)\s+.*\.(jsonl)\b.*state'; then
  WARNING="reading state .jsonl file directly"
fi

# 6. rm on database files (.db, .sqlite)
if echo "$COMMAND" | grep -qE 'rm\s+.*\.(db|sqlite)\b'; then
  WARNING="deleting database file"
fi

# 7. rm on .claude/ state files
if echo "$COMMAND" | grep -qE 'rm\s+.*\.claude[/\\].*\.(jsonl|db|sqlite)\b'; then
  WARNING="deleting .claude/ state file"
fi

# === Result ===

if [ -n "$WARNING" ]; then
  node -e "
    console.log(JSON.stringify({
      additionalContext: 'DB GUARD: Direct database access detected (' + process.argv[1] + '). Use proper API tools instead of raw queries. Direct manipulation may corrupt state files.'
    }));
  " "$WARNING"
  exit 0
fi

# All OK — silently allow
exit 0

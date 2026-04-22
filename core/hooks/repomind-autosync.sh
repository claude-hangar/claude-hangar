#!/usr/bin/env bash
# Hook: Repomind Autosync
# Trigger: SessionEnd
# Runs `python -m repomind sync` in the session's cwd when:
#   1. the env var HANGAR_REPOMIND_AUTOSYNC=true is set, AND
#   2. `.repomind.yml` exists in the session's cwd.
#
# Default off — users who want automatic vault sync at session end enable it
# explicitly in user-level settings.
#
# IMPORTANT: silent on the allow path — any stdout text on Windows Git Bash
# is interpreted as a hook error by Claude Code (Issue #20034).

# No set -euo pipefail — hooks must be resilient on Windows

# Hook profile gate
export HOOK_NAME="repomind-autosync"; export HOOK_MIN_PROFILE="strict"
source "${HOME}/.claude/lib/hook-gate.sh" 2>/dev/null || true

# Feature flag gate — stay silent if not enabled
if [ "${HANGAR_REPOMIND_AUTOSYNC:-}" != "true" ]; then
  exit 0
fi

INPUT=$(cat 2>/dev/null) || true
[ -z "$INPUT" ] && INPUT='{}'

CWD=$(echo "$INPUT" | node -e "
  try {
    const d = JSON.parse(require('fs').readFileSync(0,'utf8'));
    console.log(d.cwd || process.cwd());
  } catch (e) { console.log(process.cwd()); }
" 2>/dev/null || echo "$PWD")

# No config → nothing to sync, silent exit
if [ ! -f "$CWD/.repomind.yml" ]; then
  exit 0
fi

# Run detached — SessionEnd has a tight window and we do not want to block
# the session close on a slow sync. Any sync output goes to a per-session log.
SESSION_ID="${CLAUDE_SESSION_ID:-$$}"
LOG_DIR="${LOCALAPPDATA:-${TEMP:-/tmp}}/claude-statusline"
LOG_FILE="$LOG_DIR/repomind-autosync-${SESSION_ID}.log"
mkdir -p "$LOG_DIR" 2>/dev/null || true

(
  cd "$CWD" || exit 0
  if command -v repomind >/dev/null 2>&1; then
    repomind sync >"$LOG_FILE" 2>&1
  elif command -v python >/dev/null 2>&1; then
    python -m repomind sync >"$LOG_FILE" 2>&1
  fi
) </dev/null >/dev/null 2>&1 &
disown 2>/dev/null || true

exit 0

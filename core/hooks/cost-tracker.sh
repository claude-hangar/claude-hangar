#!/usr/bin/env bash
# Hook: Cost Tracker (Stop)
# Tracks session duration and tool usage for cost awareness.
# Trigger: Stop (session end, async)
#
# Logs session metrics to ~/.claude/.metrics/
# No blocking — runs async with 10s timeout

# No set -euo pipefail — hooks must be resilient on Windows

# Hook profile gate
export HOOK_NAME="cost-tracker"; export HOOK_MIN_PROFILE="strict"
source "${HOME}/.claude/lib/hook-gate.sh" 2>/dev/null || true

METRICS_DIR="$HOME/.claude/.metrics"
mkdir -p "$METRICS_DIR"

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
LOGFILE="$METRICS_DIR/sessions-$(date +%Y-%m).jsonl"

# Count tool calls from today's pattern log
SESSION_LOG="$HOME/.claude/.patterns/session-$(date +%Y-%m-%d).jsonl"
TOOL_COUNT=0
if [ -f "$SESSION_LOG" ]; then
  TOOL_COUNT=$(wc -l < "$SESSION_LOG" 2>/dev/null || echo "0")
fi

# Log session end
node -e "
  const entry = {
    timestamp: process.argv[1],
    tool_calls: parseInt(process.argv[2]) || 0,
    project: process.cwd(),
    type: 'session_end'
  };
  const fs = require('fs');
  fs.appendFileSync(process.argv[3], JSON.stringify(entry) + '\n');
" "$TIMESTAMP" "$TOOL_COUNT" "$LOGFILE" 2>/dev/null

exit 0

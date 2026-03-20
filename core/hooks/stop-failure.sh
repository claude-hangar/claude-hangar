#!/usr/bin/env bash
# Hook: Stop Failure Logger
# Trigger: StopFailure (on session error)
# Logs errors for tracking.
# No set -euo pipefail — hooks must be resilient on Windows

INPUT=$(cat 2>/dev/null) || true
[ -z "$INPUT" ] && exit 0

LOG_FILE="${TEMP:-/tmp}/claude-stop-failures.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
SESSION_ID="${CLAUDE_SESSION_ID:-unknown}"

# Extract error reason
REASON=$(echo "$INPUT" | node -e "
  const d = JSON.parse(require('fs').readFileSync(0,'utf8'));
  console.log(d.error || d.reason || d.message || 'Unknown error');
" 2>/dev/null || echo "Parse error")

# Log
echo "[$TIMESTAMP] ERROR: $REASON (Session: $SESSION_ID)" >> "$LOG_FILE"

# Limit log to 50 lines
if [ -f "$LOG_FILE" ]; then
  LINES=$(wc -l < "$LOG_FILE" 2>/dev/null || echo "0")
  if [ "$LINES" -gt 50 ] 2>/dev/null; then
    tail -50 "$LOG_FILE" > "${LOG_FILE}.tmp" && mv "${LOG_FILE}.tmp" "$LOG_FILE"
  fi
fi

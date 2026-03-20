#!/usr/bin/env bash
# Hook: Session Stop
# Trigger: Stop (when session ends)
# Warns about leftover temp files and logs session cost.
#
# IMPORTANT: Output only when there's something to report.
# Git Bash redirects stdout to stderr (Issue #20034) → "hook error" in TUI.

# No set -euo pipefail — hooks must be resilient on Windows

INPUT=$(cat 2>/dev/null) || true
CWD=$(echo "$INPUT" | node -e "
  const d = JSON.parse(require('fs').readFileSync(0,'utf8'));
  console.log(d.cwd || process.cwd());
" 2>/dev/null || echo "$PWD")

WARNINGS=""

# Check for temp files in project root
TEMP_FILES=$(find "$CWD" -maxdepth 1 \( \
  -name '*.tmp' -o \
  -name '*.bak' -o \
  -name '*.backup-*' -o \
  -name 'screenshot-*' -o \
  -name 'capture-*' -o \
  -name '*.debug.log' -o \
  -name '.audit-state.json.bak' \
\) 2>/dev/null | head -5) || true

if [ -n "$TEMP_FILES" ]; then
  COUNT=$(echo "$TEMP_FILES" | wc -l)
  WARNINGS+="CLEANUP: $COUNT temp file(s) found in project root:\n"
  while IFS= read -r f; do
    WARNINGS+="  - $(basename "$f")\n"
  done <<< "$TEMP_FILES"
fi

# Log session cost (cost tracking across sessions)
SESSION_ID="${CLAUDE_SESSION_ID:-$$}"
COST_LOG="${LOCALAPPDATA:-${TEMP:-/tmp}}/claude-statusline/cost-log.jsonl"
COST_DATA=$(echo "$INPUT" | node -e "
  const fs = require('fs');
  const d = JSON.parse(fs.readFileSync(0, 'utf8'));
  const cost = d.total_cost_usd || d.cost?.total_cost_usd || 0;
  const duration = d.total_duration_ms || d.cost?.total_duration_ms || 0;
  if (cost > 0) {
    const entry = {
      ts: new Date().toISOString(),
      session: process.env.CLAUDE_SESSION_ID || '',
      cost_usd: cost,
      duration_ms: duration,
      cwd: d.cwd || ''
    };
    console.log(JSON.stringify(entry));
  }
" 2>/dev/null) || true
if [ -n "$COST_DATA" ]; then
  mkdir -p "$(dirname "$COST_LOG")" 2>/dev/null
  echo "$COST_DATA" >> "$COST_LOG" 2>/dev/null || true
fi

# Token tracking cleanup
TRACK_FILE="${TEMP:-/tmp}/claude-token-track-${SESSION_ID}"
rm -f "$TRACK_FILE" 2>/dev/null || true

# Compact snapshot cleanup
SNAPSHOT_FILE="${TEMP:-/tmp}/claude-compact-snapshot-${SESSION_ID}.json"
rm -f "$SNAPSHOT_FILE" 2>/dev/null || true

# Only output warnings if temp files found
if [ -n "$WARNINGS" ]; then
  echo -e "$WARNINGS"
fi

exit 0

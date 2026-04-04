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

# Instinct capture — analyze session patterns
INSTINCT_LOG="${TEMP:-/tmp}/claude-instinct-log-${SESSION_ID}"
if [ -f "$INSTINCT_LOG" ]; then
  INSTINCT_SUMMARY=$(node -e "
    const fs = require('fs');
    const lines = fs.readFileSync(process.argv[1], 'utf8').trim().split('\n');
    const entries = lines.map(l => { try { return JSON.parse(l); } catch(e) { return null; } }).filter(Boolean);
    if (entries.length < 5) { process.exit(0); } // Too few actions to analyze

    // Count patterns
    const skills = {};
    const fileTypes = {};
    const commands = {};
    const agents = {};
    let fileEdits = 0;

    entries.forEach(e => {
      if (e.action === 'skill') skills[e.skill] = (skills[e.skill] || 0) + 1;
      if (e.action === 'file-modify') { fileTypes[e.ext] = (fileTypes[e.ext] || 0) + 1; fileEdits++; }
      if (e.action === 'command') commands[e.cmd] = (commands[e.cmd] || 0) + 1;
      if (e.action === 'agent') agents[e.type] = (agents[e.type] || 0) + 1;
    });

    const top = (obj, n=3) => Object.entries(obj).sort((a,b) => b[1]-a[1]).slice(0,n).map(([k,v]) => k+'('+v+')').join(', ');
    const parts = ['SESSION-INSTINCTS: ' + entries.length + ' tool calls tracked'];
    if (Object.keys(fileTypes).length > 0) parts.push('  Files: ' + top(fileTypes));
    if (Object.keys(skills).length > 0) parts.push('  Skills: ' + top(skills));
    if (Object.keys(commands).length > 0) parts.push('  Commands: ' + top(commands));
    if (Object.keys(agents).length > 0) parts.push('  Agents: ' + top(agents));
    console.log(parts.join('\\n'));
  " "$INSTINCT_LOG" 2>/dev/null) || true

  if [ -n "$INSTINCT_SUMMARY" ]; then
    WARNINGS+="$INSTINCT_SUMMARY\n"
  fi

  # Cleanup instinct log
  rm -f "$INSTINCT_LOG" 2>/dev/null || true
fi

# Only output warnings if temp files found
if [ -n "$WARNINGS" ]; then
  echo -e "$WARNINGS"
fi

exit 0

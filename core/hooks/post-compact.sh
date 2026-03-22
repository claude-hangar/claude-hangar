#!/usr/bin/env bash
# Hook: Post-Compact
# Trigger: PostCompact (after every context compaction, v2.1.76+)
# 1. Resets token tracking since compaction reduces context.
# 2. Saves a context snapshot for recovery after compaction.
# 3. Injects context reminder to re-read CLAUDE.md and STATUS.md.
# Source: Dicklesworthstone/post_compact_reminder community pattern

# No set -euo pipefail — hooks must be resilient on Windows

# Read input from stdin (PostCompact may deliver compact info)
INPUT=$(cat 2>/dev/null) || true
[ -z "$INPUT" ] && INPUT='{}'

# Session ID for tracking
SESSION_ID="${CLAUDE_SESSION_ID:-$$}"
TRACK_FILE="${TEMP:-/tmp}/claude-token-track-${SESSION_ID}"
SNAPSHOT_FILE="${TEMP:-/tmp}/claude-compact-snapshot-${SESSION_ID}.json"

# Read STATUS.md (if present) — first 200 chars
STATUS_SUMMARY=""
if [ -f "STATUS.md" ]; then
  STATUS_SUMMARY=$(head -c 200 STATUS.md 2>/dev/null || true)
fi

# Status summary as environment variable (safe for Node)
export HOOK_STATUS_SUMMARY="$STATUS_SUMMARY"
HOOK_CWD="$(pwd)"
export HOOK_CWD

# Reset tracking file after compaction + save snapshot
node -e "
const fs = require('fs');
const trackFile = process.argv[1];
const snapshotFile = process.argv[2];

// Load existing tracking data
let data = { calls: 0, bytes: 0, warned70: false, warned80: false };
try {
  data = JSON.parse(fs.readFileSync(trackFile, 'utf8'));
} catch {}

// Save context snapshot (before reset)
const snapshot = {
  timestamp: new Date().toISOString(),
  calls_before_compact: data.calls,
  bytes_before_compact: data.bytes,
  cwd: process.env.HOOK_CWD || ''
};

const statusSummary = process.env.HOOK_STATUS_SUMMARY || '';
if (statusSummary.length > 0) {
  snapshot.status_summary = statusSummary;
}

try {
  fs.writeFileSync(snapshotFile, JSON.stringify(snapshot, null, 2));
} catch {}

// After compaction: reset bytes (context was compressed)
// Keep calls for statistics, reset warnings
data.bytes = Math.round(data.bytes * 0.3);  // ~30% remain after compaction
data.warned70 = false;
data.warned80 = false;

fs.writeFileSync(trackFile, JSON.stringify(data));
" "$TRACK_FILE" "$SNAPSHOT_FILE" 2>/dev/null || true

# After compaction: remind Claude to re-read critical files
# This prevents context amnesia — a known anti-pattern where
# compaction loses awareness of project context and current work.
REMINDER_PARTS=""

if [ -f "CLAUDE.md" ]; then
  REMINDER_PARTS="Re-read CLAUDE.md for project instructions."
fi
if [ -f "STATUS.md" ]; then
  REMINDER_PARTS="$REMINDER_PARTS Re-read STATUS.md for current work state."
fi
if [ -f ".tasks.json" ]; then
  REMINDER_PARTS="$REMINDER_PARTS Check .tasks.json for pending tasks."
fi

if [ -n "$REMINDER_PARTS" ]; then
  node -e "console.log(JSON.stringify({
    result: 'message',
    message: 'Post-compact context reload: ' + process.argv[1]
  }))" "$REMINDER_PARTS"
else
  # Silent — no output on allow path (Git Bash Issue #20034)
  exit 0
fi

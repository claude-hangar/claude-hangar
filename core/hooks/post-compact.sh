#!/usr/bin/env bash
# Hook: Post-Compact — Smart Context Preservation
# Trigger: PostCompact (after every context compaction, v2.1.76+)
# Inspired by: GSD Managed RTK Compression + Superpowers context preservation
#
# Instead of a generic "re-read files" reminder, this hook:
# 1. Resets token tracking (30% post-compact estimate)
# 2. Saves a recovery snapshot with critical context
# 3. Builds a targeted context reload instruction based on actual project state
# 4. Detects active work items (tasks, plans, STATUS.md) and prioritizes them
#
# Source: Dicklesworthstone/post_compact_reminder + GSD managed-rtk pattern

# No set -euo pipefail — hooks must be resilient on Windows

# Read input from stdin (PostCompact may deliver compact info)
INPUT=$(cat 2>/dev/null) || true
[ -z "$INPUT" ] && INPUT='{}'

# Session ID for tracking
SESSION_ID="${CLAUDE_SESSION_ID:-$$}"
TRACK_FILE="${TEMP:-/tmp}/claude-token-track-${SESSION_ID}"
SNAPSHOT_FILE="${TEMP:-/tmp}/claude-compact-snapshot-${SESSION_ID}.json"

# Gather project context for smart reload instruction
STATUS_SUMMARY=""
TASKS_SUMMARY=""
PLAN_SUMMARY=""
HANDOFF_EXISTS="false"
ACTIVE_BRANCH=""

if [ -f "STATUS.md" ]; then
  STATUS_SUMMARY=$(head -c 300 STATUS.md 2>/dev/null || true)
fi

if [ -f ".tasks.json" ]; then
  TASKS_SUMMARY=$(node -e "
    const fs = require('fs');
    try {
      const tasks = JSON.parse(fs.readFileSync('.tasks.json', 'utf8'));
      const active = (tasks.tasks || []).filter(t => t.status === 'in_progress' || t.status === 'pending');
      const inProgress = active.filter(t => t.status === 'in_progress').map(t => t.subject || t.id);
      const pending = active.filter(t => t.status === 'pending').length;
      if (inProgress.length > 0 || pending > 0) {
        const parts = [];
        if (inProgress.length > 0) parts.push('Active: ' + inProgress.join(', '));
        if (pending > 0) parts.push(pending + ' pending');
        console.log(parts.join(' | '));
      }
    } catch {}
  " 2>/dev/null || true)
fi

# Check for active plan documents
PLAN_FILE=$(ls -t docs/superpowers/plans/*.md 2>/dev/null | head -1 || true)
if [ -n "$PLAN_FILE" ] && [ -f "$PLAN_FILE" ]; then
  PLAN_SUMMARY="Active plan: $(basename "$PLAN_FILE")"
fi

# Check for handoff document
if [ -f "HANDOFF.md" ]; then
  HANDOFF_EXISTS="true"
fi

# Get current branch
ACTIVE_BRANCH=$(git branch --show-current 2>/dev/null || true)

# Export for Node access
export HOOK_STATUS_SUMMARY="$STATUS_SUMMARY"
export HOOK_TASKS_SUMMARY="$TASKS_SUMMARY"
export HOOK_PLAN_SUMMARY="$PLAN_SUMMARY"
export HOOK_HANDOFF_EXISTS="$HANDOFF_EXISTS"
export HOOK_ACTIVE_BRANCH="$ACTIVE_BRANCH"
HOOK_CWD="$(pwd)"
export HOOK_CWD

# Reset tracking + build smart reload instruction
RELOAD_MSG=$(node -e "
const fs = require('fs');
const trackFile = process.argv[1];
const snapshotFile = process.argv[2];

// Load existing tracking data
let data = { calls: 0, bytes: 0, warned70: false, warned80: false };
try {
  data = JSON.parse(fs.readFileSync(trackFile, 'utf8'));
} catch {}

// Save recovery snapshot (before reset)
const snapshot = {
  timestamp: new Date().toISOString(),
  calls_before_compact: data.calls,
  bytes_before_compact: data.bytes,
  cwd: process.env.HOOK_CWD || '',
  branch: process.env.HOOK_ACTIVE_BRANCH || '',
  status_summary: process.env.HOOK_STATUS_SUMMARY || '',
  tasks_summary: process.env.HOOK_TASKS_SUMMARY || '',
  plan_summary: process.env.HOOK_PLAN_SUMMARY || '',
  has_handoff: process.env.HOOK_HANDOFF_EXISTS === 'true'
};

try {
  fs.writeFileSync(snapshotFile, JSON.stringify(snapshot, null, 2));
} catch {}

// After compaction: reset bytes (context was compressed)
data.bytes = Math.round(data.bytes * 0.3);
data.warned70 = false;
data.warned80 = false;
fs.writeFileSync(trackFile, JSON.stringify(data));

// ================================================================
// Build smart context reload instruction
// Priority: active tasks > plan > status > generic
// ================================================================

const parts = [];

// Critical files to re-read
const criticalFiles = [];
if (fs.existsSync('CLAUDE.md')) criticalFiles.push('CLAUDE.md');
if (fs.existsSync('STATUS.md')) criticalFiles.push('STATUS.md');

if (criticalFiles.length > 0) {
  parts.push('Re-read: ' + criticalFiles.join(', '));
}

// Active work context (highest priority)
const tasks = process.env.HOOK_TASKS_SUMMARY || '';
if (tasks) {
  parts.push('Tasks: ' + tasks);
}

const plan = process.env.HOOK_PLAN_SUMMARY || '';
if (plan) {
  parts.push(plan);
}

// Handoff document (session continuity)
if (process.env.HOOK_HANDOFF_EXISTS === 'true') {
  parts.push('HANDOFF.md exists — read it for session context');
}

// Branch context
const branch = process.env.HOOK_ACTIVE_BRANCH || '';
if (branch && branch !== 'main' && branch !== 'master') {
  parts.push('Branch: ' + branch);
}

// Verification reminder (from Superpowers iron law)
parts.push('Verify before claiming completion (IDENTIFY -> RUN -> READ -> VERIFY -> CLAIM)');

if (parts.length > 0) {
  console.log(parts.join(' | '));
}
" "$TRACK_FILE" "$SNAPSHOT_FILE" 2>/dev/null) || true

# Output smart reload message
if [ -n "$RELOAD_MSG" ]; then
  node -e "console.log(JSON.stringify({
    result: 'message',
    message: 'Context compacted. ' + process.argv[1]
  }))" "$RELOAD_MSG"
else
  # Silent — no output on allow path (Git Bash Issue #20034)
  exit 0
fi

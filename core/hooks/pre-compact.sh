#!/usr/bin/env bash
# Hook: Pre-Compact
# Trigger: PreCompact (fires before context compaction, v2.1.76+)
# Saves critical state that might be lost during compaction:
# - Active task list snapshot
# - Current working context (branch, files being edited)
# - Key decisions made in session
#
# The post-compact hook then uses this snapshot for recovery.
#
# IMPORTANT: No stdout output on the "allow" path!
# Git Bash redirects stdout to stderr (Issue #20034) → "hook error" in TUI.

# No set -euo pipefail — hooks must be resilient on Windows

# Hook profile gate
export HOOK_NAME="pre-compact"; export HOOK_MIN_PROFILE="standard"
source "${HOME}/.claude/lib/hook-gate.sh" 2>/dev/null || true

INPUT=$(cat 2>/dev/null) || true
[ -z "$INPUT" ] && INPUT='{}'

SESSION_ID="${CLAUDE_SESSION_ID:-$$}"
SNAPSHOT_FILE="${TEMP:-/tmp}/claude-pre-compact-snapshot-${SESSION_ID}.json"

# Gather state before compaction
ACTIVE_BRANCH=$(git branch --show-current 2>/dev/null || echo "")
UNCOMMITTED=$(git status --porcelain 2>/dev/null | head -10 || echo "")
TASKS_JSON=""
if [ -f ".tasks.json" ]; then
  TASKS_JSON=$(cat .tasks.json 2>/dev/null || echo "{}")
fi

export HOOK_INPUT="$INPUT"
export HOOK_BRANCH="$ACTIVE_BRANCH"
export HOOK_UNCOMMITTED="$UNCOMMITTED"
export HOOK_TASKS="$TASKS_JSON"

node -e "
const fs = require('fs');

let input = {};
try {
  input = JSON.parse(process.env.HOOK_INPUT || '{}');
} catch {}

// Build pre-compact snapshot
const snapshot = {
  timestamp: new Date().toISOString(),
  session: process.env.CLAUDE_SESSION_ID || '',
  branch: process.env.HOOK_BRANCH || '',
  uncommitted_files: (process.env.HOOK_UNCOMMITTED || '').split('\n').filter(Boolean).length,
  uncommitted_preview: (process.env.HOOK_UNCOMMITTED || '').slice(0, 500),
  cwd: input.cwd || process.cwd()
};

// Extract active tasks
try {
  const tasks = JSON.parse(process.env.HOOK_TASKS || '{}');
  const active = (tasks.tasks || []).filter(t =>
    t.status === 'in_progress' || t.status === 'pending'
  );
  snapshot.active_tasks = active.map(t => ({
    id: t.id,
    status: t.status,
    subject: t.subject
  }));
} catch {}

// Check for STATUS.md
try {
  if (fs.existsSync('STATUS.md')) {
    snapshot.status_preview = fs.readFileSync('STATUS.md', 'utf8').slice(0, 500);
  }
} catch {}

// Check for HANDOFF.md
snapshot.has_handoff = fs.existsSync('HANDOFF.md');

// Save snapshot for post-compact hook to use
try {
  fs.writeFileSync(process.argv[1], JSON.stringify(snapshot, null, 2));
} catch {}
" "$SNAPSHOT_FILE" 2>/dev/null

# Silent on allow path
exit 0

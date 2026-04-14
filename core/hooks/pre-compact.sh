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
# Blocking gate (v2.1.105+): When HANGAR_BLOCK_COMPACT=1, the hook blocks
# compaction if work-in-progress markers indicate the session is not in a
# safe point to compress. Criteria for blocking:
#   - At least one task in `in_progress` state in .tasks.json
#   - AND uncommitted git changes present
#   - AND no HANDOFF.md in cwd (user has not documented a handoff)
#
# The user can override by writing a HANDOFF.md, committing, or setting
# HANGAR_BLOCK_COMPACT=0 and retrying /compact.
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
export HOOK_BLOCK_COMPACT="${HANGAR_BLOCK_COMPACT:-0}"

DECISION=$(node -e "
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
let inProgressTasks = [];
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
  inProgressTasks = (tasks.tasks || []).filter(t => t.status === 'in_progress');
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

// Blocking gate: only when opt-in via HANGAR_BLOCK_COMPACT=1
const blockEnabled = process.env.HOOK_BLOCK_COMPACT === '1';
if (!blockEnabled) {
  console.log('ALLOW');
  process.exit(0);
}

const hasInProgress = inProgressTasks.length > 0;
const hasUncommitted = snapshot.uncommitted_files > 0;
const hasHandoff = snapshot.has_handoff;

if (hasInProgress && hasUncommitted && !hasHandoff) {
  const taskSubjects = inProgressTasks.slice(0, 3)
    .map(t => '  - ' + (t.subject || t.id)).join('\n');
  const reason = [
    'Compaction blocked: work-in-progress detected.',
    '',
    'Active in-progress tasks (' + inProgressTasks.length + '):',
    taskSubjects,
    '',
    'Uncommitted files: ' + snapshot.uncommitted_files,
    'HANDOFF.md: missing',
    '',
    'Resolve by one of:',
    '  1. Finish or pause tasks (mark completed / paused)',
    '  2. Commit pending changes (git commit / stash)',
    '  3. Write HANDOFF.md to document the pause point',
    '  4. Override once: HANGAR_BLOCK_COMPACT=0 then /compact'
  ].join('\n');
  console.log('BLOCK::' + reason);
  process.exit(0);
}
console.log('ALLOW');
" "$SNAPSHOT_FILE" 2>/dev/null)

# Parse decision and emit PreCompact hookSpecificOutput on block
case "$DECISION" in
  BLOCK::*)
    REASON="${DECISION#BLOCK::}"
    # PreCompact block format: exit 2 with stderr message (per Claude Code 2.1.105)
    printf '%s\n' "$REASON" >&2
    exit 2
    ;;
  *)
    exit 0
    ;;
esac

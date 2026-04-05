#!/usr/bin/env bash
# Hook: Task Created Init (TaskCreated event, Claude Code 2.1.89+)
# Trigger: TaskCreated
#
# When a task is created via TaskCreate:
# 1. Warns if more than 8 active tasks (scope explosion signal)
# 2. Logs task creation for session observability
#
# Inspired by: GSD v2 "doctor stale commit safety" pattern
#
# IMPORTANT: No stdout output on the "allow" path!
# Git Bash redirects stdout to stderr (Issue #20034).

# No set -euo pipefail — hooks must be resilient on Windows

# Hook profile gate
export HOOK_NAME="task-created-init"; export HOOK_MIN_PROFILE="standard"
source "${HOME}/.claude/lib/hook-gate.sh" 2>/dev/null || true

INPUT=$(cat 2>/dev/null) || true
[ -z "$INPUT" ] && INPUT='{}'

export HOOK_INPUT="$INPUT"

# Evaluate task creation
node -e "
const input = (() => {
  try { return JSON.parse(process.env.HOOK_INPUT || '{}'); }
  catch { return {}; }
})();

const subject = input.task_subject || '';
const taskId = input.task_id || '';

// Track task creation in session file
const fs = require('fs');
const trackFile = (process.env.TEMP || '/tmp') + '/claude-task-track-' + (process.env.CLAUDE_SESSION_ID || process.ppid);

let data = { tasks: [], createdCount: 0 };
try { data = JSON.parse(fs.readFileSync(trackFile, 'utf8')); } catch {}

data.createdCount++;
data.tasks.push({ id: taskId, subject: subject.slice(0, 80), created: Date.now() });

// Keep only last 20 tasks
if (data.tasks.length > 20) data.tasks = data.tasks.slice(-20);

fs.writeFileSync(trackFile, JSON.stringify(data));

// Warn if too many active tasks (scope explosion)
const activeTasks = data.tasks.filter(t => Date.now() - t.created < 3600000); // last hour
if (activeTasks.length > 8) {
  console.log(JSON.stringify({
    additionalContext: 'TASK WARNING: ' + activeTasks.length + ' tasks created in this session. Consider completing existing tasks before creating new ones. Scope explosion risk.'
  }));
}
" 2>/dev/null || true

exit 0

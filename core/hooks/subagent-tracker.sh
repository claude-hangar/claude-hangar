#!/usr/bin/env bash
# Hook: Subagent Tracker
# Trigger: SubagentStart, SubagentStop
# Tracks subagent activity for observability. Logs spawn/completion events
# and warns when many subagents run concurrently.
#
# Tracking file: ${TEMP:-/tmp}/claude-subagent-track-${SESSION_ID}
# Output: result 'message' only on notable events (first spawn, 3+ active, all done)
#
# IMPORTANT: No stdout output on non-notable events!
# Git Bash redirects stdout to stderr (Issue #20034) → "hook error" in TUI.

# No set -euo pipefail — hooks must be resilient on Windows

INPUT=$(cat 2>/dev/null) || true
[ -z "$INPUT" ] && INPUT='{}'

SESSION_ID="${CLAUDE_SESSION_ID:-$$}"
TRACK_FILE="${TEMP:-/tmp}/claude-subagent-track-${SESSION_ID}"

# Pass input as environment variable (not CLI arg due to 32k limit)
export HOOK_INPUT="$INPUT"

node -e "
const fs = require('fs');
const trackFile = process.argv[1];

let input = {};
try {
  input = JSON.parse(process.env.HOOK_INPUT || '{}');
} catch { process.exit(0); }

// Determine event type and agent identifier
const event = input.hook_event_name || input.event || '';
const agentName = input.agent_name || input.subagent_name || input.name || 'unnamed';
const agentId = input.agent_id || input.subagent_id || agentName + '-' + Date.now();

// Only handle subagent events
if (!event.toLowerCase().includes('subagent')) process.exit(0);
const isStart = event.toLowerCase().includes('start');
const isStop = event.toLowerCase().includes('stop');
if (!isStart && !isStop) process.exit(0);

// Load or initialize tracking state
let data = { active: [], total_started: 0, total_completed: 0 };
try {
  data = JSON.parse(fs.readFileSync(trackFile, 'utf8'));
  if (!Array.isArray(data.active)) data.active = [];
  if (typeof data.total_started !== 'number') data.total_started = 0;
  if (typeof data.total_completed !== 'number') data.total_completed = 0;
} catch {}

let message = '';

if (isStart) {
  data.active.push(agentId);
  data.total_started++;

  // First subagent of this session
  if (data.total_started === 1) {
    message = 'Subagent spawned: ' + agentName;
  }

  // 3+ concurrent subagents — resource warning
  if (data.active.length >= 3) {
    message = 'Active subagents: ' + data.active.length + ' — monitor resource usage';
  }
}

if (isStop) {
  // Remove agent from active list (first match only)
  const idx = data.active.indexOf(agentId);
  if (idx !== -1) {
    data.active.splice(idx, 1);
  } else if (data.active.length > 0) {
    // Fallback: remove by name prefix match (agent ID may differ)
    const namePrefix = agentName.split('-')[0];
    const fallbackIdx = data.active.findIndex(a => a.startsWith(namePrefix));
    if (fallbackIdx !== -1) {
      data.active.splice(fallbackIdx, 1);
    } else {
      // Last resort: pop the oldest entry
      data.active.shift();
    }
  }
  data.total_completed++;

  // All subagents completed
  if (data.active.length === 0 && data.total_completed > 0) {
    message = 'All subagents completed (' + data.total_completed + ' total)';
  }
}

// Persist tracking state
try {
  fs.writeFileSync(trackFile, JSON.stringify(data, null, 2));
} catch {}

// Output only on notable events
if (message) {
  console.log(JSON.stringify({ result: 'message', message: message }));
}
" "$TRACK_FILE" 2>/dev/null

exit 0

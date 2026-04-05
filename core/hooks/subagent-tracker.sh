#!/usr/bin/env bash
# Hook: Subagent Tracker — Observability + Forensics
# Trigger: SubagentStart, SubagentStop
# Inspired by: GSD forensics + Superpowers SDD two-stage review tracking
#
# Tracks subagent activity with forensics capabilities:
# - Lifecycle events (spawn, completion, failure)
# - Duration tracking (detects long-running agents)
# - Thrashing detection (same agent type restarting repeatedly)
# - Concurrent agent monitoring (resource warnings)
# - Session forensics log for post-mortem analysis
#
# Tracking file: ${TEMP:-/tmp}/claude-subagent-track-${SESSION_ID}
# Forensics log: ${TEMP:-/tmp}/claude-subagent-forensics-${SESSION_ID}.log
#
# IMPORTANT: No stdout output on non-notable events!
# Git Bash redirects stdout to stderr (Issue #20034) -> "hook error" in TUI.

# No set -euo pipefail — hooks must be resilient on Windows

# Hook profile gate
export HOOK_NAME="subagent-tracker"; export HOOK_MIN_PROFILE="strict"
source "${HOME}/.claude/lib/hook-gate.sh" 2>/dev/null || true

INPUT=$(cat 2>/dev/null) || true
[ -z "$INPUT" ] && INPUT='{}'

SESSION_ID="${CLAUDE_SESSION_ID:-$$}"
TRACK_FILE="${TEMP:-/tmp}/claude-subagent-track-${SESSION_ID}"
FORENSICS_LOG="${TEMP:-/tmp}/claude-subagent-forensics-${SESSION_ID}.log"

# Pass input as environment variable (not CLI arg due to 32k limit)
export HOOK_INPUT="$INPUT"

node -e "
const fs = require('fs');
const trackFile = process.argv[1];
const forensicsLog = process.argv[2];

let input = {};
try {
  input = JSON.parse(process.env.HOOK_INPUT || '{}');
} catch { process.exit(0); }

// Determine event type and agent identifier
const event = input.hook_event_name || input.event || '';
const agentName = input.agent_name || input.subagent_name || input.name || 'unnamed';
const agentId = input.agent_id || input.subagent_id || agentName + '-' + Date.now();
const agentType = input.agent_type || input.subagent_type || '';

// Only handle subagent events
if (!event.toLowerCase().includes('subagent')) process.exit(0);
const isStart = event.toLowerCase().includes('start');
const isStop = event.toLowerCase().includes('stop');
if (!isStart && !isStop) process.exit(0);

// Load or initialize tracking state
let data = {
  active: [],           // Currently running agents [{id, name, type, startTime}]
  total_started: 0,
  total_completed: 0,
  total_failed: 0,
  type_counts: {},      // How many times each type was spawned
  restart_tracker: {},  // Thrashing detection: {type: [timestamps]}
  peak_concurrent: 0,
  session_start: null
};

try {
  const raw = JSON.parse(fs.readFileSync(trackFile, 'utf8'));
  data = { ...data, ...raw };
  if (!Array.isArray(data.active)) data.active = [];
  if (!data.type_counts) data.type_counts = {};
  if (!data.restart_tracker) data.restart_tracker = {};
} catch {}

if (!data.session_start) data.session_start = new Date().toISOString();

const now = Date.now();
let message = '';

// ================================================================
// Forensics: append to session log
// ================================================================

function logForensics(entry) {
  const line = new Date().toISOString() + ' | ' + entry + '\\n';
  try { fs.appendFileSync(forensicsLog, line); } catch {}
}

if (isStart) {
  const agentEntry = {
    id: agentId,
    name: agentName,
    type: agentType || agentName,
    startTime: now
  };

  data.active.push(agentEntry);
  data.total_started++;

  // Track type frequency
  const typeKey = agentType || agentName;
  data.type_counts[typeKey] = (data.type_counts[typeKey] || 0) + 1;

  // Thrashing detection: same type spawned 3+ times in 2 minutes
  if (!data.restart_tracker[typeKey]) data.restart_tracker[typeKey] = [];
  data.restart_tracker[typeKey].push(now);
  // Keep only last 5 minutes of timestamps
  data.restart_tracker[typeKey] = data.restart_tracker[typeKey].filter(t => now - t < 300000);

  const recentSpawns = data.restart_tracker[typeKey].filter(t => now - t < 120000).length;
  if (recentSpawns >= 3) {
    message = 'Thrashing detected: ' + typeKey + ' spawned ' + recentSpawns + 'x in 2 minutes. Possible loop — investigate root cause.';
    logForensics('THRASH | ' + typeKey + ' | ' + recentSpawns + 'x in 2min');
  }

  // Peak concurrent tracking
  if (data.active.length > data.peak_concurrent) {
    data.peak_concurrent = data.active.length;
  }

  // First subagent of session
  if (data.total_started === 1) {
    message = message || ('Subagent spawned: ' + agentName + (agentType ? ' (' + agentType + ')' : ''));
  }

  // 3+ concurrent — resource warning
  if (data.active.length >= 3 && !message.includes('Thrashing')) {
    message = 'Active subagents: ' + data.active.length + ' (peak: ' + data.peak_concurrent + ') — monitor resource usage';
  }

  // 5+ concurrent — strong warning
  if (data.active.length >= 5) {
    message = 'High concurrency: ' + data.active.length + ' active subagents (peak: ' + data.peak_concurrent + '). Consider sequential execution.';
    logForensics('HIGH-CONCURRENCY | ' + data.active.length + ' active');
  }

  logForensics('START | ' + agentName + ' | id=' + agentId + ' | type=' + typeKey + ' | active=' + data.active.length);
}

if (isStop) {
  // Find and remove agent from active list
  let duration = 0;
  let removed = false;

  // Try exact ID match first
  const idx = data.active.findIndex(a => a.id === agentId);
  if (idx !== -1) {
    duration = now - (data.active[idx].startTime || now);
    data.active.splice(idx, 1);
    removed = true;
  } else if (data.active.length > 0) {
    // Fallback: match by name prefix
    const namePrefix = agentName.split('-')[0];
    const fallbackIdx = data.active.findIndex(a =>
      a.name === agentName || a.name.startsWith(namePrefix) || a.id.startsWith(namePrefix)
    );
    if (fallbackIdx !== -1) {
      duration = now - (data.active[fallbackIdx].startTime || now);
      data.active.splice(fallbackIdx, 1);
      removed = true;
    } else {
      // Last resort: pop oldest
      duration = now - (data.active[0].startTime || now);
      data.active.shift();
      removed = true;
    }
  }

  // Check for failure indicators in result
  const agentResult = input.result || input.output || '';
  const hasError = /\\b(error|failed|exception|timeout|killed)\\b/i.test(agentResult);
  if (hasError) {
    data.total_failed++;
    logForensics('FAIL | ' + agentName + ' | duration=' + Math.round(duration/1000) + 's | error detected in result');
  }

  data.total_completed++;

  // Duration analysis
  const durationSec = Math.round(duration / 1000);
  const durationMin = Math.round(duration / 60000);

  // Long-running agent warning (>5 minutes)
  if (duration > 300000) {
    message = 'Long-running agent completed: ' + agentName + ' took ' + durationMin + ' min';
    logForensics('SLOW | ' + agentName + ' | ' + durationMin + 'min');
  }

  // All subagents completed — session summary
  if (data.active.length === 0 && data.total_completed > 0) {
    const parts = ['All ' + data.total_completed + ' subagents completed'];
    if (data.total_failed > 0) parts.push(data.total_failed + ' had errors');
    if (data.peak_concurrent > 1) parts.push('peak concurrency: ' + data.peak_concurrent);
    message = message || parts.join(' | ');
  }

  logForensics('STOP | ' + agentName + ' | duration=' + durationSec + 's | active=' + data.active.length + (hasError ? ' | HAS_ERROR' : ''));
}

// Persist tracking state
try {
  fs.writeFileSync(trackFile, JSON.stringify(data, null, 2));
} catch {}

// Output only on notable events
if (message) {
  console.log(JSON.stringify({ result: 'message', message: message }));
}
" "$TRACK_FILE" "$FORENSICS_LOG" 2>/dev/null

exit 0

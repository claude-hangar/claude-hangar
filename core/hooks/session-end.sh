#!/usr/bin/env bash
# Hook: Session End
# Trigger: SessionEnd (when session terminates, newer than Stop)
# Provides richer data: end_reason, session_duration_seconds, stop_ts.
# Handles final cleanup and session summary logging.
#
# IMPORTANT: No stdout output on the "allow" path!
# Git Bash redirects stdout to stderr (Issue #20034) → "hook error" in TUI.

# No set -euo pipefail — hooks must be resilient on Windows

# Hook profile gate
export HOOK_NAME="session-end"; export HOOK_MIN_PROFILE="standard"
source "${HOME}/.claude/lib/hook-gate.sh" 2>/dev/null || true

INPUT=$(cat 2>/dev/null) || true
[ -z "$INPUT" ] && INPUT='{}'

export SESSION_ID="${CLAUDE_SESSION_ID:-$$}"

# Pass input as environment variable
export HOOK_INPUT="$INPUT"

# Log session summary and cleanup
node -e "
const fs = require('fs');
const path = require('path');

let input = {};
try {
  input = JSON.parse(process.env.HOOK_INPUT || '{}');
} catch { process.exit(0); }

const endReason = input.end_reason || input.reason || 'unknown';
const duration = input.session_duration_seconds || 0;
const sessionId = process.env.CLAUDE_SESSION_ID || '';

// Log session end to persistent log
const logDir = (process.env.LOCALAPPDATA || process.env.TEMP || '/tmp') + '/claude-statusline';
const logFile = path.join(logDir, 'session-log.jsonl');

const entry = {
  ts: new Date().toISOString(),
  session: sessionId,
  end_reason: endReason,
  duration_seconds: duration,
  cwd: input.cwd || process.cwd()
};

try {
  fs.mkdirSync(logDir, { recursive: true });
  fs.appendFileSync(logFile, JSON.stringify(entry) + '\n');
} catch {}

// Cleanup session-specific temp files
const tempDir = process.env.TEMP || '/tmp';
const patterns = [
  'claude-token-track-' + sessionId,
  'claude-compact-snapshot-' + sessionId + '.json',
  'claude-tool-failures-' + sessionId + '.jsonl',
  'claude-instinct-log-' + sessionId,
  'claude-config-changes-' + sessionId + '.log',
  'claude-subagent-log-' + sessionId + '.jsonl',
  'claude-batch-format-' + sessionId + '.jsonl'
];

for (const pattern of patterns) {
  try { fs.unlinkSync(path.join(tempDir, pattern)); } catch {}
}

// Detect abnormal endings
if (endReason === 'error' || endReason === 'crash') {
  console.error('SESSION-END: Abnormal termination (' + endReason + ') after ' + Math.round(duration/60) + 'min');
}
" 2>/dev/null

exit 0

#!/usr/bin/env bash
# Hook: Post Tool Failure
# Trigger: PostToolUseFailure (when a tool call fails, v2.1.76+)
# Captures tool failure patterns for learning and provides context
# to help the agent recover from errors.
#
# IMPORTANT: No stdout output on the "allow" path!
# Git Bash redirects stdout to stderr (Issue #20034) → "hook error" in TUI.

# No set -euo pipefail — hooks must be resilient on Windows

# Hook profile gate
export HOOK_NAME="post-tool-failure"; export HOOK_MIN_PROFILE="standard"
source "${HOME}/.claude/lib/hook-gate.sh" 2>/dev/null || true

INPUT=$(cat 2>/dev/null) || true
[ -z "$INPUT" ] && INPUT='{}'

SESSION_ID="${CLAUDE_SESSION_ID:-$$}"
FAILURE_LOG="${TEMP:-/tmp}/claude-tool-failures-${SESSION_ID}.jsonl"

# Pass input as environment variable
export HOOK_INPUT="$INPUT"

CONTEXT=$(node -e "
const fs = require('fs');

let input = {};
try {
  input = JSON.parse(process.env.HOOK_INPUT || '{}');
} catch { process.exit(0); }

const toolName = input.tool_name || 'unknown';
const errorType = input.error?.type || input.error_type || 'unknown';
const errorMsg = input.error?.message || input.error_message || '';
const toolInput = input.tool_input || {};

// Log failure for session analysis
const entry = {
  ts: new Date().toISOString(),
  tool: toolName,
  error_type: errorType,
  error_preview: (errorMsg || '').slice(0, 200),
  input_preview: JSON.stringify(toolInput).slice(0, 200)
};

const logFile = process.argv[1];
try {
  fs.appendFileSync(logFile, JSON.stringify(entry) + '\n');
} catch {}

// Count recent failures for this tool
let recentCount = 0;
try {
  const lines = fs.readFileSync(logFile, 'utf8').trim().split('\n');
  const twoMinAgo = Date.now() - 120000;
  recentCount = lines
    .map(l => { try { return JSON.parse(l); } catch { return null; } })
    .filter(Boolean)
    .filter(e => e.tool === toolName && new Date(e.ts).getTime() > twoMinAgo)
    .length;
} catch {}

// Build recovery context
const parts = [];

if (recentCount >= 3) {
  parts.push('TOOL-FAILURE: ' + toolName + ' failed ' + recentCount + 'x in 2min — consider alternative approach');
} else if (errorType === 'rate_limit') {
  parts.push('TOOL-FAILURE: Rate limited on ' + toolName + ' — wait before retrying');
} else if (errorType === 'timeout') {
  parts.push('TOOL-FAILURE: ' + toolName + ' timed out — reduce scope or increase timeout');
} else if (errorMsg) {
  parts.push('TOOL-FAILURE: ' + toolName + ' — ' + errorMsg.slice(0, 150));
}

if (parts.length > 0) {
  console.log(JSON.stringify({ additionalContext: parts.join('. ') }));
}
" "$FAILURE_LOG" 2>/dev/null) || true

if [ -n "$CONTEXT" ]; then
  echo "$CONTEXT"
fi

exit 0

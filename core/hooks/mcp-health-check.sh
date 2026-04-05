#!/usr/bin/env bash
# Hook: MCP Health Check
# Trigger: PreToolUse (mcp__* tools)
# Checks if an MCP server has had recent failures before allowing a tool call.
# If the server has failed 3+ times in the last 5 minutes, warns with additionalContext.
#
# Failure tracking:
#   Failures are recorded in ~/.claude/.mcp-health/failures.jsonl
#   Each line: {"server":"<name>","timestamp":<epoch_ms>,"error":"<msg>"}
#   A companion PostToolUse hook (configured in settings.json) writes to this file
#   when an MCP tool call returns an error. This hook only reads.
#
# IMPORTANT: No stdout output on the "allow" path!
# Git Bash redirects stdout to stderr (Issue #20034) → "hook error" in TUI.

# No set -euo pipefail — hooks must be resilient on Windows

# Hook profile gate
export HOOK_NAME="mcp-health-check"; export HOOK_MIN_PROFILE="standard"
source "${HOME}/.claude/lib/hook-gate.sh" 2>/dev/null || true

# Read stdin (JSON from Claude Code)
INPUT=$(cat 2>/dev/null) || true
[ -z "$INPUT" ] && INPUT='{}'
export HOOK_INPUT="$INPUT"

node -e "
const fs = require('fs');
const path = require('path');

let input = {};
try {
  input = JSON.parse(process.env.HOOK_INPUT || '{}');
} catch { process.exit(0); }

const tool = input.tool_name || '';

// Only check MCP tool calls (prefixed with mcp__)
if (!tool.startsWith('mcp__')) {
  process.exit(0);
}

// Extract MCP server name from tool name
// Format: mcp__<server>__<tool> or mcp__<scope>_<server>__<tool>
const parts = tool.split('__');
if (parts.length < 3) {
  process.exit(0);
}
// Server name is everything between first and last __ segment
const serverName = parts.slice(1, -1).join('__');

// Check failure log
const healthDir = path.join(process.env.HOME || process.env.USERPROFILE || '', '.claude', '.mcp-health');
const failuresFile = path.join(healthDir, 'failures.jsonl');

let failures = [];
try {
  const content = fs.readFileSync(failuresFile, 'utf8');
  const lines = content.trim().split('\n').filter(Boolean);
  failures = lines.map(line => {
    try { return JSON.parse(line); }
    catch { return null; }
  }).filter(Boolean);
} catch {
  // No failures file or unreadable — server is healthy
  process.exit(0);
}

// Filter failures for this server within the last 5 minutes
const fiveMinutesAgo = Date.now() - (5 * 60 * 1000);
const recentFailures = failures.filter(f =>
  f.server === serverName && f.timestamp > fiveMinutesAgo
);

// Threshold: 3+ failures → warn
if (recentFailures.length >= 3) {
  const warning = 'MCP server ' + serverName + ' has failed ' +
    recentFailures.length + ' times in the last 5 minutes. ' +
    'Consider checking server health before proceeding.';
  console.log(JSON.stringify({ additionalContext: warning }));
}

// Exit silently on allow path (no output)
" 2>/dev/null

# Advisory hook — never blocks
exit 0

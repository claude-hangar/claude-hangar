#!/usr/bin/env bash
# Hook: Permission Denied Retry (PermissionDenied event, Claude Code 2.1.89+)
# Trigger: PermissionDenied
#
# When auto mode classifier denies a tool call, this hook:
# 1. Logs the denial for observability
# 2. Returns {retry: true} for safe-to-retry tool calls
# 3. Does NOT retry destructive or sensitive operations
#
# This prevents the model from getting stuck on benign denials
# while still blocking genuinely dangerous operations.
#
# IMPORTANT: No stdout output on the "allow" path!
# Git Bash redirects stdout to stderr (Issue #20034).

# No set -euo pipefail — hooks must be resilient on Windows

INPUT=$(cat 2>/dev/null) || true
[ -z "$INPUT" ] && INPUT='{}'

export HOOK_INPUT="$INPUT"

# Evaluate denial and decide retry
node -e "
const input = (() => {
  try { return JSON.parse(process.env.HOOK_INPUT || '{}'); }
  catch { return {}; }
})();

const toolName = input.tool_name || '';
const command = input.tool_input?.command || '';
const filePath = input.tool_input?.file_path || '';

// === NEVER retry these (destructive / sensitive) ===
const neverRetryTools = ['Agent'];
const neverRetryCommands = [
  /git\s+push/,
  /git\s+reset/,
  /rm\s+-r/,
  /npm\s+publish/,
  /docker\s+(rm|rmi|system\s+prune)/,
  /DROP\s+(TABLE|DATABASE)/i
];

if (neverRetryTools.includes(toolName)) {
  // Don't retry — let auto mode handle it
  process.exit(0);
}

if (toolName === 'Bash' && command) {
  for (const pattern of neverRetryCommands) {
    if (pattern.test(command)) {
      process.exit(0);
    }
  }
}

// === Safe to retry: Read, Grep, Glob, Write, Edit, Bash (non-destructive) ===
const safeToRetry = ['Read', 'Grep', 'Glob', 'Write', 'Edit', 'Bash',
  'WebSearch', 'WebFetch', 'LSP', 'NotebookEdit'];

if (safeToRetry.includes(toolName)) {
  // Log denial for observability (stderr, not stdout)
  process.stderr.write('PermissionDenied: ' + toolName +
    (command ? ' (' + command.slice(0, 80) + ')' : '') +
    (filePath ? ' [' + filePath + ']' : '') +
    ' — retrying\\n');

  // Signal retry
  console.log(JSON.stringify({ retry: true }));
}
" 2>/dev/null || true

exit 0

#!/usr/bin/env bash
# Hook: Permission Request Inspect
# Trigger: PermissionRequest (Claude Code 2.1.110+)
#
# Fires when Claude requests permission for a tool call. Receives the original
# tool_input AND any updatedInput produced by upstream hooks. Re-checks the
# mutated input against extended deny patterns — closes the bypass lane where
# a hook could sanitize an input past the engine's deny rules.
#
# Behavior:
#   1. Logs the request to ~/.claude/.metrics/permission-requests.jsonl
#   2. Inspects BOTH tool_input and updatedInput against high-risk patterns
#   3. Exits 2 with stderr message when a pattern matches → blocks the request
#   4. Otherwise exits 0 silently (no stdout on allow path)
#
# Patterns checked (Bash tool):
#   - `curl ... | sh` / `wget ... | bash` pipe-to-shell
#   - `sudo rm -rf` (even when wrapped)
#   - Credential exfil patterns (env var dumps to external hosts)
#   - Reverse shell constructs (`bash -i >& /dev/tcp/...`)
#
# IMPORTANT: No stdout on allow path. Git Bash redirects stdout to stderr
# (Issue #20034) causing spurious "hook error" in TUI.

# No set -euo pipefail — hooks must be resilient on Windows

# Hook profile gate
export HOOK_NAME="permission-request-inspect"; export HOOK_MIN_PROFILE="standard"
source "${HOME}/.claude/lib/hook-gate.sh" 2>/dev/null || true

INPUT=$(cat 2>/dev/null) || true
[ -z "$INPUT" ] && INPUT='{}'

METRICS_DIR="$HOME/.claude/.metrics"
mkdir -p "$METRICS_DIR" 2>/dev/null
LOGFILE="$METRICS_DIR/permission-requests.jsonl"

export HOOK_INPUT="$INPUT"
export HOOK_LOGFILE="$LOGFILE"

DECISION=$(node -e "
const fs = require('fs');

const input = (() => {
  try { return JSON.parse(process.env.HOOK_INPUT || '{}'); }
  catch { return {}; }
})();

const toolName = input.tool_name || '';
const original = input.tool_input || {};
const updated = input.updatedInput || input.tool_input || {};

// Log every request for observability
try {
  const entry = {
    timestamp: new Date().toISOString(),
    session: input.session_id || '',
    tool: toolName,
    mutated: JSON.stringify(original) !== JSON.stringify(updated),
    cwd: input.cwd || ''
  };
  fs.appendFileSync(process.env.HOOK_LOGFILE, JSON.stringify(entry) + '\n');
} catch {}

// Check both original and updated input (defense-in-depth)
function getCommand(inp) {
  return (inp && (inp.command || inp.cmd)) || '';
}

const cmdOriginal = getCommand(original);
const cmdUpdated = getCommand(updated);
const cmds = [cmdOriginal, cmdUpdated].filter(Boolean);

// High-risk patterns that MUST be blocked even if upstream allowed them
const dangerPatterns = [
  { re: /curl[^|&;]+\|\s*(ba)?sh/i,         label: 'curl pipe-to-shell' },
  { re: /wget[^|&;]+\|\s*(ba)?sh/i,          label: 'wget pipe-to-shell' },
  { re: /sudo\s+rm\s+-[a-z]*r[a-z]*f/i,      label: 'sudo rm -rf' },
  { re: /bash\s+-i\s*>&?\s*\/dev\/tcp/i,     label: 'reverse shell' },
  { re: /\/dev\/tcp\/[^\/]+\/\d+/,           label: '/dev/tcp network socket' },
  { re: /nc\s+-[a-z]*e/i,                    label: 'netcat -e exec' },
  { re: /(env|printenv)[^|&;]*\|\s*curl/i,   label: 'env dump to curl' }
];

for (const cmd of cmds) {
  for (const { re, label } of dangerPatterns) {
    if (re.test(cmd)) {
      console.log('BLOCK::' + label + '::' + cmd.slice(0, 200));
      process.exit(0);
    }
  }
}

console.log('ALLOW');
" 2>/dev/null)

case "$DECISION" in
  BLOCK::*)
    DETAIL="${DECISION#BLOCK::}"
    LABEL="${DETAIL%%::*}"
    CMD="${DETAIL#*::}"
    {
      printf 'Permission denied by hangar permission-request-inspect:\n'
      printf '  pattern: %s\n' "$LABEL"
      printf '  command: %s\n' "$CMD"
      printf '\n'
      printf 'This pattern is high-risk. Review the command or override with\n'
      printf 'an explicit user-confirmed action outside the tool-call path.\n'
    } >&2
    exit 2
    ;;
  *)
    exit 0
    ;;
esac

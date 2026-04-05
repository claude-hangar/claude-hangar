#!/usr/bin/env bash
# Hook: Token Warning
# Trigger: PostToolUse (context-heavy tools only)
# Matcher: Bash|Read|Write|Edit|Grep|Glob|Agent|WebFetch|WebSearch|NotebookEdit
# Skips: Task*, ToolSearch, SendMessage, Cron*, Plan*, Worktree* (minimal context)
# Warns on high context utilization.
#
# Primary: used_percentage from hook input (if provided by Claude Code)
# Fallback: Own heuristic based on byte counting and tool calls
#
# Sources: CAT + GSD + oh-my-opencode community patterns

# No set -euo pipefail — hooks must be resilient on Windows

# Hook profile gate
export HOOK_NAME="token-warning"; export HOOK_MIN_PROFILE="standard"
source "${HOME}/.claude/lib/hook-gate.sh" 2>/dev/null || true

# Session ID for tracking (if not set: PID of parent shell)
SESSION_ID="${CLAUDE_SESSION_ID:-$$}"
TRACK_FILE="${TEMP:-/tmp}/claude-token-track-${SESSION_ID}"

# Cooldown: Evaluate at most every 30 seconds (saves ~400 process starts per session)
COOLDOWN_FILE="${TEMP:-/tmp}/claude-token-cooldown-${SESSION_ID}"
if [ -f "$COOLDOWN_FILE" ]; then
  LAST_CHECK=$(cat "$COOLDOWN_FILE" 2>/dev/null || echo "0")
  NOW=$(date +%s)
  DIFF=$((NOW - LAST_CHECK))
  if [ "$DIFF" -lt 30 ] 2>/dev/null; then
    exit 0
  fi
fi

# Read input from stdin (JSON with tool_name, tool_input, tool_result)
INPUT=$(cat 2>/dev/null) || true
[ -z "$INPUT" ] && INPUT='{}'

# Pass input as environment variable (not CLI arg due to 32k limit)
export HOOK_INPUT="$INPUT"
export HOOK_INPUT_BYTES="${#INPUT}"

# Count tool calls + check context utilization
node -e "
const fs = require('fs');
const trackFile = process.argv[1];

// Load existing data or initialize
let data = { calls: 0, bytes: 0, warned70: false, warned80: false };
try {
  data = JSON.parse(fs.readFileSync(trackFile, 'utf8'));
} catch {}

// Parse input
let input = {};
try {
  input = JSON.parse(process.env.HOOK_INPUT || '{}');
} catch {}

// Track input size
const inputBytes = parseInt(process.env.HOOK_INPUT_BYTES || '0', 10) || 0;
data.calls++;
data.bytes += inputBytes;

let warning = '';

// Primary: use used_percentage from hook input (if available)
const usedPct = input.used_percentage
  || (input.tool_input && input.tool_input.used_percentage)
  || null;

if (usedPct !== null && typeof usedPct === 'number') {
  const pct = Math.round(usedPct);

  if (pct >= 80 && !data.warned80) {
    warning = 'CONTEXT WARNING: ' + pct + '% context utilization (' + data.calls + ' calls). Running /compact now is recommended.';
    data.warned80 = true;
    data.warned70 = true;
  } else if (pct >= 70 && !data.warned70) {
    warning = 'CONTEXT NOTICE: ' + pct + '% context utilization (' + data.calls + ' calls). Will need /compact soon.';
    data.warned70 = true;
  }
} else {
  // No used_percentage available — use conservative call-count-only heuristic
  // Byte-based estimation removed (too fragile with 1M context windows)
  // Tool call count is a weak signal but better than false precision
  if (data.calls >= 400 && !data.warned80) {
    warning = 'CONTEXT NOTICE: ' + data.calls + ' tool calls in this session. Consider running /compact if context feels slow.';
    data.warned80 = true;
    data.warned70 = true;
  } else if (data.calls >= 300 && !data.warned70) {
    warning = 'CONTEXT NOTICE: ' + data.calls + ' tool calls in this session. Monitor context utilization.';
    data.warned70 = true;
  }
}

// Save state
fs.writeFileSync(trackFile, JSON.stringify(data));

// Output warning (stdout, non-blocking)
if (warning) {
  console.log(warning);
}
" "$TRACK_FILE"

# Update cooldown timestamp
date +%s > "$COOLDOWN_FILE"

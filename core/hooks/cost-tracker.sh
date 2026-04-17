#!/usr/bin/env bash
# Hook: Cost Tracker (Stop)
# Tracks session duration and tool usage for cost awareness.
# Trigger: Stop (session end, async)
#
# Logs session metrics to ~/.claude/.metrics/
# No blocking — runs async with 10s timeout

# No set -euo pipefail — hooks must be resilient on Windows

# Hook profile gate
export HOOK_NAME="cost-tracker"; export HOOK_MIN_PROFILE="strict"
source "${HOME}/.claude/lib/hook-gate.sh" 2>/dev/null || true

METRICS_DIR="$HOME/.claude/.metrics"
mkdir -p "$METRICS_DIR"

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
LOGFILE="$METRICS_DIR/sessions-$(date +%Y-%m).jsonl"

# Count tool calls from today's pattern log
SESSION_LOG="$HOME/.claude/.patterns/session-$(date +%Y-%m-%d).jsonl"
TOOL_COUNT=0
if [ -f "$SESSION_LOG" ]; then
  TOOL_COUNT=$(wc -l < "$SESSION_LOG" 2>/dev/null || echo "0")
fi

# Calculate session duration from session-start marker
START_MARKER="$HOME/.claude/.session-start"
DURATION_S=0
if [ -f "$START_MARKER" ]; then
  START_EPOCH=$(cat "$START_MARKER" 2>/dev/null || echo "0")
  NOW_EPOCH=$(date +%s 2>/dev/null || echo "0")
  DURATION_S=$(( NOW_EPOCH - START_EPOCH ))
  [ "$DURATION_S" -lt 0 ] && DURATION_S=0
  rm -f "$START_MARKER" 2>/dev/null
fi

# Count edited files (batch-format collector list)
EDITED_FILES=0
EDITED_LIST="$HOME/.claude/.batch-format/edited-files.txt"
if [ -f "$EDITED_LIST" ]; then
  EDITED_FILES=$(sort -u "$EDITED_LIST" 2>/dev/null | wc -l || echo "0")
fi

# Budget cap (RepoLens-inspired). Estimated session cost is a rough heuristic
# based on tool call count. Real cost tracking requires API billing data which
# isn't available to hooks. This gives a ballpark for runaway-loop detection.
# Override cost/call via HANGAR_COST_PER_CALL_USD (default 0.02).
BUDGET_USD="${HANGAR_BUDGET_USD:-}"
COST_PER_CALL="${HANGAR_COST_PER_CALL_USD:-0.02}"
BUDGET_ALERT_LOG="$METRICS_DIR/budget-alerts.jsonl"

# Log session end with enriched metrics + budget estimate
node -e "
  const fs = require('fs');
  const toolCalls = parseInt(process.argv[2]) || 0;
  const costPerCall = parseFloat(process.env.COST_PER_CALL || '0.02');
  const estCost = +(toolCalls * costPerCall).toFixed(4);
  const budget = parseFloat(process.env.BUDGET_USD || '');
  const budgetPct = budget > 0 ? Math.round((estCost / budget) * 100) : null;

  const entry = {
    timestamp: process.argv[1],
    tool_calls: toolCalls,
    duration_s: parseInt(process.argv[4]) || 0,
    files_edited: parseInt(process.argv[5]) || 0,
    est_cost_usd: estCost,
    budget_usd: isFinite(budget) ? budget : null,
    budget_pct: budgetPct,
    project: process.cwd(),
    type: 'session_end'
  };
  fs.appendFileSync(process.argv[3], JSON.stringify(entry) + '\n');

  // Budget alert: append to separate log if threshold crossed
  if (budgetPct !== null && budgetPct >= 80) {
    const alert = {
      timestamp: entry.timestamp,
      level: budgetPct >= 100 ? 'exceeded' : 'warning',
      est_cost_usd: estCost,
      budget_usd: budget,
      budget_pct: budgetPct,
      project: entry.project
    };
    fs.appendFileSync(process.env.ALERT_LOG, JSON.stringify(alert) + '\n');
    const label = budgetPct >= 100 ? 'BUDGET EXCEEDED' : 'budget warning';
    process.stderr.write('[cost-tracker] ' + label + ': ~\$' + estCost + ' of \$' + budget + ' (' + budgetPct + '%)\n');
  }
" "$TIMESTAMP" "$TOOL_COUNT" "$LOGFILE" "$DURATION_S" "$EDITED_FILES" 2>/dev/null
export BUDGET_USD COST_PER_CALL ALERT_LOG="$BUDGET_ALERT_LOG"

exit 0

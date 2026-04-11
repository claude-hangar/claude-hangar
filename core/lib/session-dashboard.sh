#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────
# session-dashboard.sh — Session Metrics Summary
# ─────────────────────────────────────────────────────────────────────────
# Parses cost-tracker and subagent-tracker logs to produce a session report.
#
# Usage:
#   bash ~/.claude/lib/session-dashboard.sh              # Latest session
#   bash ~/.claude/lib/session-dashboard.sh --all        # All sessions today
#   bash ~/.claude/lib/session-dashboard.sh --date 2026-04-11  # Specific date
# ─────────────────────────────────────────────────────────────────────────

METRICS_DIR="$HOME/.claude/.metrics"
PATTERNS_DIR="$HOME/.claude/.patterns"
INSTINCTS_DIR="$HOME/.claude/.instincts"

DATE="${2:-$(date +%Y-%m-%d)}"
# shellcheck disable=SC2034  # MODE reserved for future filtering
MODE="${1:---latest}"

echo "============================================================"
echo "Claude Hangar — Session Dashboard"
echo "Date: $DATE"
echo "============================================================"
echo ""

# ─── Cost Tracking ────────────────────────────────────────────────────

COST_LOG="$METRICS_DIR/costs-$DATE.jsonl"
if [ -f "$COST_LOG" ]; then
  echo "--- Cost Summary ---"
  node -e "
    const fs = require('fs');
    const lines = fs.readFileSync(process.argv[1], 'utf8').trim().split('\n');
    const entries = lines.map(l => { try { return JSON.parse(l); } catch { return null; } }).filter(Boolean);

    if (entries.length === 0) { console.log('  No cost data recorded'); process.exit(0); }

    let totalInput = 0, totalOutput = 0, sessions = new Set();
    for (const e of entries) {
      totalInput += (e.input_tokens || 0);
      totalOutput += (e.output_tokens || 0);
      if (e.session_id) sessions.add(e.session_id);
    }

    console.log('  Sessions:      ' + sessions.size);
    console.log('  Input tokens:  ' + totalInput.toLocaleString());
    console.log('  Output tokens: ' + totalOutput.toLocaleString());
    console.log('  Total tokens:  ' + (totalInput + totalOutput).toLocaleString());
    console.log('  Tool calls:    ' + entries.length);
  " "$COST_LOG" 2>/dev/null || echo "  (parse error)"
  echo ""
else
  echo "--- Cost Summary ---"
  echo "  No cost data for $DATE"
  echo ""
fi

# ─── Subagent Tracking ───────────────────────────────────────────────

AGENT_LOG="$METRICS_DIR/subagents-$DATE.jsonl"
if [ -f "$AGENT_LOG" ]; then
  echo "--- Subagent Summary ---"
  node -e "
    const fs = require('fs');
    const lines = fs.readFileSync(process.argv[1], 'utf8').trim().split('\n');
    const entries = lines.map(l => { try { return JSON.parse(l); } catch { return null; } }).filter(Boolean);

    if (entries.length === 0) { console.log('  No subagent data'); process.exit(0); }

    const types = {};
    let starts = 0, stops = 0, errors = 0;

    for (const e of entries) {
      if (e.event === 'start') {
        starts++;
        const t = e.type || 'unknown';
        types[t] = (types[t] || 0) + 1;
      } else if (e.event === 'stop') {
        stops++;
        if (e.error) errors++;
      }
    }

    console.log('  Agents spawned: ' + starts);
    console.log('  Agents completed: ' + stops);
    if (errors > 0) console.log('  Errors: ' + errors);
    console.log('  By type:');
    for (const [type, count] of Object.entries(types).sort((a,b) => b[1] - a[1])) {
      console.log('    ' + type + ': ' + count);
    }
  " "$AGENT_LOG" 2>/dev/null || echo "  (parse error)"
  echo ""
else
  echo "--- Subagent Summary ---"
  echo "  No subagent data for $DATE"
  echo ""
fi

# ─── Pattern Learning ────────────────────────────────────────────────

PATTERN_LOG="$PATTERNS_DIR/session-$DATE.jsonl"
if [ -f "$PATTERN_LOG" ]; then
  echo "--- Learning Patterns ---"
  node -e "
    const fs = require('fs');
    const lines = fs.readFileSync(process.argv[1], 'utf8').trim().split('\n');
    const entries = lines.map(l => { try { return JSON.parse(l); } catch { return null; } }).filter(Boolean);
    console.log('  Patterns captured: ' + entries.length);

    const successes = entries.filter(e => e.exit_code === 0).length;
    const failures = entries.filter(e => e.exit_code !== 0).length;
    if (entries.length > 0) {
      console.log('  Success rate: ' + Math.round(successes / entries.length * 100) + '%');
    }
  " "$PATTERN_LOG" 2>/dev/null || echo "  (parse error)"
  echo ""
fi

# ─── Instinct Health ─────────────────────────────────────────────────

INSTINCTS_FILE="$INSTINCTS_DIR/instincts.jsonl"
if [ -f "$INSTINCTS_FILE" ]; then
  echo "--- Instinct Health ---"
  node -e "
    const fs = require('fs');
    const lines = fs.readFileSync(process.argv[1], 'utf8').trim().split('\n');
    const entries = lines.map(l => { try { return JSON.parse(l); } catch { return null; } }).filter(Boolean);

    console.log('  Total instincts: ' + entries.length);

    const byConfidence = { low: 0, medium: 0, high: 0 };
    for (const e of entries) {
      const c = e.confidence || 0;
      if (c >= 8) byConfidence.high++;
      else if (c >= 4) byConfidence.medium++;
      else byConfidence.low++;
    }
    console.log('  High confidence (>=8): ' + byConfidence.high);
    console.log('  Medium (4-7): ' + byConfidence.medium);
    console.log('  Low (1-3): ' + byConfidence.low);
  " "$INSTINCTS_FILE" 2>/dev/null || echo "  (parse error)"

  # Check for promotion candidates
  CANDIDATES_DIR="$INSTINCTS_DIR/candidates"
  if [ -d "$CANDIDATES_DIR" ]; then
    CANDIDATE_COUNT=$(find "$CANDIDATES_DIR" -name '*.json' 2>/dev/null | wc -l | tr -d ' ')
    if [ "$CANDIDATE_COUNT" -gt 0 ]; then
      echo "  Rule candidates: $CANDIDATE_COUNT (ready for promotion)"
    fi
  fi
  echo ""
fi

# ─── Hook Profile ────────────────────────────────────────────────────

echo "--- Active Configuration ---"
echo "  Hook profile: ${HANGAR_HOOK_PROFILE:-standard}"
echo "  Terse mode: ${HANGAR_TERSE:-0}"
if [ -n "${HANGAR_DISABLED_HOOKS:-}" ]; then
  echo "  Disabled hooks: $HANGAR_DISABLED_HOOKS"
fi

# Count installed components
HOOKS_COUNT=$(find "$HOME/.claude/hooks" -name '*.sh' 2>/dev/null | wc -l | tr -d ' ')
AGENTS_COUNT=$(find "$HOME/.claude/agents" -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
SKILLS_COUNT=$(find "$HOME/.claude/skills" -maxdepth 2 -name 'SKILL.md' 2>/dev/null | wc -l | tr -d ' ')
echo "  Installed: ${HOOKS_COUNT} hooks, ${AGENTS_COUNT} agents, ${SKILLS_COUNT} skills"

echo ""
echo "============================================================"

#!/usr/bin/env bash
# Hook: Instinct Evolve (Stop)
# Extracts session learnings and stores them as instincts with confidence scores.
# Trigger: Stop (session end)
#
# An "instinct" is a learned behavior with a confidence score:
# - Low confidence (1-3): Observed once, needs validation
# - Medium confidence (4-7): Observed multiple times, likely useful
# - High confidence (8-10): Repeatedly validated, should be a rule
#
# Storage: ~/.claude/.instincts/
#
# NOTE: This is separate from instinct-capture.sh (PostToolUse) which feeds
# session-stop.sh. This hook runs at Stop to persist cross-session learnings.

# No set -euo pipefail — hooks must be resilient on Windows

# Hook profile gate
export HOOK_NAME="instinct-evolve"; export HOOK_MIN_PROFILE="strict"
source "${HOME}/.claude/lib/hook-gate.sh" 2>/dev/null || true

INSTINCTS_DIR="$HOME/.claude/.instincts"
mkdir -p "$INSTINCTS_DIR"

INSTINCTS_FILE="$INSTINCTS_DIR/instincts.jsonl"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Check if we have pattern data from this session
SESSION_LOG="$HOME/.claude/.patterns/session-$(date +%Y-%m-%d).jsonl"
[ ! -f "$SESSION_LOG" ] && exit 0

# Count unique recovery patterns (failed then succeeded)
RECOVERY_COUNT=$(node -e "
  const fs = require('fs');
  try {
    const lines = fs.readFileSync(process.argv[1], 'utf8').trim().split('\n');
    const entries = lines.map(l => { try { return JSON.parse(l); } catch { return null; } }).filter(Boolean);
    let recoveries = 0;
    for (let i = 1; i < entries.length; i++) {
      if (entries[i].exit_code === 0 && entries[i-1].exit_code !== 0) {
        recoveries++;
      }
    }
    console.log(recoveries);
  } catch { console.log(0); }
" "$SESSION_LOG" 2>/dev/null || echo "0")

# Only capture if there were interesting patterns
[ "$RECOVERY_COUNT" -lt 1 ] && exit 0

# Create instinct entry
node -e "
  const fs = require('fs');
  const path = require('path');
  const instinctsFile = process.argv[4];
  const newCount = parseInt(process.argv[2]);
  const newConfidence = Math.min(10, newCount + 2);

  // Check for existing instinct of same type to accumulate confidence
  let existingConfidence = 0;
  let existingOccurrences = 0;
  try {
    const lines = fs.readFileSync(instinctsFile, 'utf8').trim().split('\n');
    for (const line of lines) {
      try {
        const e = JSON.parse(line);
        if (e.type === 'recovery') {
          existingConfidence = Math.max(existingConfidence, e.confidence || 0);
          existingOccurrences += (e.count || 1);
        }
      } catch {}
    }
  } catch {}

  const totalOccurrences = existingOccurrences + newCount;
  // Confidence grows with repeated observation: base + log2(occurrences)
  const confidence = Math.min(10, Math.round(newConfidence + Math.log2(Math.max(1, totalOccurrences))));

  const entry = {
    timestamp: process.argv[1],
    type: 'recovery',
    count: newCount,
    total_occurrences: totalOccurrences,
    confidence: confidence,
    session_date: process.argv[3],
    project: process.cwd()
  };
  fs.appendFileSync(instinctsFile, JSON.stringify(entry) + '\n');

  // Auto-promote to rule candidate when confidence >= 8
  if (confidence >= 8 && existingConfidence < 8) {
    const candidatesDir = path.join(process.env.HOME || '', '.claude', '.instincts', 'candidates');
    try { fs.mkdirSync(candidatesDir, { recursive: true }); } catch {}
    const candidate = {
      promoted_at: process.argv[1],
      type: entry.type,
      total_occurrences: totalOccurrences,
      confidence: confidence,
      suggestion: 'Recovery patterns detected ' + totalOccurrences + ' times — consider adding error handling rules.'
    };
    fs.writeFileSync(
      path.join(candidatesDir, entry.type + '.json'),
      JSON.stringify(candidate, null, 2) + '\n'
    );
  }
" "$TIMESTAMP" "$RECOVERY_COUNT" "$(date +%Y-%m-%d)" "$INSTINCTS_FILE" 2>/dev/null

exit 0

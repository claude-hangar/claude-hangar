#!/usr/bin/env bash
# Hook: Model Router — UserPromptSubmit
# Analyzes user prompt and suggests the optimal model tier based on task complexity.
# Tiers: haiku (simple/fast), sonnet (default — no suggestion), opus (complex/deep).
#
# IMPORTANT: No stdout output when no suggestion is needed!
# Git Bash redirects stdout to stderr (Issue #20034) → "hook error" in TUI.
# Output ONLY when a model suggestion is made.

# No set -euo pipefail — hooks must be resilient on Windows

# ============================================================
# Cooldown: max one suggestion per tier every 5 minutes
# Prevents nagging on repeated similar prompts.
# ============================================================

SESSION_ID="${CLAUDE_SESSION_ID:-$$}"
COOLDOWN_DIR="${TEMP:-/tmp}"

# Input from Claude Code (JSON via stdin)
INPUT=$(cat 2>/dev/null) || true
[ -z "$INPUT" ] && INPUT='{}'

USER_PROMPT=$(echo "$INPUT" | node -e "
  const fs = require('fs');
  const input = JSON.parse(fs.readFileSync(0, 'utf8'));
  console.log((input.user_prompt || '').toLowerCase());
" 2>/dev/null || echo "")

# Empty prompt → skip
[ -z "$USER_PROMPT" ] && exit 0

# ============================================================
# Tier detection via Node (keyword matching with word boundaries)
# ============================================================

TIER=$(node -e "
  const prompt = process.argv[1];

  // Keyword lists per tier
  const haiku = [
    'rename', 'typo', 'format', 'lint', 'simple', 'quick',
    'trivial', 'one-liner', 'delete this', 'remove this'
  ];

  const opus = [
    'architect', 'design', 'refactor', 'security audit', 'migrate',
    'rewrite', 'complex', 'analyze the', 'deep dive',
    'review the entire', 'plan the', 'system design'
  ];

  /**
   * Match keywords against the prompt.
   * Multi-word keywords use includes (phrase match).
   * Single-word keywords use word-boundary regex to avoid
   * false positives (e.g. 'format' inside 'information').
   */
  function matchesTier(keywords) {
    return keywords.some(kw => {
      if (kw.includes(' ')) return prompt.includes(kw);
      const re = new RegExp('(^|\\\\s)' + kw.replace(/[.*+?^\${}()|[\\]\\\\]/g, '\\\\$&') + '(\\\\s|\$)', 'i');
      return re.test(prompt);
    });
  }

  // Opus checked first — complex tasks take priority over simple keyword overlap
  if (matchesTier(opus)) {
    console.log('opus');
  } else if (matchesTier(haiku)) {
    console.log('haiku');
  } else {
    console.log('');
  }
" "$USER_PROMPT" 2>/dev/null || echo "")

# No tier matched (sonnet-level / default) → exit silently
[ -z "$TIER" ] && exit 0

# ============================================================
# Cooldown check: one suggestion per tier per 5 minutes
# ============================================================

COOLDOWN_FILE="${COOLDOWN_DIR}/claude-model-router-${TIER}-${SESSION_ID}"
COOLDOWN_SECONDS=300

if [ -f "$COOLDOWN_FILE" ]; then
  LAST_SUGGEST=$(cat "$COOLDOWN_FILE" 2>/dev/null || echo "0")
  NOW=$(date +%s)
  DIFF=$((NOW - LAST_SUGGEST))
  if [ "$DIFF" -lt "$COOLDOWN_SECONDS" ] 2>/dev/null; then
    exit 0
  fi
fi

# Update cooldown timestamp
date +%s > "$COOLDOWN_FILE"

# ============================================================
# Output suggestion as non-blocking message
# ============================================================

if [ "$TIER" = "haiku" ]; then
  node -e "console.log(JSON.stringify({
    result: 'message',
    message: 'Model hint: This looks like a quick task — Haiku could handle it faster and cheaper. Consider switching with /model haiku.'
  }))"
elif [ "$TIER" = "opus" ]; then
  node -e "console.log(JSON.stringify({
    result: 'message',
    message: 'Model hint: This looks like a complex task — Opus may deliver better results for deep analysis, architecture, and large refactors. Consider switching with /model opus.'
  }))"
fi

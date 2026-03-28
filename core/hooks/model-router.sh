#!/usr/bin/env bash
# Hook: Model Router — Smart Complexity Analysis
# Trigger: UserPromptSubmit
# Inspired by: SDD model selection (mechanical/integration/architecture tiers)
#
# Analyzes user prompt for task complexity and suggests optimal model tier:
# - Haiku: Mechanical tasks (rename, format, typo, 1-2 files)
# - Sonnet: Default — no suggestion (integration, moderate complexity)
# - Opus: Architecture, deep analysis, security audits, large refactors
#
# Complexity signals: keyword matching + structural indicators (file counts,
# scope markers, review/audit language, multi-step descriptions)
#
# IMPORTANT: No stdout output when no suggestion is needed!
# Git Bash redirects stdout to stderr (Issue #20034) -> "hook error" in TUI.
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

# Empty prompt -> skip
[ -z "$USER_PROMPT" ] && exit 0

# ============================================================
# Smart Complexity Analysis via Node
# ============================================================

TIER=$(node -e "
  const prompt = process.argv[1];

  // --- HAIKU tier: mechanical, simple, single-file tasks ---
  const haikuKeywords = [
    'rename', 'typo', 'format', 'lint', 'simple', 'quick',
    'trivial', 'one-liner', 'delete this', 'remove this',
    'fix import', 'fix typo', 'add comment', 'update version',
    'change name', 'swap', 'toggle'
  ];

  // --- OPUS tier: architecture, deep analysis, multi-system ---
  const opusKeywords = [
    'architect', 'design system', 'refactor', 'security audit',
    'migrate', 'rewrite', 'complex', 'deep dive', 'deep analysis',
    'review the entire', 'plan the', 'system design', 'full audit',
    'analyze architecture', 'performance audit', 'threat model',
    'code review', 'comprehensive', 'ultrathink'
  ];

  // --- Structural complexity signals ---
  const opusSignals = [
    // Multi-file scope indicators
    /\\b(all files|entire|whole|every file|across the|throughout)\\b/,
    // Multi-step descriptions
    /\\b(step 1|phase 1|first .* then|and then|after that|finally)\\b/,
    // Large scope markers
    /\\b(refactor|redesign|overhaul|rebuild|rearchitect)\\b/,
    // Audit/review language
    /\\b(audit|review|analyze|evaluate|assess|investigate)\\b.*\\b(all|every|entire|whole|complete)\\b/,
    // Security-specific
    /\\b(vulnerability|exploit|injection|xss|csrf|owasp)\\b/,
    // Planning language
    /\\b(plan|strategy|roadmap|proposal|rfc|adr)\\b/
  ];

  const haikuSignals = [
    // Single-file scope
    /\\b(this file|this line|line \\d+|just the)\\b/,
    // Minimal change language
    /\\b(just|only|simply|quick|small)\\b.*\\b(change|fix|update|add|remove)\\b/,
    // Direct small actions
    /^(fix|add|remove|update|change|rename|delete|swap|toggle)\\s/
  ];

  /**
   * Match keywords against the prompt.
   * Multi-word keywords use includes (phrase match).
   * Single-word keywords use word-boundary regex.
   */
  function matchesTier(keywords) {
    return keywords.some(kw => {
      if (kw.includes(' ')) return prompt.includes(kw);
      const re = new RegExp('(^|\\\\s)' + kw.replace(/[.*+?^\${}()|[\\]\\\\]/g, '\\\\$&') + '(\\\\s|\$)', 'i');
      return re.test(prompt);
    });
  }

  function matchesSignals(signals) {
    return signals.filter(re => re.test(prompt)).length;
  }

  // Score both tiers
  const opusKeywordMatch = matchesTier(opusKeywords);
  const opusSignalCount = matchesSignals(opusSignals);
  const haikuKeywordMatch = matchesTier(haikuKeywords);
  const haikuSignalCount = matchesSignals(haikuSignals);

  // Prompt length as complexity proxy (>300 chars suggests complex task)
  const isLongPrompt = prompt.length > 300;

  // Decision logic with signal weighting
  if (opusKeywordMatch || opusSignalCount >= 2 || (opusSignalCount >= 1 && isLongPrompt)) {
    console.log('opus');
  } else if (haikuKeywordMatch && opusSignalCount === 0) {
    // Only suggest haiku if NO opus signals present
    if (haikuSignalCount > 0 || !isLongPrompt) {
      console.log('haiku');
    }
  }
  // Default: no output (sonnet is fine)
" "$USER_PROMPT" 2>/dev/null || echo "")

# No tier matched (sonnet-level / default) -> exit silently
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
    message: 'Model hint: This looks like a quick/mechanical task. Haiku could handle it faster and cheaper. Switch with /model haiku.'
  }))"
elif [ "$TIER" = "opus" ]; then
  node -e "console.log(JSON.stringify({
    result: 'message',
    message: 'Model hint: This looks like a complex/architectural task. Opus may deliver better results for deep analysis, planning, and large-scope work. Switch with /model opus.'
  }))"
fi

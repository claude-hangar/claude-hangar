#!/usr/bin/env bash
# Hook: Skill Suggest — UserPromptSubmit
# Analyzes user prompt and suggests a matching skill (non-blocking).
# Source: Infrastructure Showcase pattern (diet103/claude-code-infrastructure-showcase)
#
# Intent Cascade (5 tiers, highest priority first):
#   1. Explicit slash command → exit early (line ~29)
#   2. Active plan context → suggest based on plan type
#   3. STATUS.md phase → suggest based on current work
#   4. Git branch context → suggest based on branch + action
#   5. Keyword matching → existing skill-rules.json triggers
#
# IMPORTANT: No stdout output when no match!
# Git Bash redirects stdout to stderr (Issue #20034) → "hook error" in TUI.
# Output ONLY when a skill suggestion is made.

# No set -euo pipefail — hooks must be resilient on Windows

# Hook profile gate
export HOOK_NAME="skill-suggest"; export HOOK_MIN_PROFILE="standard"
source "${HOME}/.claude/lib/hook-gate.sh" 2>/dev/null || true

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

# If prompt starts with / → skill is being called directly, no suggestion needed
echo "$USER_PROMPT" | grep -qE '^\s*/' && exit 0

# ─── Tier 2-4: Context-based suggestions ─────────────────────────
# Check project context for smarter routing (before keyword matching)

CONTEXT_MATCH=$(node -e "
  const fs = require('fs');
  const path = require('path');
  const cwd = process.cwd();

  // Tier 2: Active plan context
  const plansDir = path.join(cwd, 'docs', 'superpowers', 'plans');
  try {
    const plans = fs.readdirSync(plansDir).filter(f => f.endsWith('.md'));
    if (plans.length > 0) {
      // Active plan exists — suggest /execute-plan or relevant skill
      const latest = plans.sort().pop();
      const content = fs.readFileSync(path.join(plansDir, latest), 'utf8').toLowerCase();
      if (content.includes('audit') || content.includes('review')) {
        console.log('Plan context: active audit/review plan detected');
        process.exit(0);
      }
    }
  } catch {}

  // Tier 3: STATUS.md phase detection
  try {
    const status = fs.readFileSync(path.join(cwd, 'STATUS.md'), 'utf8').toLowerCase();
    if (status.includes('audit') && status.includes('in progress')) {
      console.log('Status context: audit in progress');
      process.exit(0);
    }
    if (status.includes('deploy') && status.includes('pending')) {
      console.log('Status context: deployment pending — consider /deploy-check');
      process.exit(0);
    }
  } catch {}

  // Tier 4: Git branch context
  try {
    const { execSync } = require('child_process');
    const branch = execSync('git rev-parse --abbrev-ref HEAD 2>/dev/null', { encoding: 'utf8' }).trim();
    if (branch.startsWith('feat/') && process.argv[1].includes('done')) {
      console.log('Branch context: feature branch + done → consider /verify before merge');
      process.exit(0);
    }
    if (branch.startsWith('fix/') && process.argv[1].includes('test')) {
      console.log('Branch context: fix branch + test → TDD workflow recommended');
      process.exit(0);
    }
  } catch {}

  // No context match — fall through to Tier 5 (keyword matching)
" "$USER_PROMPT" 2>/dev/null || echo "")

# If context provided a suggestion, output it
if [ -n "$CONTEXT_MATCH" ]; then
  node -e "console.log(JSON.stringify({
    result: 'message',
    message: process.argv[1]
  }))" "$CONTEXT_MATCH"
  exit 0
fi

# ─── Tier 5: Keyword matching (fallback) ─────────────────────────
# Find skill-rules.json (next to this script)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RULES_FILE="$SCRIPT_DIR/skill-rules.json"

[ ! -f "$RULES_FILE" ] && exit 0

# Matching via Node (JSON parsing + trigger check)
MATCH=$(RULES_FILE="$RULES_FILE" node -e "
  const fs = require('fs');
  const rules = JSON.parse(fs.readFileSync(process.env.RULES_FILE, 'utf8')).rules;
  const prompt = process.argv[1];

  for (const rule of rules) {
    // Exclude check first
    const excluded = rule.exclude.some(ex => prompt.includes(ex));
    if (excluded) continue;

    // Trigger check with word boundaries (prevents e.g. 'review' in 'reviewed')
    const matched = rule.triggers.some(trigger => {
      // Multi-word trigger: includes is enough
      if (trigger.includes(' ')) return prompt.includes(trigger);
      // Single-word trigger: check word boundaries
      const re = new RegExp('(^|\\\\s|/)' + trigger.replace(/[.*+?^${}()|[\\]\\\\]/g, '\\\\$&') + '(\\\\s|$)', 'i');
      return re.test(prompt);
    });
    if (matched) {
      console.log(rule.skill);
      process.exit(0);
    }
  }
  console.log('');
" "$USER_PROMPT" 2>/dev/null || echo "")

# No match → exit silently
[ -z "$MATCH" ] && exit 0

# Match found → suggest as non-blocking message
node -e "console.log(JSON.stringify({
  result: 'message',
  message: 'Skill suggestion: ' + process.argv[1] + ' matches this request. Use the skill for better results.'
}))" "$MATCH"

exit 0

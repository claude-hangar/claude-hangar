#!/usr/bin/env bash
# Hook: Continuous Learning (PostToolUse)
# Captures successful patterns and stores them for future reference.
# Trigger: PostToolUse (Bash, Edit, Write)
#
# Captures:
# - Commands that succeeded after a failure (recovery patterns)
# - File modifications that fixed test failures
# - Patterns in successful workflows
#
# Storage: ~/.claude/.patterns/

# No set -euo pipefail — hooks must be resilient on Windows

# Hook profile gate
export HOOK_NAME="continuous-learning"; export HOOK_MIN_PROFILE="strict"
source "${HOME}/.claude/lib/hook-gate.sh" 2>/dev/null || true

INPUT=$(cat 2>/dev/null) || true
[ -z "$INPUT" ] && exit 0

PATTERNS_DIR="$HOME/.claude/.patterns"
mkdir -p "$PATTERNS_DIR"

# Extract tool name and result
TOOL_NAME=$(echo "$INPUT" | node -e "
  const d = JSON.parse(require('fs').readFileSync(0,'utf8'));
  console.log(d.tool_name || '');
" 2>/dev/null || echo "")

# Only capture from Bash tool (commands with observable outcomes)
[ "$TOOL_NAME" != "Bash" ] && exit 0

COMMAND=$(echo "$INPUT" | node -e "
  const d = JSON.parse(require('fs').readFileSync(0,'utf8'));
  console.log(d.tool_input?.command || '');
" 2>/dev/null || echo "")

EXIT_CODE=$(echo "$INPUT" | node -e "
  const d = JSON.parse(require('fs').readFileSync(0,'utf8'));
  console.log(d.tool_result?.exit_code ?? '');
" 2>/dev/null || echo "")

# Skip empty or trivial commands
[ -z "$COMMAND" ] && exit 0
echo "$COMMAND" | grep -qE '^(ls|cd|pwd|echo|cat|head|tail)' && exit 0

# Record pattern: timestamp, command, success/failure
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
LOGFILE="$PATTERNS_DIR/session-$(date +%Y-%m-%d).jsonl"

node -e "
  const entry = {
    timestamp: process.argv[1],
    command: process.argv[2],
    exit_code: parseInt(process.argv[3]) || 0,
    project: process.cwd()
  };
  console.log(JSON.stringify(entry));
" "$TIMESTAMP" "$COMMAND" "$EXIT_CODE" >> "$LOGFILE" 2>/dev/null

exit 0

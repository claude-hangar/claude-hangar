#!/usr/bin/env bash
# Hook: Checkpoint — PreToolUse (Write|Edit)
# Automatically creates a git stash checkpoint before files are modified.
# Source: claudekit checkpoint pattern (carlrannaberg/claudekit)
#
# Logic:
# - Only when uncommitted changes exist
# - Only every 5 minutes (not on every edit)
# - Stash with timestamp + filename as message
# - Non-blocking (always exit 0, no output)
#
# IMPORTANT: No stdout output! Git Bash redirects stdout to stderr (Issue #20034).

# No set -euo pipefail — hooks must be resilient on Windows

# Hook profile gate
export HOOK_NAME="checkpoint"; export HOOK_MIN_PROFILE="standard"
source "${HOME}/.claude/lib/hook-gate.sh" 2>/dev/null || true

INPUT=$(cat 2>/dev/null) || true
[ -z "$INPUT" ] && INPUT='{}'

# Extract filename (Write or Edit tool)
FILE_PATH=$(echo "$INPUT" | node -e "
  const input = JSON.parse(require('fs').readFileSync(0, 'utf8'));
  console.log(input.tool_input?.file_path || input.tool_input?.path || '');
" 2>/dev/null || echo "")

# No file path → skip
[ -z "$FILE_PATH" ] && exit 0

# Not in a git repo → skip
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

# Cooldown: Max 1 checkpoint every 5 minutes
CHECKPOINT_FILE="${TEMP:-/tmp}/.claude-checkpoint-last"
NOW=$(date +%s)

if [ -f "$CHECKPOINT_FILE" ]; then
  LAST=$(cat "$CHECKPOINT_FILE" 2>/dev/null || echo "0")
  DIFF=$((NOW - LAST))
  [ "$DIFF" -lt 300 ] && exit 0
fi

# Check for uncommitted changes
if git diff --quiet && git diff --cached --quiet; then
  exit 0
fi

# Create checkpoint (git stash create — does NOT modify working tree)
STASH_REF=$(git stash create 2>/dev/null || echo "")

if [ -n "$STASH_REF" ]; then
  TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
  git stash store -m "checkpoint: $TIMESTAMP (before edit of $(basename "$FILE_PATH"))" "$STASH_REF" 2>/dev/null || true
  echo "$NOW" > "$CHECKPOINT_FILE"
fi

exit 0

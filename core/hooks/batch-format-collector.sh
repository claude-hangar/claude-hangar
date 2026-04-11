#!/usr/bin/env bash
# Hook: Batch Format Collector
# Trigger: PostToolUse (Edit, Write)
# Collects file paths edited during the session for batch formatting at Stop.
#
# Companion to: stop-batch-format.sh (Stop hook)
# Architecture:
#   PostToolUse → append file_path to ~/.claude/.batch-format/edited-files.txt
#   Stop → stop-batch-format.sh reads the list and runs formatters once
#
# Output: None (collector hook — no stdout)

# No set -euo pipefail — hooks must be resilient on Windows

# Hook profile gate
export HOOK_NAME="batch-format-collector"; export HOOK_MIN_PROFILE="standard"
source "${HOME}/.claude/lib/hook-gate.sh" 2>/dev/null || true

INPUT=$(cat 2>/dev/null) || true
[ -z "$INPUT" ] && exit 0

# Extract tool name and file_path — only for Edit and Write
FILE_PATH=$(echo "$INPUT" | node -e "
  const d = JSON.parse(require('fs').readFileSync(0, 'utf8'));
  const tool = d.tool_name || '';
  if (tool !== 'Edit' && tool !== 'Write') { process.exit(0); }
  const fp = d.tool_input?.file_path || d.tool_input?.path || '';
  if (fp) console.log(fp);
" 2>/dev/null) || true

[ -z "$FILE_PATH" ] && exit 0

# Append to collector file
COLLECT_DIR="$HOME/.claude/.batch-format"
mkdir -p "$COLLECT_DIR" 2>/dev/null || true
echo "$FILE_PATH" >> "$COLLECT_DIR/edited-files.txt" 2>/dev/null || true

exit 0

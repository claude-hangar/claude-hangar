#!/usr/bin/env bash
# Hook: Worktree Init (WorktreeCreate event, Claude Code 2.1.89+)
# Trigger: WorktreeCreate
#
# When a git worktree is created for an agent:
# 1. Logs the worktree path and branch for observability
# 2. Provides context about the project to the agent
#
# IMPORTANT: No stdout output on the "allow" path!
# Git Bash redirects stdout to stderr (Issue #20034).

# No set -euo pipefail — hooks must be resilient on Windows

# Hook profile gate
export HOOK_NAME="worktree-init"; export HOOK_MIN_PROFILE="standard"
source "${HOME}/.claude/lib/hook-gate.sh" 2>/dev/null || true

INPUT=$(cat 2>/dev/null) || true
[ -z "$INPUT" ] && INPUT='{}'

export HOOK_INPUT="$INPUT"

# Log and provide context
node -e "
const input = (() => {
  try { return JSON.parse(process.env.HOOK_INPUT || '{}'); }
  catch { return {}; }
})();

const worktreePath = input.worktree_path || input.path || '';
const branch = input.branch || '';

if (worktreePath) {
  // Log for observability (stderr, not stdout)
  process.stderr.write('WorktreeCreate: ' + worktreePath + (branch ? ' (' + branch + ')' : '') + '\\n');
}
" 2>/dev/null || true

exit 0

#!/usr/bin/env bash
# Hook: Worktree Init (WorktreeCreate event, Claude Code 2.1.89+)
# Trigger: WorktreeCreate
# Mode: async (MUST be registered with "async": true)
#
# When a git worktree is created for an agent:
# 1. Logs the worktree path and branch for observability
#
# IMPORTANT: This hook MUST run async. Synchronous WorktreeCreate hooks
# that produce no stdout cause "no successful output" failures in Claude Code,
# blocking all agents with isolation: worktree.

# No set -euo pipefail — hooks must be resilient on Windows

# Hook profile gate
export HOOK_NAME="worktree-init"; export HOOK_MIN_PROFILE="standard"
source "${HOME}/.claude/lib/hook-gate.sh" 2>/dev/null || true

INPUT=$(cat 2>/dev/null) || true
[ -z "$INPUT" ] && INPUT='{}'

export HOOK_INPUT="$INPUT"

# Log for observability (stderr only — no stdout to avoid Git Bash Issue #20034)
node -e "
const input = (() => {
  try { return JSON.parse(process.env.HOOK_INPUT || '{}'); }
  catch { return {}; }
})();

const worktreePath = input.worktree_path || input.path || '';
const branch = input.branch || '';

if (worktreePath) {
  process.stderr.write('WorktreeCreate: ' + worktreePath + (branch ? ' (' + branch + ')' : '') + '\n');
}
" 2>/dev/null || true

exit 0

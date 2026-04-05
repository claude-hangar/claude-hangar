#!/usr/bin/env bash
# Hook: Instinct Capture
# Trigger: PostToolUse (Bash, Write, Edit)
# Tracks tool usage patterns per session for later analysis.
# Lightweight learning loop: captures WHAT was done, not HOW.
#
# Architecture:
#   PostToolUse → append to session log (temp file)
#   SessionStop → session-stop.sh reads log and prompts reflection
#
# Output: None (notification hook — no stdout)

# No set -euo pipefail — hooks must be resilient on Windows

INPUT=$(cat 2>/dev/null) || true
[ -z "$INPUT" ] && exit 0

# Parse tool name and basic info
TOOL_INFO=$(echo "$INPUT" | node -e "
  const d = JSON.parse(require('fs').readFileSync(0, 'utf8'));
  const tool = d.tool_name || '';
  const input = d.tool_input || {};

  // Only track meaningful tool calls
  const skip = ['Read', 'Glob', 'Grep', 'TaskCreate', 'TaskUpdate', 'TaskGet', 'TaskList'];
  if (skip.includes(tool)) { process.exit(0); }

  const entry = { ts: new Date().toISOString(), tool };

  if (tool === 'Write' || tool === 'Edit') {
    const fp = input.file_path || input.path || '';
    // Extract file extension and directory
    const ext = fp.split('.').pop() || '';
    const dir = fp.replace(/\\\\/g, '/').split('/').slice(-3, -1).join('/');
    entry.action = 'file-modify';
    entry.ext = ext;
    entry.dir = dir;
  } else if (tool === 'Bash') {
    const cmd = (input.command || '').split(' ')[0].split('/').pop();
    entry.action = 'command';
    entry.cmd = cmd;
  } else if (tool === 'Skill') {
    entry.action = 'skill';
    entry.skill = input.skill || '';
  } else if (tool === 'Agent') {
    entry.action = 'agent';
    entry.type = input.subagent_type || 'general';
  } else {
    entry.action = 'other';
  }

  console.log(JSON.stringify(entry));
" 2>/dev/null) || true

[ -z "$TOOL_INFO" ] && exit 0

# Append to session log file
SESSION_ID="${CLAUDE_SESSION_ID:-$$}"
LOG_FILE="${TEMP:-/tmp}/claude-instinct-log-${SESSION_ID}"

echo "$TOOL_INFO" >> "$LOG_FILE" 2>/dev/null || true

exit 0

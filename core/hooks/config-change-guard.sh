#!/usr/bin/env bash
# Hook: Config Change Guard
# Trigger: ConfigChange (when Claude Code modifies config files)
# Logs config changes and warns on critical settings.
# Does NOT block — informational only.
#
# IMPORTANT: No stdout output on the "allow" path!
# Git Bash redirects stdout to stderr (Issue #20034) → "hook error" in TUI.
# Output ONLY on warning.

# No set -euo pipefail — hooks must be resilient on Windows

INPUT=$(cat 2>/dev/null) || true
[ -z "$INPUT" ] && INPUT='{}'

# Session ID for log file
SESSION_ID="${CLAUDE_SESSION_ID:-$$}"
LOG_FILE="${TEMP:-/tmp}/claude-config-changes-${SESSION_ID}.log"

# Pass input as environment variable (not CLI arg due to 32k limit)
export HOOK_INPUT="$INPUT"

# Analyze and log config change
node -e "
const fs = require('fs');
const logFile = process.argv[1];

let input = {};
try {
  input = JSON.parse(process.env.HOOK_INPUT || '{}');
} catch {}

const toolInput = input.tool_input || input || {};
const changedFile = toolInput.file_path || toolInput.path || toolInput.file || '';
const content = toolInput.content || toolInput.new_content || '';
const jsonStr = JSON.stringify(input);

// Timestamp for log
const timestamp = new Date().toISOString();
const logEntry = timestamp + ' | Config changed: ' + (changedFile || 'unknown') + '\n';

try {
  fs.appendFileSync(logFile, logEntry);
} catch {}

// Check critical settings — both in content and full input
const criticalSettings = [
  'skipDangerousModePermissionPrompt',
  'dangerouslySkipPermissions',
  'skipPermissionPrompt',
  'allowedTools',
  'trustAll'
];

const searchText = content + ' ' + jsonStr;
const warnings = [];
for (const setting of criticalSettings) {
  if (searchText.includes(setting)) {
    warnings.push(setting);
  }
}

// Warn on critical changes only (non-blocking)
if (warnings.length > 0) {
  const msg = 'CONFIG WARNING: Critical settings changed: ' + warnings.join(', ') +
    (changedFile ? ' in ' + changedFile : '') +
    '. Please verify this is intentional.';
  console.log(msg);
}
" "$LOG_FILE" 2>/dev/null

# Silent on allow path (Git Bash Issue #20034)
exit 0

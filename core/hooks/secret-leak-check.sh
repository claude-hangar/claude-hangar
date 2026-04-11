#!/usr/bin/env bash
# Hook: Secret Leak Check
# Trigger: PreToolUse (Write, Edit)
# Checks if sensitive data is being written to files.
#
# IMPORTANT: No stdout output on the "allow" path!
# Git Bash on Windows redirects stdout to stderr (Issue #20034).
# Claude Code interprets stderr as "hook error".
# Therefore: Output ONLY on block (exit 2).

# No set -euo pipefail — hooks must be resilient on Windows

# Hook profile gate
export HOOK_NAME="secret-leak-check"; export HOOK_MIN_PROFILE="minimal"
source "${HOME}/.claude/lib/hook-gate.sh" 2>/dev/null || true

# Read input from stdin (JSON) — with fallback on pipe error
INPUT=$(cat 2>/dev/null) || true
[ -z "$INPUT" ] && INPUT='{}'

# Extract file content and path
FILE_PATH=$(echo "$INPUT" | node -e "
  const d = JSON.parse(require('fs').readFileSync(0,'utf8'));
  console.log(d.tool_input?.file_path || d.tool_input?.path || '');
" 2>/dev/null || echo "")

CONTENT=$(echo "$INPUT" | node -e "
  const d = JSON.parse(require('fs').readFileSync(0,'utf8'));
  console.log(d.tool_input?.content || d.tool_input?.new_string || '');
" 2>/dev/null || echo "")

# Files to ignore (only safe exceptions)
BASENAME=$(basename "$FILE_PATH" 2>/dev/null || echo "")
case "$BASENAME" in
  .env.example|*.template|secret-leak-check.sh)
    exit 0
    ;;
esac

# Known documentation paths — skip (not blanket *.md)
# Windows delivers backslash paths — normalize for pattern matching
NORM_PATH="${FILE_PATH//\\//}"
case "$NORM_PATH" in
  */fix-templates*|*/CHANGELOG*|*/changelog*|*/README*|*/docs/tutorials/*|*/docs/concepts/*)
    exit 0
    ;;
esac

# Patterns indicating secrets (POSIX ERE — no grep -P needed)
PATTERNS=(
  # API Keys (generic formats)
  'sk-[a-zA-Z0-9]{20,}'
  'pk-[a-zA-Z0-9]{20,}'
  "api[_-]?key[[:space:]]*[:=][[:space:]]*[\"'][a-zA-Z0-9]{16,}"
  "api[_-]?secret[[:space:]]*[:=][[:space:]]*[\"'][a-zA-Z0-9]{16,}"
  # AWS
  'AKIA[0-9A-Z]{16}'
  'aws[_-]?secret[_-]?access[_-]?key'
  # GitHub Tokens
  'ghp_[a-zA-Z0-9]{36}'
  'gho_[a-zA-Z0-9]{36}'
  'ghs_[a-zA-Z0-9]{36}'
  'github_pat_[a-zA-Z0-9_]{22,}'
  # Anthropic API Keys
  'sk-ant-[a-zA-Z0-9_-]{20,}'
  # Private Keys
  '-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----'
  # Password assignments
  "password[[:space:]]*[:=][[:space:]]*[\"'][^[:space:]]{8,}"
  "passwd[[:space:]]*[:=][[:space:]]*[\"'][^[:space:]]{8,}"
  # Token assignments
  "token[[:space:]]*[:=][[:space:]]*[\"'][a-zA-Z0-9_-]{20,}"
  # Database URLs with credentials
  '(postgres|mysql|mongodb)://[^:]+:[^@]+@'
  # OpenAI
  'sk-proj-[a-zA-Z0-9]{20,}'
  # Slack Tokens
  'xox[bprs]-[a-zA-Z0-9-]{10,}'
  # Stripe Keys
  '(sk|pk)_live_[a-zA-Z0-9]{20,}'
  # Sendgrid
  'SG\.[a-zA-Z0-9_-]{22,}\.[a-zA-Z0-9_-]{20,}'
  # Telegram Bot Tokens
  '[0-9]{8,}:[a-zA-Z0-9_-]{35}'
  # Google Cloud API Keys
  'AIza[0-9A-Za-z_-]{35}'
  # HashiCorp Vault Tokens
  'hvs\.[a-zA-Z0-9_-]{20,}'
  # Cloudflare API Tokens
  'cf[_-]api[_-]?(key|token)'
  # DigitalOcean
  'dop_v1_[a-f0-9]{64}'
  # Hetzner API Tokens
  'hcloud[_-]?(api[_-]?)?(key|token)'
)

WARNINGS=""
for PATTERN in "${PATTERNS[@]}"; do
  if echo "$CONTENT" | grep -qiE -- "$PATTERN" 2>/dev/null; then
    WARNINGS="${WARNINGS}Pattern found: ${PATTERN}\n"
  fi
done

# Warn on .env files directly (except .env.example)
if [[ "$FILE_PATH" =~ \.env$ || ( "$FILE_PATH" =~ \.env\. && ! "$FILE_PATH" =~ \.example ) ]]; then
  WARNINGS="${WARNINGS}.env file being written: ${FILE_PATH}\n"
fi

# Check for <private> tagged content being written to committed files
# Memory files with <private> sections should not be committed
if echo "$CONTENT" | grep -qE '<private>|privacy:\s*private' 2>/dev/null; then
  # Allow in memory directories (those are local, not committed)
  case "$NORM_PATH" in
    */.claude/projects/*/memory/*|*/.claude/memory/*)
      ;; # Memory files are local — private tags are fine
    *)
      WARNINGS="${WARNINGS}Private-tagged content being written to a potentially committed file\n"
      ;;
  esac
fi

if [ -n "$WARNINGS" ]; then
  REASON="SECRET-LEAK WARNING in ${FILE_PATH}: ${WARNINGS}Please check if secrets are present."
  node -e "console.log(JSON.stringify({hookSpecificOutput:{permissionDecision:'block',permissionDecisionReason:process.argv[1]}}))" "$REASON"
  exit 2
fi

exit 0

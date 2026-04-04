#!/usr/bin/env bash
# Consolidated Hook: Bash Guard (PreToolUse/Bash)
# Combines: bash-command-guard + commit-message-validator + ci-guard
# Trigger: PreToolUse (Bash)
#
# Benefits: 1x stdin read, 1x JSON parse instead of 3x
#
# IMPORTANT: No stdout output on the "allow" path!
# Git Bash redirects stdout to stderr (Issue #20034) → "hook error" in TUI.
# Output ONLY on block (exit 2).

# No set -euo pipefail — hooks must be resilient on Windows

# === 1x stdin read, 1x command extraction ===

INPUT=$(cat 2>/dev/null) || true
[ -z "$INPUT" ] && INPUT='{}'

COMMAND=$(echo "$INPUT" | node -e "
  const d = JSON.parse(require('fs').readFileSync(0,'utf8'));
  console.log(d.tool_input?.command || '');
" 2>/dev/null || echo "")

# Empty command → allow
[ -z "$COMMAND" ] && exit 0

# ============================================================
# PART A: Bash Command Guard (block destructive commands)
# ============================================================

BLOCKED=""

# --- 1. Destructive filesystem operations ---

# rm -rf / or rm -rf /* (root deletion)
if echo "$COMMAND" | grep -qE 'rm\s+(-[a-zA-Z]*r[a-zA-Z]*f|(-[a-zA-Z]*f[a-zA-Z]*r))\s+/(\s|$|\*)'; then
  BLOCKED+="rm -rf / (root directory deletion)\n"
fi

# rm -rf ~ or $HOME (but allow rm on specific subdirectories like ~/.claude/skills/foo)
# Block: rm -rf ~, rm -rf ~/, rm -rf ~/*, rm -rf $HOME
# Allow: rm -rf ~/.claude/skills/foo (2+ path segments after ~)
if echo "$COMMAND" | grep -qE 'rm\s+(-[a-zA-Z]*r[a-zA-Z]*f|(-[a-zA-Z]*f[a-zA-Z]*r))\s+(~|\$HOME|\$\{HOME\}|"?\$HOME"?)(\s|$|/(\s|$|\*))' && \
   ! echo "$COMMAND" | grep -qE 'rm\s+(-[a-zA-Z]*r[a-zA-Z]*f|(-[a-zA-Z]*f[a-zA-Z]*r))\s+(~|\$HOME|\$\{HOME\})/[^/\s]+/[^/\s]+'; then
  BLOCKED+="rm -rf ~ (home directory deletion)\n"
fi

# rm -rf . (current directory)
if echo "$COMMAND" | grep -qE 'rm\s+(-[a-zA-Z]*r[a-zA-Z]*f|(-[a-zA-Z]*f[a-zA-Z]*r))\s+\.(\s|$)'; then
  BLOCKED+="rm -rf . (current directory deletion)\n"
fi

# rm -rf C:\ or D:\ (Windows root)
if echo "$COMMAND" | grep -qiE 'rm\s+(-[a-zA-Z]*r[a-zA-Z]*f|(-[a-zA-Z]*f[a-zA-Z]*r))\s+[A-Z]:[/\\](\s|$|\*)'; then
  BLOCKED+="rm -rf <drive>: (Windows root deletion)\n"
fi

# --- 2. Remote code execution ---

# curl|bash, curl|sh, wget|bash, wget|sh
if echo "$COMMAND" | grep -qE '(curl|wget)\s+[^|]*\|\s*(ba)?sh'; then
  BLOCKED+="curl/wget | bash (remote code execution)\n"
fi

# eval "$(curl ...)" or eval "$(wget ...)"
if echo "$COMMAND" | grep -qE 'eval\s+.*\$\((curl|wget)'; then
  BLOCKED+="eval \$(curl/wget) (remote code execution)\n"
fi

# bash <(curl ...) — process substitution
if echo "$COMMAND" | grep -qE '(ba)?sh\s+<\(\s*(curl|wget)'; then
  BLOCKED+="bash <(curl) (remote code execution via process substitution)\n"
fi

# --- 3. Dangerous permissions ---

# chmod 777 (world-writable)
if echo "$COMMAND" | grep -qE 'chmod\s+(-R\s+)?777'; then
  BLOCKED+="chmod 777 (world-writable — security risk)\n"
fi

# --- 4. Disk/system operations ---

# mkfs (format filesystem)
if echo "$COMMAND" | grep -qE '\bmkfs\b'; then
  BLOCKED+="mkfs (format filesystem)\n"
fi

# dd if= ... of=/dev/ (raw disk write)
if echo "$COMMAND" | grep -qE '\bdd\b.*\bof=/dev/'; then
  BLOCKED+="dd of=/dev/ (raw disk write)\n"
fi

# Fork bomb
if echo "$COMMAND" | grep -qE ':\(\)\s*\{.*\|'; then
  BLOCKED+="Fork bomb detected\n"
fi

# --- 4b. Windows-specific destructive commands ---

# del /s /q (recursive delete on Windows)
if echo "$COMMAND" | grep -qiE '\bdel\b.*/s.*/q'; then
  BLOCKED+="del /s /q (Windows recursive delete)\n"
fi

# rd /s /q (remove directory on Windows)
if echo "$COMMAND" | grep -qiE '\brd\b.*/s.*/q'; then
  BLOCKED+="rd /s /q (Windows recursive directory removal)\n"
fi

# --- 5. Git protection ---

# git push --force / -f
if echo "$COMMAND" | grep -qE 'git\s+push\s+.*(-f\b|--force\b)'; then
  BLOCKED+="git push --force (can overwrite remote history)\n"
fi

# git reset --hard origin
if echo "$COMMAND" | grep -qE 'git\s+reset\s+--hard\s+origin'; then
  BLOCKED+="git reset --hard origin (discards all local changes)\n"
fi

# --no-verify (hook bypass)
if echo "$COMMAND" | grep -qF -- '--no-verify'; then
  BLOCKED+="--no-verify (git hook bypass)\n"
fi

# --- 6. Accidental publish ---

# npm publish (without --dry-run)
if echo "$COMMAND" | grep -qE '\bnpm\s+publish\b' && ! echo "$COMMAND" | grep -qF -- '--dry-run'; then
  BLOCKED+="npm publish (without --dry-run — accidental publish?)\n"
fi

# --- 7. SQL injection via CLI ---

# DROP TABLE / DROP DATABASE
if echo "$COMMAND" | grep -qiE '\bDROP\s+(TABLE|DATABASE)\b'; then
  BLOCKED+="DROP TABLE/DATABASE (destructive SQL operation)\n"
fi

# --- Command guard result ---

if [ -n "$BLOCKED" ]; then
  REASON="BASH-COMMAND-GUARD: Dangerous command blocked!\n\n${BLOCKED}\nCommand: $(echo "$COMMAND" | head -c 200)\n\nPlease use a safe command or ask the user for confirmation."
  node -e "console.log(JSON.stringify({decision:'block',reason:process.argv[1]}))" "$REASON"
  exit 2
fi

# ============================================================
# PART B: Commit Message Validator (only on git commit)
# ============================================================

if echo "$COMMAND" | grep -q 'git commit'; then

  # Extract commit message (all common formats)
  MSG=$(echo "$COMMAND" | node -e "
    const cmd = require('fs').readFileSync(0,'utf8');

    // Format 1: -m 'message' or -m \"message\"
    let m = cmd.match(/-m\\s+['\"]([^'\"]+)['\"]/);
    if (m) { console.log(m[1]); process.exit(0); }

    // Format 2: -m \"\$(cat <<'EOF'\\nmessage\\nEOF\\n)\" (Claude Code HEREDOC)
    m = cmd.match(/<<['\"]?([A-Z_]+)['\"]?[\\s)]*\\n([\\s\\S]*?)\\n\\s*\\1/);
    if (m) { console.log(m[2].trim().split('\\n')[0]); process.exit(0); }

    // Format 3: -m \"\$(cat <<EOF\\nmessage\\nEOF)\" (without quotes)
    m = cmd.match(/<<\\s*([A-Z_]+)\\n([\\s\\S]*?)\\n\\s*\\1/);
    if (m) { console.log(m[2].trim().split('\\n')[0]); process.exit(0); }

    console.log('');
  " 2>/dev/null || echo "")

  # Empty or non-extractable message → allow
  if [ -n "$MSG" ]; then
    # First line (subject)
    SUBJECT=$(echo "$MSG" | head -1)

    # Conventional Commits check
    VALID_PATTERN='^(feat|fix|refactor|docs|test|chore|style|perf|ci|build|revert)(\([a-z0-9_-]+\))?!?:[[:space:]].+'

    if ! echo "$SUBJECT" | grep -qE "$VALID_PATTERN"; then
      node -e "console.log(JSON.stringify({decision:'block',reason:'COMMIT-MESSAGE: Not a Conventional Commit format. Expected: type(scope): description. Types: feat, fix, refactor, docs, test, chore, style, perf, ci, build, revert. Got: ' + process.argv[1]}))" "$SUBJECT"
      exit 2
    fi

    # Length check (max 72 chars for subject)
    if [ ${#SUBJECT} -gt 72 ]; then
      node -e "console.log(JSON.stringify({decision:'block',reason:'COMMIT-MESSAGE: Subject too long (' + process.argv[1].length + ' chars, max 72). Please shorten.'}))" "$SUBJECT"
      exit 2
    fi

    # No trailing period
    if echo "$SUBJECT" | grep -q '\.$'; then
      echo '{"decision":"block","reason":"COMMIT-MESSAGE: Subject ends with period — please remove."}'
      exit 2
    fi
  fi

fi

# ============================================================
# PART C: CI Guard (only on git push)
# ============================================================

if echo "$COMMAND" | grep -q 'git push'; then

  ERRORS=""

  # ShellCheck (if installed)
  if command -v shellcheck &>/dev/null; then
    SC_OUT=$(find . -name '*.sh' -not -path './.git/*' -not -path '*/node_modules/*' -not -path './.claude/*' -maxdepth 5 \
      -exec shellcheck --severity=warning --format=gcc {} + 2>&1) || true
    if [ -n "$SC_OUT" ]; then
      SC_COUNT=$(echo "$SC_OUT" | wc -l)
      ERRORS+="ShellCheck: $SC_COUNT warnings\n"
      ERRORS+="$(echo "$SC_OUT" | head -5)\n"
      if [ "$SC_COUNT" -gt 5 ]; then
        ERRORS+="... and $((SC_COUNT - 5)) more\n"
      fi
    fi
  fi

  # Markdownlint (if globally installed)
  if command -v markdownlint &>/dev/null; then
    MD_OUT=$(markdownlint '**/*.md' --ignore node_modules --ignore .git 2>&1) || true
    if [ -n "$MD_OUT" ]; then
      MD_COUNT=$(echo "$MD_OUT" | wc -l)
      ERRORS+="Markdownlint: $MD_COUNT errors\n"
      ERRORS+="$(echo "$MD_OUT" | head -5)\n"
    fi
  fi

  # GitHub Actions SHA-Pinning Check (advisory, additionalContext)
  SHA_WARNING=""
  if [ -d ".github/workflows" ]; then
    SHA_OUT=$(node -e "
      const fs = require('fs');
      const path = require('path');
      const dir = '.github/workflows';
      const findings = [];
      try {
        const files = fs.readdirSync(dir).filter(f => f.endsWith('.yml') || f.endsWith('.yaml'));
        for (const file of files) {
          const content = fs.readFileSync(path.join(dir, file), 'utf8');
          const lines = content.split('\n');
          for (let i = 0; i < lines.length; i++) {
            const match = lines[i].match(/uses:\s*([^@]+)@(?!([a-f0-9]{40}))(\S+)/);
            if (match && !match[1].startsWith('./') && !match[1].startsWith('docker://')) {
              findings.push(file + ':' + (i+1) + ' uses: ' + match[1] + '@' + match[3]);
            }
          }
        }
        if (findings.length > 0) {
          console.log(findings.slice(0, 5).join('\n'));
          if (findings.length > 5) console.log('... and ' + (findings.length - 5) + ' more');
        }
      } catch {}
    " 2>/dev/null || echo "")
    if [ -n "$SHA_OUT" ]; then
      SHA_WARNING="GitHub Actions: SHA pinning recommended (supply chain risk):\n$SHA_OUT\n"
    fi
  fi

  # CI Guard result
  if [ -n "$ERRORS" ]; then
    REASON="CI-GUARD: Push blocked — CI would fail!\n\n${ERRORS}\nPlease fix, then push again."
    if [ -n "$SHA_WARNING" ]; then
      REASON+="\n\nAdvisory:\n${SHA_WARNING}"
    fi
    node -e "console.log(JSON.stringify({decision:'block',reason:process.argv[1]}))" "$REASON"
    exit 2
  fi

  # SHA pinning as advisory (non-blocking, additionalContext)
  if [ -n "$SHA_WARNING" ]; then
    node -e "console.log(JSON.stringify({additionalContext:'CI-GUARD Advisory: ' + process.argv[1]}))" "$SHA_WARNING"
    exit 0
  fi

fi

# All OK — silently allow
exit 0

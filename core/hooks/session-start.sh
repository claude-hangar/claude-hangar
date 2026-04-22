#!/usr/bin/env bash
# Hook: Session Start
# Trigger: SessionStart (once at session start/resume)
# Checks for STATUS.md and .tasks.json and returns context.

# No set -euo pipefail — hooks must be resilient on Windows

# Hook profile gate
export HOOK_NAME="session-start"; export HOOK_MIN_PROFILE="standard"
source "${HOME}/.claude/lib/hook-gate.sh" 2>/dev/null || true

INPUT=$(cat 2>/dev/null) || true
CWD=$(echo "$INPUT" | node -e "
  const d = JSON.parse(require('fs').readFileSync(0,'utf8'));
  console.log(d.cwd || process.cwd());
" 2>/dev/null || echo "$PWD")

CONTEXT=""

# Check STATUS.md
STATUS_FILE="$CWD/STATUS.md"
if [ -f "$STATUS_FILE" ]; then
  SECTION=$(node -e "
    const fs = require('fs');
    const content = fs.readFileSync(process.argv[1], 'utf8');
    // Look for 'Current Work' or 'In Progress' section
    const match = content.match(/##[^#]*(?:Current Work|In Progress|Aktuelle Arbeit|In Arbeit|Aktuell)[^\n]*\n([\s\S]*?)(?=\n## [^#]|\$)/i);
    if (match) {
      console.log(match[0].trim().substring(0, 500));
    } else {
      // Fallback: first 300 chars
      console.log(content.substring(0, 300).trim());
    }
  " "$STATUS_FILE" 2>/dev/null || echo "STATUS.md found")
  CONTEXT+="STATUS.md found: $SECTION\n"
fi

# Check .tasks.json
TASKS_FILE="$CWD/.tasks.json"
if [ -f "$TASKS_FILE" ]; then
  TASK_SUMMARY=$(node -e "
    const fs = require('fs');
    const data = JSON.parse(fs.readFileSync(process.argv[1], 'utf8'));
    const tasks = data.tasks || [];
    const open = tasks.filter(t => t.status === 'open').length;
    const inProgress = tasks.filter(t => t.status === 'in-progress').length;
    const done = tasks.filter(t => t.status === 'done').length;
    const parts = [];
    if (inProgress > 0) parts.push(inProgress + ' in progress');
    if (open > 0) parts.push(open + ' open');
    if (done > 0) parts.push(done + ' done');
    if (parts.length > 0) {
      console.log('Tasks: ' + parts.join(', '));
      tasks.filter(t => t.status === 'in-progress' || t.status === 'open')
        .slice(0, 3)
        .forEach(t => console.log('  - [' + t.status + '] ' + (t.title || t.id)));
    }
  " "$TASKS_FILE" 2>/dev/null || echo ".tasks.json found")
  if [ -n "$TASK_SUMMARY" ]; then
    CONTEXT+="$TASK_SUMMARY\n"
  fi
fi

# MEMORY.md size check (token efficiency)
MEMORY_WARNING=$(node -e "
  const fs=require('fs'), path=require('path');
  let cwd=process.argv[1]||'';
  if(/^\/[a-zA-Z]\//.test(cwd)) cwd=cwd[1].toUpperCase()+':\\\\'+cwd.substring(3).replace(/\//g,'\\\\');
  const enc=cwd.replace(/[:\\\\/]/g,'-');
  const f=path.join(process.env.USERPROFILE||process.env.HOME,'.claude','projects',enc,'memory','MEMORY.md');
  try{const s=fs.statSync(f).size; if(s>3072) console.log('WARNING: MEMORY.md is '+Math.round(s/1024)+'KB (>3KB) — consider compressing');}catch(e){}
" "$CWD" 2>/dev/null) || true
if [ -n "$MEMORY_WARNING" ]; then
  CONTEXT+="$MEMORY_WARNING\n"
fi

# Memory hygiene check (ASI06 — Memory & Context Poisoning)
MEMORY_HYGIENE=$(node -e "
  const fs=require('fs'), path=require('path');
  let cwd=process.argv[1]||'';
  if(/^\/[a-zA-Z]\//.test(cwd)) cwd=cwd[1].toUpperCase()+':\\\\'+cwd.substring(3).replace(/\//g,'\\\\');
  const enc=cwd.replace(/[:\\\\/]/g,'-');
  const f=path.join(process.env.USERPROFILE||process.env.HOME,'.claude','projects',enc,'memory','MEMORY.md');
  try {
    const content=fs.readFileSync(f,'utf8');
    const findings=[];
    const lines=content.split('\n');
    for(let i=0;i<lines.length;i++){
      const l=lines[i].toLowerCase();
      const n=i+1;
      if(/\b(skip|bypass|disable|ignore|deactivate|turn.?off)\b.*(security|verification|hook|guard|check|review|audit|permission)/i.test(lines[i]))
        findings.push('L'+n+': Suspicious control override: '+lines[i].substring(0,80));
      if(/(sk-ant-|ghp_|gho_|ghs_|AKIA|sk-proj-|xox[bprs]-|-----BEGIN.*PRIVATE KEY)/i.test(lines[i]))
        findings.push('L'+n+': Possible secret in MEMORY.md!');
      if(/https?:\/\/(?!github\.com|npmjs\.com|docs\.|developer\.|anthropic\.com|astro\.build|svelte\.dev|tailwindcss\.com)[^\s)]+\.(exe|sh|ps1|bat|cmd)/i.test(lines[i]))
        findings.push('L'+n+': Suspicious external link to executable');
      if(/\b(eval|exec)\s*\(/.test(lines[i])&&!/code.*example|pattern|docs|replace|alternative/i.test(lines[i]))
        findings.push('L'+n+': eval/exec call in memory');
    }
    if(findings.length>0) console.log('MEMORY-HYGIENE: '+findings.length+' finding(s):\\n'+findings.join('\\n'));
  } catch(e){}
" "$CWD" 2>/dev/null) || true
if [ -n "$MEMORY_HYGIENE" ]; then
  CONTEXT+="$MEMORY_HYGIENE\n"
fi

# Frontend project detection — remind about design-system
FRONTEND_HINT=$(node -e "
  const fs = require('fs');
  const path = require('path');
  const cwd = process.argv[1] || '';
  const pkgPath = path.join(cwd, 'package.json');
  try {
    const pkg = JSON.parse(fs.readFileSync(pkgPath, 'utf8'));
    const deps = { ...pkg.dependencies, ...pkg.devDependencies };
    const stack = [];
    if (deps['astro']) stack.push('Astro');
    if (deps['@sveltejs/kit']) stack.push('SvelteKit');
    if (deps['next']) stack.push('Next.js');
    if (deps['tailwindcss']) stack.push('Tailwind');
    if (stack.length > 0) {
      // Check if design-system/MASTER.md exists
      const masterPath = path.join(cwd, 'design-system', 'MASTER.md');
      const hasMaster = fs.existsSync(masterPath);
      let hint = 'DESIGN: ' + stack.join('+') + ' project detected.';
      hint += ' /design-system available (48 styles, 75 palettes, 34 fonts, 70 UX rules).';
      if (hasMaster) {
        hint += ' MASTER.md found — project design tokens active.';
      } else {
        hint += ' No MASTER.md — consider /design-system for initial design setup.';
      }
      console.log(hint);
    }
  } catch(e) {}
" "$CWD" 2>/dev/null) || true
if [ -n "$FRONTEND_HINT" ]; then
  CONTEXT+="$FRONTEND_HINT\n"
fi

# Config-Secret-Scan — catch secrets in ~/.claude/settings.json(.local) on every session start
# Complements secret-leak-check.sh which only runs on Write/Edit, not on manual edits outside Claude.
CONFIG_LEAK=$(node -e "
  const fs = require('fs'), path = require('path');
  const home = process.env.USERPROFILE || process.env.HOME || '';
  if (!home) { process.exit(0); }
  const files = [
    path.join(home, '.claude', 'settings.json'),
    path.join(home, '.claude', 'settings.local.json'),
  ];
  const patterns = [
    [/ghp_[A-Za-z0-9]{36}/, 'GitHub PAT'],
    [/gho_[A-Za-z0-9]{36}/, 'GitHub OAuth token'],
    [/ghs_[A-Za-z0-9]{36}/, 'GitHub App token'],
    [/github_pat_[A-Za-z0-9_]{22,}/, 'GitHub fine-grained PAT'],
    [/sk-ant-[A-Za-z0-9_-]{20,}/, 'Anthropic API key'],
    [/sk-proj-[A-Za-z0-9]{20,}/, 'OpenAI project key'],
    [/AKIA[0-9A-Z]{16}/, 'AWS access key'],
    [/(postgres|mysql|mongodb):\/\/[^:\s\"']+:[^@\s\"']+@/, 'DB URL with inline credentials'],
    [/-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----/, 'Private key block'],
  ];
  const hits = [];
  for (const f of files) {
    try {
      const body = fs.readFileSync(f, 'utf8');
      for (const [re, label] of patterns) {
        if (re.test(body)) hits.push(path.basename(f) + ': ' + label);
      }
    } catch (e) { /* file missing — ignore */ }
  }
  if (hits.length > 0) {
    console.log('CONFIG-SECRET WARNING — secrets found in global config: ' + hits.join(' | ') + '. Rotate and remove immediately.');
  }
" 2>/dev/null) || true
if [ -n "$CONFIG_LEAK" ]; then
  CONTEXT+="$CONFIG_LEAK\n"
fi

# Write session start timestamp (used by cost-tracker and desktop-notify)
date +%s > "$HOME/.claude/.session-start" 2>/dev/null || true

# Reset token tracking file (new session)
SESSION_ID="${CLAUDE_SESSION_ID:-$$}"
TRACK_FILE="${TEMP:-/tmp}/claude-token-track-${SESSION_ID}"
if [ -f "$TRACK_FILE" ]; then
  rm -f "$TRACK_FILE"
fi

# Return context as JSON (consistent with other hooks)
if [ -n "$CONTEXT" ]; then
  node -e "
    const ctx = process.argv[1].replace(/\\\\n/g, '\n').trim();
    if (ctx) console.log(JSON.stringify({ additionalContext: ctx }));
  " "$CONTEXT" 2>/dev/null || true
fi

exit 0

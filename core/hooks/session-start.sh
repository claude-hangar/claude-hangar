#!/usr/bin/env bash
# Hook: Session Start
# Trigger: SessionStart (once at session start/resume)
# Checks for STATUS.md and .tasks.json and returns context.

# No set -euo pipefail — hooks must be resilient on Windows

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

# Reset token tracking file (new session)
SESSION_ID="${CLAUDE_SESSION_ID:-$$}"
TRACK_FILE="${TEMP:-/tmp}/claude-token-track-${SESSION_ID}"
if [ -f "$TRACK_FILE" ]; then
  rm -f "$TRACK_FILE"
fi

# Return context (additionalContext for the model)
if [ -n "$CONTEXT" ]; then
  echo -e "$CONTEXT"
fi

exit 0

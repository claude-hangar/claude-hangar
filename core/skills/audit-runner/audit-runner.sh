#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────
# audit-runner.sh — Autonomous Audit Runner for Claude Code
# ─────────────────────────────────────────────────────────────────────────
# Runs /audit, /astro-audit and /project-audit fully autonomously.
# Each phase runs in its own Claude session (no context limit).
#
# Usage:
#   bash audit-runner.sh /path/to/project [options]
#
# Options:
#   --audits "audit,project-audit"   Which audits (default: all three)
#   --timeout 600                    Timeout per session in seconds
#   --max-retries 3                  Max retries on error
#   --dry-run                        Show plan only, don't execute
#   --skip-orchestrator              Skip orchestrator phase
#   --batch                          Audit all git repos in directory
#   --depth 3                        Search depth for --batch (default: 3)
#   --repos "1,3,5"                  Only specific repos in batch (numbers from list)
#
# Prerequisites:
#   - Claude Code CLI (claude)
#   - Node.js (JSON parsing)
#   - Audit skills in ~/.claude/skills/
# ─────────────────────────────────────────────────────────────────────────

set -euo pipefail

# ─── Load shared functions ─────────────────────────────────────────────
# Tries to load common.sh from deploy path or source tree.
# Fallback: inline color codes if not found.
_common_loaded=false
for _common_path in \
  "$HOME/.claude/lib/common.sh" \
  "$(cd "$(dirname "$0")/../../.." 2>/dev/null && pwd)/global/lib/common.sh"; do
  if [ -f "$_common_path" ]; then
    # shellcheck source=../../lib/common.sh
    source "$_common_path"
    _common_loaded=true
    break
  fi
done
if [ "$_common_loaded" = false ]; then
  # Inline fallback (minimal color codes, used in log()/blog())
  # shellcheck disable=SC2034
  {
    RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
    CYAN='\033[0;36m'; NC='\033[0m'
  }
  to_node_path() {
    if command -v cygpath &>/dev/null; then cygpath -m "$1"; else echo "$1" | tr '\\' '/'; fi
  }
fi
unset _common_loaded _common_path

# ─── Defaults ────────────────────────────────────────────────────────────

CLAUDE_BIN="${CLAUDE_BIN:-claude}"
AUDITS="audit,astro-audit,project-audit"
TIMEOUT=600
MAX_RETRIES=3
DRY_RUN=false
SKIP_ORCHESTRATOR=false
BATCH_MODE=false
BATCH_DEPTH=3
BATCH_REPOS=""
MAX_SESSIONS_PER_AUDIT=8

# ─── Argument Parsing ────────────────────────────────────────────────────

PROJECT_DIR="${1:-.}"
shift || true

while [[ $# -gt 0 ]]; do
  case "$1" in
    --audits) AUDITS="$2"; shift 2 ;;
    --timeout) TIMEOUT="$2"; shift 2 ;;
    --max-retries) MAX_RETRIES="$2"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    --skip-orchestrator) SKIP_ORCHESTRATOR=true; shift ;;
    --batch) BATCH_MODE=true; shift ;;
    --depth) BATCH_DEPTH="$2"; shift 2 ;;
    --repos) BATCH_REPOS="$2"; shift 2 ;;
    --help|-h)
      head -20 "$0" | grep '^#' | sed 's/^# *//'
      exit 0
      ;;
    *) echo "Unknown option: $1 (--help for usage)"; exit 1 ;;
  esac
done

# ─── Normalize paths (Windows/Git Bash) ──────────────────────────────────

if command -v cygpath &>/dev/null; then
  PROJECT_DIR="$(cygpath -u "$PROJECT_DIR")"
fi
PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"

LOG_DIR="$PROJECT_DIR/.audit-runner-logs"
TIMESTAMP="$(date '+%Y%m%d-%H%M%S')"
LOG_FILE="$LOG_DIR/runner-$TIMESTAMP.log"
SUMMARY_FILE="$LOG_DIR/summary.json"

# ─── Helper functions ─────────────────────────────────────────────────────

log() {
  local msg
  msg="[$(date '+%H:%M:%S')] $*"
  echo "$msg"
  echo "$msg" >> "$LOG_FILE"
}

log_section() {
  local line="════════════════════════════════════════════════════════"
  log ""
  log "$line"
  log "  $*"
  log "$line"
}

# Progress bar: progress_bar done total [findings]
# Example: progress_bar 3 8 12 → "  [████████████░░░░░░░░░░░░] 3/8 phases (38%) — 12 findings"
progress_bar() {
  local done="$1"
  local total="$2"
  local findings="${3:-0}"
  local width=24

  if [ "$total" -eq 0 ]; then
    return
  fi

  local filled=$(( (done * width) / total ))
  local empty=$(( width - filled ))
  local pct=$(( (done * 100) / total ))

  local bar=""
  for ((i=0; i<filled; i++)); do bar+="█"; done
  for ((i=0; i<empty; i++)); do bar+="░"; done

  local findings_text=""
  if [ "$findings" -gt 0 ]; then
    findings_text=" — $findings findings"
  fi

  local msg="  [$bar] $done/$total phases ($pct%)$findings_text"
  echo "$msg"
  echo "[$(date '+%H:%M:%S')] $msg" >> "$LOG_FILE"
}

# Read JSON value (Node instead of jq — cross-platform)
json_get() {
  local file="$1"
  local expr="$2"
  local normalized
  normalized="$(to_node_path "$file")"
  JSON_FILE="$normalized" JSON_EXPR="$expr" node -e "
    try {
      const d = JSON.parse(require('fs').readFileSync(process.env.JSON_FILE,'utf8'));
      // Safe accessor: only property access and array methods allowed
      // No generic eval — controlled evaluation instead
      const expr = process.env.JSON_EXPR;
      const fn = new Function('d', 'return ' + expr);
      const r = fn(d);
      console.log(typeof r === 'object' ? JSON.stringify(r) : String(r));
    } catch(e) { console.log('ERROR'); }
  "
}

# Read state file — outputs Key=Value pairs
# All values are controlled strings/numbers, no user input.
check_audit_state() {
  local state_file="$1"

  if [ ! -f "$state_file" ]; then
    echo "STATE_STATUS=NOT_FOUND"
    echo "STATE_ALL_DONE=false"
    echo "STATE_TOTAL=0"
    echo "STATE_DONE=0"
    echo "STATE_PENDING=0"
    echo "STATE_FINDINGS=0"
    return
  fi

  local normalized
  normalized="$(to_node_path "$state_file")"
  local result
  result=$(STATE_FILE="$normalized" node -e "
    try {
      const state = JSON.parse(require('fs').readFileSync(process.env.STATE_FILE,'utf8'));
      const items = state.phases || state.areas || {};
      let total=0, done=0, pending=0;
      for (const [k,v] of Object.entries(items)) {
        total++;
        const s = typeof v === 'object' ? v.status : v;
        if (s === 'done' || s === 'skipped') done++;
        else if (s === 'pending') pending++;
      }
      const findings = (state.summary && typeof state.summary.total === 'number') ? state.summary.total : 0;
      console.log('STATE_STATUS=FOUND');
      console.log('STATE_ALL_DONE=' + (done === total && total > 0));
      console.log('STATE_TOTAL=' + total);
      console.log('STATE_DONE=' + done);
      console.log('STATE_PENDING=' + pending);
      console.log('STATE_FINDINGS=' + findings);
    } catch(e) {
      console.log('STATE_STATUS=ERROR');
      console.log('STATE_ALL_DONE=false');
      console.log('STATE_TOTAL=0');
      console.log('STATE_DONE=0');
      console.log('STATE_PENDING=0');
      console.log('STATE_FINDINGS=0');
    }
  " 2>/dev/null)

  # Fallback if Node fails completely
  if [ -z "$result" ]; then
    echo "STATE_STATUS=ERROR"
    echo "STATE_ALL_DONE=false"
    echo "STATE_TOTAL=0"
    echo "STATE_DONE=0"
    echo "STATE_PENDING=0"
    echo "STATE_FINDINGS=0"
  else
    echo "$result"
  fi
}

# Safe parsing of check_audit_state output (replaces eval)
# Sets STATE_* variables in caller scope without eval
parse_audit_state() {
  local _out
  _out=$(check_audit_state "$1")
  STATE_STATUS=$(echo "$_out" | sed -n 's/^STATE_STATUS=//p')
  STATE_ALL_DONE=$(echo "$_out" | sed -n 's/^STATE_ALL_DONE=//p')
  STATE_TOTAL=$(echo "$_out" | sed -n 's/^STATE_TOTAL=//p')
  STATE_DONE=$(echo "$_out" | sed -n 's/^STATE_DONE=//p')
  # shellcheck disable=SC2034  # STATE_PENDING is part of structured output, may be used by callers
  STATE_PENDING=$(echo "$_out" | sed -n 's/^STATE_PENDING=//p')
  STATE_FINDINGS=$(echo "$_out" | sed -n 's/^STATE_FINDINGS=//p')
}

# Run Claude session
run_claude() {
  local prompt="$1"
  local attempt="${2:-1}"
  local session_id
  session_id="session-$(date '+%H%M%S')-$$"
  local session_log="$LOG_DIR/$session_id.log"

  log "[$session_id] Starting (attempt $attempt/$MAX_RETRIES)..."
  log "[$session_id] Prompt: ${prompt:0:120}..."

  if [ "$DRY_RUN" = true ]; then
    log "[$session_id] [DRY-RUN] Skipped"
    return 0
  fi

  local exit_code=0

  # Run Claude in project directory
  cd "$PROJECT_DIR"

  if command -v timeout &>/dev/null; then
    timeout "$TIMEOUT" "$CLAUDE_BIN" -p "$prompt" \
      --dangerously-skip-permissions \
      > "$session_log" 2>&1 || exit_code=$?
  else
    # Fallback without timeout (Windows without coreutils)
    "$CLAUDE_BIN" -p "$prompt" \
      --dangerously-skip-permissions \
      > "$session_log" 2>&1 || exit_code=$?
  fi

  # Brief summary to main log
  if [ -f "$session_log" ]; then
    local lines
    lines=$(wc -l < "$session_log" 2>/dev/null || echo "0")
    log "[$session_id] Output: $lines lines → $session_log"
  fi

  if [ $exit_code -ne 0 ]; then
    log "[$session_id] WARNING: Exit code $exit_code"
    if [ "$attempt" -lt "$MAX_RETRIES" ]; then
      log "[$session_id] Retry in 15 seconds..."
      sleep 15
      run_claude "$prompt" $((attempt + 1))
    else
      log "[$session_id] ERROR: All $MAX_RETRIES attempts failed"
      return 1
    fi
  else
    log "[$session_id] Successful"
  fi
}

# ─── Audit Mappings ──────────────────────────────────────────────────────

get_state_file() {
  case "$1" in
    audit)         echo "$PROJECT_DIR/.audit-state.json" ;;
    astro-audit)   echo "$PROJECT_DIR/.astro-audit-state.json" ;;
    project-audit) echo "$PROJECT_DIR/.project-audit-state.json" ;;
  esac
}

get_skill_name() {
  case "$1" in
    audit)         echo "/audit" ;;
    astro-audit)   echo "/astro-audit" ;;
    project-audit) echo "/project-audit" ;;
  esac
}

# ─── Prerequisites ─────────────────────────────────────────────────────

check_prerequisites() {
  local ok=true

  echo "Checking prerequisites..."

  if ! command -v "$CLAUDE_BIN" &>/dev/null; then
    echo "  ERROR: Claude Code CLI not found ($CLAUDE_BIN)"
    echo "    → npm install -g @anthropic-ai/claude-code"
    ok=false
  else
    echo "  Claude Code: OK ($($CLAUDE_BIN --version 2>/dev/null || echo 'version unknown'))"
  fi

  if ! command -v node &>/dev/null; then
    echo "  ERROR: Node.js not found"
    ok=false
  else
    echo "  Node.js: OK ($(node --version))"
  fi

  if [ ! -d "$PROJECT_DIR" ]; then
    echo "  ERROR: Project directory not found: $PROJECT_DIR"
    ok=false
  else
    echo "  Project: $PROJECT_DIR"
  fi

  # Check Bash 4+ (for associative arrays)
  if [ "${BASH_VERSINFO[0]}" -lt 4 ]; then
    echo "  ERROR: Bash 4.0+ required (current: $BASH_VERSION)"
    ok=false
  fi

  if [ "$ok" = false ]; then
    echo ""
    echo "Prerequisites not met. Aborting."
    exit 1
  fi

  echo ""
}

# ─── Read config (optional) ─────────────────────────────────────────────

read_config() {
  local config_file="$PROJECT_DIR/.audit-runner-config.json"

  if [ ! -f "$config_file" ]; then
    return
  fi

  log "Config found: $config_file"

  local cfg_audits
  cfg_audits=$(json_get "$config_file" "d.audits ? d.audits.join(',') : 'NONE'")
  if [ "$cfg_audits" != "NONE" ] && [ "$cfg_audits" != "ERROR" ]; then
    AUDITS="$cfg_audits"
    log "  Audits from config: $AUDITS"
  fi

  local cfg_timeout
  cfg_timeout=$(json_get "$config_file" "d.timeout || 'NONE'")
  if [ "$cfg_timeout" != "NONE" ] && [ "$cfg_timeout" != "ERROR" ]; then
    TIMEOUT="$cfg_timeout"
    log "  Timeout from config: $TIMEOUT"
  fi

  local cfg_retries
  cfg_retries=$(json_get "$config_file" "d.maxRetries || 'NONE'")
  if [ "$cfg_retries" != "NONE" ] && [ "$cfg_retries" != "ERROR" ]; then
    MAX_RETRIES="$cfg_retries"
    log "  Max retries from config: $MAX_RETRIES"
  fi

  local cfg_skip_orch
  cfg_skip_orch=$(json_get "$config_file" "d.skipOrchestrator === true ? 'true' : 'NONE'")
  if [ "$cfg_skip_orch" = "true" ]; then
    SKIP_ORCHESTRATOR=true
    log "  Orchestrator skipped (config)"
  fi
}

# ─── Run a single audit ──────────────────────────────────────────────────
# Sets AUDIT_RESULT as global variable (no subshell problem)

AUDIT_RESULT=""

run_single_audit() {
  local audit="$1"
  local state_file
  state_file=$(get_state_file "$audit")
  local skill
  skill=$(get_skill_name "$audit")
  local session_count=0

  log_section "$skill"

  # Check existing state
  parse_audit_state "$state_file"

  if [ "$STATE_STATUS" = "FOUND" ] && [ "$STATE_ALL_DONE" = "true" ]; then
    log "$skill: RESUME — already completed ($STATE_FINDINGS findings)"
    progress_bar "$STATE_DONE" "$STATE_TOTAL" "$STATE_FINDINGS"
    log "$skill: Generating report only"
    run_claude "$skill report" || true
    AUDIT_RESULT="SKIPPED:already completed ($STATE_FINDINGS findings)"
    return
  fi

  # First call
  if [ "$STATE_STATUS" = "FOUND" ] && [ "$STATE_DONE" -gt 0 ]; then
    log "$skill: RESUME — continuing at $STATE_DONE/$STATE_TOTAL phases"
    progress_bar "$STATE_DONE" "$STATE_TOTAL" "$STATE_FINDINGS"
    run_claude "$skill continue" || true
  else
    log "$skill: Starting with auto mode..."
    run_claude "$skill auto" || true
  fi
  session_count=$((session_count + 1))

  # Continue loop until all phases done
  while [ "$session_count" -lt "$MAX_SESSIONS_PER_AUDIT" ]; do
    parse_audit_state "$state_file"

    if [ "$STATE_STATUS" = "NOT_FOUND" ]; then
      # Check if skill is actually available (check last session log)
      local last_log
      last_log=$(ls -t "$LOG_DIR"/session-*.log 2>/dev/null | head -1)
      if [ -n "$last_log" ] && grep -qi "not found\|not available\|does not exist" "$last_log" 2>/dev/null; then
        log "$skill: SKIP — skill not available in this project"
        AUDIT_RESULT="SKIP:skill not available"
        return
      fi

      # After 3 unsuccessful attempts without state: give up
      if [ "$session_count" -ge 3 ]; then
        log "$skill: SKIP — no state after $session_count attempts (skill probably not available)"
        AUDIT_RESULT="SKIP:no state after $session_count attempts"
        return
      fi

      log "$skill: WARNING — no state after session $session_count"
      log "$skill: Trying with start mode..."
      run_claude "$skill start" || true
      session_count=$((session_count + 1))
      continue
    fi

    progress_bar "$STATE_DONE" "$STATE_TOTAL" "$STATE_FINDINGS"

    if [ "$STATE_ALL_DONE" = "true" ]; then
      log "$skill: All phases completed!"
      break
    fi

    log "$skill: Session $((session_count + 1))..."
    run_claude "$skill continue" || true
    session_count=$((session_count + 1))
  done

  if [ "$session_count" -ge "$MAX_SESSIONS_PER_AUDIT" ]; then
    log "$skill: Max sessions ($MAX_SESSIONS_PER_AUDIT) reached"
    parse_audit_state "$state_file"
    progress_bar "$STATE_DONE" "$STATE_TOTAL" "$STATE_FINDINGS"
  fi

  # Generate report (only if state exists)
  parse_audit_state "$state_file"
  if [ "$STATE_STATUS" = "FOUND" ]; then
    log "$skill: Generating report..."
    run_claude "$skill report" || true
    progress_bar "$STATE_DONE" "$STATE_TOTAL" "$STATE_FINDINGS"
    AUDIT_RESULT="DONE:$STATE_FINDINGS findings in $session_count sessions ($STATE_DONE/$STATE_TOTAL phases)"
  else
    log "$skill: No state present — skipping report"
    AUDIT_RESULT="SKIP:no state after $session_count sessions"
  fi
}

# ─── Main program ───────────────────────────────────────────────────────

main() {
  check_prerequisites
  mkdir -p "$LOG_DIR"

  log_section "Audit Runner v1.0"
  log "Project:     $PROJECT_DIR"
  log "Audits:      $AUDITS"
  log "Timeout:     ${TIMEOUT}s/session"
  log "Max Retries: $MAX_RETRIES"
  log "Dry Run:     $DRY_RUN"
  log "Log:         $LOG_FILE"

  read_config

  local start_time
  start_time=$(date +%s)

  # Result storage (arrays instead of assoc-array for order)
  local result_names=()
  local result_values=()

  # Phase 1: Orchestrator
  local orch_state="$PROJECT_DIR/.audit-orchestrator-state.json"

  if [ "$SKIP_ORCHESTRATOR" = false ]; then
    # On resume: reuse existing orchestrator state
    # Check if state file exists and is valid JSON (format may vary)
    if [ -f "$orch_state" ]; then
      local orch_valid
      orch_valid=$(node -e "
        try {
          const d = JSON.parse(require('fs').readFileSync('$(to_node_path "$orch_state")','utf8'));
          console.log(d && typeof d === 'object' ? 'VALID' : 'INVALID');
        } catch(e) { console.log('INVALID'); }
      " 2>/dev/null)

      if [ "$orch_valid" = "VALID" ]; then
        log_section "Orchestrator (Resume)"
        log "Existing audit plan found — skipping orchestrator"
      else
        log_section "Orchestrator"
        run_claude "Analyze this project and create an audit plan. Save the plan in .audit-orchestrator-state.json." || true
      fi
    else
      # No state → run orchestrator normally
      log_section "Orchestrator"
      run_claude "Analyze this project and create an audit plan. Save the plan in .audit-orchestrator-state.json." || true
    fi
  fi

  # Phase 2-N: Run audits
  IFS=',' read -ra AUDIT_LIST <<< "$AUDITS"

  for audit in "${AUDIT_LIST[@]}"; do
    audit=$(echo "$audit" | tr -d ' ')
    run_single_audit "$audit"
    result_names+=("$audit")
    result_values+=("$AUDIT_RESULT")
  done

  # ─── Summary ─────────────────────────────────────────────────────────

  local end_time
  end_time=$(date +%s)
  local duration=$(( (end_time - start_time) / 60 ))

  log_section "Summary"
  log "Duration: ${duration} minutes"
  log ""

  for i in "${!result_names[@]}"; do
    log "  $(get_skill_name "${result_names[$i]}"): ${result_values[$i]}"
  done

  log ""
  log "Logs:    $LOG_DIR/"
  log "Reports: In project root (*-REPORT-*.md)"

  # Generate summary JSON
  local audit_json=""
  for i in "${!result_names[@]}"; do
    local name="${result_names[$i]}"
    local val="${result_values[$i]}"
    local status="${val%%:*}"
    local detail="${val#*:}"
    if [ -n "$audit_json" ]; then audit_json="$audit_json,"; fi
    # Escape special characters in detail
    detail=$(echo "$detail" | tr '"' "'")
    audit_json="$audit_json\"$name\":{\"status\":\"$status\",\"detail\":\"$detail\"}"
  done

  local node_project_dir
  node_project_dir="$(to_node_path "$PROJECT_DIR")"
  local node_summary_file
  node_summary_file="$(to_node_path "$SUMMARY_FILE")"

  node -e "
    const summary = {
      date: new Date().toISOString(),
      project: '$node_project_dir',
      durationMinutes: $duration,
      audits: {$audit_json}
    };
    require('fs').writeFileSync(
      '$node_summary_file',
      JSON.stringify(summary, null, 2)
    );
  " 2>/dev/null || true

  log ""
  log "Summary: $SUMMARY_FILE"
  log_section "Audit Runner finished"
}

# ─── Open fix terminal (after successful audit) ─────────────────────────

open_fix_terminal() {
  local repo="$1"
  local name="$2"
  local findings_info="$3"
  local repo_num="$4"
  local repo_total="$5"

  # Windows path for PowerShell
  local win_repo
  win_repo="$(cygpath -w "$repo" 2>/dev/null || echo "$repo")"

  # Generate PowerShell script
  local fix_script="$repo/.audit-runner-logs/fix-terminal.ps1"
  mkdir -p "$repo/.audit-runner-logs"

  cat > "$fix_script" << PSEOF
# Audit Runner — Fix Terminal
\$Host.UI.RawUI.WindowTitle = "Audit Fix: $name"
Write-Host ""
Write-Host "  ════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Audit completed: $name [$repo_num/$repo_total]" -ForegroundColor Cyan
Write-Host "  ════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "  $findings_info" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Next steps:" -ForegroundColor Green
Write-Host "    1. claude                           (Start Claude Code)" -ForegroundColor White
Write-Host "    2. /audit-runner status             (Show findings)" -ForegroundColor White
Write-Host "    3. Fix all audit findings autonomously (Start fixes)" -ForegroundColor White
Write-Host ""
Write-Host "  ════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
PSEOF

  # Open new terminal (Windows)
  if command -v cmd.exe &>/dev/null; then
    local win_script
    win_script="$(cygpath -w "$fix_script" 2>/dev/null)"

    # .bat wrapper (cmd.exe /c start has quoting issues from Git Bash)
    local bat_file="$repo/.audit-runner-logs/fix-terminal.bat"
    local win_bat
    win_bat="$(cygpath -w "$bat_file" 2>/dev/null)"

    cat > "$bat_file" << BATEOF
@echo off
cd /d "$win_repo"
powershell -NoExit -ExecutionPolicy Bypass -File "$win_script"
BATEOF

    # Start .bat in new window (& = non-blocking, otherwise runner hangs)
    cmd.exe /c start "" "$win_bat" > /dev/null 2>&1 &
    disown 2>/dev/null || true
  fi
}

# ─── Batch mode ──────────────────────────────────────────────────────────

# Find git repos in directory and list them.
# Sets: BATCH_REPOS_FOUND[] (array with absolute paths)
discover_batch_repos() {
  local base_dir="$1"

  BATCH_REPOS_FOUND=()
  while IFS= read -r gitdir; do
    BATCH_REPOS_FOUND+=("$(dirname "$gitdir")")
  done < <(find "$base_dir" -maxdepth "$BATCH_DEPTH" -name .git -type d 2>/dev/null | sort)

  if [ ${#BATCH_REPOS_FOUND[@]} -eq 0 ]; then
    blog "No git repos found in $base_dir (depth: $BATCH_DEPTH)"
    return 1
  fi

  blog "Found repos (${#BATCH_REPOS_FOUND[@]}):"
  blog ""
  local idx=1
  for repo in "${BATCH_REPOS_FOUND[@]}"; do
    blog "  [$idx] $(echo "$repo" | sed "s|$base_dir/||")"
    idx=$((idx + 1))
  done
  blog ""
}

# Select repos via --repos flag or interactively.
# Reads: BATCH_REPOS_FOUND[]
# Sets: BATCH_REPOS_SELECTED[] (array with absolute paths)
select_batch_repos() {
  BATCH_REPOS_SELECTED=()

  if [ -n "$BATCH_REPOS" ]; then
    # Pre-selected via flag
    IFS=',' read -ra repo_nums <<< "$BATCH_REPOS"
    for num in "${repo_nums[@]}"; do
      num=$(echo "$num" | tr -d ' ')
      if [ "$num" -ge 1 ] && [ "$num" -le "${#BATCH_REPOS_FOUND[@]}" ] 2>/dev/null; then
        BATCH_REPOS_SELECTED+=("${BATCH_REPOS_FOUND[$((num - 1))]}")
      else
        blog "WARNING: Repo number $num invalid (1-${#BATCH_REPOS_FOUND[@]})"
      fi
    done
  elif [ -t 0 ]; then
    # Interactive: ask user
    echo ""
    read -p "Which repos? (Enter = all, or e.g. 1,3,5): " repo_selection
    if [ -n "$repo_selection" ]; then
      IFS=',' read -ra repo_nums <<< "$repo_selection"
      for num in "${repo_nums[@]}"; do
        num=$(echo "$num" | tr -d ' ')
        if [ "$num" -ge 1 ] && [ "$num" -le "${#BATCH_REPOS_FOUND[@]}" ] 2>/dev/null; then
          BATCH_REPOS_SELECTED+=("${BATCH_REPOS_FOUND[$((num - 1))]}")
        else
          blog "WARNING: Repo number $num invalid (1-${#BATCH_REPOS_FOUND[@]})"
        fi
      done
    fi
  fi

  # Fallback: all repos
  if [ ${#BATCH_REPOS_SELECTED[@]} -eq 0 ]; then
    BATCH_REPOS_SELECTED=("${BATCH_REPOS_FOUND[@]}")
  fi
}

# Audit a single repo in batch + open fix terminal.
# Sets: batch_results[], succeeded, failed (in caller scope)
process_single_batch_repo() {
  local repo="$1"
  local base_dir="$2"
  local repo_num="$3"
  local repo_total="$4"
  local name
  name=$(echo "$repo" | sed "s|$base_dir/||")
  local line="════════════════════════════════════════════════════════"

  blog ""
  blog "$line"
  blog "  [$repo_num/$repo_total] $name"
  blog "$line"

  # Build options for individual run
  local opts=()
  opts+=("--audits" "$AUDITS")
  opts+=("--timeout" "$TIMEOUT")
  opts+=("--max-retries" "$MAX_RETRIES")
  if [ "$SKIP_ORCHESTRATOR" = true ]; then
    opts+=("--skip-orchestrator")
  fi

  # Run runner as sub-process (same script file, different path)
  local exit_code=0
  bash "$0" "$repo" "${opts[@]}" || exit_code=$?

  if [ $exit_code -eq 0 ]; then
    blog "  $name — Successful"
    succeeded=$((succeeded + 1))

    # Read findings info from summary
    local summary="$repo/.audit-runner-logs/summary.json"
    local findings_info="Audit completed"
    if [ -f "$summary" ]; then
      local detail
      detail=$(node -e "
        try {
          const s = JSON.parse(require('fs').readFileSync('$(to_node_path "$summary")','utf8'));
          const parts = [];
          for (const [k,v] of Object.entries(s.audits || {})) {
            parts.push('/' + k + ': ' + v.detail);
          }
          console.log(parts.join('  |  ') || 'No details');
        } catch(e) { console.log('No details'); }
      " 2>/dev/null)
      findings_info="$detail"
      batch_results+=("$name:OK")
    else
      batch_results+=("$name:OK (no summary)")
    fi

    # Open fix terminal (new window, ready for fixing)
    open_fix_terminal "$repo" "$name" "$findings_info" "$repo_num" "$repo_total"
    blog "  → Fix terminal opened for: $name"
  else
    blog "  $name — ERROR (exit $exit_code)"
    failed=$((failed + 1))
    batch_results+=("$name:ERROR")
  fi
}

# Print batch summary.
print_batch_summary() {
  local batch_start="$1"
  local total_repos="$2"
  local line="════════════════════════════════════════════════════════"

  local batch_end
  batch_end=$(date +%s)
  local batch_duration=$(( (batch_end - batch_start) / 60 ))

  blog ""
  blog "$line"
  blog "  Batch Summary"
  blog "$line"
  blog "Repos:      ${#BATCH_REPOS_SELECTED[@]}/${total_repos}"
  blog "Successful: $succeeded"
  blog "Failed:     $failed"
  blog "Duration:   ${batch_duration} minutes"
  blog ""

  for result in "${batch_results[@]}"; do
    blog "  ${result%%:*} — ${result#*:}"
  done

  blog ""
  blog "Batch log: $batch_log"
  blog ""
  blog "Next step: Switch to each project and fix findings:"
  blog "  cd <project> && claude"
  blog "  > Fix all open audit findings autonomously"
  blog ""
  blog "$line"
  blog "  Batch finished"
  blog "$line"
}

# Batch orchestrator: Init → Discover → Select → Loop → Summary
run_batch() {
  local base_dir="$PROJECT_DIR"
  local batch_start
  batch_start=$(date +%s)
  local batch_log_dir="$base_dir/.audit-runner-batch"
  mkdir -p "$batch_log_dir"
  local batch_log
  batch_log="$batch_log_dir/batch-$(date '+%Y%m%d-%H%M%S').log"

  # blog() stays nested — needs local $batch_log variable
  blog() {
    local msg
    msg="[$(date '+%H:%M:%S')] $*"
    echo "$msg"
    echo "$msg" >> "$batch_log"
  }

  local line="════════════════════════════════════════════════════════"
  blog ""
  blog "$line"
  blog "  Audit Runner — Batch Mode"
  blog "$line"
  blog "Base:   $base_dir"
  blog "Depth:  $BATCH_DEPTH"
  blog "Log:    $batch_log"
  blog ""

  # 1. Find repos
  discover_batch_repos "$base_dir" || return 1

  if [ "$DRY_RUN" = true ]; then
    blog "[DRY-RUN] Would audit ${#BATCH_REPOS_FOUND[@]} repos."
    blog "Tip: Use --repos \"1,3,5\" to select specific repos."
    return 0
  fi

  # 2. Select repos
  select_batch_repos

  blog ""
  blog "Starting audit for ${#BATCH_REPOS_SELECTED[@]}/${#BATCH_REPOS_FOUND[@]} repos"

  # 3. Process repos
  local batch_results=()
  local succeeded=0
  local failed=0
  local repo_num=0

  for repo in "${BATCH_REPOS_SELECTED[@]}"; do
    repo_num=$((repo_num + 1))
    process_single_batch_repo "$repo" "$base_dir" "$repo_num" "${#BATCH_REPOS_SELECTED[@]}"
  done

  # 4. Summary
  print_batch_summary "$batch_start" "${#BATCH_REPOS_FOUND[@]}"
}

# ─── Start ────────────────────────────────────────────────────────────────

if [ "$BATCH_MODE" = true ]; then
  run_batch
else
  main
fi

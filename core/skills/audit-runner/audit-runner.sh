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

# shellcheck disable=SC2034  # BATCH_DEPTH, BATCH_REPOS used in audit-batch.sh
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

# ─── Load audit-runner modules ─────────────────────────────────────────
_AUDIT_RUNNER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=audit-lib.sh
source "$_AUDIT_RUNNER_DIR/audit-lib.sh"
# shellcheck source=audit-batch.sh
source "$_AUDIT_RUNNER_DIR/audit-batch.sh"
unset _AUDIT_RUNNER_DIR

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

# ─── Start ────────────────────────────────────────────────────────────────

if [ "$BATCH_MODE" = true ]; then
  run_batch
else
  main
fi

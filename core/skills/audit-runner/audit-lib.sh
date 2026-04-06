#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────
# audit-lib.sh — Shared functions for the Audit Runner
# ─────────────────────────────────────────────────────────────────────────
# Sourced by audit-runner.sh. Provides: logging, state management,
# Claude session runner, audit mappings, prerequisites, config loading.
#
# Globals expected (set by audit-runner.sh before sourcing):
#   LOG_FILE, LOG_DIR, DRY_RUN, TIMEOUT, CLAUDE_BIN, MAX_RETRIES, PROJECT_DIR
# ─────────────────────────────────────────────────────────────────────────

# Include guard
[ -n "${_AUDIT_LIB_SH_LOADED:-}" ] && return 0
_AUDIT_LIB_SH_LOADED=1

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
# Uses dot-path access (e.g., "audits", "timeout") — no eval.
json_get() {
  local file="$1"
  local key="$2"
  local normalized
  normalized="$(to_node_path "$file")"
  JSON_FILE="$normalized" JSON_KEY="$key" node -e "
    try {
      const d = JSON.parse(require('fs').readFileSync(process.env.JSON_FILE,'utf8'));
      const key = process.env.JSON_KEY;
      const val = key.split('.').reduce((o, k) => o && o[k], d);
      if (val === undefined || val === null) { console.log('NONE'); }
      else if (Array.isArray(val)) { console.log(val.join(',')); }
      else if (typeof val === 'object') { console.log(JSON.stringify(val)); }
      else { console.log(String(val)); }
    } catch(e) { console.log('ERROR'); }
  "
}

# ─── State Management ─────────────────────────────────────────────────────

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
# shellcheck disable=SC2034  # STATE_* variables are used by callers in audit-runner.sh
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

# ─── Claude Session Runner ────────────────────────────────────────────────

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
  cd "$PROJECT_DIR" || return 1

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
  cfg_audits=$(json_get "$config_file" "audits")
  if [ "$cfg_audits" != "NONE" ] && [ "$cfg_audits" != "ERROR" ]; then
    AUDITS="$cfg_audits"
    log "  Audits from config: $AUDITS"
  fi

  local cfg_timeout
  cfg_timeout=$(json_get "$config_file" "timeout")
  if [ "$cfg_timeout" != "NONE" ] && [ "$cfg_timeout" != "ERROR" ]; then
    TIMEOUT="$cfg_timeout"
    log "  Timeout from config: $TIMEOUT"
  fi

  local cfg_retries
  cfg_retries=$(json_get "$config_file" "maxRetries")
  if [ "$cfg_retries" != "NONE" ] && [ "$cfg_retries" != "ERROR" ]; then
    MAX_RETRIES="$cfg_retries"
    log "  Max retries from config: $MAX_RETRIES"
  fi

  local cfg_skip_orch
  cfg_skip_orch=$(json_get "$config_file" "skipOrchestrator")
  if [ "$cfg_skip_orch" = "true" ]; then
    # shellcheck disable=SC2034
    SKIP_ORCHESTRATOR=true
    log "  Orchestrator skipped (config)"
  fi
}

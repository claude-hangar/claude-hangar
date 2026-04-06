#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────
# audit-batch.sh — Batch mode and Windows fix terminal for the Audit Runner
# ─────────────────────────────────────────────────────────────────────────
# Sourced by audit-runner.sh. Provides: batch discovery, selection,
# per-repo processing, summary, and Windows fix terminal generation.
#
# Globals expected (set by audit-runner.sh before sourcing):
#   PROJECT_DIR, BATCH_DEPTH, DRY_RUN, AUDITS, TIMEOUT, MAX_RETRIES,
#   SKIP_ORCHESTRATOR, BATCH_REPOS
# Globals from audit-lib.sh: blog uses BATCH_LOG_FILE
# ─────────────────────────────────────────────────────────────────────────

# Include guard
[ -n "${_AUDIT_BATCH_SH_LOADED:-}" ] && return 0
_AUDIT_BATCH_SH_LOADED=1

# ─── Batch logging ────────────────────────────────────────────────────────

# Set by run_batch() before any batch function is called
BATCH_LOG_FILE=""

blog() {
  local msg
  msg="[$(date '+%H:%M:%S')] $*"
  echo "$msg"
  [ -n "$BATCH_LOG_FILE" ] && echo "$msg" >> "$BATCH_LOG_FILE"
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
    read -rp "Which repos? (Enter = all, or e.g. 1,3,5): " repo_selection
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
  blog "Batch log: $BATCH_LOG_FILE"
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
  BATCH_LOG_FILE="$batch_log_dir/batch-$(date '+%Y%m%d-%H%M%S').log"

  local line="════════════════════════════════════════════════════════"
  blog ""
  blog "$line"
  blog "  Audit Runner — Batch Mode"
  blog "$line"
  blog "Base:   $base_dir"
  blog "Depth:  $BATCH_DEPTH"
  blog "Log:    $BATCH_LOG_FILE"
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

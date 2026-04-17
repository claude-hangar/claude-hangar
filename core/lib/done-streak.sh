#!/usr/bin/env bash
# Helper: DONE-Streak Convergence
# Pattern adopted from RepoLens: an autonomous agent signals "DONE" N times
# consecutively to trigger termination. Prevents premature exits on the first
# "I think I'm done" and prevents infinite loops by demanding stable consensus.
#
# Usage (from a loop-operator or /loop consumer):
#
#   source "$HOME/.claude/lib/done-streak.sh"
#   done_streak_init "my-task"              # Initialize streak state
#   done_streak_tick "my-task" "DONE"       # Increment when agent says DONE
#   done_streak_tick "my-task" "WORKING"    # Reset when agent is working
#   if done_streak_reached "my-task"; then  # Check if N-streak hit
#     echo "Terminated after stable DONE streak"
#   fi
#
# Default streak target: 3 (override via HANGAR_DONE_STREAK_N).
# State is stored in ~/.claude/.streaks/<id>.count for per-task isolation.

# No set -euo pipefail — must be source-able safely

_HANGAR_STREAK_DIR="$HOME/.claude/.streaks"
_HANGAR_STREAK_N="${HANGAR_DONE_STREAK_N:-3}"

done_streak_init() {
  local id="${1:-default}"
  mkdir -p "$_HANGAR_STREAK_DIR" 2>/dev/null
  printf '0' > "$_HANGAR_STREAK_DIR/${id}.count"
}

done_streak_tick() {
  local id="${1:-default}"
  local signal="${2:-}"
  local file="$_HANGAR_STREAK_DIR/${id}.count"
  mkdir -p "$_HANGAR_STREAK_DIR" 2>/dev/null
  local current=0
  [ -f "$file" ] && current=$(cat "$file" 2>/dev/null || echo 0)
  case "$signal" in
    DONE|done|COMPLETE|complete)
      current=$(( current + 1 ))
      ;;
    *)
      current=0
      ;;
  esac
  printf '%s' "$current" > "$file"
  printf '%s\n' "$current"
}

done_streak_reached() {
  local id="${1:-default}"
  local file="$_HANGAR_STREAK_DIR/${id}.count"
  local current=0
  [ -f "$file" ] && current=$(cat "$file" 2>/dev/null || echo 0)
  [ "$current" -ge "$_HANGAR_STREAK_N" ]
}

done_streak_reset() {
  local id="${1:-default}"
  local file="$_HANGAR_STREAK_DIR/${id}.count"
  printf '0' > "$file" 2>/dev/null
}

done_streak_count() {
  local id="${1:-default}"
  local file="$_HANGAR_STREAK_DIR/${id}.count"
  [ -f "$file" ] && cat "$file" 2>/dev/null || printf '0'
}

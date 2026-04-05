#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────
# common.sh — Shared shell functions for Claude Hangar
# ─────────────────────────────────────────────────────────────────────────
# Loaded by setup.sh, audit-runner.sh and other scripts via source.
# Contains: Color codes, logging, OS detection, path conversion.
#
# Usage:
#   source "$SCRIPT_DIR/core/lib/common.sh"
#   # or after deploy:
#   source "$HOME/.claude/lib/common.sh"
# ─────────────────────────────────────────────────────────────────────────

# Include guard — prevents double loading
[ -n "${_COMMON_SH_LOADED:-}" ] && return 0
_COMMON_SH_LOADED=1

# ─── Color codes ────────────────────────────────────────────────────────
# shellcheck disable=SC2034
RED='\033[0;31m'
# shellcheck disable=SC2034
GREEN='\033[0;32m'
# shellcheck disable=SC2034
YELLOW='\033[1;33m'
# shellcheck disable=SC2034
BLUE='\033[0;34m'
# shellcheck disable=SC2034
CYAN='\033[0;36m'
# shellcheck disable=SC2034
BOLD='\033[1m'
# shellcheck disable=SC2034
DIM='\033[2m'
# shellcheck disable=SC2034
NC='\033[0m'

# ─── Standard logging ──────────────────────────────────────────────────

info()    { echo -e "${CYAN}[i]${NC} $*"; }
success() { echo -e "${GREEN}[+]${NC} $*"; }
warn()    { echo -e "${YELLOW}[!]${NC} $*"; }
error()   { echo -e "${RED}[x]${NC} $*"; }

# ─── OS detection ──────────────────────────────────────────────────────

detect_os() {
  case "$(uname -s)" in
    Linux*)  echo "linux" ;;
    MINGW*|MSYS*|CYGWIN*) echo "windows" ;;
    Darwin*) echo "macos" ;;
    *)       echo "unknown" ;;
  esac
}

# ─── Path conversion (Git Bash → Windows) ─────────────────────────────
# /d/projects/... → D:/projects/... (Node.js doesn't understand /d/...)

to_node_path() {
  local p="$1"
  if command -v cygpath &>/dev/null; then
    cygpath -m "$p"
  else
    echo "$p" | tr '\\' '/'
  fi
}

# ─── Prerequisite check ───────────────────────────────────────────────
# Note: jq is NOT required — hooks use node -e for cross-platform JSON.

check_prereqs() {
  local missing=()
  command -v git &>/dev/null || missing+=("git")
  command -v node &>/dev/null || missing+=("node")

  if [ ${#missing[@]} -gt 0 ]; then
    error "Missing prerequisites: ${missing[*]}"
    echo "  Install them first, then re-run setup."
    return 1
  fi
  return 0
}

# ─── Cross-platform stat (file mtime as epoch) ───────────────────────

file_mtime() {
  stat -c %Y "$1" 2>/dev/null || stat -f %m "$1" 2>/dev/null || echo "0"
}

# ─── Hook Profile Check ──────────────────────────────────────────────

# Check if current hook should run based on profile
# Usage: should_hook_run "hook-name" "minimal|standard|strict" || exit 0
should_hook_run() {
  local hook_name="$1"
  local min_profile="${2:-standard}"
  local current_profile="${HANGAR_HOOK_PROFILE:-standard}"

  # Check disabled hooks list
  if [ -n "${HANGAR_DISABLED_HOOKS:-}" ]; then
    echo "$HANGAR_DISABLED_HOOKS" | tr ',' '\n' | grep -qx "$hook_name" && return 1
  fi

  # Profile hierarchy: minimal < standard < strict
  case "$min_profile" in
    minimal) return 0 ;;  # Always runs
    standard)
      [ "$current_profile" = "minimal" ] && return 1
      return 0
      ;;
    strict)
      [ "$current_profile" = "strict" ] && return 0
      return 1
      ;;
  esac
}

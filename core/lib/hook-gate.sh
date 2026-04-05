#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────
# hook-gate.sh — Runtime profile gate for hooks
# ─────────────────────────────────────────────────────────────────────────
# Source this at the top of any hook AFTER setting HOOK_NAME and HOOK_MIN_PROFILE.
# If the hook should not run (wrong profile or explicitly disabled), this
# script calls `exit 0` — the hook exits silently.
#
# Usage (add to top of any hook):
#   HOOK_NAME="bash-guard"; HOOK_MIN_PROFILE="minimal"
#   source "${HOME}/.claude/lib/hook-gate.sh" 2>/dev/null || true
#
# Environment variables:
#   HANGAR_HOOK_PROFILE   — minimal | standard | strict (default: standard)
#   HANGAR_DISABLED_HOOKS — Comma-separated hook names to skip
# ─────────────────────────────────────────────────────────────────────────

# Profile not set → standard (default)
_HG_PROFILE="${HANGAR_HOOK_PROFILE:-standard}"

# Check disabled list first (fastest path)
if [ -n "${HANGAR_DISABLED_HOOKS:-}" ]; then
  case ",$HANGAR_DISABLED_HOOKS," in
    *,"${HOOK_NAME:-}",*) exit 0 ;;
  esac
fi

# Profile hierarchy: minimal(1) < standard(2) < strict(3)
_hg_level() {
  case "$1" in
    minimal)  echo 1 ;;
    strict)   echo 3 ;;
    *)        echo 2 ;;  # standard is default
  esac
}

_HG_CURRENT=$(_hg_level "$_HG_PROFILE")
_HG_REQUIRED=$(_hg_level "${HOOK_MIN_PROFILE:-standard}")

# Skip if current profile level is below required level
[ "$_HG_CURRENT" -lt "$_HG_REQUIRED" ] && exit 0

# Clean up temp variables
unset _HG_PROFILE _HG_CURRENT _HG_REQUIRED

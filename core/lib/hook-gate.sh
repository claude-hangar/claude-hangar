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

# ─────────────────────────────────────────────────────────────────────────
# Hook Manifest Override (optional)
# ─────────────────────────────────────────────────────────────────────────
# If ~/.claude/lib/hook-manifest.json exists and contains an entry for this
# hook, it can override the profile gate and provide per-hook options.
# The manifest is OPTIONAL — without it, everything works as before.
_HG_MANIFEST="${HOME}/.claude/lib/hook-manifest.json"

if [ -f "$_HG_MANIFEST" ] && [ -n "${HOOK_NAME:-}" ]; then
  # Parse manifest entry for this hook via node (cross-platform, no jq)
  _HG_MANIFEST_ENTRY=$(node -e "
    try {
      const m = require('$_HG_MANIFEST');
      const h = (m.hooks || {})[process.argv[1]];
      if (h) console.log(JSON.stringify(h));
    } catch(_) {}
  " "$HOOK_NAME" 2>/dev/null || true)

  if [ -n "$_HG_MANIFEST_ENTRY" ]; then
    # Check enabled flag — if explicitly false, skip this hook
    _HG_ENABLED=$(node -e "
      const e = JSON.parse(process.argv[1]);
      console.log(e.enabled === false ? 'false' : 'true');
    " "$_HG_MANIFEST_ENTRY" 2>/dev/null || echo "true")

    if [ "$_HG_ENABLED" = "false" ]; then
      unset _HG_PROFILE _HG_CURRENT _HG_REQUIRED _HG_MANIFEST _HG_MANIFEST_ENTRY _HG_ENABLED
      exit 0
    fi

    # Override profile if manifest specifies one
    _HG_MANIFEST_PROFILE=$(node -e "
      const e = JSON.parse(process.argv[1]);
      if (e.profile) console.log(e.profile);
    " "$_HG_MANIFEST_ENTRY" 2>/dev/null || true)

    if [ -n "$_HG_MANIFEST_PROFILE" ]; then
      _HG_MANIFEST_REQUIRED=$(_hg_level "$_HG_MANIFEST_PROFILE")
      if [ "$_HG_CURRENT" -lt "$_HG_MANIFEST_REQUIRED" ]; then
        unset _HG_PROFILE _HG_CURRENT _HG_REQUIRED _HG_MANIFEST _HG_MANIFEST_ENTRY _HG_ENABLED _HG_MANIFEST_PROFILE _HG_MANIFEST_REQUIRED
        exit 0
      fi
      unset _HG_MANIFEST_REQUIRED
    fi

    # Export options as HOOK_OPTIONS env var (JSON string) if present
    _HG_OPTIONS=$(node -e "
      const e = JSON.parse(process.argv[1]);
      if (e.options && Object.keys(e.options).length > 0) console.log(JSON.stringify(e.options));
    " "$_HG_MANIFEST_ENTRY" 2>/dev/null || true)

    if [ -n "$_HG_OPTIONS" ]; then
      export HOOK_OPTIONS="$_HG_OPTIONS"
    fi

    unset _HG_ENABLED _HG_MANIFEST_PROFILE _HG_OPTIONS
  fi

  unset _HG_MANIFEST_ENTRY
fi

unset _HG_MANIFEST

# Clean up temp variables
unset _HG_PROFILE _HG_CURRENT _HG_REQUIRED

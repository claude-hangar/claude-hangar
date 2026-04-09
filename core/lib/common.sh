#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────
# common.sh — Shared shell functions for Claude Hangar
# ─────────────────────────────────────────────────────────────────────────
# Loaded by setup.sh, audit-runner.sh and other scripts via source.
# Contains: Color codes, logging, OS detection, path conversion,
#           BOM-safe JSON reading, atomic file writes, Node.js helpers.
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

# ─── BOM-safe JSON reading ───────────────────────────────────────────
# Windows editors (Notepad, PowerShell) often save UTF-8 files with a
# Byte Order Mark (\xEF\xBB\xBF = U+FEFF). This invisible prefix causes
# "Unexpected token" / "InvalidSymbol at offset 0" when parsing JSON.
#
# Usage (bash):
#   content=$(strip_bom < "$file")
#   data=$(read_json_file "$file")
#
# Usage (inline node -e in hooks):
#   const data = safeParseJSON(fs.readFileSync(file, 'utf8'));
#   — where safeParseJSON is: JSON.parse(s.replace(/^\uFEFF/, ''))

strip_bom() {
  # Read stdin and strip UTF-8 BOM if present (first 3 bytes: EF BB BF)
  node -e "
    process.stdin.setEncoding('utf8');
    let d='';
    process.stdin.on('data', c => d += c);
    process.stdin.on('end', () => process.stdout.write(d.replace(/^\uFEFF/, '')));
  "
}

read_json_file() {
  # Read a JSON file, strip BOM, parse and re-serialize (validates JSON)
  # Returns clean JSON on stdout, exits non-zero on parse error
  local file="$1"
  [ -f "$file" ] || { echo "{}"; return 0; }
  node -e "
    const fs = require('fs');
    const raw = fs.readFileSync(process.argv[1], 'utf8').replace(/^\uFEFF/, '');
    const data = JSON.parse(raw);
    process.stdout.write(JSON.stringify(data));
  " "$file"
}

# ─── Atomic file writes ─────────────────────────────────────────────
# Write content to a temporary file, then rename to target path.
# Prevents corruption if a process crashes or is killed mid-write.
# The temp file is created in the same directory as the target so that
# rename (mv) is atomic on the same filesystem.
#
# Usage (bash):
#   atomic_write "/path/to/state.json" "$json_content"
#
# Usage (inline node -e in hooks):
#   atomicWriteSync(target, content)
#   — see NODE_ATOMIC_WRITE below for the JS implementation

atomic_write() {
  local target="$1"
  local content="$2"
  local dir
  dir="$(dirname "$target")"
  # Ensure target directory exists
  [ -d "$dir" ] || mkdir -p "$dir"
  # Unique temp file: PID + RANDOM avoids collisions
  local tmp="${target}.tmp.$$.$RANDOM"
  if printf '%s' "$content" > "$tmp" && mv "$tmp" "$target"; then
    return 0
  else
    # Clean up failed temp file
    rm -f "$tmp" 2>/dev/null
    return 1
  fi
}

# ─── Node.js snippets for inline use in hooks ───────────────────────
# Hooks use `node -e` for JSON processing. These string constants hold
# reusable JS helper functions that hooks can prepend to their scripts.
#
# Usage in a hook:
#   node -e "
#     ${NODE_SAFE_JSON}
#     ${NODE_ATOMIC_WRITE}
#     const data = safeParseJSON(fs.readFileSync('state.json', 'utf8'));
#     data.count++;
#     atomicWriteSync('state.json', JSON.stringify(data));
#   "

# shellcheck disable=SC2034
NODE_SAFE_JSON='function safeParseJSON(s,fallback){try{return JSON.parse(s.replace(/^\uFEFF/,""));}catch(e){return fallback!==undefined?fallback:{};}}'

# shellcheck disable=SC2034
NODE_ATOMIC_WRITE='function atomicWriteSync(target,content){const fs=require("fs"),path=require("path"),tmp=target+".tmp."+process.pid+"."+Math.random().toString(36).slice(2);try{fs.writeFileSync(tmp,content);fs.renameSync(tmp,target);}catch(e){try{fs.unlinkSync(tmp);}catch(_){}throw e;}}'

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

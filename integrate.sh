#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────
# Claude Hangar — Stack Integration
# ─────────────────────────────────────────────────────────────────────────
# Add or remove framework stacks after initial setup.
#
# Usage:
#   bash integrate.sh <stack>           # Add a stack
#   bash integrate.sh --remove <stack>  # Remove a stack
#   bash integrate.sh --list            # List available and installed stacks
#   bash integrate.sh --help            # Show this help
# ─────────────────────────────────────────────────────────────────────────

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

# Source shared functions
source "$SCRIPT_DIR/core/lib/common.sh" 2>/dev/null || {
  RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
  CYAN='\033[0;36m'; NC='\033[0m'
  info()    { echo -e "${CYAN}[i]${NC} $*"; }
  success() { echo -e "${GREEN}[+]${NC} $*"; }
  warn()    { echo -e "${YELLOW}[!]${NC} $*"; }
  error()   { echo -e "${RED}[x]${NC} $*"; }
}

# ─── Stack Discovery ─────────────────────────────────────────────────

get_available_stacks() {
  for dir in "$SCRIPT_DIR"/stacks/*/; do
    [ -d "$dir" ] || continue
    basename "$dir"
  done
}

get_installed_stacks() {
  for dir in "$CLAUDE_DIR"/skills/*/; do
    [ -d "$dir" ] || continue
    local name
    name=$(basename "$dir")
    # A stack is "installed" if it exists in both stacks/ and skills/
    if [ -d "$SCRIPT_DIR/stacks/$name" ]; then
      echo "$name"
    fi
  done
}

is_stack_available() {
  [ -d "$SCRIPT_DIR/stacks/$1" ]
}

is_stack_installed() {
  [ -d "$CLAUDE_DIR/skills/$1" ] && [ -d "$SCRIPT_DIR/stacks/$1" ]
}

# ─── Operations ──────────────────────────────────────────────────────

add_stack() {
  local stack="$1"

  if ! is_stack_available "$stack"; then
    error "Unknown stack: $stack"
    echo ""
    echo "Available stacks:"
    get_available_stacks | while read -r s; do echo "  - $s"; done
    exit 1
  fi

  if is_stack_installed "$stack"; then
    warn "Stack '$stack' is already installed — updating..."
  fi

  # Deploy stack to skills directory
  mkdir -p "$CLAUDE_DIR/skills/$stack"
  cp -r "$SCRIPT_DIR/stacks/$stack/." "$CLAUDE_DIR/skills/$stack/"

  # Check for MCP config
  if [ -f "$SCRIPT_DIR/stacks/$stack/mcp.json" ]; then
    info "Stack has MCP configuration — merging..."
    if [ -f "$SCRIPT_DIR/core/mcp/install.sh" ]; then
      bash "$SCRIPT_DIR/core/mcp/install.sh" 2>/dev/null || warn "MCP merge skipped (install.sh failed)"
    fi
  fi

  success "Stack '$stack' integrated successfully"

  # Show post-install hint
  if [ -f "$SCRIPT_DIR/stacks/$stack/SKILL.md" ]; then
    echo ""
    info "Skill available: /$stack"
    info "Add the CLAUDE.md snippet to your project for stack-specific instructions."
    if [ -f "$SCRIPT_DIR/stacks/$stack/CLAUDE.md.snippet" ]; then
      info "Snippet: stacks/$stack/CLAUDE.md.snippet"
    fi
  fi
}

remove_stack() {
  local stack="$1"

  if ! is_stack_installed "$stack"; then
    error "Stack '$stack' is not installed"
    exit 1
  fi

  rm -rf "${CLAUDE_DIR:?}/skills/${stack:?}"
  success "Stack '$stack' removed"
  info "Note: MCP server configs may need manual cleanup in settings.json"
}

list_stacks() {
  echo ""
  echo "  Available Stacks"
  echo "  ────────────────"
  echo ""

  local available
  available=$(get_available_stacks)
  local installed
  installed=$(get_installed_stacks)

  for stack in $available; do
    local status="  "
    if echo "$installed" | grep -qx "$stack"; then
      status="[+]"
    else
      status="[ ]"
    fi

    # Read description from SKILL.md if available
    local desc=""
    if [ -f "$SCRIPT_DIR/stacks/$stack/SKILL.md" ]; then
      desc=$(grep -m1 "^description:" "$SCRIPT_DIR/stacks/$stack/SKILL.md" 2>/dev/null | sed 's/^description:\s*//' || echo "")
    fi

    printf "  %s %-12s %s\n" "$status" "$stack" "$desc"
  done

  echo ""
  echo "  [+] = installed    [ ] = available"
  echo ""
  echo "  Add:    bash integrate.sh <stack>"
  echo "  Remove: bash integrate.sh --remove <stack>"
}

# ─── Main ────────────────────────────────────────────────────────────

main() {
  echo ""
  echo "  Claude Hangar — Stack Integration"
  echo "  ──────────────────────────────────"
  echo ""

  if [ $# -eq 0 ]; then
    list_stacks
    exit 0
  fi

  case "$1" in
    --list|-l)
      list_stacks
      ;;
    --remove|-r)
      if [ -z "${2:-}" ]; then
        error "--remove requires a stack name"
        exit 1
      fi
      remove_stack "$2"
      ;;
    --help|-h)
      echo "Usage: bash integrate.sh [COMMAND] [STACK]"
      echo ""
      echo "Commands:"
      echo "  <stack>           Add/update a stack"
      echo "  --remove <stack>  Remove an installed stack"
      echo "  --list            List available and installed stacks"
      echo "  --help            Show this help"
      echo ""
      echo "Examples:"
      echo "  bash integrate.sh astro        # Add Astro stack"
      echo "  bash integrate.sh database     # Add Database (Drizzle) stack"
      echo "  bash integrate.sh --remove auth  # Remove Auth stack"
      ;;
    -*)
      error "Unknown flag: $1"
      echo "Use --help for usage"
      exit 1
      ;;
    *)
      add_stack "$1"
      ;;
  esac
}

main "$@"

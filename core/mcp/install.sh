#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────
# MCP Install Script — Merges stack MCP configs into ~/.claude/settings.json
# ─────────────────────────────────────────────────────────────────────────
# Called by setup.sh after deploying stacks.
#
# Usage:
#   bash core/mcp/install.sh [--check]
#
# Arguments:
#   --check    Dry-run — show what would be merged without changing settings.json
# ─────────────────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CLAUDE_DIR="$HOME/.claude"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"

# Source shared functions
# shellcheck source=core/lib/common.sh
source "$REPO_ROOT/core/lib/common.sh" 2>/dev/null || {
  info()    { echo "[i] $1"; }
  success() { echo "[+] $1"; }
  warn()    { echo "[!] $1"; }
  error()   { echo "[x] $1"; }
}

DRY_RUN=false
[ "${1:-}" = "--check" ] && DRY_RUN=true

# ─── Prerequisites ─────────────────────────────────────────────────────

if ! command -v npx &>/dev/null; then
  warn "npx not found — MCP servers require Node.js and npx"
  warn "Install Node.js (18+) to enable MCP server support"
  exit 0
fi

if [ ! -f "$SETTINGS_FILE" ]; then
  warn "settings.json not found at $SETTINGS_FILE — skipping MCP merge"
  exit 0
fi

# ─── Merge Stack MCPs ─────────────────────────────────────────────────

merge_mcp_configs() {
  local settings_path="$1"
  local stacks_dir="$REPO_ROOT/stacks"
  local merged=0
  local warnings=0

  # Convert path for Node.js on Windows
  local node_settings="$settings_path"
  if command -v cygpath &>/dev/null; then
    node_settings="$(cygpath -m "$settings_path")"
  fi

  for mcp_file in "$stacks_dir"/*/mcp.json; do
    [ -f "$mcp_file" ] || continue

    local stack_name
    stack_name=$(basename "$(dirname "$mcp_file")")

    local node_mcp="$mcp_file"
    if command -v cygpath &>/dev/null; then
      node_mcp="$(cygpath -m "$mcp_file")"
    fi

    if [ "$DRY_RUN" = true ]; then
      info "Would merge: stacks/$stack_name/mcp.json"
      merged=$((merged + 1))
      continue
    fi

    # Merge using Node.js (cross-platform, no jq dependency)
    local result
    result=$(node -e "
      const fs = require('fs');
      const settingsPath = '$node_settings';
      const mcpPath = '$node_mcp';

      const settings = JSON.parse(fs.readFileSync(settingsPath, 'utf8'));
      const stackMcp = JSON.parse(fs.readFileSync(mcpPath, 'utf8'));

      if (!settings.mcpServers) settings.mcpServers = {};

      let added = 0;
      for (const [id, config] of Object.entries(stackMcp)) {
        if (!settings.mcpServers[id]) {
          settings.mcpServers[id] = config;
          added++;
        }
      }

      fs.writeFileSync(settingsPath, JSON.stringify(settings, null, 2) + '\n');
      console.log(added);
    " 2>&1)

    if [ "$result" -gt 0 ] 2>/dev/null; then
      success "Merged: stacks/$stack_name/mcp.json ($result server(s))"
      merged=$((merged + result))
    else
      info "Stack $stack_name — MCP servers already configured"
    fi
  done

  # Check for unresolved placeholders
  local placeholders
  placeholders=$(node -e "
    const fs = require('fs');
    const s = JSON.parse(fs.readFileSync('$node_settings', 'utf8'));
    const json = JSON.stringify(s.mcpServers || {});
    const re = /\{\{([A-Z][A-Z0-9_]*)\}\}/g;
    const found = [];
    let m;
    while ((m = re.exec(json)) !== null) found.push(m[1]);
    console.log([...new Set(found)].join(','));
  " 2>&1)

  if [ -n "$placeholders" ]; then
    echo ""
    warn "Unresolved MCP credential placeholders:"
    IFS=',' read -ra ADDR <<< "$placeholders"
    for p in "${ADDR[@]}"; do
      warn "  {{$p}} — set this environment variable before using the MCP server"
      warnings=$((warnings + 1))
    done
  fi

  echo ""
  if [ "$DRY_RUN" = true ]; then
    info "Dry run: $merged stack MCP config(s) would be merged"
  else
    success "MCP setup complete: $merged server(s) merged, $warnings warning(s)"
  fi
}

merge_mcp_configs "$SETTINGS_FILE"

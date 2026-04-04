#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────
# Claude Hangar — Setup Script
# ─────────────────────────────────────────────────────────────────────────
# Deploys hooks, agents, skills, statusline and CLAUDE.md to ~/.claude/
#
# Usage:
#   bash setup.sh              # Interactive wizard (first run) or sync
#   bash setup.sh --check      # Dry-run — validate without deploying
#   bash setup.sh --verify     # Verify existing installation
#   bash setup.sh --rollback   # Restore from backup
#   bash setup.sh --update     # git pull + sync
#   bash setup.sh --uninstall  # Remove Hangar-managed files (keeps user data)
# ─────────────────────────────────────────────────────────────────────────

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

# Source shared functions
# shellcheck source=core/lib/common.sh
source "$SCRIPT_DIR/core/lib/common.sh" 2>/dev/null || {
  # Inline fallback if common.sh not found
  RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
  CYAN='\033[0;36m'; NC='\033[0m'
  info()    { echo -e "${CYAN}[i]${NC} $1"; }
  success() { echo -e "${GREEN}[+]${NC} $1"; }
  warn()    { echo -e "${YELLOW}[!]${NC} $1"; }
  error()   { echo -e "${RED}[x]${NC} $1"; }
  detect_os() {
    case "$(uname -s)" in
      Linux*) echo "linux" ;; MINGW*|MSYS*|CYGWIN*) echo "windows" ;;
      Darwin*) echo "macos" ;; *) echo "unknown" ;;
    esac
  }
}

# shellcheck disable=SC2034  # OS used by deploy logic
OS=$(detect_os)

# ─── Prerequisites ─────────────────────────────────────────────────────

check_prerequisites() {
  local missing=()
  command -v git &>/dev/null || missing+=("git")
  command -v node &>/dev/null || missing+=("node")
  command -v npx &>/dev/null || missing+=("npx (optional, for MCP servers)")
  command -v jq &>/dev/null || missing+=("jq (optional, for statusline)")

  if [ ${#missing[@]} -gt 0 ]; then
    for m in "${missing[@]}"; do
      if [[ "$m" == *optional* ]]; then
        warn "Missing (optional): $m"
      else
        error "Missing: $m"
      fi
    done
    # Only fail on required deps
    command -v git &>/dev/null && command -v node &>/dev/null && return 0
    error "Install missing prerequisites, then re-run setup."
    return 1
  fi
  return 0
}

# ─── Validate Structure ───────────────────────────────────────────────

validate_structure() {
  local errors=0

  # Check required directories (core/skills may be empty initially)
  for dir in core/hooks core/agents core/lib core/mcp; do
    if [ ! -d "$SCRIPT_DIR/$dir" ]; then
      error "Missing directory: $dir"
      errors=$((errors + 1))
    fi
  done

  # Check required files
  for file in core/lib/common.sh core/statusline-command.sh core/settings.json.template core/CLAUDE.md.template; do
    if [ ! -f "$SCRIPT_DIR/$file" ]; then
      error "Missing file: $file"
      errors=$((errors + 1))
    fi
  done

  # Check hooks
  local hook_count
  hook_count=$(find "$SCRIPT_DIR/core/hooks" -name '*.sh' 2>/dev/null | wc -l)
  if [ "$hook_count" -lt 5 ]; then
    warn "Only $hook_count hooks found (expected 13+)"
  fi

  # Check agents
  local agent_count
  agent_count=$(find "$SCRIPT_DIR/core/agents" -name '*.md' 2>/dev/null | wc -l)
  if [ "$agent_count" -lt 3 ]; then
    warn "Only $agent_count agents found (expected 5+)"
  fi

  # Validate JSON files
  local json_errors=0
  while IFS= read -r file; do
    # Convert Git Bash paths to Windows paths for Node.js
    local node_file="$file"
    if [ "$OS" = "windows" ] && command -v cygpath &>/dev/null; then
      node_file="$(cygpath -m "$file")"
    fi
    if ! node -e "JSON.parse(require('fs').readFileSync('$node_file','utf8'))" 2>/dev/null; then
      error "Invalid JSON: $file"
      json_errors=$((json_errors + 1))
    fi
  done < <(find "$SCRIPT_DIR" -name '*.json' -not -path '*/.git/*' -not -path '*/node_modules/*')

  errors=$((errors + json_errors))

  if [ "$errors" -eq 0 ]; then
    success "Structure validation passed"
    return 0
  else
    error "$errors validation error(s) found"
    return 1
  fi
}

# ─── Deploy ────────────────────────────────────────────────────────────

deploy_component() {
  local src="$1"
  local dest="$2"
  local label="$3"

  if [ ! -e "$src" ]; then
    warn "Source not found: $src"
    return 1
  fi

  mkdir -p "$(dirname "$dest")"

  if [ -d "$src" ]; then
    cp -r "$src/." "$dest/"
  else
    cp "$src" "$dest"
  fi
  success "Deployed: $label"
}

# ─── MCP ──────────────────────────────────────────────────────────────

deploy_mcp() {
  if [ -f "$SCRIPT_DIR/core/mcp/install.sh" ]; then
    info "Configuring MCP servers..."
    bash "$SCRIPT_DIR/core/mcp/install.sh"
  fi
}

deploy_all() {
  info "Deploying to $CLAUDE_DIR..."

  # Backup existing config
  if [ -d "$CLAUDE_DIR" ] && [ ! -f "$CLAUDE_DIR/.hangar-backup-done" ]; then
    local backup_dir
    backup_dir="$CLAUDE_DIR/.backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$backup_dir"
    for item in hooks agents skills lib statusline-command.sh settings.json CLAUDE.md; do
      [ -e "$CLAUDE_DIR/$item" ] && cp -r "$CLAUDE_DIR/$item" "$backup_dir/" 2>/dev/null || true
    done
    success "Backed up existing config to $backup_dir"
    touch "$CLAUDE_DIR/.hangar-backup-done"
  fi

  # Deploy components
  mkdir -p "$CLAUDE_DIR"
  deploy_component "$SCRIPT_DIR/core/hooks" "$CLAUDE_DIR/hooks" "Hooks ($(find "$SCRIPT_DIR/core/hooks" -name '*.sh' | wc -l) scripts)"
  deploy_component "$SCRIPT_DIR/core/agents" "$CLAUDE_DIR/agents" "Agents ($(find "$SCRIPT_DIR/core/agents" -name '*.md' | wc -l) definitions)"
  deploy_component "$SCRIPT_DIR/core/skills" "$CLAUDE_DIR/skills" "Skills"
  deploy_component "$SCRIPT_DIR/core/lib" "$CLAUDE_DIR/lib" "Shared lib"
  deploy_component "$SCRIPT_DIR/core/statusline-command.sh" "$CLAUDE_DIR/statusline-command.sh" "Statusline"

  # Deploy stacks into skills
  if [ -d "$SCRIPT_DIR/stacks" ]; then
    for stack_dir in "$SCRIPT_DIR"/stacks/*/; do
      [ -d "$stack_dir" ] || continue
      local stack_name
      stack_name=$(basename "$stack_dir")
      [ "$stack_name" = "README.md" ] && continue
      deploy_component "$stack_dir" "$CLAUDE_DIR/skills/$stack_name" "Stack: $stack_name"
    done
  fi

  # Deploy MCP server configs from stacks
  deploy_mcp

  # Settings: merge or deploy template
  if [ ! -f "$CLAUDE_DIR/settings.json" ]; then
    # First install: deploy template (strip {{LANGUAGE}} placeholder)
    sed 's/{{LANGUAGE}}/English/' "$SCRIPT_DIR/core/settings.json.template" > "$CLAUDE_DIR/settings.json"
    success "Deployed: settings.json (from template)"
  else
    info "settings.json exists — skipping (manual merge recommended)"
  fi

  # Write version info
  local version_hash
  version_hash=$(git -C "$SCRIPT_DIR" rev-parse --short HEAD 2>/dev/null || echo "unknown")
  local version_date
  version_date=$(date '+%Y-%m-%d')
  echo "{\"hash\":\"$version_hash\",\"date\":\"$version_date\",\"source\":\"$SCRIPT_DIR\"}" > "$CLAUDE_DIR/.hangar-version"

  echo ""
  success "Deployment complete! (version: $version_hash)"
  info "Open Claude Code in any project to start using your new setup."
}

# ─── Main ──────────────────────────────────────────────────────────────

main() {
  echo ""
  echo "  Claude Hangar — Setup"
  echo "  ─────────────────────"
  echo ""

  case "${1:-}" in
    --check)
      info "Running dry-run validation..."
      check_prerequisites || exit 1
      validate_structure || exit 1
      success "All checks passed — ready to deploy"
      ;;

    --verify)
      info "Verifying installation..."
      if [ ! -d "$CLAUDE_DIR" ]; then
        error "\$HOME/.claude/ not found — run setup.sh first"
        exit 1
      fi
      local verified=0 total=0
      # Check version info
      if [ -f "$CLAUDE_DIR/.hangar-version" ]; then
        local ver
        ver=$(node -e "const d=JSON.parse(require('fs').readFileSync('$CLAUDE_DIR/.hangar-version','utf8'));console.log(d.hash+' ('+d.date+')')" 2>/dev/null || echo "unknown")
        info "Installed version: $ver"
      else
        warn "No version info found (.hangar-version missing)"
      fi
      for item in hooks/secret-leak-check.sh hooks/bash-guard.sh hooks/checkpoint.sh \
                  hooks/token-warning.sh hooks/session-start.sh hooks/session-stop.sh \
                  hooks/post-compact.sh hooks/config-change-guard.sh hooks/skill-suggest.sh \
                  hooks/model-router.sh hooks/task-completed-gate.sh hooks/subagent-tracker.sh \
                  hooks/stop-failure.sh hooks/permission-denied-retry.sh \
                  hooks/task-created-init.sh hooks/worktree-init.sh \
                  agents/explorer.md agents/explorer-deep.md \
                  agents/security-reviewer.md agents/commit-reviewer.md agents/dependency-checker.md \
                  agents/plan-reviewer.md agents/refactor-agent.md agents/test-writer.md \
                  statusline-command.sh lib/common.sh settings.json; do
        total=$((total + 1))
        if [ -f "$CLAUDE_DIR/$item" ]; then
          verified=$((verified + 1))
        else
          warn "Missing: ~/.claude/$item"
        fi
      done
      echo ""
      if [ "$verified" -eq "$total" ]; then
        success "Verification passed: $verified/$total components installed"
      else
        warn "Verification: $verified/$total components found"
      fi
      ;;

    --rollback)
      info "Looking for backups..."
      local latest_backup
      latest_backup=$(find "$CLAUDE_DIR" -maxdepth 1 -name '.backup-*' -type d 2>/dev/null | sort -r | head -1)
      if [ -z "$latest_backup" ]; then
        error "No backup found"
        exit 1
      fi
      info "Restoring from: $latest_backup"
      for item in hooks agents skills lib statusline-command.sh settings.json CLAUDE.md; do
        [ -e "$latest_backup/$item" ] && cp -r "$latest_backup/$item" "$CLAUDE_DIR/" 2>/dev/null || true
      done
      success "Rollback complete"
      ;;

    --update)
      info "Updating..."
      git -C "$SCRIPT_DIR" pull --ff-only || { error "git pull failed"; exit 1; }
      success "Repository updated"
      info "Re-running setup..."
      deploy_all
      ;;

    --sync)
      info "Syncing deployment — removing orphaned files..."
      if [ ! -d "$CLAUDE_DIR" ]; then
        error "\$HOME/.claude/ not found — run setup.sh first"
        exit 1
      fi

      local orphaned=0

      # Find orphaned hooks (in deployed but not in repo)
      for hook_file in "$CLAUDE_DIR"/hooks/*.sh; do
        [ -f "$hook_file" ] || continue
        local hook_name
        hook_name=$(basename "$hook_file")
        if [ ! -f "$SCRIPT_DIR/core/hooks/$hook_name" ]; then
          warn "Orphaned hook: $hook_name"
          rm -f "$hook_file"
          success "Removed: hooks/$hook_name"
          orphaned=$((orphaned + 1))
        fi
      done

      # Find orphaned backup files
      for backup_file in "$CLAUDE_DIR"/hooks/*.backup-* "$CLAUDE_DIR"/agents/*.backup-*; do
        [ -f "$backup_file" ] || continue
        rm -f "$backup_file"
        orphaned=$((orphaned + 1))
      done
      if [ "$orphaned" -gt 0 ]; then
        success "Cleaned $orphaned backup file(s)"
      fi

      # Find empty skill directories
      for skill_dir in "$CLAUDE_DIR"/skills/*/; do
        [ -d "$skill_dir" ] || continue
        if [ -z "$(ls -A "$skill_dir" 2>/dev/null)" ]; then
          warn "Empty skill directory: $(basename "$skill_dir")"
          rmdir "$skill_dir"
          orphaned=$((orphaned + 1))
        fi
      done

      if [ "$orphaned" -eq 0 ]; then
        success "No orphaned files found — deployment is clean"
      else
        success "Removed $orphaned orphaned item(s)"
      fi

      # Redeploy latest from repo
      info "Re-deploying from repo..."
      deploy_all
      ;;

    --uninstall)
      info "Uninstalling Claude Hangar..."
      if [ ! -d "$CLAUDE_DIR" ]; then
        error "\$HOME/.claude/ not found — nothing to uninstall"
        exit 1
      fi
      warn "This will remove Hangar-managed hooks, agents, skills, and lib."
      warn "User data (settings.json, CLAUDE.md, projects/, memory/) is preserved."
      echo ""
      read -rp "Continue? [y/N] " confirm
      if [[ ! "$confirm" =~ ^[yY]$ ]]; then
        info "Cancelled."
        exit 0
      fi
      # Remove Hangar-managed directories
      rm -rf "${CLAUDE_DIR:?}/hooks" "${CLAUDE_DIR:?}/agents" "${CLAUDE_DIR:?}/lib"
      rm -f "$CLAUDE_DIR/statusline-command.sh"
      rm -f "$CLAUDE_DIR/.hangar-version"
      # Remove Hangar-deployed skills (keep user-created ones)
      if [ -d "$CLAUDE_DIR/skills" ]; then
        for skill_dir in "$CLAUDE_DIR/skills"/*/; do
          [ -d "$skill_dir" ] || continue
          if [ -f "$skill_dir/SKILL.md" ]; then
            rm -rf "$skill_dir"
          fi
        done
      fi
      success "Claude Hangar uninstalled. User data preserved."
      info "To fully remove: rm -rf ~/.claude/"
      ;;

    --help|-h)
      echo "Usage: bash setup.sh [MODE]"
      echo ""
      echo "Modes:"
      echo "  (no args)    Interactive wizard (first run) or sync"
      echo "  --check      Dry-run validation"
      echo "  --verify     Verify existing installation"
      echo "  --sync       Remove orphaned files + redeploy"
      echo "  --rollback   Restore from backup"
      echo "  --update     git pull + redeploy"
      echo "  --uninstall  Remove Hangar files (preserves user data)"
      echo "  --help       Show this help"
      ;;

    *)
      check_prerequisites || exit 1
      validate_structure || exit 1
      deploy_all
      ;;
  esac
}

main "$@"

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
#   bash setup.sh --skills design,security   # Install only specific skill categories
#   bash setup.sh --minimal                  # Core only (hooks, agents, lib) — no skills
#   bash setup.sh --with hooks,agents,lib    # Install only specific components
#   bash setup.sh --without learning,contexts # Install everything except these
#   bash setup.sh --list-categories          # List available skill categories
#   bash setup.sh --list-components          # List available components
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
  command -v node &>/dev/null || missing+=("node (18+)")
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

  # Check Node.js minimum version (18+)
  if command -v node &>/dev/null; then
    local node_major
    node_major=$(node -e "console.log(process.versions.node.split('.')[0])" 2>/dev/null || echo "0")
    if [ "$node_major" -lt 18 ] 2>/dev/null; then
      error "Node.js $node_major.x detected — version 18+ required"
      error "Install a current LTS version from https://nodejs.org/"
      return 1
    fi
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
    warn "Only $hook_count hooks found (expected 27+)"
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

# ─── Deploy Rules ─────────────────────────────────────────────────────

deploy_rules() {
  info "Deploying rules..."
  local rules_src="$SCRIPT_DIR/rules"
  local rules_dst="$CLAUDE_DIR/rules"

  if [ ! -d "$rules_src" ]; then
    warn "No rules directory found — skipping"
    return 0
  fi

  mkdir -p "$rules_dst"

  # Copy common rules (always deployed)
  if [ -d "$rules_src/common" ]; then
    mkdir -p "$rules_dst/common"
    cp -r "$rules_src/common/"* "$rules_dst/common/" 2>/dev/null || true
    success "Common rules deployed"
  fi

  # Copy language-specific rules if they exist
  for lang_dir in "$rules_src"/*/; do
    local lang
    lang=$(basename "$lang_dir")
    [ "$lang" = "common" ] && continue
    [ ! -d "$lang_dir" ] && continue
    mkdir -p "$rules_dst/$lang"
    cp -r "$lang_dir"* "$rules_dst/$lang/" 2>/dev/null || true
    success "Rules deployed: $lang"
  done
}

# ─── Deploy Contexts ──────────────────────────────────────────────────

deploy_contexts() {
  info "Deploying context modes..."
  local ctx_src="$SCRIPT_DIR/core/contexts"
  local ctx_dst="$CLAUDE_DIR/contexts"

  if [ ! -d "$ctx_src" ]; then
    warn "No contexts directory found — skipping"
    return 0
  fi

  mkdir -p "$ctx_dst"
  cp "$ctx_src"/*.md "$ctx_dst/" 2>/dev/null || true
  success "Context modes deployed ($(ls -1 "$ctx_dst"/*.md 2>/dev/null | wc -l) modes)"
}

# ─── Initialize Learning System ───────────────────────────────────────

init_learning_system() {
  info "Initializing learning system..."
  mkdir -p "$CLAUDE_DIR/.patterns"
  mkdir -p "$CLAUDE_DIR/.instincts"
  mkdir -p "$CLAUDE_DIR/.metrics"
  success "Learning system directories initialized"
}

# ─── Skill Filtering ──────────────────────────────────────────────────

# List available skill categories from skills_index.json
list_categories() {
  local index_file="$SCRIPT_DIR/skills_index.json"
  if [ ! -f "$index_file" ]; then
    error "skills_index.json not found"
    return 1
  fi

  # Convert path for Node.js on Windows
  local node_file="$index_file"
  if [ "$OS" = "windows" ] && command -v cygpath &>/dev/null; then
    node_file="$(cygpath -m "$index_file")"
  fi

  echo ""
  echo "Available skill categories:"
  echo ""
  node -e "
    const idx = JSON.parse(require('fs').readFileSync('$node_file', 'utf8'));
    const cats = idx.categories;
    const maxLen = Math.max(...Object.keys(cats).map(k => k.length));
    for (const [cat, skills] of Object.entries(cats)) {
      const pad = ' '.repeat(maxLen - cat.length);
      console.log('  ' + cat + pad + ' (' + skills.length + '):  ' + skills.join(', '));
    }
  "
  echo ""
}

# Get skill IDs for given categories from skills_index.json
# Outputs one skill ID per line
get_skills_for_categories() {
  local categories="$1"
  local index_file="$SCRIPT_DIR/skills_index.json"

  # Convert path for Node.js on Windows
  local node_file="$index_file"
  if [ "$OS" = "windows" ] && command -v cygpath &>/dev/null; then
    node_file="$(cygpath -m "$index_file")"
  fi

  node -e "
    const idx = JSON.parse(require('fs').readFileSync('$node_file', 'utf8'));
    const requested = '$categories'.split(',').map(c => c.trim());
    const invalid = requested.filter(c => !idx.categories[c]);
    if (invalid.length > 0) {
      process.stderr.write('Unknown categories: ' + invalid.join(', ') + '\\n');
      process.stderr.write('Available: ' + Object.keys(idx.categories).join(', ') + '\\n');
      process.exit(1);
    }
    const skills = new Set();
    for (const cat of requested) {
      for (const s of idx.categories[cat]) skills.add(s);
    }
    for (const s of skills) console.log(s);
  "
}

# Deploy only selected skill directories (plus _shared)
deploy_filtered_skills() {
  local categories="$1"

  # Get matching skill IDs
  local skill_ids
  skill_ids=$(get_skills_for_categories "$categories") || return 1

  # Always deploy _shared
  if [ -d "$SCRIPT_DIR/core/skills/_shared" ]; then
    deploy_component "$SCRIPT_DIR/core/skills/_shared" "$CLAUDE_DIR/skills/_shared" "Skills: _shared (shared resources)"
  fi

  # Deploy each matching skill
  local count=0
  while IFS= read -r skill_id; do
    [ -z "$skill_id" ] && continue
    local skill_dir="$SCRIPT_DIR/core/skills/$skill_id"
    if [ -d "$skill_dir" ]; then
      deploy_component "$skill_dir" "$CLAUDE_DIR/skills/$skill_id" "Skill: $skill_id"
      count=$((count + 1))
    else
      warn "Skill directory not found: core/skills/$skill_id"
    fi
  done <<< "$skill_ids"

  success "Deployed $count skill(s) from categories: $categories"
}

# ─── Component Filtering ─────────────────────────────────────────────

# Available components for --with/--without (used in --list-components output)
# shellcheck disable=SC2034
AVAILABLE_COMPONENTS="hooks,agents,skills,lib,rules,contexts,references,mcp-server,statusline,learning"

# Check if a component should be deployed
# Usage: should_deploy "hooks" && deploy_hooks
should_deploy() {
  local component="$1"

  # --with takes precedence: only deploy listed components
  if [ -n "${INCLUDE_COMPONENTS:-}" ]; then
    echo ",$INCLUDE_COMPONENTS," | grep -q ",$component," && return 0
    return 1
  fi

  # --without: deploy everything except listed
  if [ -n "${EXCLUDE_COMPONENTS:-}" ]; then
    echo ",$EXCLUDE_COMPONENTS," | grep -q ",$component," && return 1
    return 0
  fi

  # No filter: deploy everything
  return 0
}

deploy_all() {
  info "Deploying to $CLAUDE_DIR..."

  # Backup existing config (timestamped, runs every time)
  if [ -d "$CLAUDE_DIR" ]; then
    local backup_dir
    backup_dir="$CLAUDE_DIR/.backup-$(date +%Y%m%d-%H%M%S)"
    local has_content=false
    for item in hooks agents skills lib rules contexts references mcp-server statusline-command.sh settings.json CLAUDE.md; do
      [ -e "$CLAUDE_DIR/$item" ] && has_content=true && break
    done
    if [ "$has_content" = true ]; then
      mkdir -p "$backup_dir"
      for item in hooks agents skills lib rules contexts references mcp-server statusline-command.sh settings.json CLAUDE.md; do
        [ -e "$CLAUDE_DIR/$item" ] && cp -r "$CLAUDE_DIR/$item" "$backup_dir/" 2>/dev/null || true
      done
      success "Backed up existing config to $backup_dir"
    fi
  fi

  # Deploy components (respecting --with/--without filters)
  mkdir -p "$CLAUDE_DIR"

  should_deploy "hooks" && \
    deploy_component "$SCRIPT_DIR/core/hooks" "$CLAUDE_DIR/hooks" "Hooks ($(find "$SCRIPT_DIR/core/hooks" -name '*.sh' | wc -l) scripts)" || \
    info "Skipped: hooks (filtered out)"

  should_deploy "agents" && \
    deploy_component "$SCRIPT_DIR/core/agents" "$CLAUDE_DIR/agents" "Agents ($(find "$SCRIPT_DIR/core/agents" -name '*.md' | wc -l) definitions)" || \
    info "Skipped: agents (filtered out)"

  # Skills deployment: full, filtered, or skipped
  if should_deploy "skills"; then
    if [ "${SKILL_MODE:-all}" = "none" ]; then
      info "Skipping skills deployment (--minimal)"
    elif [ "${SKILL_MODE:-all}" = "filtered" ]; then
      deploy_filtered_skills "$SKILL_CATEGORIES"
    else
      deploy_component "$SCRIPT_DIR/core/skills" "$CLAUDE_DIR/skills" "Skills"
    fi
  else
    info "Skipped: skills (filtered out)"
  fi

  should_deploy "lib" && \
    deploy_component "$SCRIPT_DIR/core/lib" "$CLAUDE_DIR/lib" "Shared lib" || \
    info "Skipped: lib (filtered out)"

  should_deploy "statusline" && \
    deploy_component "$SCRIPT_DIR/core/statusline-command.sh" "$CLAUDE_DIR/statusline-command.sh" "Statusline" || \
    info "Skipped: statusline (filtered out)"

  # Deploy stacks into skills (stacks are part of skills)
  if should_deploy "skills"; then
    if [ -d "$SCRIPT_DIR/stacks" ]; then
      for stack_dir in "$SCRIPT_DIR"/stacks/*/; do
        [ -d "$stack_dir" ] || continue
        local stack_name
        stack_name=$(basename "$stack_dir")
        [ "$stack_name" = "README.md" ] && continue
        deploy_component "$stack_dir" "$CLAUDE_DIR/skills/$stack_name" "Stack: $stack_name"
      done
    fi
  fi

  # Deploy references
  should_deploy "references" && {
    if [ -d "$SCRIPT_DIR/core/references" ]; then
      deploy_component "$SCRIPT_DIR/core/references" "$CLAUDE_DIR/references" "References"
    fi
  } || info "Skipped: references (filtered out)"

  # Deploy MCP server
  should_deploy "mcp-server" && {
    deploy_mcp
    if [ -d "$SCRIPT_DIR/core/mcp-server" ]; then
      deploy_component "$SCRIPT_DIR/core/mcp-server" "$CLAUDE_DIR/mcp-server" "MCP Server (hangar-state)"
    fi
  } || info "Skipped: mcp-server (filtered out)"

  should_deploy "rules" && deploy_rules || info "Skipped: rules (filtered out)"
  should_deploy "contexts" && deploy_contexts || info "Skipped: contexts (filtered out)"
  should_deploy "learning" && init_learning_system || info "Skipped: learning (filtered out)"

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

# Skill deployment mode: "all" (default), "filtered", or "none"
SKILL_MODE="all"
SKILL_CATEGORIES=""

# Component filtering for --with/--without
INCLUDE_COMPONENTS=""
EXCLUDE_COMPONENTS=""

main() {
  echo ""
  echo "  Claude Hangar — Setup"
  echo "  ─────────────────────"
  echo ""

  # Parse flags that can combine with modes
  local mode=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --skills)
        if [ -z "${2:-}" ]; then
          error "--skills requires a comma-separated list of categories"
          error "Use --list-categories to see available categories"
          exit 1
        fi
        SKILL_MODE="filtered"
        SKILL_CATEGORIES="$2"
        shift 2
        ;;
      --skills=*)
        SKILL_MODE="filtered"
        SKILL_CATEGORIES="${1#--skills=}"
        if [ -z "$SKILL_CATEGORIES" ]; then
          error "--skills requires a comma-separated list of categories"
          error "Use --list-categories to see available categories"
          exit 1
        fi
        shift
        ;;
      --with)
        INCLUDE_COMPONENTS="$2"
        shift 2
        ;;
      --with=*)
        INCLUDE_COMPONENTS="${1#--with=}"
        shift
        ;;
      --without)
        EXCLUDE_COMPONENTS="$2"
        shift 2
        ;;
      --without=*)
        EXCLUDE_COMPONENTS="${1#--without=}"
        shift
        ;;
      --minimal)
        SKILL_MODE="none"
        shift
        ;;
      --list-categories)
        mode="list-categories"
        shift
        ;;
      --list-components)
        mode="list-components"
        shift
        ;;
      *)
        if [ -z "$mode" ]; then
          mode="$1"
        fi
        shift
        ;;
    esac
  done

  case "${mode:-}" in
    list-categories)
      list_categories
      ;;

    list-components|--list-components)
      echo ""
      echo "Available components for --with/--without:"
      echo ""
      echo "  hooks       — Lifecycle hooks (safety, quality gates, monitoring)"
      echo "  agents      — Specialized AI worker definitions"
      echo "  skills      — Slash commands and workflow automations"
      echo "  lib         — Shared libraries and defaults"
      echo "  rules       — Always-on governance rules"
      echo "  contexts    — Context modes (dev, research, review)"
      echo "  references  — Shared behavioral references"
      echo "  mcp-server  — Hangar State MCP server"
      echo "  statusline  — Terminal statusline integration"
      echo "  learning    — Continuous learning system directories"
      echo ""
      echo "Examples:"
      echo "  bash setup.sh --with hooks,agents,lib    # Core only"
      echo "  bash setup.sh --without learning,contexts # Everything except these"
      ;;

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
                  hooks/continuous-learning.sh hooks/instinct-evolve.sh \
                  hooks/cost-tracker.sh hooks/desktop-notify.sh \
                  hooks/batch-format-collector.sh hooks/config-protection.sh \
                  hooks/db-query-guard.sh hooks/design-quality-check.sh \
                  hooks/instinct-capture.sh hooks/mcp-health-check.sh \
                  hooks/stop-batch-format.sh \
                  agents/planner.md agents/architect.md agents/loop-operator.md \
                  agents/typescript-reviewer.md agents/python-reviewer.md agents/go-reviewer.md \
                  agents/build-resolver-typescript.md agents/build-resolver-python.md agents/build-resolver-go.md \
                  agents/explorer.md agents/explorer-deep.md \
                  agents/security-reviewer.md agents/commit-reviewer.md agents/dependency-checker.md \
                  agents/plan-reviewer.md agents/refactor-agent.md agents/test-writer.md \
                  agents/doc-updater.md agents/harness-optimizer.md \
                  agents/performance-optimizer.md agents/tdd-guide.md \
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
      for item in hooks agents skills lib rules contexts references mcp-server statusline-command.sh settings.json CLAUDE.md; do
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
      echo "Usage: bash setup.sh [MODE] [OPTIONS]"
      echo ""
      echo "Modes:"
      echo "  (no args)           Interactive wizard (first run) or sync"
      echo "  --check             Dry-run validation"
      echo "  --verify            Verify existing installation"
      echo "  --sync              Remove orphaned files + redeploy"
      echo "  --rollback          Restore from backup"
      echo "  --update            git pull + redeploy"
      echo "  --uninstall         Remove Hangar files (preserves user data)"
      echo "  --list-categories   List available skill categories with counts"
      echo "  --list-components   List available components for --with/--without"
      echo "  --help              Show this help"
      echo ""
      echo "Options:"
      echo "  --skills CATS       Install only skills from given categories (comma-separated)"
      echo "  --minimal           Install core only (hooks, agents, lib) — skip all skills"
      echo "  --with COMPONENTS   Install only specific components (comma-separated)"
      echo "  --without COMPS     Install everything except these components"
      echo ""
      echo "  Components: hooks, agents, skills, lib, rules, contexts, references,"
      echo "              mcp-server, statusline, learning"
      echo ""
      echo "Examples:"
      echo "  bash setup.sh --skills design,security      # Only design + security skills"
      echo "  bash setup.sh --minimal                     # Core without skills"
      echo "  bash setup.sh --list-categories              # Show available categories"
      echo "  bash setup.sh --update --skills audit        # Update + deploy audit skills only"
      echo "  bash setup.sh --with hooks,agents,lib        # Core components only"
      echo "  bash setup.sh --without learning,contexts    # Everything except these"
      ;;

    *)
      check_prerequisites || exit 1
      validate_structure || exit 1
      deploy_all
      ;;
  esac
}

main "$@"

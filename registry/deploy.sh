#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────
# Claude Hangar — Registry Deploy
# ─────────────────────────────────────────────────────────────────────────
# Deploys project-specific configs based on registry.json
#
# Usage:
#   bash registry/deploy.sh                    # Deploy all projects
#   bash registry/deploy.sh --project my-app   # Deploy single project
#   bash registry/deploy.sh --check            # Dry-run
# ─────────────────────────────────────────────────────────────────────────

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REGISTRY_FILE="$SCRIPT_DIR/registry.json"

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; NC='\033[0m'
info()    { echo -e "${CYAN}[i]${NC} $1"; }
success() { echo -e "${GREEN}[+]${NC} $1"; }
warn()    { echo -e "${YELLOW}[!]${NC} $1"; }
error()   { echo -e "${RED}[x]${NC} $1"; }

# Check registry exists
if [ ! -f "$REGISTRY_FILE" ]; then
  # Try example registry
  if [ -f "$SCRIPT_DIR/example-registry.json" ]; then
    warn "No registry.json found — using example-registry.json"
    warn "Copy example-registry.json to registry.json and customize it."
    REGISTRY_FILE="$SCRIPT_DIR/example-registry.json"
  else
    error "No registry.json found in $SCRIPT_DIR"
    exit 1
  fi
fi

DRY_RUN=false
TARGET_PROJECT=""

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --check) DRY_RUN=true; shift ;;
    --project) TARGET_PROJECT="$2"; shift 2 ;;
    --help|-h)
      echo "Usage: bash registry/deploy.sh [--check] [--project <name>]"
      echo ""
      echo "  --check          Dry-run — show what would be deployed"
      echo "  --project <name> Deploy only this project"
      exit 0 ;;
    *) error "Unknown option: $1"; exit 1 ;;
  esac
done

# Process each project
deploy_count=0
project_count=$(node -e "
  const r = JSON.parse(require('fs').readFileSync('$REGISTRY_FILE','utf8'));
  console.log(r.projects.length);
" 2>/dev/null || echo "0")

for i in $(seq 0 $((project_count - 1))); do
  project_info=$(node -e "
    const r = JSON.parse(require('fs').readFileSync('$REGISTRY_FILE','utf8'));
    const p = r.projects[$i];
    console.log(JSON.stringify(p));
  " 2>/dev/null)

  name=$(echo "$project_info" | node -e "console.log(JSON.parse(require('fs').readFileSync(0,'utf8')).name)" 2>/dev/null)
  default_path=$(echo "$project_info" | node -e "console.log(JSON.parse(require('fs').readFileSync(0,'utf8')).defaultPath)" 2>/dev/null)

  # Filter by project name if specified
  if [ -n "$TARGET_PROJECT" ] && [ "$name" != "$TARGET_PROJECT" ]; then
    continue
  fi

  # Expand ~ to $HOME
  project_path="${default_path/#\~/$HOME}"

  echo ""
  info "Project: $name ($project_path)"

  if [ ! -d "$project_path" ]; then
    warn "  Directory not found — skipping"
    continue
  fi

  # Deploy workflows
  workflows=$(echo "$project_info" | node -e "
    const p = JSON.parse(require('fs').readFileSync(0,'utf8'));
    (p.workflows || []).forEach(w => console.log(w));
  " 2>/dev/null) || true

  for workflow in $workflows; do
    src="$REPO_ROOT/templates/ci/$workflow"
    dst="$project_path/.github/workflows/$workflow"
    if [ -f "$src" ]; then
      if $DRY_RUN; then
        info "  Would deploy: $workflow → .github/workflows/"
      else
        mkdir -p "$(dirname "$dst")"
        cp "$src" "$dst"
        success "  Deployed: $workflow"
      fi
    else
      warn "  Template not found: $workflow"
    fi
  done

  deploy_count=$((deploy_count + 1))
done

echo ""
if $DRY_RUN; then
  success "Dry run complete — $deploy_count project(s) checked"
else
  success "Deployed to $deploy_count project(s)"
fi

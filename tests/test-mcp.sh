#!/usr/bin/env bash
# Test Suite: MCP Configuration
# Validates MCP registry, stack MCP configs, and settings template.
# Usage: bash tests/test-mcp.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# ============================================================
# Test Framework
# ============================================================

PASS=0
FAIL=0
TOTAL=0

test_assert() {
  local description="$1"
  local condition="$2"

  TOTAL=$((TOTAL + 1))

  if eval "$condition"; then
    echo "  PASS  $description"
    PASS=$((PASS + 1))
  else
    echo "  FAIL  $description"
    FAIL=$((FAIL + 1))
  fi
}

# Helper: convert path for Node.js on Windows
node_path() {
  cygpath -m "$1" 2>/dev/null || echo "$1"
}

echo "============================================================"
echo "Claude Hangar — MCP Test Suite"
echo "============================================================"
echo ""

# ============================================================
# 1. Registry validation
# ============================================================

echo "--- MCP Registry ---"

test_assert \
  "core/mcp/registry.json exists" \
  "[ -f '$REPO_ROOT/core/mcp/registry.json' ]"

REGISTRY_PATH=$(node_path "$REPO_ROOT/core/mcp/registry.json")

test_assert \
  "registry.json is valid JSON" \
  "node -e \"JSON.parse(require('fs').readFileSync('$REGISTRY_PATH','utf8'))\" 2>/dev/null"

# Check required fields in registry
REGISTRY_FIELDS=$(node -e "
  const r = JSON.parse(require('fs').readFileSync('$REGISTRY_PATH','utf8'));
  const s = r.servers || {};
  const errors = [];
  for (const [id, srv] of Object.entries(s)) {
    if (!srv.name) errors.push(id + ': missing name');
    if (!srv.category) errors.push(id + ': missing category');
    if (!srv.description) errors.push(id + ': missing description');
    if (!srv.package) errors.push(id + ': missing package');
  }
  if (errors.length) { console.log(errors.join('; ')); process.exit(1); }
  console.log('OK');
" 2>&1) || true

test_assert \
  "registry entries have required fields (name, category, description, package)" \
  "[ '$REGISTRY_FIELDS' = 'OK' ]"

# Check core servers are marked required
CORE_REQUIRED=$(node -e "
  const r = JSON.parse(require('fs').readFileSync('$REGISTRY_PATH','utf8'));
  const s = r.servers || {};
  const cores = Object.entries(s).filter(([,v]) => v.category === 'core');
  if (cores.length === 0) { console.log('no core servers'); process.exit(1); }
  const missing = cores.filter(([,v]) => !v.required).map(([k]) => k);
  if (missing.length) { console.log('not required: ' + missing.join(', ')); process.exit(1); }
  console.log('OK');
" 2>&1) || true

test_assert \
  "core MCP servers are marked as required" \
  "[ '$CORE_REQUIRED' = 'OK' ]"

# ============================================================
# 2. Stack MCP configs
# ============================================================

echo ""
echo "--- Stack MCP Configs ---"

MCP_COUNT=$(find "$REPO_ROOT/stacks" -name 'mcp.json' 2>/dev/null | wc -l | tr -d ' ')

test_assert \
  "at least one stack has mcp.json" \
  "[ '$MCP_COUNT' -gt 0 ]"

# Validate each mcp.json
while IFS= read -r mcp_file; do
  [ -f "$mcp_file" ] || continue
  stack_name=$(basename "$(dirname "$mcp_file")")
  np=$(node_path "$mcp_file")

  test_assert \
    "stacks/$stack_name/mcp.json is valid JSON" \
    "node -e \"JSON.parse(require('fs').readFileSync('$np','utf8'))\" 2>/dev/null"

  # Check MCP config structure (each key must have command + args)
  STRUCT=$(node -e "
    const cfg = JSON.parse(require('fs').readFileSync('$np','utf8'));
    const errors = [];
    for (const [id, srv] of Object.entries(cfg)) {
      if (!srv.command) errors.push(id + ': missing command');
      if (!Array.isArray(srv.args)) errors.push(id + ': missing or invalid args');
    }
    if (errors.length) { console.log(errors.join('; ')); process.exit(1); }
    console.log('OK');
  " 2>&1) || true

  test_assert \
    "stacks/$stack_name/mcp.json servers have command + args" \
    "[ '$STRUCT' = 'OK' ]"
done < <(find "$REPO_ROOT/stacks" -name 'mcp.json' 2>/dev/null)

# ============================================================
# 3. Placeholder format validation
# ============================================================

echo ""
echo "--- Placeholder Format ---"

STACKS_PATH=$(node_path "$REPO_ROOT")

PLACEHOLDER_CHECK=$(node -e "
  const fs = require('fs');
  const path = require('path');
  const root = '$STACKS_PATH';
  const stacksDir = path.join(root, 'stacks');
  const errors = [];
  const re = /\{\{([^}]+)\}\}/g;

  try {
    const dirs = fs.readdirSync(stacksDir, { withFileTypes: true })
      .filter(d => d.isDirectory());
    for (const d of dirs) {
      const mcpPath = path.join(stacksDir, d.name, 'mcp.json');
      if (!fs.existsSync(mcpPath)) continue;
      const content = fs.readFileSync(mcpPath, 'utf8');
      let m;
      while ((m = re.exec(content)) !== null) {
        if (!/^[A-Z][A-Z0-9_]*$/.test(m[1])) {
          errors.push(d.name + ': invalid placeholder {{' + m[1] + '}} (must be UPPER_SNAKE_CASE)');
        }
      }
    }
  } catch (e) { errors.push(e.message); }

  if (errors.length) { console.log(errors.join('; ')); process.exit(1); }
  console.log('OK');
" 2>&1) || true

test_assert \
  "all credential placeholders use {{UPPER_SNAKE_CASE}} format" \
  "[ '$PLACEHOLDER_CHECK' = 'OK' ]"

# ============================================================
# 4. Settings template has mcpServers
# ============================================================

echo ""
echo "--- Settings Template ---"

SETTINGS_PATH=$(node_path "$REPO_ROOT/core/settings.json.template")

SETTINGS_MCP=$(node -e "
  const s = JSON.parse(require('fs').readFileSync('$SETTINGS_PATH','utf8'));
  if (!s.mcpServers) { console.log('missing mcpServers'); process.exit(1); }
  const keys = Object.keys(s.mcpServers);
  if (keys.length === 0) { console.log('empty mcpServers'); process.exit(1); }
  console.log('OK');
" 2>&1) || true

test_assert \
  "settings.json.template contains mcpServers block" \
  "[ '$SETTINGS_MCP' = 'OK' ]"

# Check that core registry servers appear in settings template
CORE_IN_SETTINGS=$(node -e "
  const r = JSON.parse(require('fs').readFileSync('$REGISTRY_PATH','utf8'));
  const s = JSON.parse(require('fs').readFileSync('$SETTINGS_PATH','utf8'));
  const coreIds = Object.entries(r.servers).filter(([,v]) => v.required).map(([k]) => k);
  const settingsIds = Object.keys(s.mcpServers || {});
  const missing = coreIds.filter(id => !settingsIds.includes(id));
  if (missing.length) { console.log('missing in template: ' + missing.join(', ')); process.exit(1); }
  console.log('OK');
" 2>&1) || true

test_assert \
  "all required core MCPs appear in settings.json.template" \
  "[ '$CORE_IN_SETTINGS' = 'OK' ]"

# ============================================================
# 5. Registry <-> Stack consistency
# ============================================================

echo ""
echo "--- Registry-Stack Consistency ---"

CONSISTENCY=$(node -e "
  const fs = require('fs');
  const path = require('path');
  const root = '$STACKS_PATH';
  const r = JSON.parse(fs.readFileSync(path.join(root, 'core/mcp/registry.json'), 'utf8'));
  const errors = [];
  for (const [id, srv] of Object.entries(r.servers)) {
    if (srv.category === 'stack' && srv.stack) {
      const mcpPath = path.join(root, 'stacks', srv.stack, 'mcp.json');
      if (!fs.existsSync(mcpPath)) {
        errors.push(id + ': registry references stack \"' + srv.stack + '\" but stacks/' + srv.stack + '/mcp.json not found');
      }
    }
  }
  if (errors.length) { console.log(errors.join('; ')); process.exit(1); }
  console.log('OK');
" 2>&1) || true

test_assert \
  "every stack MCP in registry has a corresponding stacks/*/mcp.json" \
  "[ '$CONSISTENCY' = 'OK' ]"

# ============================================================
# 6. Install script exists
# ============================================================

echo ""
echo "--- Install Script ---"

test_assert \
  "core/mcp/install.sh exists" \
  "[ -f '$REPO_ROOT/core/mcp/install.sh' ]"

test_assert \
  "install.sh has valid bash syntax" \
  "bash -n '$REPO_ROOT/core/mcp/install.sh' 2>/dev/null"

# ============================================================
# Summary
# ============================================================

echo ""
echo "============================================================"
echo "Results: $PASS passed, $FAIL failed, $TOTAL total"
echo "============================================================"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi

exit 0

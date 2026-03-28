# MCP Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Integrate MCP server management into Claude Hangar with core MCPs (always installed) and stack MCPs (activated per stack).

**Architecture:** Core MCPs live in `core/mcp/` with a central registry. Stack MCPs live alongside their stacks as `mcp.json` files. `setup.sh` deploys core MCPs via `settings.json.template` and merges stack MCPs via `core/mcp/install.sh`. A new test file validates all MCP JSON files and the registry.

**Tech Stack:** Bash 4.0+, Node.js (JSON processing), JSON Schema

**Spec:** `docs/superpowers/specs/2026-03-28-mcp-integration-design.md`

---

## File Map

### New Files

| File | Responsibility |
|------|---------------|
| `core/mcp/registry.json` | Central catalog of all supported MCP servers with metadata |
| `core/mcp/install.sh` | MCP installer — merges stack MCP configs into user's settings.json |
| `core/mcp/README.md` | Contributor documentation for adding new MCP servers |
| `stacks/github/mcp.json` | GitHub MCP server configuration |
| `stacks/github/README.md` | GitHub stack documentation |
| `stacks/web/mcp.json` | Playwright MCP server configuration |
| `stacks/web/README.md` | Web tooling stack documentation |
| `stacks/security/mcp.json` | Snyk MCP server configuration |
| `stacks/security/README.md` | Security stack documentation |
| `stacks/database/mcp.json` | PostgreSQL Pro MCP server configuration |
| `tests/test-mcp.sh` | Validation tests for all MCP JSON files and registry |
| `docs/mcp-guide.md` | User-facing MCP guide |

### Modified Files

| File | Change |
|------|--------|
| `core/settings.json.template` | Add `mcpServers` block with core MCPs (sequential-thinking, context7) |
| `setup.sh` | Add MCP deployment section calling `core/mcp/install.sh` |
| `registry/registry.schema.json` | Add optional `mcpServers` array field to project schema |
| `registry/example-registry.json` | Add MCP examples to both sample projects |
| `stacks/README.md` | Add new stacks (github, web, security) to the table |

---

## Task 1: Create MCP Registry

The central catalog that all other tasks reference.

**Files:**
- Create: `core/mcp/registry.json`

- [ ] **Step 1: Create core/mcp/ directory and registry.json**

```json
{
  "version": "1.0.0",
  "description": "Claude Hangar MCP Server Registry — catalog of all supported MCP servers",
  "servers": {
    "sequential-thinking": {
      "name": "Sequential Thinking",
      "category": "core",
      "description": "Structured step-by-step reasoning for complex problems",
      "source": "https://github.com/modelcontextprotocol/servers",
      "package": "@modelcontextprotocol/server-sequential-thinking",
      "required": true
    },
    "context7": {
      "name": "Context7",
      "category": "core",
      "description": "Live documentation lookup for any library or framework",
      "source": "https://github.com/upstash/context7",
      "package": "@upstash/context7-mcp",
      "required": true
    },
    "github": {
      "name": "GitHub",
      "category": "stack",
      "stack": "github",
      "description": "GitHub repos, PRs, issues, code search",
      "source": "https://github.com/github/github-mcp-server",
      "package": "@modelcontextprotocol/server-github",
      "credentials": ["GITHUB_TOKEN"]
    },
    "playwright": {
      "name": "Playwright",
      "category": "stack",
      "stack": "web",
      "description": "Browser automation and UI verification",
      "source": "https://github.com/microsoft/playwright-mcp",
      "package": "@playwright/mcp"
    },
    "postgres": {
      "name": "PostgreSQL Pro",
      "category": "stack",
      "stack": "database",
      "description": "Database schema inspection, queries, performance analysis",
      "source": "https://github.com/crystaldba/postgres-mcp",
      "package": "@crystaldba/postgres-mcp",
      "credentials": ["POSTGRES_URL"]
    },
    "snyk": {
      "name": "Snyk",
      "category": "stack",
      "stack": "security",
      "description": "Security scanning for dependencies, code, IaC, and containers",
      "source": "https://docs.snyk.io/integrations/snyk-studio-agentic-integrations",
      "package": "snyk"
    }
  }
}
```

- [ ] **Step 2: Validate JSON is parseable**

Run: `node -e "JSON.parse(require('fs').readFileSync('core/mcp/registry.json','utf8')); console.log('OK')"`
Expected: `OK`

- [ ] **Step 3: Commit**

```bash
git add core/mcp/registry.json
git commit -m "feat: add MCP server registry (core/mcp/registry.json)"
```

---

## Task 2: Create MCP Test Suite

Write tests before implementation (TDD for the validation logic).

**Files:**
- Create: `tests/test-mcp.sh`

- [ ] **Step 1: Write test-mcp.sh**

```bash
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

test_assert \
  "registry.json is valid JSON" \
  "node -e \"JSON.parse(require('fs').readFileSync('$(cygpath -m "$REPO_ROOT/core/mcp/registry.json" 2>/dev/null || echo "$REPO_ROOT/core/mcp/registry.json")','utf8'))\" 2>/dev/null"

# Check required fields in registry
REGISTRY_CHECK=$(node -e "
  const r = JSON.parse(require('fs').readFileSync('$(cygpath -m "$REPO_ROOT/core/mcp/registry.json" 2>/dev/null || echo "$REPO_ROOT/core/mcp/registry.json")','utf8'));
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
  "[ '$REGISTRY_CHECK' = 'OK' ]"

# Check core servers are marked required
CORE_CHECK=$(node -e "
  const r = JSON.parse(require('fs').readFileSync('$(cygpath -m "$REPO_ROOT/core/mcp/registry.json" 2>/dev/null || echo "$REPO_ROOT/core/mcp/registry.json")','utf8'));
  const s = r.servers || {};
  const cores = Object.entries(s).filter(([,v]) => v.category === 'core');
  if (cores.length === 0) { console.log('no core servers'); process.exit(1); }
  const missing = cores.filter(([,v]) => !v.required).map(([k]) => k);
  if (missing.length) { console.log('not required: ' + missing.join(', ')); process.exit(1); }
  console.log('OK');
" 2>&1) || true

test_assert \
  "core MCP servers are marked as required" \
  "[ '$CORE_CHECK' = 'OK' ]"

# ============================================================
# 2. Stack MCP configs
# ============================================================

echo ""
echo "--- Stack MCP Configs ---"

# Find all mcp.json files in stacks/
MCP_FILES=$(find "$REPO_ROOT/stacks" -name 'mcp.json' 2>/dev/null)

test_assert \
  "at least one stack has mcp.json" \
  "[ -n '$MCP_FILES' ]"

# Validate each mcp.json
for mcp_file in $MCP_FILES; do
  stack_name=$(basename "$(dirname "$mcp_file")")
  node_path=$(cygpath -m "$mcp_file" 2>/dev/null || echo "$mcp_file")

  test_assert \
    "stacks/$stack_name/mcp.json is valid JSON" \
    "node -e \"JSON.parse(require('fs').readFileSync('$node_path','utf8'))\" 2>/dev/null"

  # Check MCP config structure (each key must have command + args)
  STRUCT_CHECK=$(node -e "
    const cfg = JSON.parse(require('fs').readFileSync('$node_path','utf8'));
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
    "[ '$STRUCT_CHECK' = 'OK' ]"
done

# ============================================================
# 3. Placeholder format validation
# ============================================================

echo ""
echo "--- Placeholder Format ---"

# Check all mcp.json files for credential placeholders matching {{UPPER_SNAKE_CASE}}
PLACEHOLDER_CHECK=$(node -e "
  const fs = require('fs');
  const path = require('path');
  const root = '$(cygpath -m "$REPO_ROOT" 2>/dev/null || echo "$REPO_ROOT")';
  const files = fs.readdirSync(path.join(root, 'stacks'), { withFileTypes: true })
    .filter(d => d.isDirectory())
    .map(d => path.join(root, 'stacks', d.name, 'mcp.json'))
    .filter(f => fs.existsSync(f));

  const errors = [];
  const re = /\{\{([^}]+)\}\}/g;
  for (const f of files) {
    const content = fs.readFileSync(f, 'utf8');
    let m;
    while ((m = re.exec(content)) !== null) {
      if (!/^[A-Z][A-Z0-9_]*$/.test(m[1])) {
        errors.push(path.basename(path.dirname(f)) + ': invalid placeholder {{' + m[1] + '}} (must be UPPER_SNAKE_CASE)');
      }
    }
  }
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

SETTINGS_MCP_CHECK=$(node -e "
  const s = JSON.parse(require('fs').readFileSync('$(cygpath -m "$REPO_ROOT/core/settings.json.template" 2>/dev/null || echo "$REPO_ROOT/core/settings.json.template")','utf8'));
  if (!s.mcpServers) { console.log('missing mcpServers'); process.exit(1); }
  const keys = Object.keys(s.mcpServers);
  if (keys.length === 0) { console.log('empty mcpServers'); process.exit(1); }
  console.log('OK');
" 2>&1) || true

test_assert \
  "settings.json.template contains mcpServers block" \
  "[ '$SETTINGS_MCP_CHECK' = 'OK' ]"

# Check that core registry servers appear in settings template
CORE_IN_SETTINGS=$(node -e "
  const r = JSON.parse(require('fs').readFileSync('$(cygpath -m "$REPO_ROOT/core/mcp/registry.json" 2>/dev/null || echo "$REPO_ROOT/core/mcp/registry.json")','utf8'));
  const s = JSON.parse(require('fs').readFileSync('$(cygpath -m "$REPO_ROOT/core/settings.json.template" 2>/dev/null || echo "$REPO_ROOT/core/settings.json.template")','utf8'));
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

CONSISTENCY_CHECK=$(node -e "
  const fs = require('fs');
  const path = require('path');
  const root = '$(cygpath -m "$REPO_ROOT" 2>/dev/null || echo "$REPO_ROOT")';
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
  "[ '$CONSISTENCY_CHECK' = 'OK' ]"

# ============================================================
# 6. Install script exists
# ============================================================

echo ""
echo "--- Install Script ---"

test_assert \
  "core/mcp/install.sh exists" \
  "[ -f '$REPO_ROOT/core/mcp/install.sh' ]"

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
```

- [ ] **Step 2: Run tests — expect failures (TDD red phase)**

Run: `bash tests/test-mcp.sh`
Expected: Multiple FAIL (stack mcp.json files don't exist yet, settings template missing mcpServers, install.sh missing)

- [ ] **Step 3: Commit test file**

```bash
git add tests/test-mcp.sh
git commit -m "test: add MCP validation test suite (red phase)"
```

---

## Task 3: Add Core MCPs to Settings Template

**Files:**
- Modify: `core/settings.json.template:142-157` (add mcpServers before language field)

- [ ] **Step 1: Add mcpServers block to settings.json.template**

Add the following block after the closing `}` of `"hooks"` and before `"language"`:

```json
  "mcpServers": {
    "sequential-thinking": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"]
    },
    "context7": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp@latest"]
    }
  },
```

- [ ] **Step 2: Validate the template is still valid JSON**

Run: `node -e "JSON.parse(require('fs').readFileSync('core/settings.json.template','utf8')); console.log('OK')"`
Expected: `OK`

- [ ] **Step 3: Commit**

```bash
git add core/settings.json.template
git commit -m "feat: add core MCP servers to settings.json.template"
```

---

## Task 4: Create Stack MCP Configs

Create `mcp.json` for each stack that provides MCP servers. New stacks (github, web, security) also get a README.md.

**Files:**
- Create: `stacks/github/mcp.json`, `stacks/github/README.md`
- Create: `stacks/web/mcp.json`, `stacks/web/README.md`
- Create: `stacks/database/mcp.json` (stack already exists)
- Create: `stacks/security/mcp.json`, `stacks/security/README.md`

- [ ] **Step 1: Create stacks/github/mcp.json**

```json
{
  "github": {
    "type": "stdio",
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-github"],
    "env": {
      "GITHUB_PERSONAL_ACCESS_TOKEN": "{{GITHUB_TOKEN}}"
    }
  }
}
```

- [ ] **Step 2: Create stacks/github/README.md**

```markdown
# GitHub Stack

MCP server for GitHub integration. Provides Claude Code with direct access to repositories, pull requests, issues, code search, and branch management.

## MCP Server

| Server | Package | Credentials |
|--------|---------|-------------|
| GitHub | `@modelcontextprotocol/server-github` | `GITHUB_TOKEN` (Personal Access Token) |

## Setup

1. Create a GitHub Personal Access Token at https://github.com/settings/tokens
2. Set the environment variable: `export GITHUB_TOKEN=ghp_your_token_here`
3. Run `bash setup.sh` — the GitHub MCP server will be configured automatically

## What Claude Can Do With This

- Search code across repositories
- Read and create issues
- Review and create pull requests
- Create branches and manage files
- Query commit history
```

- [ ] **Step 3: Create stacks/web/mcp.json**

```json
{
  "playwright": {
    "type": "stdio",
    "command": "npx",
    "args": ["-y", "@playwright/mcp@latest"]
  }
}
```

- [ ] **Step 4: Create stacks/web/README.md**

```markdown
# Web Tooling Stack

MCP servers for general web development. Browser automation for testing and UI verification.

## MCP Server

| Server | Package | Credentials |
|--------|---------|-------------|
| Playwright | `@playwright/mcp` | None |

## Setup

Run `bash setup.sh` — the Playwright MCP server will be configured automatically.

## What Claude Can Do With This

- Open a browser and navigate to any URL (including localhost)
- Click elements, fill forms, take screenshots
- Verify UI changes after code modifications
- Run visual QA checks on web applications
```

- [ ] **Step 5: Create stacks/database/mcp.json**

```json
{
  "postgres": {
    "type": "stdio",
    "command": "npx",
    "args": ["-y", "@crystaldba/postgres-mcp"],
    "env": {
      "DATABASE_URL": "{{POSTGRES_URL}}"
    }
  }
}
```

- [ ] **Step 6: Create stacks/security/mcp.json**

```json
{
  "snyk": {
    "type": "stdio",
    "command": "npx",
    "args": ["-y", "snyk@latest", "mcp"]
  }
}
```

- [ ] **Step 7: Create stacks/security/README.md**

```markdown
# Security Stack

MCP server for security scanning. Provides Claude Code with vulnerability detection across dependencies, code, infrastructure-as-code, and container images.

## MCP Server

| Server | Package | Credentials |
|--------|---------|-------------|
| Snyk | `snyk` | OAuth (runs `snyk auth` on first use) |

## Setup

1. Install Snyk CLI: `npm install -g snyk`
2. Authenticate: `snyk auth`
3. Run `bash setup.sh` — the Snyk MCP server will be configured automatically

## What Claude Can Do With This

- `snyk_sca_scan` — Scan dependencies for known vulnerabilities
- `snyk_code_scan` — Static analysis for security flaws in source code
- `snyk_iac_scan` — Check infrastructure-as-code (Dockerfiles, Terraform, etc.)
- `snyk_container_scan` — Scan container images for vulnerabilities
```

- [ ] **Step 8: Validate all mcp.json files**

Run: `for f in stacks/*/mcp.json; do echo "$f:"; node -e "JSON.parse(require('fs').readFileSync('$f','utf8')); console.log('OK')"; done`
Expected: All print `OK`

- [ ] **Step 9: Commit**

```bash
git add stacks/github/ stacks/web/ stacks/database/mcp.json stacks/security/
git commit -m "feat: add MCP configs for github, web, database, and security stacks"
```

---

## Task 5: Create MCP Install Script

The script that merges stack MCP configs into the user's `settings.json`.

**Files:**
- Create: `core/mcp/install.sh`

- [ ] **Step 1: Write core/mcp/install.sh**

```bash
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
```

- [ ] **Step 2: Validate script syntax**

Run: `bash -n core/mcp/install.sh && echo "Syntax OK"`
Expected: `Syntax OK`

- [ ] **Step 3: Commit**

```bash
git add core/mcp/install.sh
git commit -m "feat: add MCP install script for stack MCP merging"
```

---

## Task 6: Create MCP README

**Files:**
- Create: `core/mcp/README.md`

- [ ] **Step 1: Write core/mcp/README.md**

```markdown
# MCP Server Management

This directory contains the MCP (Model Context Protocol) server registry and installer for Claude Hangar.

## Architecture

- **Core MCPs** are defined in `settings.json.template` and always deployed
- **Stack MCPs** live in `stacks/*/mcp.json` and are merged on setup
- **registry.json** is the single source of truth for all supported servers

## Files

| File | Purpose |
|------|---------|
| `registry.json` | Catalog of all supported MCP servers with metadata |
| `install.sh` | Merges stack MCP configs into user's settings.json |

## Adding a New MCP Server

1. Add the server entry to `registry.json` with all required fields
2. If it belongs to a stack, create or update `stacks/<stack>/mcp.json`
3. If it's a core server, add it to `core/settings.json.template`
4. Add a test case or verify `tests/test-mcp.sh` covers the new entry
5. Update `docs/mcp-guide.md` with setup instructions

### Registry Entry Format

```json
{
  "server-id": {
    "name": "Human-Readable Name",
    "category": "core|stack",
    "stack": "stack-name",
    "description": "What this server does",
    "source": "https://github.com/...",
    "package": "npm-package-name",
    "required": true,
    "credentials": ["ENV_VAR_NAME"]
  }
}
```

### Stack MCP Config Format

```json
{
  "server-id": {
    "type": "stdio",
    "command": "npx",
    "args": ["-y", "package-name"],
    "env": {
      "CREDENTIAL_NAME": "{{PLACEHOLDER}}"
    }
  }
}
```

Credential placeholders must use `{{UPPER_SNAKE_CASE}}` format.
```

- [ ] **Step 2: Commit**

```bash
git add core/mcp/README.md
git commit -m "docs: add MCP contributor README"
```

---

## Task 7: Extend setup.sh with MCP Deployment

**Files:**
- Modify: `setup.sh:168-193` (add MCP section after stack deployment, before settings deployment)

- [ ] **Step 1: Add MCP deployment function to setup.sh**

Add after the `deploy_component` function (after line 145) and before `deploy_all`:

```bash
# ─── MCP ──────────────────────────────────────────────────────────────

deploy_mcp() {
  if [ -f "$SCRIPT_DIR/core/mcp/install.sh" ]; then
    info "Configuring MCP servers..."
    bash "$SCRIPT_DIR/core/mcp/install.sh"
  fi
}
```

- [ ] **Step 2: Call deploy_mcp in deploy_all**

Add `deploy_mcp` call after the stacks deployment block (after line 179) and before the settings deployment (line 182):

```bash
  # Deploy MCP server configs from stacks
  deploy_mcp
```

- [ ] **Step 3: Add npx to prerequisite check output**

In `check_prerequisites()`, after the node check (line 46), add npx as optional:

```bash
  command -v npx &>/dev/null || missing+=("npx (optional, for MCP servers)")
```

- [ ] **Step 4: Add core/mcp to validation**

In `validate_structure()`, add to the directory check loop (line 71):

```bash
  for dir in core/hooks core/agents core/lib core/mcp; do
```

- [ ] **Step 5: Validate setup.sh syntax**

Run: `bash -n setup.sh && echo "Syntax OK"`
Expected: `Syntax OK`

- [ ] **Step 6: Run setup --check to verify dry-run still works**

Run: `bash setup.sh --check`
Expected: "All checks passed — ready to deploy"

- [ ] **Step 7: Commit**

```bash
git add setup.sh
git commit -m "feat: extend setup.sh with MCP server deployment"
```

---

## Task 8: Extend Registry Schema and Example

**Files:**
- Modify: `registry/registry.schema.json:51-60`
- Modify: `registry/example-registry.json`

- [ ] **Step 1: Add mcpServers field to registry schema**

Add after the `workflows` property block in registry.schema.json (after line 58):

```json
          "mcpServers": {
            "type": "array",
            "description": "MCP server IDs from core/mcp/registry.json to activate for this project.",
            "items": {
              "type": "string"
            },
            "default": []
          },
```

- [ ] **Step 2: Add mcpServers to example registry projects**

Add to the "my-website" project (after "workflows" array):

```json
      "mcpServers": [
        "github",
        "playwright"
      ],
```

Add to the "my-app" project (after "workflows" array):

```json
      "mcpServers": [
        "github",
        "playwright",
        "postgres"
      ],
```

- [ ] **Step 3: Validate both JSON files**

Run: `node -e "JSON.parse(require('fs').readFileSync('registry/registry.schema.json','utf8')); console.log('Schema OK')" && node -e "JSON.parse(require('fs').readFileSync('registry/example-registry.json','utf8')); console.log('Example OK')"`
Expected: `Schema OK` then `Example OK`

- [ ] **Step 4: Commit**

```bash
git add registry/registry.schema.json registry/example-registry.json
git commit -m "feat: extend registry schema with mcpServers field"
```

---

## Task 9: Update Stacks README

**Files:**
- Modify: `stacks/README.md`

- [ ] **Step 1: Add new stacks to the Available Stacks table**

Add these rows to the table (after line 13):

```markdown
| **GitHub** | `github/` | — | GitHub repos, PRs, issues via MCP |
| **Web** | `web/` | — | Browser automation (Playwright) via MCP |
| **Security** | `security/` | — | Security scanning (Snyk) via MCP |
```

- [ ] **Step 2: Add MCP section to directory structure**

Add after the auth stack in the structure diagram:

```markdown
├── github/
│   ├── mcp.json              # GitHub MCP server configuration
│   └── README.md             # Stack documentation
├── web/
│   ├── mcp.json              # Playwright MCP server configuration
│   └── README.md             # Stack documentation
├── security/
│   ├── mcp.json              # Snyk MCP server configuration
│   └── README.md             # Stack documentation
```

- [ ] **Step 3: Add MCP note to "Creating a New Stack" section**

Add after the existing guidelines list:

```markdown
- **MCP servers** — if your stack includes an MCP server, add a `mcp.json` file (see `core/mcp/README.md` for format)
```

- [ ] **Step 4: Commit**

```bash
git add stacks/README.md
git commit -m "docs: add github, web, security stacks to README"
```

---

## Task 10: Create User-Facing MCP Guide

**Files:**
- Create: `docs/mcp-guide.md`

- [ ] **Step 1: Write docs/mcp-guide.md**

```markdown
# MCP Server Guide

Claude Hangar manages MCP (Model Context Protocol) servers that extend what Claude Code can do. MCP servers give Claude access to external tools and services.

## What Gets Installed

### Core MCP Servers (Always Active)

These are installed automatically with every Claude Hangar setup:

| Server | What It Does |
|--------|-------------|
| **Sequential Thinking** | Helps Claude reason through complex problems step by step |
| **Context7** | Fetches live documentation for any library (React, Astro, SvelteKit, Tailwind, Drizzle, etc.) |

### Stack MCP Servers (Per Stack)

These activate when you use the corresponding stack:

| Stack | Server | What It Does | Credentials Needed |
|-------|--------|-------------|-------------------|
| GitHub | GitHub MCP | Repos, PRs, issues, code search | `GITHUB_TOKEN` |
| Web | Playwright | Browser automation, screenshots, UI testing | None |
| Database | PostgreSQL Pro | Schema inspection, queries, performance analysis | `POSTGRES_URL` |
| Security | Snyk | Vulnerability scanning (deps, code, containers) | OAuth via `snyk auth` |

## Setting Up Credentials

Some MCP servers need credentials. Set them as environment variables before running Claude Code:

```bash
# GitHub — Personal Access Token
export GITHUB_TOKEN=ghp_your_token_here

# PostgreSQL — Connection string
export POSTGRES_URL=postgresql://user:pass@localhost:5432/mydb
```

After setting up credentials, the `{{PLACEHOLDER}}` values in your `~/.claude/settings.json` will be replaced by the environment variables at runtime.

## Adding More MCP Servers

You can manually add MCP servers to `~/.claude/settings.json`:

```json
{
  "mcpServers": {
    "my-server": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "package-name"]
    }
  }
}
```

Or use the Claude Code CLI:

```bash
claude mcp add my-server -- npx -y package-name
```

## Security

- Only install MCP servers from trusted sources (official repos, verified packages)
- Never give MCP servers write access to production databases
- Use read-only modes where available (e.g., PostgreSQL restricted mode)
- Review the source code of community MCP servers before installing
- See `SECURITY.md` for the full security policy
```

- [ ] **Step 2: Commit**

```bash
git add docs/mcp-guide.md
git commit -m "docs: add user-facing MCP server guide"
```

---

## Task 11: Run All Tests — Green Phase

**Files:**
- None (validation only)

- [ ] **Step 1: Run MCP test suite**

Run: `bash tests/test-mcp.sh`
Expected: All PASS, 0 FAIL

- [ ] **Step 2: Run hook test suite (regression)**

Run: `bash tests/test-hooks.sh`
Expected: All PASS, 0 FAIL

- [ ] **Step 3: Run setup test suite (regression)**

Run: `bash tests/test-setup.sh`
Expected: All PASS, 0 FAIL

- [ ] **Step 4: Run setup --check (dry run)**

Run: `bash setup.sh --check`
Expected: "All checks passed — ready to deploy"

- [ ] **Step 5: Validate all JSON files in repo**

Run: `find . -name '*.json' -not -path '*/.git/*' -not -path '*/node_modules/*' -exec sh -c 'node -e "JSON.parse(require(\"fs\").readFileSync(\"$1\",\"utf8\"))" -- {} && echo "OK: {}" || echo "FAIL: {}"' _ {} \;`
Expected: All print `OK`

---

## Task 12: Final Commit and Summary

- [ ] **Step 1: Check git status for any uncommitted files**

Run: `git status`
Expected: Clean working tree or only untracked files that are intentionally ignored

- [ ] **Step 2: If any files are uncommitted, commit them**

```bash
git add -A
git commit -m "chore: finalize MCP integration"
```

- [ ] **Step 3: Review git log for clean commit history**

Run: `git log --oneline -10`
Expected: Clean conventional commit messages for the MCP integration

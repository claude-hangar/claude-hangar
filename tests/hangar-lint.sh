#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────
# hangar-lint.sh — Configuration Linter for Claude Hangar
# ─────────────────────────────────────────────────────────────────────────
# Validates: SKILL.md frontmatter, hook scripts, agent markdown,
# settings.json template, skill-rules.json, registry.json, plugin.json
#
# Usage:
#   bash tests/hangar-lint.sh          # Run all checks
#   bash tests/hangar-lint.sh --fix    # Report only (no auto-fix yet)
# ─────────────────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

PASS=0
FAIL=0
WARN=0
TOTAL=0

pass() {
  TOTAL=$((TOTAL + 1))
  PASS=$((PASS + 1))
  echo "  PASS  $1"
}

fail() {
  TOTAL=$((TOTAL + 1))
  FAIL=$((FAIL + 1))
  echo "  FAIL  $1"
}

warn() {
  WARN=$((WARN + 1))
  echo "  WARN  $1"
}

echo "============================================================"
echo "Claude Hangar — Configuration Linter"
echo "============================================================"
echo ""

# ─── 1. SKILL.md Frontmatter ─────────────────────────────────────────

echo "--- Skill Frontmatter ---"

for skill_dir in "$REPO_ROOT"/core/skills/*/; do
  [ -d "$skill_dir" ] || continue
  skill_name=$(basename "$skill_dir")
  [ "$skill_name" = "_shared" ] && continue

  skill_file="$skill_dir/SKILL.md"
  if [ ! -f "$skill_file" ]; then
    fail "$skill_name: missing SKILL.md"
    continue
  fi

  # Check frontmatter exists (starts with ---)
  if ! head -1 "$skill_file" | grep -q '^---'; then
    fail "$skill_name: missing frontmatter (no --- header)"
    continue
  fi

  # Extract frontmatter (between first and second ---)
  frontmatter=$(sed -n '1,/^---$/p' "$skill_file" | tail -n +2 | head -n -1)

  # Required fields
  if ! echo "$frontmatter" | grep -q '^name:'; then
    fail "$skill_name: missing 'name' in frontmatter"
  else
    # Check name matches directory
    fm_name=$(echo "$frontmatter" | grep '^name:' | sed 's/^name: *//')
    if [ "$fm_name" != "$skill_name" ]; then
      fail "$skill_name: frontmatter name '$fm_name' != directory name '$skill_name'"
    else
      pass "$skill_name: name field matches directory"
    fi
  fi

  if ! echo "$frontmatter" | grep -q '^description:'; then
    fail "$skill_name: missing 'description' in frontmatter"
  fi

  # Check for deprecated underscore format
  if echo "$frontmatter" | grep -q 'user_invocable\|argument_hint\|disable_model_invocation'; then
    fail "$skill_name: uses deprecated underscore format (use hyphens)"
  fi

  # Check effort field
  if ! echo "$frontmatter" | grep -q '^effort:'; then
    warn "$skill_name: missing 'effort' field"
  else
    effort=$(echo "$frontmatter" | grep '^effort:' | sed 's/^effort: *//')
    case "$effort" in
      low|medium|high) ;;
      *) fail "$skill_name: invalid effort '$effort' (must be low/medium/high)" ;;
    esac
  fi
done

# Also check stack skills
for stack_dir in "$REPO_ROOT"/stacks/*/; do
  [ -d "$stack_dir" ] || continue
  stack_name=$(basename "$stack_dir")
  skill_file="$stack_dir/SKILL.md"
  [ -f "$skill_file" ] || continue

  if ! head -1 "$skill_file" | grep -q '^---'; then
    fail "stacks/$stack_name: missing frontmatter"
  else
    frontmatter=$(sed -n '1,/^---$/p' "$skill_file" | tail -n +2 | head -n -1)
    if ! echo "$frontmatter" | grep -q '^name:'; then
      fail "stacks/$stack_name: missing 'name' in frontmatter"
    else
      pass "stacks/$stack_name: frontmatter valid"
    fi
  fi
done

echo ""

# ─── 2. Agent Markdown ───────────────────────────────────────────────

echo "--- Agent Definitions ---"

for agent_file in "$REPO_ROOT"/core/agents/*.md; do
  [ -f "$agent_file" ] || continue
  agent_name=$(basename "$agent_file" .md)

  # Check frontmatter exists
  if ! head -1 "$agent_file" | grep -q '^---'; then
    fail "$agent_name: missing frontmatter"
    continue
  fi

  frontmatter=$(sed -n '1,/^---$/p' "$agent_file" | tail -n +2 | head -n -1)

  # Required fields
  if ! echo "$frontmatter" | grep -q '^model:'; then
    fail "$agent_name: missing 'model' field"
  else
    model=$(echo "$frontmatter" | grep '^model:' | sed 's/^model: *//')
    case "$model" in
      opus|sonnet|haiku) pass "$agent_name: model=$model" ;;
      *) fail "$agent_name: invalid model '$model' (must be opus/sonnet/haiku)" ;;
    esac
  fi

  if ! echo "$frontmatter" | grep -q '^description:'; then
    fail "$agent_name: missing 'description'"
  fi

  # Check maxTurns
  if ! echo "$frontmatter" | grep -q '^maxTurns:'; then
    warn "$agent_name: missing 'maxTurns' (safety limit)"
  fi

  # Check effort
  if ! echo "$frontmatter" | grep -q '^effort:'; then
    warn "$agent_name: missing 'effort' field"
  fi
done

echo ""

# ─── 3. Hook Scripts ─────────────────────────────────────────────────

echo "--- Hook Scripts ---"

for hook_file in "$REPO_ROOT"/core/hooks/*.sh; do
  [ -f "$hook_file" ] || continue
  hook_name=$(basename "$hook_file" .sh)

  # Check shebang
  if ! head -1 "$hook_file" | grep -q '^#!/usr/bin/env bash'; then
    fail "$hook_name: missing or wrong shebang (expected #!/usr/bin/env bash)"
  fi

  # Check hook-gate integration
  if ! grep -q 'HOOK_NAME=.*HOOK_MIN_PROFILE=' "$hook_file"; then
    fail "$hook_name: missing HOOK_NAME/HOOK_MIN_PROFILE declaration"
  fi

  if ! grep -q 'source.*hook-gate\.sh' "$hook_file"; then
    fail "$hook_name: does not source hook-gate.sh"
  fi

  # Check for set -e (problematic on Windows Git Bash)
  if grep -q '^set -e' "$hook_file"; then
    fail "$hook_name: uses 'set -e' (breaks on Windows Git Bash, use explicit error handling)"
  fi

  # Check profile is valid
  profile=$(grep 'HOOK_MIN_PROFILE=' "$hook_file" | head -1 | sed 's/.*HOOK_MIN_PROFILE="\([^"]*\)".*/\1/')
  case "$profile" in
    minimal|standard|strict) pass "$hook_name: profile=$profile, gate integrated" ;;
    *) fail "$hook_name: invalid profile '$profile'" ;;
  esac
done

echo ""

# ─── 4. JSON Files ───────────────────────────────────────────────────

echo "--- JSON Validation ---"

json_files=(
  "core/settings.json.template"
  "core/hooks/skill-rules.json"
  "core/mcp/registry.json"
  ".claude-plugin/plugin.json"
  "skills_index.json"
)

# Add hooks.json if it exists
[ -f "$REPO_ROOT/hooks/hooks.json" ] && json_files+=("hooks/hooks.json")

for json_rel in "${json_files[@]}"; do
  json_file="$REPO_ROOT/$json_rel"
  if [ ! -f "$json_file" ]; then
    fail "$json_rel: file not found"
    continue
  fi

  # Convert path for Node.js on Windows
  node_file="$json_file"
  if command -v cygpath &>/dev/null; then
    node_file="$(cygpath -m "$json_file")"
  fi

  if node -e "JSON.parse(require('fs').readFileSync('$node_file','utf8'))" 2>/dev/null; then
    pass "$json_rel: valid JSON"
  else
    fail "$json_rel: invalid JSON"
  fi
done

echo ""

# ─── 5. Cross-References ─────────────────────────────────────────────

echo "--- Cross-Reference Checks ---"

# skill-rules.json points to existing skill directories
if [ -f "$REPO_ROOT/core/hooks/skill-rules.json" ]; then
  node_rules="$REPO_ROOT/core/hooks/skill-rules.json"
  if command -v cygpath &>/dev/null; then
    node_rules="$(cygpath -m "$node_rules")"
  fi

  while IFS= read -r skill_name; do
    [ -z "$skill_name" ] && continue
    # Remove leading /
    skill_name="${skill_name#/}"
    if [ -d "$REPO_ROOT/core/skills/$skill_name" ] || [ -d "$REPO_ROOT/stacks/$skill_name" ]; then
      pass "skill-rules → $skill_name: directory exists"
    else
      fail "skill-rules → $skill_name: directory not found"
    fi
  done < <(node -e "
    const r = JSON.parse(require('fs').readFileSync('$node_rules','utf8'));
    r.rules.forEach(rule => console.log(rule.skill));
  " 2>/dev/null)
fi

# skills_index.json paths match existing directories
if [ -f "$REPO_ROOT/skills_index.json" ]; then
  node_idx="$REPO_ROOT/skills_index.json"
  if command -v cygpath &>/dev/null; then
    node_idx="$(cygpath -m "$node_idx")"
  fi

  while IFS= read -r line; do
    [ -z "$line" ] && continue
    skill_id=$(echo "$line" | cut -d'|' -f1)
    skill_path=$(echo "$line" | cut -d'|' -f2)
    if [ -d "$REPO_ROOT/$skill_path" ]; then
      pass "skills_index → $skill_id: path exists"
    else
      fail "skills_index → $skill_id: path '$skill_path' not found"
    fi
  done < <(node -e "
    const idx = JSON.parse(require('fs').readFileSync('$node_idx','utf8'));
    idx.skills.forEach(s => console.log(s.id + '|' + s.path));
  " 2>/dev/null)
fi

echo ""

# ─── 6. Hook Profile Consistency ─────────────────────────────────────

echo "--- Hook Profile Consistency ---"

# Check that hook-profiles.md counts match actual hook counts
minimal_count=$(grep -l 'HOOK_MIN_PROFILE="minimal"' "$REPO_ROOT/core/hooks/"*.sh 2>/dev/null | wc -l)
standard_count=$(grep -l 'HOOK_MIN_PROFILE="standard"' "$REPO_ROOT/core/hooks/"*.sh 2>/dev/null | wc -l)
strict_count=$(grep -l 'HOOK_MIN_PROFILE="strict"' "$REPO_ROOT/core/hooks/"*.sh 2>/dev/null | wc -l)
total_hooks=$((minimal_count + standard_count + strict_count))
hook_files=$(find "$REPO_ROOT/core/hooks" -name '*.sh' | wc -l)

if [ "$total_hooks" -eq "$hook_files" ]; then
  pass "all $hook_files hooks have a profile assignment"
else
  fail "$total_hooks hooks have profiles but $hook_files hook files exist"
fi

pass "profile distribution: $minimal_count minimal, $standard_count standard, $strict_count strict"

echo ""

# ─── 7. settings.json.template Structure ─────────────────────────────

echo "--- Settings Template ---"

template="$REPO_ROOT/core/settings.json.template"
if [ -f "$template" ]; then
  node_tmpl="$template"
  if command -v cygpath &>/dev/null; then
    node_tmpl="$(cygpath -m "$template")"
  fi

  # Check required top-level keys
  for key in hooks mcpServers language env statusLine; do
    if node -e "const s=JSON.parse(require('fs').readFileSync('$node_tmpl','utf8')); if(!s.$key) process.exit(1)" 2>/dev/null; then
      pass "settings.json.template has '$key'"
    else
      fail "settings.json.template missing '$key'"
    fi
  done

  # Check hook event types exist
  for event in PreToolUse PostToolUse UserPromptSubmit Stop SessionStart StopFailure TaskCompleted PermissionDenied; do
    if node -e "const s=JSON.parse(require('fs').readFileSync('$node_tmpl','utf8')); if(!s.hooks['$event']) process.exit(1)" 2>/dev/null; then
      pass "settings.json.template has hook event '$event'"
    else
      warn "settings.json.template missing hook event '$event'"
    fi
  done
fi

echo ""

# ─── Summary ─────────────────────────────────────────────────────────

echo "============================================================"
echo "Results: $PASS passed, $FAIL failed, $WARN warnings ($TOTAL checks)"
echo "============================================================"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi

exit 0

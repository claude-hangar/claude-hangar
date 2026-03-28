#!/usr/bin/env bash
# Test Suite: Setup Script
# Validates that setup.sh exists, is executable, and produces correct output.
# Usage: bash tests/test-setup.sh

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
echo "Claude Hangar — Setup Test Suite"
echo "============================================================"
echo ""

# ============================================================
# 1. setup.sh existence and permissions
# ============================================================

echo "--- setup.sh ---"

test_assert \
  "setup.sh exists" \
  "[ -f '$REPO_ROOT/setup.sh' ]"

test_assert \
  "setup.sh is executable (or we are on Windows)" \
  "[ -x '$REPO_ROOT/setup.sh' ] || [[ \"\$(uname -s)\" == MINGW* ]] || [[ \"\$(uname -s)\" == MSYS* ]]"

# ============================================================
# 2. --check mode (dry run without side effects)
# ============================================================

echo ""
echo "--- --check mode ---"

if [ -f "$REPO_ROOT/setup.sh" ]; then
  CHECK_OUTPUT=$(bash "$REPO_ROOT/setup.sh" --check 2>&1) || true
  CHECK_EXIT=$?

  test_assert \
    "--check mode runs without crash" \
    "[ $CHECK_EXIT -eq 0 ] || [ $CHECK_EXIT -eq 1 ]"

  test_assert \
    "--check mode produces output" \
    "[ -n '$CHECK_OUTPUT' ]"
else
  echo "  SKIP  --check mode (setup.sh not found)"
  TOTAL=$((TOTAL + 2))
  FAIL=$((FAIL + 2))
fi

# ============================================================
# 3. Required directories exist
# ============================================================

echo ""
echo "--- Required directories ---"

test_assert \
  "core/ directory exists" \
  "[ -d '$REPO_ROOT/core' ]"

test_assert \
  "core/hooks/ directory exists" \
  "[ -d '$REPO_ROOT/core/hooks' ]"

test_assert \
  "core/agents/ directory exists" \
  "[ -d '$REPO_ROOT/core/agents' ]"

test_assert \
  "templates/ directory exists" \
  "[ -d '$REPO_ROOT/templates' ]"

test_assert \
  "templates/ci/ directory exists" \
  "[ -d '$REPO_ROOT/templates/ci' ]"

test_assert \
  "registry/ directory exists" \
  "[ -d '$REPO_ROOT/registry' ]"

test_assert \
  "stacks/ directory exists" \
  "[ -d '$REPO_ROOT/stacks' ]"

test_assert \
  "docs/ directory exists" \
  "[ -d '$REPO_ROOT/docs' ]"

test_assert \
  "tests/ directory exists" \
  "[ -d '$REPO_ROOT/tests' ]"

# ============================================================
# 4. Critical files exist
# ============================================================

echo ""
echo "--- Critical files ---"

test_assert \
  "README.md exists" \
  "[ -f '$REPO_ROOT/README.md' ]"

test_assert \
  "CLAUDE.md exists" \
  "[ -f '$REPO_ROOT/CLAUDE.md' ]"

test_assert \
  "LICENSE exists" \
  "[ -f '$REPO_ROOT/LICENSE' ]"

# ============================================================
# 5. Skill validation (frontmatter)
# ============================================================

echo ""
echo "--- Skill validation ---"

SKILL_ERRORS=0
for skill_dir in "$REPO_ROOT"/core/skills/*/; do
  [ -d "$skill_dir" ] || continue
  skill_name=$(basename "$skill_dir")
  [ "$skill_name" = "_shared" ] && continue

  skill_file="$skill_dir/SKILL.md"

  TOTAL=$((TOTAL + 1))
  if [ -f "$skill_file" ]; then
    # Check for frontmatter (--- at line 1)
    if head -1 "$skill_file" | grep -q '^---'; then
      echo "  PASS  Skill $skill_name has frontmatter"
      PASS=$((PASS + 1))
    else
      echo "  FAIL  Skill $skill_name missing frontmatter"
      FAIL=$((FAIL + 1))
      SKILL_ERRORS=$((SKILL_ERRORS + 1))
    fi
  else
    echo "  FAIL  Skill $skill_name missing SKILL.md"
    FAIL=$((FAIL + 1))
    SKILL_ERRORS=$((SKILL_ERRORS + 1))
  fi
done

# ============================================================
# 6. Agent validation (frontmatter)
# ============================================================

echo ""
echo "--- Agent validation ---"

for agent_file in "$REPO_ROOT"/core/agents/*.md; do
  [ -f "$agent_file" ] || continue
  agent_name=$(basename "$agent_file" .md)

  TOTAL=$((TOTAL + 1))
  # Check for frontmatter with model and description
  if head -5 "$agent_file" | grep -q '^---'; then
    if head -10 "$agent_file" | grep -q 'model:'; then
      echo "  PASS  Agent $agent_name has model in frontmatter"
      PASS=$((PASS + 1))
    else
      echo "  FAIL  Agent $agent_name missing model in frontmatter"
      FAIL=$((FAIL + 1))
    fi
  else
    echo "  FAIL  Agent $agent_name missing frontmatter"
    FAIL=$((FAIL + 1))
  fi
done

# ============================================================
# 7. skill-rules.json cross-reference
# ============================================================

echo ""
echo "--- skill-rules.json validation ---"

RULES_FILE="$REPO_ROOT/core/hooks/skill-rules.json"
if [ -f "$RULES_FILE" ]; then
  # Extract skill names from rules and check they exist as directories
  RULE_SKILLS=$(RULES_FILE="$RULES_FILE" node -e "
    const rules = JSON.parse(require('fs').readFileSync(process.env.RULES_FILE, 'utf8'));
    rules.rules.forEach(r => console.log(r.skill.replace('/', '')));
  " 2>/dev/null) || true

  while IFS= read -r skill; do
    [ -z "$skill" ] && continue
    TOTAL=$((TOTAL + 1))
    # Skills can be in core/skills/ or stacks/
    if [ -d "$REPO_ROOT/core/skills/$skill" ] || [ -d "$REPO_ROOT/stacks/$skill" ]; then
      echo "  PASS  Rule /$skill points to existing skill"
      PASS=$((PASS + 1))
    else
      echo "  FAIL  Rule /$skill points to non-existent skill directory"
      FAIL=$((FAIL + 1))
    fi
  done <<< "$RULE_SKILLS"
else
  echo "  SKIP  skill-rules.json not found"
fi

# ============================================================
# 8. Registry schema validates example
# ============================================================

echo ""
echo "--- Registry validation ---"

test_assert \
  "registry.schema.json exists" \
  "[ -f '$REPO_ROOT/registry/registry.schema.json' ]"

test_assert \
  "example-registry.json exists" \
  "[ -f '$REPO_ROOT/registry/example-registry.json' ]"

REGISTRY_FILE="$REPO_ROOT/registry/example-registry.json"
test_assert \
  "example-registry.json is valid JSON" \
  "REGISTRY_FILE='$REGISTRY_FILE' node -e \"JSON.parse(require('fs').readFileSync(process.env.REGISTRY_FILE,'utf8'))\" 2>/dev/null"

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

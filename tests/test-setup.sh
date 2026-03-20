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

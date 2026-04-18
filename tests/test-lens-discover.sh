#!/usr/bin/env bash
# Tests for core/lib/lens-discover.sh
# Verifies frontmatter parsing, glob discovery, category filtering, cost estimation.

# No set -euo pipefail — we count failures explicitly

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

PASS=0
FAIL=0

assert() {
  local description="$1"
  local actual="$2"
  local expected="$3"
  if [ "$actual" = "$expected" ]; then
    echo "  PASS  $description"
    PASS=$((PASS + 1))
  else
    echo "  FAIL  $description"
    echo "        expected: $expected"
    echo "        actual:   $actual"
    FAIL=$((FAIL + 1))
  fi
}

assert_contains() {
  local description="$1"
  local haystack="$2"
  local needle="$3"
  if echo "$haystack" | grep -q "$needle"; then
    echo "  PASS  $description"
    PASS=$((PASS + 1))
  else
    echo "  FAIL  $description (needle not found: $needle)"
    FAIL=$((FAIL + 1))
  fi
}

export HANGAR_HOME="$REPO_ROOT"
# shellcheck source=/dev/null
. "$REPO_ROOT/core/lib/lens-discover.sh"

echo "--- lens_discover_for_stack ---"

ASTRO_JSON=$(lens_discover_for_stack astro)
assert_contains "astro discovers content-collections" "$ASTRO_JSON" "content-collections"
assert_contains "astro discovers view-transitions" "$ASTRO_JSON" "view-transitions"

SVK_JSON=$(lens_discover_for_stack sveltekit)
assert_contains "sveltekit discovers server-load-security" "$SVK_JSON" "server-load-security"
assert_contains "sveltekit discovers form-actions-csrf" "$SVK_JSON" "form-actions-csrf"
assert_contains "sveltekit discovers runes-migration" "$SVK_JSON" "runes-migration"

DB_JSON=$(lens_discover_for_stack database)
assert_contains "database discovers migration-safety" "$DB_JSON" "migration-safety"
assert_contains "database discovers index-strategy" "$DB_JSON" "index-strategy"
assert_contains "database discovers transaction-boundaries" "$DB_JSON" "transaction-boundaries"

NONEXIST=$(lens_discover_for_stack nonexistent-stack)
assert "missing stack returns empty array" "$NONEXIST" "[]"

# README.md should be skipped, not parsed
assert_contains "README.md not in output (sveltekit)" \
  "$([ -z "$(echo "$SVK_JSON" | grep -o '"name":"README"')" ] && echo OK || echo FAIL)" "OK"

echo ""
echo "--- lens_discover_filtered ---"

SEC_JSON=$(lens_discover_filtered sveltekit security)
assert_contains "sveltekit security filter includes server-load-security" "$SEC_JSON" "server-load-security"
assert_contains "sveltekit security filter includes form-actions-csrf" "$SEC_JSON" "form-actions-csrf"
# Migration lens should NOT be in security filter
NOT_MIG=$([ -z "$(echo "$SEC_JSON" | grep -o '"name":"runes-migration"')" ] && echo OK || echo FAIL)
assert "sveltekit security filter excludes runes-migration" "$NOT_MIG" "OK"

echo ""
echo "--- lens_estimate_cost ---"

EST=$(lens_estimate_cost sveltekit)
assert_contains "sveltekit cost estimate mentions lens count" "$EST" "lens"
assert_contains "sveltekit cost estimate mentions USD" "$EST" "USD"

echo ""
echo "============================================================"
echo "Results: $PASS passed, $FAIL failed, $((PASS + FAIL)) total"
echo "============================================================"

[ "$FAIL" -gt 0 ] && exit 1
exit 0

#!/usr/bin/env bash
# test-models.sh — Validates model references across agents and configs
# Ensures model IDs stay current with Claude model naming.
# Usage: bash tests/test-models.sh
#
# No set -euo pipefail — tests must tolerate expected failures

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ERRORS=0
TESTS=0

# Current valid model patterns (update these when models change)
# Aliases: short names used in agent frontmatter
# Full IDs: complete model identifiers used in defaults.json
VALID_ALIASES="opus|sonnet|haiku"
VALID_FULL_IDS="claude-opus-4-6|claude-sonnet-4-6|claude-haiku-4-5-20251001"

echo "============================================================"
echo "Claude Hangar — Model Reference Validation"
echo "============================================================"
echo ""

# ============================================================
# 1. Agent definitions — model frontmatter
# ============================================================

echo "--- agent model references ---"

for agent_file in "$SCRIPT_DIR"/core/agents/*.md; do
  [ -f "$agent_file" ] || continue
  TESTS=$((TESTS + 1))

  # Extract model from YAML frontmatter (first occurrence)
  model=$(grep -i "^model:" "$agent_file" | head -1 | sed 's/model:[[:space:]]*//' | tr -d ' "'"'"'')

  if [ -z "$model" ]; then
    echo "  SKIP: $(basename "$agent_file") — no model field"
    TESTS=$((TESTS - 1))
    continue
  fi

  if echo "$model" | grep -qiE "^($VALID_ALIASES|$VALID_FULL_IDS)$"; then
    echo "  OK: $(basename "$agent_file") — model: $model"
  else
    echo "  FAIL: $(basename "$agent_file") — invalid model: '$model'"
    ERRORS=$((ERRORS + 1))
  fi
done

# ============================================================
# 2. defaults.json — model ID mappings
# ============================================================

echo ""
echo "--- defaults.json model IDs ---"

TESTS=$((TESTS + 1))
DEFAULTS_FILE="$SCRIPT_DIR/core/lib/defaults.json"

if [ -f "$DEFAULTS_FILE" ]; then
  # Use node to parse JSON and validate model IDs
  DEFAULTS_PATH="$DEFAULTS_FILE" node -e "
    const fs = require('fs');
    const defaults = JSON.parse(fs.readFileSync(process.env.DEFAULTS_PATH, 'utf8'));
    const models = defaults.models || {};
    const valid = /^(${VALID_FULL_IDS})$/;
    let ok = true;
    for (const [alias, id] of Object.entries(models)) {
      if (!valid.test(id)) {
        console.log('  FAIL: defaults.json models.' + alias + ' = ' + id + ' — not a current model ID');
        ok = false;
      } else {
        console.log('  OK: defaults.json models.' + alias + ' = ' + id);
      }
    }
    if (!ok) process.exit(1);
  " 2>/dev/null
  if [ $? -ne 0 ]; then
    ERRORS=$((ERRORS + 1))
  fi
else
  echo "  SKIP: defaults.json not found"
  TESTS=$((TESTS - 1))
fi

# ============================================================
# 3. Cross-check: agent aliases resolve to defaults.json
# ============================================================

echo ""
echo "--- alias-to-ID cross-check ---"

if [ -f "$DEFAULTS_FILE" ]; then
  for agent_file in "$SCRIPT_DIR"/core/agents/*.md; do
    [ -f "$agent_file" ] || continue

    model=$(grep -i "^model:" "$agent_file" | head -1 | sed 's/model:[[:space:]]*//' | tr -d ' "'"'"'')
    [ -z "$model" ] && continue

    # Only check aliases (not full IDs)
    if echo "$model" | grep -qiE "^($VALID_ALIASES)$"; then
      TESTS=$((TESTS + 1))
      AGENT_NAME=$(basename "$agent_file")

      # Verify this alias exists as a key in defaults.json models
      ALIAS_LOWER=$(echo "$model" | tr '[:upper:]' '[:lower:]')
      DEFAULTS_PATH="$DEFAULTS_FILE" ALIAS="$ALIAS_LOWER" node -e "
        const fs = require('fs');
        const defaults = JSON.parse(fs.readFileSync(process.env.DEFAULTS_PATH, 'utf8'));
        const models = defaults.models || {};
        const alias = process.env.ALIAS;
        if (models[alias]) {
          console.log('  OK: ' + process.argv[1] + ' alias \"' + alias + '\" -> ' + models[alias]);
        } else {
          console.log('  FAIL: ' + process.argv[1] + ' alias \"' + alias + '\" not found in defaults.json');
          process.exit(1);
        }
      " "$AGENT_NAME" 2>/dev/null
      if [ $? -ne 0 ]; then
        ERRORS=$((ERRORS + 1))
      fi
    fi
  done
else
  echo "  SKIP: defaults.json not found — cannot cross-check"
fi

# ============================================================
# Summary
# ============================================================

echo ""
echo "============================================================"
echo "Results: $TESTS tests, $ERRORS failures"
echo "============================================================"

[ "$ERRORS" -gt 0 ] && exit 1
exit 0

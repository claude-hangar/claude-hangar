#!/usr/bin/env bash
# Hook: Stop Batch Format
# Trigger: Stop (session end, async, 30s timeout)
# Runs project formatters once on all files edited during the session,
# instead of formatting after every individual Edit/Write.
#
# Companion to: batch-format-collector.sh (PostToolUse hook)
# Architecture:
#   PostToolUse → batch-format-collector.sh appends paths to edited-files.txt
#   Stop → this hook deduplicates the list and runs detected formatters
#
# Output: stderr only (debugging). No stdout on allow path.

# No set -euo pipefail — hooks must be resilient on Windows

# Hook profile gate
export HOOK_NAME="stop-batch-format"; export HOOK_MIN_PROFILE="strict"
source "${HOME}/.claude/lib/hook-gate.sh" 2>/dev/null || true

COLLECT_FILE="$HOME/.claude/.batch-format/edited-files.txt"

# Exit silently if no files were collected
[ ! -f "$COLLECT_FILE" ] && exit 0
if [ ! -s "$COLLECT_FILE" ]; then
  rm -f "$COLLECT_FILE" 2>/dev/null || true
  exit 0
fi

# Read and deduplicate file list (filter out files that no longer exist)
UNIQUE_FILES=$(sort -u "$COLLECT_FILE" 2>/dev/null) || true
if [ -z "$UNIQUE_FILES" ]; then
  rm -f "$COLLECT_FILE" 2>/dev/null || true
  exit 0
fi

EXISTING_FILES=""
while IFS= read -r filepath; do
  [ -f "$filepath" ] && EXISTING_FILES="${EXISTING_FILES}${filepath}"$'\n'
done <<< "$UNIQUE_FILES"
EXISTING_FILES="${EXISTING_FILES%$'\n'}"

# Nothing to format after filtering
if [ -z "$EXISTING_FILES" ]; then
  rm -f "$COLLECT_FILE" 2>/dev/null || true
  exit 0
fi

FILE_COUNT=$(echo "$EXISTING_FILES" | wc -l | tr -d ' ')

# Detect project root from stdin cwd or fallback to PWD
INPUT=$(cat 2>/dev/null) || true
CWD=$(echo "$INPUT" | node -e "
  const d = JSON.parse(require('fs').readFileSync(0, 'utf8'));
  console.log(d.cwd || process.cwd());
" 2>/dev/null || echo "$PWD")

# Detect available formatters in the project
# Priority: biome > prettier > ruff/black (can stack for mixed projects)
JS_FORMATTER=""
PY_FORMATTER=""

# Check for Biome
if [ -f "$CWD/biome.json" ] || [ -f "$CWD/biome.jsonc" ]; then
  JS_FORMATTER="biome"
fi

# Check for Prettier (only if biome not found for JS/TS)
if [ -z "$JS_FORMATTER" ]; then
  PRETTIER_FOUND=false
  for rc in "$CWD/.prettierrc" "$CWD/.prettierrc.json" "$CWD/.prettierrc.yml" "$CWD/.prettierrc.yaml" "$CWD/.prettierrc.js" "$CWD/.prettierrc.cjs" "$CWD/.prettierrc.mjs" "$CWD/.prettierrc.toml" "$CWD/prettier.config.js" "$CWD/prettier.config.cjs" "$CWD/prettier.config.mjs" "$CWD/prettier.config.ts"; do
    if [ -f "$rc" ]; then
      PRETTIER_FOUND=true
      break
    fi
  done
  # Also check package.json for "prettier" key
  if [ "$PRETTIER_FOUND" = "false" ] && [ -f "$CWD/package.json" ]; then
    node -e "
      const pkg = JSON.parse(require('fs').readFileSync(process.argv[1], 'utf8'));
      if (pkg.prettier) process.exit(0); else process.exit(1);
    " "$CWD/package.json" 2>/dev/null && PRETTIER_FOUND=true
  fi
  [ "$PRETTIER_FOUND" = "true" ] && JS_FORMATTER="prettier"
fi

# Check for Python formatters (ruff or black via pyproject.toml)
if [ -f "$CWD/pyproject.toml" ]; then
  if grep -q '\[tool\.ruff\]' "$CWD/pyproject.toml" 2>/dev/null; then
    PY_FORMATTER="ruff"
  elif grep -q '\[tool\.black\]' "$CWD/pyproject.toml" 2>/dev/null; then
    PY_FORMATTER="black"
  fi
fi

# Exit silently if no formatter detected
if [ -z "$JS_FORMATTER" ] && [ -z "$PY_FORMATTER" ]; then
  rm -f "$COLLECT_FILE" 2>/dev/null || true
  exit 0
fi

# Split files by type for appropriate formatters
JS_FILES=""
PY_FILES=""
OTHER_FILES=""

while IFS= read -r filepath; do
  case "$filepath" in
    *.js|*.jsx|*.ts|*.tsx|*.mjs|*.cjs|*.json|*.jsonc|*.css|*.scss|*.less|*.html|*.vue|*.svelte|*.astro|*.md|*.yaml|*.yml)
      JS_FILES="${JS_FILES}${filepath}"$'\n'
      ;;
    *.py)
      PY_FILES="${PY_FILES}${filepath}"$'\n'
      ;;
    *)
      OTHER_FILES="${OTHER_FILES}${filepath}"$'\n'
      ;;
  esac
done <<< "$EXISTING_FILES"

JS_FILES="${JS_FILES%$'\n'}"
PY_FILES="${PY_FILES%$'\n'}"
FORMATTED=0
ERRORS=0

# Run JS/TS/Web formatter
if [ -n "$JS_FILES" ] && [ -n "$JS_FORMATTER" ]; then
  # Write file list to temp file for xargs-style batch processing
  TMPFILE="${TEMP:-/tmp}/batch-format-js-$$"
  echo "$JS_FILES" > "$TMPFILE" 2>/dev/null

  if [ "$JS_FORMATTER" = "biome" ]; then
    # Biome accepts file paths as arguments
    xargs npx biome format --write < "$TMPFILE" 2>&1 | while IFS= read -r line; do echo "[batch-format] $line" >&2; done
    RESULT=${PIPESTATUS[0]:-0}
  elif [ "$JS_FORMATTER" = "prettier" ]; then
    xargs npx prettier --write < "$TMPFILE" 2>&1 | while IFS= read -r line; do echo "[batch-format] $line" >&2; done
    RESULT=${PIPESTATUS[0]:-0}
  fi

  if [ "${RESULT:-0}" -eq 0 ]; then
    JS_COUNT=$(echo "$JS_FILES" | wc -l | tr -d ' ')
    FORMATTED=$((FORMATTED + JS_COUNT))
    echo "[batch-format] Formatted $JS_COUNT file(s) with $JS_FORMATTER" >&2
  else
    ERRORS=$((ERRORS + 1))
    echo "[batch-format] WARNING: $JS_FORMATTER exited with code $RESULT" >&2
  fi

  rm -f "$TMPFILE" 2>/dev/null || true
fi

# Run Python formatter
if [ -n "$PY_FILES" ] && [ -n "$PY_FORMATTER" ]; then
  TMPFILE="${TEMP:-/tmp}/batch-format-py-$$"
  echo "$PY_FILES" > "$TMPFILE" 2>/dev/null

  if [ "$PY_FORMATTER" = "ruff" ]; then
    xargs ruff format < "$TMPFILE" 2>&1 | while IFS= read -r line; do echo "[batch-format] $line" >&2; done
    RESULT=${PIPESTATUS[0]:-0}
  elif [ "$PY_FORMATTER" = "black" ]; then
    xargs black < "$TMPFILE" 2>&1 | while IFS= read -r line; do echo "[batch-format] $line" >&2; done
    RESULT=${PIPESTATUS[0]:-0}
  fi

  if [ "${RESULT:-0}" -eq 0 ]; then
    PY_COUNT=$(echo "$PY_FILES" | wc -l | tr -d ' ')
    FORMATTED=$((FORMATTED + PY_COUNT))
    echo "[batch-format] Formatted $PY_COUNT file(s) with $PY_FORMATTER" >&2
  else
    ERRORS=$((ERRORS + 1))
    echo "[batch-format] WARNING: $PY_FORMATTER exited with code $RESULT" >&2
  fi

  rm -f "$TMPFILE" 2>/dev/null || true
fi

# Summary to stderr
if [ "$FORMATTED" -gt 0 ] || [ "$ERRORS" -gt 0 ]; then
  echo "[batch-format] Session complete: $FORMATTED formatted, $ERRORS error(s), $FILE_COUNT total tracked" >&2
fi

# Cleanup collector file
rm -f "$COLLECT_FILE" 2>/dev/null || true

exit 0

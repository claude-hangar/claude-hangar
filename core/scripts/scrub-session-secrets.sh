#!/usr/bin/env bash
# Scrub session-log secrets from ~/.claude/ artifacts.
#
# WHAT it cleans:
#   - ~/.claude/history.jsonl
#   - ~/.claude/projects/**/*.jsonl
#   - ~/.claude/file-history/**
#   - ~/.claude/sessions-index.json
#
# WHAT it replaces:
#   Known secret patterns get swapped for `<KIND>_REDACTED_<N>` placeholders
#   that preserve the original length so JSONL parsers stay happy.
#
# USAGE:
#   bash core/scripts/scrub-session-secrets.sh              # dry-run, count only
#   bash core/scripts/scrub-session-secrets.sh --apply      # actually rewrite files
#   bash core/scripts/scrub-session-secrets.sh --apply -v   # verbose per-file output
#
# EXITS:
#   0 — done (dry-run or apply)
#   1 — missing Node (required for safe JSONL handling)

# No set -euo pipefail — must be resilient on Windows Git Bash

APPLY=0
VERBOSE=0
for arg in "$@"; do
  case "$arg" in
    --apply) APPLY=1 ;;
    -v|--verbose) VERBOSE=1 ;;
    -h|--help)
      sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
  esac
done

if ! command -v node >/dev/null 2>&1; then
  echo "scrub-session-secrets: node is required, not found on PATH" >&2
  exit 1
fi

HOME_DIR="${USERPROFILE:-$HOME}"
BASE="$HOME_DIR/.claude"
if [ ! -d "$BASE" ]; then
  echo "scrub-session-secrets: $BASE does not exist — nothing to do"
  exit 0
fi

# Collect target files
TARGETS=()
[ -f "$BASE/history.jsonl" ] && TARGETS+=("$BASE/history.jsonl")
[ -f "$BASE/sessions-index.json" ] && TARGETS+=("$BASE/sessions-index.json")
while IFS= read -r -d '' f; do TARGETS+=("$f"); done < <(find "$BASE/projects" -type f \( -name '*.jsonl' -o -name '*.json' \) -print0 2>/dev/null)
while IFS= read -r -d '' f; do TARGETS+=("$f"); done < <(find "$BASE/file-history" -type f -print0 2>/dev/null)

if [ "${#TARGETS[@]}" -eq 0 ]; then
  echo "scrub-session-secrets: no candidate files"
  exit 0
fi

MODE="dry-run"
[ "$APPLY" -eq 1 ] && MODE="apply"
echo "scrub-session-secrets: mode=$MODE, candidates=${#TARGETS[@]}"

TOTAL_HITS=0
TOTAL_FILES=0

for f in "${TARGETS[@]}"; do
  # node does the regex work — portable + safe for JSONL lines
  RESULT=$(APPLY="$APPLY" node -e "
    const fs = require('fs');
    const p = process.argv[1];
    let body;
    try { body = fs.readFileSync(p, 'utf8'); } catch (e) { console.log('0 0'); process.exit(0); }

    const patterns = [
      [/ghp_[A-Za-z0-9]{36}/g,         'ghp_REDACTED_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'],
      [/gho_[A-Za-z0-9]{36}/g,         'gho_REDACTED_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'],
      [/ghs_[A-Za-z0-9]{36}/g,         'ghs_REDACTED_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'],
      [/github_pat_[A-Za-z0-9_]{22,}/g, 'github_pat_REDACTED_xxxxxxxxxxxxxxxx'],
      [/sk-ant-[A-Za-z0-9_-]{20,}/g,   'sk-ant-REDACTED_xxxxxxxxxxxxxxxxxxx'],
      [/sk-proj-[A-Za-z0-9]{20,}/g,    'sk-proj-REDACTED_xxxxxxxxxxxxxxxxxx'],
      [/AKIA[0-9A-Z]{16}/g,            'AKIA_REDACTED_XXXXXXXXXXXX'],
      [/(postgres|mysql|mongodb):\/\/([^:\/\s\"']+):([^@\s\"']+)@/g, '\$1://\$2:REDACTED@'],
      [/-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----[\s\S]*?-----END \\1?PRIVATE KEY-----/g, '-----BEGIN PRIVATE KEY-----REDACTED-----END PRIVATE KEY-----'],
    ];

    let hits = 0;
    let out = body;
    for (const [re, rep] of patterns) {
      const m = out.match(re);
      if (m) hits += m.length;
      out = out.replace(re, rep);
    }

    if (hits > 0 && process.env.APPLY === '1') {
      // Write atomically via tmp file
      const tmp = p + '.scrub-tmp';
      fs.writeFileSync(tmp, out);
      fs.renameSync(tmp, p);
    }
    console.log(hits + ' ' + (hits > 0 ? 1 : 0));
  " "$f" 2>/dev/null)

  HITS=$(echo "$RESULT" | awk '{print $1}')
  FILES=$(echo "$RESULT" | awk '{print $2}')
  HITS=${HITS:-0}
  FILES=${FILES:-0}
  TOTAL_HITS=$((TOTAL_HITS + HITS))
  TOTAL_FILES=$((TOTAL_FILES + FILES))
  if [ "$HITS" -gt 0 ] && [ "$VERBOSE" -eq 1 ]; then
    echo "  $HITS hit(s) in $f"
  fi
done

echo "scrub-session-secrets: $TOTAL_HITS total match(es) across $TOTAL_FILES file(s)"
if [ "$APPLY" -eq 0 ] && [ "$TOTAL_HITS" -gt 0 ]; then
  echo "scrub-session-secrets: DRY-RUN — re-run with --apply to scrub"
fi

exit 0

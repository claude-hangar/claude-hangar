#!/usr/bin/env bash
# Helper: Lens Discovery & Dispatch Planning
# Scans stacks/{stack}/lenses/*.md, parses frontmatter, emits dispatch plan as
# JSON for orchestrator consumption. Pattern adapted from RepoLens.
#
# Usage:
#   source "$HOME/.claude/lib/lens-discover.sh"
#   lens_discover_for_stack sveltekit            # → JSON to stdout
#   lens_discover_filtered sveltekit security    # → JSON, only category=security
#   lens_estimate_cost sveltekit                 # → est. USD lower bound
#
# Environment:
#   HANGAR_HOME              — defaults to $HOME/.claude (where stacks/ lives after deploy)
#   HANGAR_COST_PER_CALL_USD — defaults to 0.02
#   HANGAR_LENS_MAX_PARALLEL — defaults to 4 (orchestrator semaphore cap)
#
# Output JSON shape (one entry per lens):
#   [{"name":"server-load-security","stack":"sveltekit","category":"security",
#     "effort_min":2,"effort_max":6,"path":"/abs/path/to/lens.md"}, ...]
#
# Read-only. Never modifies lens files. Never spawns sub-agents.

# No set -euo pipefail — must be source-able safely

_HANGAR_HOME="${HANGAR_HOME:-$HOME/.claude}"
_HANGAR_COST_PER_CALL="${HANGAR_COST_PER_CALL_USD:-0.02}"

_lens_parse_frontmatter() {
  # $1 = path to lens .md
  # Emits one JSON object to stdout, or nothing if frontmatter missing/invalid.
  local path="$1"
  [ -f "$path" ] || return 0
  [ "$(basename "$path")" = "README.md" ] && return 0

  node -e '
    (() => {
      const fs = require("fs");
      const path = process.argv[1];
      const text = fs.readFileSync(path, "utf8");
      const m = text.match(/^---\s*\n([\s\S]*?)\n---/);
      if (!m) return;
      const fm = {};
      for (const line of m[1].split(/\n/)) {
        const kv = line.match(/^(\w+):\s*(.*)$/);
        if (kv) fm[kv[1]] = kv[2].trim();
      }
      if (!fm.name || !fm.stack || !fm.category) return;
      const out = {
        name: fm.name,
        stack: fm.stack,
        category: fm.category,
        effort_min: Number(fm.effort_min || 1),
        effort_max: Number(fm.effort_max || 4),
        path: path,
      };
      process.stdout.write(JSON.stringify(out));
    })();
  ' "$path" 2>/dev/null
}

lens_discover_for_stack() {
  # $1 = stack name (sveltekit, astro, database, ...)
  local stack="$1"
  local dir="$_HANGAR_HOME/stacks/$stack/lenses"
  [ -d "$dir" ] || { echo "[]"; return 0; }

  local first=1
  printf '['
  for f in "$dir"/*.md; do
    [ -f "$f" ] || continue
    local entry
    entry="$(_lens_parse_frontmatter "$f")"
    [ -z "$entry" ] && continue
    if [ $first -eq 1 ]; then
      first=0
    else
      printf ','
    fi
    printf '%s' "$entry"
  done
  printf ']\n'
}

lens_discover_filtered() {
  # $1 = stack, $2 = category filter
  local stack="$1"
  local cat="$2"
  lens_discover_for_stack "$stack" | node -e '
    let buf = ""; process.stdin.on("data", d => buf += d);
    process.stdin.on("end", () => {
      const cat = process.argv[1];
      try {
        const arr = JSON.parse(buf);
        process.stdout.write(JSON.stringify(arr.filter(l => l.category === cat)));
      } catch (e) { process.stdout.write("[]"); }
    });
  ' "$cat"
}

lens_estimate_cost() {
  # $1 = stack (or path to JSON file via $2 if needed)
  local stack="$1"
  local cost_per="$_HANGAR_COST_PER_CALL"
  lens_discover_for_stack "$stack" | node -e '
    let buf = ""; process.stdin.on("data", d => buf += d);
    process.stdin.on("end", () => {
      const cost = Number(process.argv[1]);
      try {
        const arr = JSON.parse(buf);
        const calls = arr.reduce((s, l) => s + (l.effort_max || 4), 0);
        const usd = (calls * cost).toFixed(2);
        process.stdout.write(`${arr.length} lens(es), ~${calls} tool calls, est. lower-bound USD ${usd}\n`);
      } catch (e) { process.stdout.write("0 lenses, est. USD 0.00\n"); }
    });
  ' "$cost_per"
}

# When sourced, expose nothing implicitly. When executed directly, run a self-test.
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  echo "lens-discover.sh self-test"
  for stack in astro sveltekit database; do
    echo "--- $stack ---"
    lens_discover_for_stack "$stack"
    echo
    lens_estimate_cost "$stack"
  done
fi

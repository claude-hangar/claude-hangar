#!/usr/bin/env bash
# Hook: Config Protection
# Trigger: PreToolUse (Edit, Write)
# Blocks weakening of linter/formatter/compiler configs.
# Steers the agent to fix code instead of weakening configs.
#
# Protected files: .eslintrc*, .prettierrc*, tsconfig.json, biome.json,
#   .stylelintrc*, .editorconfig, pyproject.toml (tool sections),
#   .golangci.yml, rustfmt.toml, Cargo.toml (lints section)
#
# IMPORTANT: No stdout output on the "allow" path!
# Git Bash redirects stdout to stderr (Issue #20034) → "hook error" in TUI.

# No set -euo pipefail — hooks must be resilient on Windows

INPUT=$(cat 2>/dev/null) || true
[ -z "$INPUT" ] && INPUT='{}'

# Pass input as environment variable (not CLI arg due to 32k limit)
export HOOK_INPUT="$INPUT"

node -e "
let input = {};
try {
  input = JSON.parse(process.env.HOOK_INPUT || '{}');
} catch { process.exit(0); }

const tool = (input.tool_name || '').toLowerCase();

// Only check Write and Edit tools
if (!['write', 'edit'].includes(tool)) {
  process.exit(0);
}

const toolInput = input.tool_input || {};
const filePath = (toolInput.file_path || toolInput.path || '').replace(/\\\\/g, '/');
const fileName = filePath.split('/').pop() || '';

// Protected config file patterns
const protectedPatterns = [
  /^\.eslintrc/,
  /^eslint\.config/,
  /^\.prettierrc/,
  /^prettier\.config/,
  /^tsconfig.*\.json$/,
  /^biome\.json$/,
  /^\.stylelintrc/,
  /^\.editorconfig$/,
  /^\.golangci/,
  /^rustfmt\.toml$/,
  /^clippy\.toml$/,
  /^pyproject\.toml$/,
  /^tox\.ini$/,
  /^\.flake8$/,
  /^\.pylintrc/,
  /^setup\.cfg$/,
  /^\.markdownlint/,
];

const isProtected = protectedPatterns.some(p => p.test(fileName));
if (!isProtected) {
  process.exit(0);
}

// Check for weakening patterns in the content
const content = (toolInput.content || toolInput.new_string || '').toLowerCase();
const oldContent = (toolInput.old_string || '').toLowerCase();

const weakeningPatterns = [
  // TypeScript strictness
  { pattern: /strict.*false/,            desc: 'Disabling TypeScript strict mode' },
  { pattern: /nouncheckedindexedaccess.*false/, desc: 'Disabling unchecked indexed access' },
  { pattern: /skiplibc?heck.*true/i,     desc: 'Enabling skipLibCheck' },
  { pattern: /noimplicitany.*false/,      desc: 'Disabling noImplicitAny' },
  { pattern: /strictnullchecks.*false/,   desc: 'Disabling strictNullChecks' },

  // ESLint weakening
  { pattern: /\"off\"/,                   desc: 'Turning off lint rules' },
  { pattern: /eslint-disable/,            desc: 'Adding eslint-disable' },
  { pattern: /0[,\s]*[/\\/*]/,            desc: 'Setting rules to 0 (off)' },

  // Prettier weakening (removing formatting rules)
  // biome weakening
  { pattern: /\"enabled\":\s*false/,       desc: 'Disabling biome checks' },
  { pattern: /\"recommended\":\s*false/,   desc: 'Disabling recommended rules' },

  // Python weakening
  { pattern: /disable[=:]/,               desc: 'Disabling linter checks' },
  { pattern: /ignore[=:]/,                desc: 'Ignoring linter checks' },
  { pattern: /max-line-length\s*=\s*\d{4,}/, desc: 'Setting unreasonably high line length' },

  // General weakening
  { pattern: /\"ignore\"/,                desc: 'Setting severity to ignore' },
  { pattern: /severity.*off/,             desc: 'Turning off severity' },
];

const warnings = [];
for (const wp of weakeningPatterns) {
  // Only flag if the weakening pattern is in the NEW content but not in the OLD
  if (wp.pattern.test(content) && !wp.pattern.test(oldContent)) {
    warnings.push(wp.desc);
  }
}

if (warnings.length > 0) {
  const msg = 'CONFIG PROTECTION: Potential config weakening detected in ' + fileName + ':\\n' +
    warnings.map(w => '  - ' + w).join('\\n') + '\\n' +
    'Consider fixing the code instead of weakening the config. ' +
    'If this change is intentional, approve it.';
  console.log(msg);
}
" 2>/dev/null

# Silent on allow path (Git Bash Issue #20034)
exit 0

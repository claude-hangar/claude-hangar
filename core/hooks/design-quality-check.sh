#!/usr/bin/env bash
# Hook: Design Quality Check
# Trigger: PostToolUse (Write, Edit)
# Detects generic AI UI drift patterns ("AI slop") in frontend files.
# Advisory only — outputs additionalContext when 2+ patterns detected.
#
# Checks for:
# - Generic CTAs ("Get Started", "Learn More", etc.)
# - Stock gradient combos (purple-to-pink, blue-to-indigo)
# - Template grids without responsive variants
# - Generic hero patterns ("Welcome to" + large heading)
# - Stock placeholder text (Lorem ipsum, "Your trusted partner")
# - Bare font-sans without customization
# - Overused pill button cliche (rounded-full + shadow-lg)
#
# IMPORTANT: No stdout output on the "allow" path!
# Git Bash redirects stdout to stderr (Issue #20034) -> "hook error" in TUI.
# Output ONLY when warning is emitted.

# No set -euo pipefail — hooks must be resilient on Windows

# Hook profile gate
export HOOK_NAME="design-quality-check"; export HOOK_MIN_PROFILE="standard"
source "${HOME}/.claude/lib/hook-gate.sh" 2>/dev/null || true

# Read input from stdin (JSON) — with fallback on pipe error
INPUT=$(cat 2>/dev/null) || true
[ -z "$INPUT" ] && INPUT='{}'
export HOOK_INPUT="$INPUT"

# All logic in node for reliable JSON parsing and pattern matching
node -e "
const fs = require('fs');

let input = {};
try {
  input = JSON.parse(process.env.HOOK_INPUT || '{}');
} catch { process.exit(0); }

const toolName = input.tool_name || '';

// Only trigger on Write and Edit tools
if (toolName !== 'Write' && toolName !== 'Edit') {
  process.exit(0);
}

// Extract file path and content
const filePath = input.tool_input?.file_path || input.tool_input?.path || '';
const content = input.tool_input?.content || input.tool_input?.new_string || '';

if (!filePath || !content) {
  process.exit(0);
}

// Only check frontend file extensions
const frontendExts = ['.html', '.jsx', '.tsx', '.svelte', '.astro', '.vue'];
const ext = filePath.replace(/\\\\/g, '/').split('/').pop().match(/\.[^.]+$/)?.[0] || '';
if (!frontendExts.includes(ext.toLowerCase())) {
  process.exit(0);
}

const filename = filePath.replace(/\\\\/g, '/').split('/').pop();
const lowerContent = content.toLowerCase();
const findings = [];

// 1. Generic CTAs
const genericCTAs = ['get started', 'learn more', 'sign up now', 'join us'];
const foundCTAs = genericCTAs.filter(cta => lowerContent.includes(cta));
if (foundCTAs.length > 0) {
  findings.push('Generic CTAs: ' + foundCTAs.map(c => '\"' + c + '\"').join(', '));
}

// 2. Stock gradient combos
const stockGradients = [
  'from-purple-500 to-pink-500',
  'from-purple-600 to-pink-600',
  'from-blue-500 to-indigo-500',
  'from-blue-600 to-indigo-600',
];
const foundGradients = stockGradients.filter(g => content.includes(g));
if (foundGradients.length > 0) {
  findings.push('Stock gradient combos: ' + foundGradients.join(', '));
}

// 3. Template grid without responsive variants
// Match grid-cols-3 that is NOT preceded by sm:/md:/lg:/xl:/2xl:
const gridPattern = /(?<![a-z]:)grid-cols-3/;
if (gridPattern.test(content) && !/[a-z]{2}:grid-cols/.test(content)) {
  findings.push('Template grid: grid-cols-3 without responsive variants (sm:/md:/lg:)');
}

// 4. Generic hero pattern: \"Welcome to\" combined with large heading indicators
const hasWelcomeTo = /welcome\s+to/i.test(content);
const hasLargeHeading = /leading-tight|text-5xl|text-6xl|text-7xl/.test(content);
if (hasWelcomeTo && hasLargeHeading) {
  findings.push('Generic hero: \"Welcome to\" with large heading styling');
}

// 5. Stock placeholder text
const placeholders = [
  { pattern: /lorem\s+ipsum/i, label: '\"Lorem ipsum\"' },
  { pattern: /your\s+trusted\s+partner/i, label: '\"Your trusted partner\"' },
];
const foundPlaceholders = placeholders.filter(p => p.pattern.test(content));
if (foundPlaceholders.length > 0) {
  findings.push('Stock placeholder text: ' + foundPlaceholders.map(p => p.label).join(', '));
}

// 6. Bare font-sans without customization
// Detect font-sans used as the only font class (no font-serif, font-mono, or custom font- class nearby)
if (/\bfont-sans\b/.test(content)) {
  // Check if there is any other font class in the file (font-serif, font-mono, font-display, or a custom font- class beyond font-sans)
  const otherFonts = content.match(/\bfont-(?!sans\b)[a-zA-Z][\w-]*/);
  if (!otherFonts) {
    findings.push('Bare font-sans without custom font family (consider a distinctive typeface)');
  }
}

// 7. Overused pill button cliche: rounded-full + shadow-lg in proximity
// Check if both classes appear in the same file and likely on similar elements
const hasRoundedFull = /\brounded-full\b/.test(content);
const hasShadowLg = /\bshadow-lg\b/.test(content);
if (hasRoundedFull && hasShadowLg) {
  findings.push('Overused pill button cliche: rounded-full + shadow-lg combo');
}

// Threshold: 2+ patterns to trigger warning
if (findings.length < 2) {
  process.exit(0);
}

const msg = 'DESIGN QUALITY: ' + findings.length + ' generic patterns detected in ' + filename + ':\\n' +
  findings.map(f => '  - ' + f).join('\\n') +
  '\\nConsider making the design more distinctive. Refer to the project\\'s design-system skill for curated alternatives.';

console.log(JSON.stringify({ additionalContext: msg }));
" 2>/dev/null

# Advisory hook — never blocks
exit 0

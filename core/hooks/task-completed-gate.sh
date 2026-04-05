#!/usr/bin/env bash
# Hook: Task Completed Gate — 4-Level Quality Gate
# Trigger: TaskCompleted
# Inspired by: Superpowers verification-before-completion + GSD 4-Level Verification
#
# Iron Law: NO COMPLETION CLAIMS WITHOUT EVIDENCE
#
# Level 1: Empty/Error — result must exist and not be an error marker
# Level 2: Error Resolution — errors in output must have resolution language
# Level 3: Test Evidence — test/verify tasks must include test output
# Level 4: Substance Check — result must be proportional to task complexity
#
# IMPORTANT: No stdout output on the "allow" path!
# Git Bash redirects stdout to stderr (Issue #20034) -> "hook error" in TUI.
# Output ONLY on reject (exit 2).

# No set -euo pipefail — hooks must be resilient on Windows

# Hook profile gate
export HOOK_NAME="task-completed-gate"; export HOOK_MIN_PROFILE="standard"
source "${HOME}/.claude/lib/hook-gate.sh" 2>/dev/null || true

# Read input from stdin (JSON) — with fallback on pipe error
INPUT=$(cat 2>/dev/null) || true
[ -z "$INPUT" ] && INPUT='{}'

# Pass input as environment variable (not CLI arg due to 32k limit)
export HOOK_INPUT="$INPUT"

# 4-Level Quality Gate
REJECT_OUTPUT=$(node -e "
const input = (() => {
  try { return JSON.parse(process.env.HOOK_INPUT || '{}'); }
  catch { return {}; }
})();

const taskId = input.task_id || '';
const subject = (input.task_subject || '').trim();
const description = (input.task_description || '').trim();
const result = (input.task_result || '').trim();

// ================================================================
// LEVEL 1: Existence — result must be present and non-trivial
// ================================================================

if (!result) {
  console.log(JSON.stringify({
    result: 'reject',
    reason: '[L1-EMPTY] Task result is empty. A completed task must include a meaningful result describing what was done.'
  }));
  process.exit(0);
}

// Error-only markers (task was just marked done with an error)
const errorOnlyPatterns = [
  /^ERROR$/i, /^FAILED$/i, /^undefined$/, /^null$/,
  /^ERROR:/i, /^FAILED:/i, /^N\/A$/i, /^TODO$/i, /^TBD$/i
];

for (const pattern of errorOnlyPatterns) {
  if (pattern.test(result)) {
    console.log(JSON.stringify({
      result: 'reject',
      reason: '[L1-MARKER] Task result is only an error/placeholder marker (\"' + result.slice(0, 50) + '\"). Resolve the issue or provide a real result.'
    }));
    process.exit(0);
  }
}

// ================================================================
// LEVEL 2: Error Resolution — errors must have resolution language
// ================================================================

const errorIndicators = [
  { pattern: /\\bERROR\\b/g, label: 'ERROR' },
  { pattern: /\\bFAILED\\b/g, label: 'FAILED' },
  { pattern: /\\bFATAL\\b/g, label: 'FATAL' },
  { pattern: /\\bPANIC\\b/g, label: 'PANIC' },
  { pattern: /\\bUnhandled(?:Rejection|Exception)\\b/g, label: 'UnhandledException' },
  { pattern: /\\bSegmentation fault\\b/gi, label: 'Segfault' },
  { pattern: /\\bstack trace\\b/gi, label: 'Stack trace' },
  { pattern: /\\bTraceback\\b/g, label: 'Traceback' },
  { pattern: /\\bTypeError\\b/g, label: 'TypeError' },
  { pattern: /\\bReferenceError\\b/g, label: 'ReferenceError' }
];

const foundErrors = [];
for (const { pattern, label } of errorIndicators) {
  const matches = result.match(pattern);
  if (matches && matches.length > 0) {
    foundErrors.push(label + ' (x' + matches.length + ')');
  }
}

if (foundErrors.length > 0) {
  const resolutionPatterns = /\\b(fixed|resolved|handled|addressed|corrected|mitigated|patched|workaround|expected|intentional|by design|false positive)\\b/i;
  if (!resolutionPatterns.test(result)) {
    console.log(JSON.stringify({
      result: 'reject',
      reason: '[L2-UNRESOLVED] Task result contains error indicators (' + foundErrors.join(', ') + ') without resolution language. Verify errors are resolved before completing.'
    }));
    process.exit(0);
  }
}

// ================================================================
// LEVEL 3: Test Evidence — test tasks must show test output
// ================================================================

const testSubjectPatterns = /\\b(test|verify|validate|check|assert|spec|e2e|integration[\\s._-]test|unit[\\s._-]test|run tests?)\\b/i;
if (testSubjectPatterns.test(subject) || testSubjectPatterns.test(description)) {
  const testOutputIndicators = /\\b(pass|fail|passing|failing|passed|tests?\\s+ran|test\\s+results?|assertions?|expect|coverage|\\d+\\s+(pass|fail|skip)|PASS|FAIL|ok\\s+\\d|not\\s+ok|suites?|✓|✗|\\d+\\s+tests?)\\b/i;
  if (!testOutputIndicators.test(result)) {
    console.log(JSON.stringify({
      result: 'reject',
      reason: '[L3-NO-EVIDENCE] Task mentions testing/verification (\"' + subject.slice(0, 60) + '\") but result contains no test output. Include actual pass/fail evidence. Iron Law: NO COMPLETION CLAIMS WITHOUT EVIDENCE.'
    }));
    process.exit(0);
  }
}

// ================================================================
// LEVEL 4: Substance Check — result proportional to task complexity
// ================================================================

// Detect vague/hand-wavy results that lack substance
const vaguePatterns = [
  /^(done|completed|finished|ready|ok|looks good|all good|worked|success)[\\.!]?$/i,
  /^(implemented|fixed|updated|changed|modified|added|removed)[\\.!]?$/i
];

for (const pattern of vaguePatterns) {
  if (pattern.test(result)) {
    console.log(JSON.stringify({
      result: 'reject',
      reason: '[L4-VAGUE] Task result is too vague (\"' + result + '\"). Describe WHAT was done, not just THAT it was done. Include specific files, functions, or outcomes.'
    }));
    process.exit(0);
  }
}

// For tasks with descriptions > 100 chars, result should be proportionally detailed
if (description.length > 100 && result.length < 30) {
  console.log(JSON.stringify({
    result: 'reject',
    reason: '[L4-THIN] Task has a detailed description (' + description.length + ' chars) but the result is suspiciously brief (' + result.length + ' chars). Provide a result proportional to the task complexity.'
  }));
  process.exit(0);
}

// All 4 levels passed — no output (allow path)
" 2>/dev/null) || true

# If node produced reject output, print it and exit 2
if [ -n "$REJECT_OUTPUT" ]; then
  echo "$REJECT_OUTPUT"
  exit 2
fi

# All OK — silently allow (Git Bash Issue #20034)
exit 0

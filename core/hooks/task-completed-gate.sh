#!/usr/bin/env bash
# Hook: Task Completed Gate
# Trigger: TaskCompleted
# Quality gate that validates task results before allowing completion.
# Rejects tasks with empty results, error markers, or missing test output.
#
# IMPORTANT: No stdout output on the "allow" path!
# Git Bash redirects stdout to stderr (Issue #20034) → "hook error" in TUI.
# Output ONLY on reject (exit 2).

# No set -euo pipefail — hooks must be resilient on Windows

# Read input from stdin (JSON) — with fallback on pipe error
INPUT=$(cat 2>/dev/null) || true
[ -z "$INPUT" ] && INPUT='{}'

# Pass input as environment variable (not CLI arg due to 32k limit)
export HOOK_INPUT="$INPUT"

# Validate task result quality
REJECT_OUTPUT=$(node -e "
const input = (() => {
  try { return JSON.parse(process.env.HOOK_INPUT || '{}'); }
  catch { return {}; }
})();

const taskId = input.task_id || '';
const subject = (input.task_subject || '').trim();
const description = (input.task_description || '').trim();
const result = (input.task_result || '').trim();

// --- Check 1: Empty result ---
if (!result) {
  console.log(JSON.stringify({
    result: 'reject',
    reason: 'Task result is empty. A completed task must include a meaningful result describing what was done.'
  }));
  process.exit(0);
}

// --- Check 2: Result is only an error marker ---
const errorOnlyPatterns = [
  /^ERROR$/i,
  /^FAILED$/i,
  /^undefined$/,
  /^null$/,
  /^ERROR:/i,
  /^FAILED:/i
];

for (const pattern of errorOnlyPatterns) {
  if (pattern.test(result)) {
    console.log(JSON.stringify({
      result: 'reject',
      reason: 'Task result appears to contain only an error marker (\"' + result.slice(0, 50) + '\"). Please resolve the error or provide a meaningful result before completing.'
    }));
    process.exit(0);
  }
}

// --- Check 3: Result contains prominent error indicators ---
const errorIndicators = [
  { pattern: /\bERROR\b/g, label: 'ERROR' },
  { pattern: /\bFAILED\b/g, label: 'FAILED' },
  { pattern: /\bFATAL\b/g, label: 'FATAL' },
  { pattern: /\bPANIC\b/g, label: 'PANIC' },
  { pattern: /\bUnhandled(?:Rejection|Exception)\b/g, label: 'UnhandledException' },
  { pattern: /\bSegmentation fault\b/gi, label: 'Segfault' },
  { pattern: /\bstack trace\b/gi, label: 'Stack trace' }
];

const foundErrors = [];
for (const { pattern, label } of errorIndicators) {
  const matches = result.match(pattern);
  if (matches && matches.length > 0) {
    foundErrors.push(label + ' (x' + matches.length + ')');
  }
}

if (foundErrors.length > 0) {
  // Only reject if errors appear without resolution language
  const resolutionPatterns = /\b(fixed|resolved|handled|addressed|corrected|mitigated|patched|workaround)\b/i;
  if (!resolutionPatterns.test(result)) {
    console.log(JSON.stringify({
      result: 'reject',
      reason: 'Task result contains error indicators (' + foundErrors.join(', ') + ') without resolution language. Please verify the errors are resolved before completing.'
    }));
    process.exit(0);
  }
}

// --- Check 4: Test/verification tasks should mention test output ---
const testSubjectPatterns = /\b(test|verify|validate|check|assert|spec|e2e|integration.test|unit.test)\b/i;
if (testSubjectPatterns.test(subject)) {
  const testOutputIndicators = /\b(pass|fail|passing|failing|passed|tests?\s+ran|test\s+results?|assertions?|expect|coverage|\d+\s+(pass|fail|skip)|✓|✗|PASS|FAIL|ok\s+\d|not\s+ok)\b/i;
  if (!testOutputIndicators.test(result)) {
    console.log(JSON.stringify({
      result: 'reject',
      reason: 'Task subject indicates testing/verification (\"' + subject.slice(0, 60) + '\") but result contains no test output or pass/fail indicators. Please include test results.'
    }));
    process.exit(0);
  }
}

// All checks passed — no output (allow path)
" 2>/dev/null) || true

# If node produced reject output, print it and exit 2
if [ -n "$REJECT_OUTPUT" ]; then
  echo "$REJECT_OUTPUT"
  exit 2
fi

# All OK — silently allow (Git Bash Issue #20034)
exit 0

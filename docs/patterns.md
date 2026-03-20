# Error Handling and Development Patterns

Patterns and anti-patterns for working effectively with Claude Code. These apply to any project, not just Claude Hangar.

---

## Anti-Patterns

### Phantom Fix

**The problem:** Claiming a bug is fixed without verifying the fix actually works.

**How it happens:** You see the error, make a change that looks correct, and declare it fixed — without running the code to confirm.

**The pattern to follow:**

```
IDENTIFY → RUN → READ → VERIFY → CLAIM
```

1. **IDENTIFY** — Understand what is broken and why
2. **RUN** — Apply the fix
3. **READ** — Read the output, logs, or test results
4. **VERIFY** — Confirm the specific error is gone (not just "no errors")
5. **CLAIM** — Only then report it as fixed

**Example violation:** "I updated the regex pattern, the secret-leak-check should work now." (Did you test it with an actual secret string? Did the hook return exit code 2?)

**Example correct:** "I updated the regex pattern and tested with `echo '{"tool_input":{"content":"sk_test_example_key_here"}}' | bash secret-leak-check.sh`. Exit code was 2 and the message correctly identified the suspicious token."

---

### Scope Explosion

**The problem:** A small task grows into a large refactor because related issues keep being discovered and addressed without agreement.

**How it happens:** You start fixing a typo in a hook, notice the error handling could be better, then see the logging format is inconsistent, then decide to refactor the shared library, and suddenly you have changed 15 files.

**Prevention:**

1. **Define scope before starting.** "Fix the typo in bash-guard.sh" is the scope. Nothing else.
2. **Note related issues, don't fix them.** Add them to STATUS.md or create issues.
3. **Ask before expanding.** "I also noticed X and Y — should I fix those now or separately?"
4. **One commit per concern.** If you do fix multiple things, separate them into distinct commits.

**Rule of thumb:** If a task touches more than 3 files, pause and check whether you are still in scope.

---

### Context Amnesia

**The problem:** Losing track of what was decided, what was done, and what remains after context compaction or session breaks.

**How it happens:** Claude Code compacts context at high usage. Important decisions, file paths, or architectural choices get dropped. The next response contradicts earlier work.

**Prevention:**

1. **STATUS.md** — Maintain a status file in the project root with current task, completed steps, and next actions. Update it after each significant step.

```markdown
## Current Task
Fix token-warning cooldown

## Completed
- [x] Identified: cooldown file not being written (missing TEMP var)
- [x] Fixed: use ${TEMP:-/tmp} instead of /tmp

## Next
- [ ] Test on Windows Git Bash
- [ ] Test on Linux
```

2. **MEMORY.md** — Store long-term learnings in a memory file. Things like "Windows hooks cannot use set -euo pipefail" or "jq @tsv is the safe alternative to eval" go here.

3. **/compact** — Use `/compact` proactively when context is at 70-80%, before auto-compaction drops information unpredictably. This gives you control over what gets preserved.

4. **Repeat key decisions.** After compaction, briefly restate what you are doing and why. This costs a few tokens but prevents wasted work.

---

### Silent Failure

**The problem:** Code fails without visible errors, leading to the false belief that everything works.

**How it happens:** Error output is suppressed (`2>/dev/null`), exit codes are ignored, or errors are caught and swallowed without logging.

**Prevention:**

1. **Exit codes matter.** A hook returning exit 0 means "allow". If it should have blocked but returned 0 because an error was swallowed, the guard fails silently.
2. **Log before suppressing.** If you must suppress stderr, at least log to a file first:
   ```bash
   some_command 2>>"${TEMP:-/tmp}/hook-errors.log" || true
   ```
3. **Test the failure path.** Don't just test that the hook works when things go right. Test what happens when the input is empty, malformed, or missing.
4. **Distinguish "no problem found" from "check didn't run".** A security scan that crashes and returns nothing is not the same as a clean scan.

---

### Stub Blindness

**The problem:** Treating the existence of a file, function, or test as proof that it works.

**How it happens:** "The test file exists" is not the same as "the tests pass." A skill directory with a SKILL.md that contains `# TODO` is not a working skill.

**How to check:**

- **File exists?** Read it. Is it complete?
- **Function exists?** Does it handle edge cases? Is it called?
- **Test exists?** Run it. Does it pass? Does it test the right thing?
- **CI config exists?** Does the pipeline actually run? When did it last succeed?

**Rule:** "Exists" does not equal "works." Always verify the substance, not just the presence.

---

### Courtesy Review

**The problem:** Reviewing code and finding nothing wrong — or only superficial issues.

**How it happens:** The natural tendency toward positive assessment. "Looks good, well structured, no issues" is almost never the honest assessment of any codebase.

**Prevention:**

1. **Minimum 5 findings.** If you find fewer than 5 issues, look again. Every codebase has at least 5 things that could be improved.
2. **Use the adversarial-review skill.** `/adversarial-review code` enforces honest review with three tracks:
   - **Adversarial track:** Actively try to break the code
   - **Catalog track:** Systematic checklist of known issue categories
   - **Path tracer:** Follow data from input to output
3. **Severity distribution.** A review with only "LOW" findings is suspicious. Real codebases have a mix of severities.
4. **No praise until 5 problems are named.** Compliments before critique create anchoring bias.

---

### Over-Engineering

**The problem:** Building more abstraction, configuration, or generalization than the problem requires.

**How it happens:** "What if we need to support 10 different databases later?" when the project uses SQLite and will never use anything else.

**Prevention:**

1. **Solve the problem in front of you.** Not the problem you imagine might exist later.
2. **Three strikes rule.** Abstract when you have three concrete cases, not when you have one case and two hypotheticals.
3. **Count the files.** If your solution creates more files than the problem has lines of code, reconsider.
4. **Explain why.** If you can't explain why the abstraction is needed *right now*, it probably isn't.

---

### Cargo Cult Config

**The problem:** Copying configuration patterns without understanding what they do.

**How it happens:** "This config works in project A, let me copy it to project B." But project B has different requirements, and the config either does nothing or causes subtle issues.

**Prevention:**

1. **Understand every line.** Before adding a config option, know what it does.
2. **Test removal.** If you are unsure whether a config line is needed, remove it and see what changes.
3. **Document non-obvious settings.** If a config value is not self-explanatory, add a comment explaining why it has that value.

---

## Root Cause Analysis

When something goes wrong, follow this structured approach instead of guessing:

### SYMPTOM

What exactly is happening? Be specific.

- Bad: "The hook doesn't work"
- Good: "bash-guard.sh exits 0 (allow) when the command contains `rm -rf /`"

### CONTEXT

What is the environment? What changed recently?

- OS, shell version, Claude Code version
- Recent changes to config, hooks, or scripts
- Whether this worked before

### CAUSE

Why is this happening? Trace the actual code path.

- Read the relevant code
- Add debug output if needed
- Identify the exact line or condition that fails

### FIX

What is the minimal change that resolves the cause?

- Change as little as possible
- Prefer fixing the root cause over adding workarounds
- Verify the fix using the IDENTIFY-RUN-READ-VERIFY-CLAIM pattern

### PREVENTION

How do we prevent this from happening again?

- Add a test case
- Add a guard condition
- Document the edge case
- Update the relevant CLAUDE.md or patterns doc

### Example

```
SYMPTOM:   token-warning.sh fires on every tool call, ignoring the 30-second
           cooldown. Session gets flooded with warnings.

CONTEXT:   Windows 11, Git Bash. Recently updated Claude Code. Cooldown file
           uses /tmp/ which maps differently on Windows.

CAUSE:     TRACK_FILE uses /tmp/ but Git Bash on Windows does not persist
           /tmp/ across process invocations consistently. The cooldown file
           is written but not found on the next call.

FIX:       Changed /tmp/ to ${TEMP:-/tmp}. TEMP is set in Git Bash and
           points to a persistent Windows temp directory.

PREVENTION: Added to MEMORY.md: "Windows hooks must use ${TEMP:-/tmp}
            instead of /tmp for persistent temp files." Added test case
            for cooldown behavior.
```

---

## Session Continuity Patterns

### STATUS.md

Maintain per-session state in the project root. Update it after each significant step:

```markdown
## Current Task
[What you are working on right now]

## Completed
- [x] Step 1 — specific outcome
- [x] Step 2 — specific outcome

## Next
- [ ] Step 3 — what needs to happen
- [ ] Step 4 — what needs to happen

## Decisions
- Chose approach X over Y because [reason]
- Deferred Z to a separate task

## Blockers
- Waiting for [dependency]
```

**Key rule:** Be semantic, not vague. "Fixed the bug" is useless after compaction. "Fixed secret-leak-check false positive on .lock files by adding basename exclusion" is recoverable.

### MEMORY.md

Store cross-session knowledge:

```markdown
## Learnings
- Windows Git Bash: stdout to stderr in hooks — use silent allow path
- Hook JSON parsing: use `node -e` with readFileSync(0), not jq (cross-platform)
- ${TEMP:-/tmp} for temp files, not /tmp (Windows compat)

## Decisions
- Hooks use node for JSON, not jq (node is required, jq is optional)
- No set -euo pipefail in hooks on Windows (causes silent failures)
```

### /compact

Use `/compact` proactively when context reaches 70-80%:

1. Update STATUS.md with current state
2. Run `/compact`
3. After compaction, verify STATUS.md is still readable
4. Continue working

This is better than waiting for auto-compaction at 95%, which drops information unpredictably.

---

## Summary

| Pattern | Rule |
|---------|------|
| Phantom Fix | IDENTIFY-RUN-READ-VERIFY-CLAIM |
| Scope Explosion | Define scope, note related issues, ask before expanding |
| Context Amnesia | STATUS.md + MEMORY.md + proactive /compact |
| Silent Failure | Test failure paths, check exit codes, log before suppressing |
| Stub Blindness | "Exists" does not equal "works" — verify substance |
| Courtesy Review | Minimum 5 findings, use adversarial-review |
| Over-Engineering | Three strikes before abstracting |
| Cargo Cult Config | Understand every line, test removal |
| Root Cause Analysis | SYMPTOM-CONTEXT-CAUSE-FIX-PREVENTION |

---

## Next Steps

- [Getting Started](getting-started.md) — installation guide
- [Configuration Reference](configuration.md) — all settings explained
- [FAQ](faq.md) — common questions

# Anti-Rationalization Patterns

LLMs have predictable failure modes where they rationalize skipping work.
This document identifies those patterns and provides countermeasures.

## Common Rationalization Patterns

| # | Rationalization | Reality | Counter |
|---|----------------|---------|---------|
| 1 | "The project looks simple, a quick scan is enough" | Simple-looking projects often hide complexity | Always complete all applicable phases |
| 2 | "I already know what the issues are" | Confirmation bias — you'll miss things outside your initial hypothesis | Follow the systematic checklist, don't skip |
| 3 | "This finding is too minor to report" | Minor findings compound; the minimum exists for a reason | Report everything, let severity levels handle prioritization |
| 4 | "The user probably knows about this" | Never assume the user's knowledge | Report all findings, let the user decide |
| 5 | "This would take too long to verify" | Unverified findings are worthless | Apply IDENTIFY→RUN→READ→VERIFY→CLAIM protocol |
| 6 | "I'll come back to this later" | "Later" in an LLM context means "never" — no persistent memory | Complete each check before moving on |
| 7 | "The code style is a matter of preference" | Inconsistent code style causes real maintenance burden | Apply objective criteria, not opinions |
| 8 | "This is working correctly" | "Works" != "correct" — edge cases, error paths, security | Test the unhappy path, not just the happy path |
| 9 | "I don't have enough context" | You have file access — read more files | Use Glob/Grep/Read to gather context before concluding |
| 10 | "The existing tests cover this" | Tests may be stubs, outdated, or testing the wrong thing | Verify test quality: meaningful assertions? Edge cases? |

## Verification Anchors

- Never mark a phase as done without completeness tracking
- Never report 0 findings — every codebase has room for improvement
- Never skip verification steps (READ + VERIFY are mandatory)
- Never assume — always read the actual file

## When to Apply

This document is referenced by any skill that performs analysis, review, or audit work.
It is a behavioral contract, not a checklist. If you catch yourself thinking any phrase
from the left column above, stop and apply the counter in the right column.

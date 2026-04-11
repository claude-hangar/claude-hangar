---
name: docs-team
description: >
  Launch parallel documentation agents: one detects what changed, one updates docs,
  one verifies completeness against the codebase.
  Use when: "docs team", "docs-team", "update docs", "documentation sweep", "stale docs".
effort: high
user-invocable: true
argument-hint: "[scope: 'all', specific files, or 'since last release']"
---

# /docs-team — Parallel Documentation Sweep

Three agents work simultaneously to find stale documentation, update it, and verify
nothing was missed. Eliminates the "docs drift" problem where code evolves but
documentation doesn't.

## Team Composition

| Agent | Role | Focus |
|-------|------|-------|
| **explorer-deep** | Change Analyst | Maps what changed in code and what docs are affected |
| **doc-updater** | Writer | Updates README, API docs, inline comments, config references |
| **plan-reviewer** | Completeness Checker | Verifies all changes have corresponding doc updates |

## Why Three Agents?

Documentation tasks have a hidden dependency problem:
- You can't update docs without knowing what changed (analysis first)
- You can't verify completeness without knowing both what changed AND what was updated

This team solves it by running analysis and writing in parallel, then using the
reviewer to catch gaps:

1. `explorer-deep` builds a change map (code deltas → doc impact)
2. `doc-updater` updates docs based on current code state (not just diffs)
3. `plan-reviewer` cross-checks: every public API change has a doc update

## Instructions

### Step 1: Determine Scope

From `$ARGUMENTS`:
- `all` → Full documentation sweep of the entire project
- `since last release` → Only changes since the last git tag
- Specific files/dirs → Focus on those areas
- No argument → Use `git diff --name-only HEAD~5` for recent changes

### Step 2: Inventory Documentation

Before launching agents, identify all documentation:

```bash
# Find all doc files
find . -name '*.md' -not -path './.git/*' -not -path './node_modules/*'
find . -name 'README*'
find . -name 'CHANGELOG*'
find . -name '*.mdx'
```

Also check for:
- JSDoc/TSDoc comments in source files
- OpenAPI/Swagger specs
- Config file comments
- Inline code examples in docs

### Step 3: Launch Parallel Agents

Launch all three agents in a **single message** (parallel execution):

```
Agent({
  subagent_type: "explorer-deep",
  description: "Analyze code changes for doc impact",
  prompt: "Analyze what has changed in the codebase and map the documentation impact.

Scope: [scope description]

Process:
1. If scope is 'since last release': run `git log --oneline [last-tag]..HEAD`
   and `git diff --stat [last-tag]..HEAD`
2. If scope is 'all': scan all source files for public APIs
3. For each changed/public file, identify:
   - Public functions, types, classes that are exported
   - Configuration options and their defaults
   - CLI commands or flags
   - Environment variables
   - Breaking changes (renamed, removed, changed signature)

Output a structured change map:
```
## Change Map
### New (needs documentation)
- file.ts: newFunction() — [what it does]

### Modified (docs may be stale)
- file.ts: existingFunction() — [what changed]

### Removed (docs reference something that no longer exists)
- oldFile.ts — deleted, but referenced in README.md line 42

### Config Changes
- New env var: X_NEW_VAR (default: Y)
- Changed default: Z_VAR was 'old', now 'new'
```"
})

Agent({
  subagent_type: "doc-updater",
  description: "Update stale documentation",
  prompt: "Scan the project documentation and update anything that is stale or missing.

Scope: [scope description]

Process:
1. Read all .md files in the project
2. For each doc file, check if referenced code still exists:
   - Function names mentioned → grep for them in source
   - File paths mentioned → verify they exist
   - Code examples → verify syntax and imports are current
   - Version numbers → check if they match package.json/pyproject.toml
   - CLI commands → verify they still work
3. Update stale references
4. Add documentation for undocumented public APIs
5. Fix broken internal links between docs

Rules:
- Don't add new doc files unless something is completely undocumented
- Preserve the existing style and tone
- Update code examples to match current API
- Mark any uncertainty with TODO comments

Output: list of files updated and what changed in each."
})

Agent({
  subagent_type: "plan-reviewer",
  description: "Verify documentation completeness",
  prompt: "Verify that project documentation is complete and consistent.

Scope: [scope description]

Check these dimensions:

1. **API Coverage:** Every public export has a doc reference
   - Scan all source files for exports
   - Check if each export appears in at least one .md file
   - Flag undocumented public APIs

2. **Accuracy:** Doc claims match code reality
   - Function signatures in docs match actual signatures
   - Default values in docs match actual defaults
   - Feature lists match what's implemented

3. **Freshness:** No references to removed code
   - File paths in docs → verify files exist
   - Function names in docs → verify functions exist
   - Links in docs → verify targets exist

4. **Structure:** Docs are navigable
   - README has a clear table of contents
   - Each major feature has a doc entry
   - Getting started guide is up to date

Output a completeness report:
```
## Documentation Completeness

### Fully Documented (N items)
[list]

### Partially Documented (N items)
- [item]: missing [what]

### Undocumented (N items)
- [item]: public API with no documentation

### Stale References (N items)
- [doc file:line]: references [thing] which no longer exists

### Score: X/100
```"
})
```

### Step 4: Unified Report

After all three agents complete:

```markdown
## Documentation Team Report

### Scope
[what was analyzed]

### Change Impact
[from explorer-deep]
- New APIs: N (need docs)
- Modified APIs: N (docs may be stale)
- Removed: N (docs reference dead code)

### Updates Made
[from doc-updater]
- Files updated: N
- References fixed: N
- Examples updated: N
- TODOs added: N (needs human review)

### Completeness Score
[from plan-reviewer]
- API coverage: X%
- Accuracy: X%
- Freshness: X%
- Overall: X/100

### Remaining Gaps
[items that still need attention — prioritized]
```

### Step 5: Offer Next Steps

"Documentation sweep complete. Options:
1. **Accept all** — Commit the doc updates
2. **Review changes** — Show diffs for each updated file
3. **Fix gaps** — Work through the remaining undocumented items
4. **Generate missing** — Create new doc files for undocumented features"

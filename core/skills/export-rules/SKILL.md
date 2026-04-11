---
name: export-rules
description: >
  Export Claude Hangar skills and rules to other AI coding tool formats.
  Use when: "export rules", "cursor rules", "windsurf rules", "export-rules", "convert to mdc".
effort: medium
user-invocable: true
argument-hint: "[cursor|windsurf|copilot|all]"
---

# /export-rules — Cross-IDE Rule Export

Convert Claude Hangar skills and rules into formats compatible with other AI coding tools.

## Supported Formats

| Target | Format | Output Location |
|--------|--------|----------------|
| Cursor | `.cursor/rules/*.mdc` | One .mdc file per rule |
| Windsurf | `.windsurfrules` | Single rules file |
| GitHub Copilot | `.github/copilot-instructions.md` | Single instructions file |

## Instructions

### Step 1: Determine Target

From `$ARGUMENTS`:
- `cursor` → Generate Cursor .mdc rules
- `windsurf` → Generate Windsurf rules file
- `copilot` → Generate Copilot instructions
- `all` → Generate all formats
- No argument → Ask which format(s) to generate

### Step 2: Gather Source Material

Read these Hangar sources (in order of importance):
1. Project CLAUDE.md (if exists in cwd)
2. `~/.claude/rules/common/*.md` — Governance rules
3. `~/.claude/rules/{lang}/*.md` — Language-specific rules (detect from project)
4. Active skills in `~/.claude/skills/*/SKILL.md` — Extract key patterns

### Step 3: Generate — Cursor (.mdc)

Create `.cursor/rules/` directory and generate one `.mdc` file per rule category:

```markdown
---
description: {{Rule description for Cursor context matching}}
globs: {{file patterns this rule applies to, e.g. "**/*.ts"}}
alwaysApply: {{true for universal rules, false for file-specific}}
---

{{Rule content — concise, actionable instructions}}
```

**Mapping:**
- `rules/common/coding-style.md` → `.cursor/rules/coding-style.mdc` (alwaysApply: true)
- `rules/common/security.md` → `.cursor/rules/security.mdc` (alwaysApply: true)
- `rules/typescript/patterns.md` → `.cursor/rules/typescript.mdc` (globs: `**/*.ts,**/*.tsx`)
- `rules/python/patterns.md` → `.cursor/rules/python.mdc` (globs: `**/*.py`)

### Step 4: Generate — Windsurf

Create a single `.windsurfrules` file at the project root:

```markdown
# Project Rules

## Code Quality
{{Extracted from coding-style.md}}

## Security
{{Extracted from security.md}}

## Language-Specific
{{Extracted from detected language rules}}

## Workflow
{{Extracted from development-workflow.md}}
```

### Step 5: Generate — GitHub Copilot

Create `.github/copilot-instructions.md`:

```markdown
# Copilot Instructions

## Project Context
{{From CLAUDE.md}}

## Code Standards
{{From coding-style.md, testing.md}}

## Security Requirements
{{From security.md}}
```

### Step 6: Report

```markdown
## Export Complete

| Format | Files | Location |
|--------|-------|----------|
| Cursor | N rules | .cursor/rules/*.mdc |
| Windsurf | 1 file | .windsurfrules |
| Copilot | 1 file | .github/copilot-instructions.md |

Total rules exported: N
```

## Rules

- Preserve the intent and strictness of original rules
- Adapt format but not content — don't weaken rules for compatibility
- Skip Hangar-specific references (hook-gate, skills, statusline)
- Include only rules relevant to the detected project stack
- Don't export hooks (these are Claude Code-specific)

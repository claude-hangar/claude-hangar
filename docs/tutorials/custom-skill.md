# Tutorial: Building a Custom Skill

Build a "readme-check" skill that validates whether a project's README.md meets quality standards.

## Step 1: Create the Skill Directory

Skills live in `core/skills/{skill-name}/` with at least a `SKILL.md` file:

```bash
mkdir -p core/skills/readme-check
```

## Step 2: Write SKILL.md

Create `core/skills/readme-check/SKILL.md`. Every SKILL.md has three parts:

**Frontmatter** with name and description (includes trigger phrases for the skill-suggest hook):

```yaml
---
name: readme-check
description: >
  Validates README.md completeness and quality.
  Use when: "check readme", "readme quality", "is my readme good".
---
```

**AI-QUICK-REF block** for fast context loading (under 10 lines):

```html
<!-- AI-QUICK-REF
## /readme-check -- Quick Reference
- **Modes:** check | fix
- **Output:** Finding list with severity + fix suggestions
- **Severity:** HIGH (missing critical section) | MEDIUM (weak section)
-->
```

**Full instructions** defining modes, checks, and behavior:

```markdown
# /readme-check -- README Quality Check

## Modes

| Mode | Trigger | Description |
|------|---------|-------------|
| `check` | `/readme-check check` | Scan README.md, report findings |
| `fix` | `/readme-check fix` | Fix missing sections interactively |

## Mode: check

### Checks

1. **Title** [MUST] -- First line is an H1 heading
2. **Description** [MUST] -- Non-empty paragraph after the title
3. **Installation** [MUST] -- Section with install instructions and a code block
4. **Usage** [SHOULD] -- Section with usage examples
5. **License** [MUST] -- License section or LICENSE file reference
6. **Contributing** [SHOULD] -- Contributing section or CONTRIBUTING.md reference
7. **Prerequisites** [SHOULD] -- Lists required tools/versions
8. **Badge/Status** [COULD] -- CI status badge

### Finding Format

    RD-01 [HIGH] -- Missing Installation Section
      Problem:  No section matching "install", "setup", or "getting started"
      Fix:      Add an ## Installation section with setup commands

## Mode: fix

1. Show missing sections from check mode
2. Generate content from project files (package.json, LICENSE)
3. User confirms before inserting
4. Re-run check to verify
```

## Step 3: Add Trigger Rules

Register the skill in `core/hooks/skill-rules.json`:

```json
{
  "skill": "/readme-check",
  "triggers": ["check readme", "readme", "readme quality", "is my readme good"],
  "exclude": ["audit", "project-audit"]
}
```

The `exclude` array prevents conflicts with similarly-worded skills.

## Step 4: Test the Skill

Start Claude Code in any project and test:

```
/readme-check check
```

Test the suggestion hook with natural language:

```
> is my readme any good?
Skill suggestion: /readme-check matches this request.
```

## Step 5: Add Fix Templates (Optional)

Create `core/skills/readme-check/fix-templates.md` with ready-made templates for common fixes. Templates provide starting points that the skill adapts to the actual project.

## Step 6: Deploy

```bash
bash setup.sh
```

This copies the skill from `core/skills/readme-check/` to `~/.claude/skills/readme-check/`, making it available in all projects.

## Conventions

| Convention | Reason |
|------------|--------|
| One SKILL.md per directory | Single source of truth |
| Unique finding-ID prefix | No collisions (check `audit-patterns.md`) |
| MUST/SHOULD/COULD markers | Enables completeness tracking |
| Modes as first argument | Consistent UX across skills |
| AI-QUICK-REF block | Fast context loading |
| Frontmatter with description | Required for skill-suggest matching |

# Writing Skills

A guide to creating custom skills for Claude Hangar.

## What Is a Skill?

A skill is a set of instructions packaged as a `SKILL.md` file. When invoked via `/skill-name`, Claude Code reads the SKILL.md and follows its instructions to perform a structured task. Skills are not executable code — they are detailed prompts that define **what** Claude Code should do, **how** to do it, and **what format** to produce.

Think of a skill as a reusable playbook: a deployment checklist, an audit workflow, a code review protocol, or any repeatable process you want Claude Code to execute consistently.

## Directory Structure

Every skill lives in its own directory under `core/skills/`:

```
core/skills/
├── _shared/                   # Shared resources across skills
│   ├── audit-patterns.md
│   └── audit-blueprint.md
├── deploy-check/
│   └── SKILL.md               # Minimal skill (single file)
├── audit/
│   ├── SKILL.md               # Complex skill (multi-file)
│   ├── state-schema.md
│   ├── fix-templates.md
│   ├── phases/
│   │   ├── 01-baseline.md
│   │   └── 02-security.md
│   └── templates/
│       └── report.md
└── your-new-skill/
    └── SKILL.md               # Start here
```

The directory name becomes the command: `core/skills/health-check/` is invoked as `/health-check`.

## SKILL.md Anatomy

A SKILL.md has three sections: frontmatter, quick reference, and body.

### 1. Frontmatter (Required)

```yaml
---
name: health-check
description: >
  Quick health check for running services.
  Use when: "health check", "is it running", "check services".
---
```

| Field | Required | Purpose |
|-------|----------|---------|
| `name` | Yes | Skill identifier, matches directory name |
| `description` | Yes | What the skill does + trigger phrases for skill-suggest hook |

### 2. Quick Reference (Optional)

An HTML comment block for fast context loading:

```html
<!-- AI-QUICK-REF
## /health-check -- Quick Reference
- **Modes:** check, deep
- **Checks:** HTTP status, response time, SSL expiry
- **Output:** Traffic light table (OK/WARN/ERROR)
-->
```

This block helps Claude Code quickly understand the skill without reading the full body. Useful for complex skills with many sections.

### 3. Body (Required)

The main instructions. Structure varies by skill complexity, but typically includes:

| Section | Purpose |
|---------|---------|
| Introduction | One-line summary of what the skill does |
| Modes | Different ways to invoke the skill (with arguments) |
| Checks / Steps | What the skill actually does, step by step |
| Output Format | Exact format Claude Code should produce |
| Rules | Constraints (read-only, max scope, etc.) |

## Minimal Example: health-check

Create `core/skills/health-check/SKILL.md`:

```markdown
---
name: health-check
description: >
  Quick health check for HTTP services.
  Use when: "health check", "is it up", "check endpoint", "service status".
---

# /health-check -- Service Health Check

Checks whether HTTP endpoints are responding correctly.

## Usage

- `/health-check https://example.com` -- Check single URL
- `/health-check` -- Auto-detect from docker-compose.yml or package.json

## Checks

### 1. HTTP Status
`curl -sf -o /dev/null -w "%{http_code}" $URL` -- 200-299: OK, 300-399: WARNING, 400+: ERROR

### 2. Response Time
`curl -sf -o /dev/null -w "%{time_total}" $URL` -- <500ms: OK, 500ms-2s: WARNING, >2s: ERROR

### 3. SSL Certificate (HTTPS only)
Check expiry via `openssl s_client` -- >30 days: OK, 7-30: WARNING, <7: ERROR

## Output Format

| Check         | Status  | Detail              |
|---------------|---------|---------------------|
| HTTP Status   | OK      | 200 in 120ms        |
| Response Time | OK      | 0.12s               |
| SSL Cert      | WARNING | Expires in 22 days  |

Result: 3 checks, 2 OK, 1 WARNING, 0 ERROR

## Rules

- **Read-only** -- does not modify any files or services
- SSL check only when URL uses HTTPS
```

## Advanced Features

### State Persistence

For multi-session skills (like audits), persist progress in a JSON state file:

```markdown
## State File (.health-check-state.json)

After each check run, save state:
- `lastRun`: ISO timestamp
- `endpoints`: Array of checked URLs with results
- `history`: Last 5 runs for trend analysis

On next invocation: Load state, show trends, skip recently-checked endpoints.
```

The state file lives in the project root (not in the skill directory). Name it `.{skill-name}-state.json`.

### Fix Templates

For skills that find problems and suggest fixes, add a `fix-templates.md`:

```
your-skill/
├── SKILL.md
└── fix-templates.md     # Code snippets for common fixes
```

Reference it in SKILL.md: "When a finding matches a template, load the fix from `fix-templates.md`."

### Multi-Phase Skills

Break large workflows into phases with separate files:

```
your-skill/
├── SKILL.md             # Orchestrator
├── phases/
│   ├── 01-scan.md       # Phase 1 instructions
│   ├── 02-analyze.md    # Phase 2 instructions
│   └── 03-report.md     # Phase 3 instructions
└── templates/
    └── report.md        # Output template
```

In SKILL.md, define the phase loading logic: "For each phase, read `phases/{NN}-{name}.md` and execute its checks."

### Modes

Skills can accept arguments to control behavior:

```markdown
## Modes

| Mode    | Argument               | Description             |
|---------|------------------------|-------------------------|
| check   | `/skill` (default)     | Run all checks          |
| docker  | `/skill docker`        | Docker checks only      |
| report  | `/skill report`        | Generate report from state |
```

Access the argument as `$0` in the description: `/skill $0` where `$0` is the mode.

## Trigger Integration

To enable automatic skill suggestions, add your skill to `core/hooks/skill-rules.json`:

```json
{
  "skill": "/health-check",
  "triggers": ["health check", "is it up", "check endpoint", "service status"],
  "exclude": ["deploy check"]
}
```

| Field | Purpose |
|-------|---------|
| `skill` | The `/command` name |
| `triggers` | Phrases that suggest this skill (matched against user prompt) |
| `exclude` | Phrases that should NOT trigger this skill (disambiguation) |

The `skill-suggest` hook matches user prompts against these rules and shows a non-blocking suggestion. Multi-word triggers use substring matching; single-word triggers use word boundary matching to avoid false positives.

## Testing Your Skill

### Manual Testing

1. Deploy: `bash setup.sh` (copies to `~/.claude/skills/`)
2. Open Claude Code in any project
3. Type `/health-check` and verify the output matches your format
4. Test edge cases: no URL provided, HTTPS vs HTTP, unreachable endpoint

### Trigger Testing

1. Add entry to `skill-rules.json`
2. Deploy: `bash setup.sh`
3. Type a natural language prompt like "is my site up?"
4. Verify the skill-suggest hook recommends `/health-check`

### Checklist

- [ ] SKILL.md has valid frontmatter (`name`, `description`)
- [ ] Description includes trigger phrases ("Use when: ...")
- [ ] Output format is clearly defined with a code block example
- [ ] Rules section defines constraints (read-only, scope limits)
- [ ] Skill-rules.json entry added with triggers and excludes
- [ ] Tested with `bash setup.sh` + manual invocation

## Contributing Back

When submitting a skill via PR:

1. **One skill per PR** -- keep reviews focused
2. **Follow naming**: `core/skills/{kebab-case-name}/SKILL.md`
3. **Include trigger entry** in `skill-rules.json`
4. **Test on both platforms** (Linux + Git Bash on Windows) if the skill uses Bash commands
5. **No hardcoded paths or secrets** -- use `{{PLACEHOLDER}}` format for personal data
6. **Conventional Commit**: `feat(skills): add health-check skill`

### PR Description Template

```
## New Skill: /health-check

**What it does:** Quick health check for HTTP endpoints
**Trigger phrases:** "health check", "is it up", "service status"
**Modes:** check (default), deep
**Dependencies:** curl, openssl (for SSL check)
**Tested on:** Linux, Git Bash (Windows 11)
```

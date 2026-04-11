# Writing Skills

How to create custom skills for Claude Hangar.

---

## What Is a Skill?

A skill is a `SKILL.md` file with structured instructions. When invoked via `/skill-name`, Claude Code loads the file and follows its instructions. Skills are not executable code — they are detailed prompts that define what Claude Code should do, how, and in what format.

---

## Directory Structure

Every skill lives in its own directory under `core/skills/`:

```
core/skills/
├── _shared/              # Shared resources across skills
├── deploy-check/
│   └── SKILL.md          # Minimal skill (single file)
├── audit/
│   ├── SKILL.md          # Complex skill (multi-file)
│   ├── phases/
│   │   ├── 01-baseline.md
│   │   └── 02-security.md
│   └── templates/
│       └── report.md
└── your-new-skill/
    └── SKILL.md           # Start here
```

The directory name becomes the command: `core/skills/health-check/` is invoked as `/health-check`.

---

## SKILL.md Format

### Frontmatter (Required)

```yaml
---
name: health-check
description: >
  Quick health check for HTTP services.
  Use when: "health check", "is it up", "check endpoint".
paths:
  - "docker-compose*.yml"
  - "**/*.service"
---
```

The `paths` field accepts a YAML list of globs. When set, the skill only activates in projects where at least one matching file exists. This prevents irrelevant skill suggestions.

| Field | Required | Purpose |
|-------|----------|---------|
| `name` | Yes | Matches directory name |
| `description` | Yes | What it does + trigger phrases for skill-suggest hook |
| `user-invocable` | No | `true` if the skill can be invoked via `/skill-name` (default: false) |
| `argument-hint` | No | Hint text shown after the skill name (e.g. `"code\|audit\|plan"`) |
| `effort` | No | Model effort level: `low`, `medium` (default), `high`. Use `low` for quick checks, `high` for deep analysis |
| `paths` | No | YAML list of globs — skill only activates when matching files exist |
| `allowed-tools` | No | Restrict which tools the skill can use (e.g. `Read, Glob, Grep`) |
| `disable-model-invocation` | No | `true` to prevent the model from auto-invoking this skill |
| `hooks` | No | Skill-scoped hooks — hooks that only fire when this skill is active |
| `shell` | No | Preferred shell: `bash` (default) or `powershell` |
| `context` | No | `fork` to run the skill in a subagent context |
| `agent` | No | Agent name to delegate execution to |

**Note:** Use hyphenated field names (`user-invocable`, not `user_invocable`). This is the official format.

#### Skill Variables

| Variable | Available In | Purpose |
|----------|-------------|---------|
| `${CLAUDE_SKILL_DIR}` | Skill body | Absolute path to the skill's own directory |
| `${CLAUDE_SESSION_ID}` | Skill body | Current session identifier |
| `$ARGUMENTS` / `$0`, `$1`, ... | Skill body | Arguments passed to the skill |

### Quick Reference (Optional)

An HTML comment for fast context loading:

```html
<!-- AI-QUICK-REF
## /health-check -- Quick Reference
- **Modes:** check, deep
- **Output:** Traffic light table
-->
```

### Body (Required)

The main instructions. Typical sections:

| Section | Purpose |
|---------|---------|
| Introduction | One-line summary |
| Usage / Modes | How to invoke with arguments |
| Steps / Checks | What the skill does step by step |
| Output Format | Exact format with code block example |
| Rules | Constraints (read-only, scope limits) |

---

## Minimal Example

Create `core/skills/health-check/SKILL.md`:

```markdown
---
name: health-check
description: >
  Quick health check for HTTP services.
  Use when: "health check", "is it up", "check endpoint".
---

# /health-check -- Service Health Check

Checks whether HTTP endpoints respond correctly.

## Usage

- `/health-check https://example.com` -- Check single URL
- `/health-check` -- Auto-detect from docker-compose.yml

## Checks

1. **HTTP Status** — `curl -sf -o /dev/null -w "%{http_code}" $URL`
2. **Response Time** — <500ms OK, 500ms-2s WARNING, >2s ERROR
3. **SSL Certificate** — Check expiry via openssl (HTTPS only)

## Output Format

| Check | Status | Detail |
|-------|--------|--------|
| HTTP Status | OK | 200 in 120ms |
| SSL Cert | WARNING | Expires in 22 days |

## Rules

- **Read-only** -- does not modify files or services
```

---

## Advanced Features

### State Persistence

For multi-session skills, save progress to `.{skill-name}-state.json` in the project root. On next invocation, load state and show trends.

### Multi-Phase Skills

Break large workflows into phase files under `phases/` with an orchestrator SKILL.md. See `core/skills/audit/` for a real example.

### Modes

Skills accept arguments: `/skill docker` runs Docker checks only. Define modes as a table in your SKILL.md.

---

## Trigger Integration

Add your skill to `core/hooks/skill-rules.json` to enable automatic suggestions:

```json
{
  "skill": "/health-check",
  "triggers": ["health check", "is it up", "check endpoint"],
  "exclude": ["deploy check"]
}
```

Multi-word triggers use substring matching. Single-word triggers use word boundary matching to avoid false positives (e.g., "review" won't match "reviewed").

---

## Testing

1. Deploy: `bash setup.sh`
2. Open Claude Code and type `/health-check`
3. Verify output matches your format
4. Test trigger: type a natural prompt like "is my site up?" and check for the skill suggestion

### Checklist

- [ ] SKILL.md has valid frontmatter (`name`, `description`)
- [ ] Description includes trigger phrases
- [ ] Output format defined with code block example
- [ ] Rules section defines constraints
- [ ] Entry added to `skill-rules.json`
- [ ] Tested via manual invocation

---

## Next Steps

- [Writing Hooks](writing-hooks.md) — create custom hooks
- [Writing Agents](writing-agents.md) — create sub-agents
- [Architecture](architecture.md) — how skills are deployed

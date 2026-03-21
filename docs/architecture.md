# Architecture

System architecture of Claude Hangar.

---

## Directory Structure

```
claude-hangar/
├── core/                          # Global config → deployed to ~/.claude/
│   ├── hooks/                     #   10 lifecycle hooks (.sh)
│   ├── agents/                    #   5 agent definitions (.md)
│   ├── skills/                    #   17 skill workflows (SKILL.md per dir)
│   ├── lib/common.sh              #   Shared shell functions
│   ├── statusline-command.sh      #   Statusline script
│   ├── settings.json.template     #   Settings template (hooks, env, effort)
│   └── CLAUDE.md.template         #   Global instructions template
├── stacks/                        # Framework extensions → deployed as skills
│   ├── astro/
│   ├── sveltekit/
│   ├── nextjs/
│   ├── database/
│   └── auth/
├── templates/                     # Scaffolding (used on demand, not auto-deployed)
│   ├── ci/                        #   GitHub Actions workflows
│   └── project/                   #   CLAUDE.md templates (minimal, web, fullstack, management)
├── registry/                      # Multi-project management
│   ├── registry.schema.json       #   JSON Schema for registry files
│   └── example-registry.json      #   Example multi-project config
├── tests/                         # Hook tests, setup tests
├── i18n/                          # Internationalization
└── setup.sh                       # Deployment script
```

---

## Three-Layer Design

```
+---------------------------------------------------+
|                    Templates                       |
|    CI workflows, project CLAUDE.md scaffolds       |
+---------------------------------------------------+
|                     Stacks                         |
|    Framework extensions (Astro, SvelteKit, ...)    |
+---------------------------------------------------+
|                      Core                          |
|    Hooks, Agents, Skills, Settings, Statusline     |
+---------------------------------------------------+
```

**Core** — universal config for every project. Deploys to `~/.claude/`.

**Stacks** — framework-specific extensions. Deploy into `~/.claude/skills/` alongside core skills.

**Templates** — project scaffolding and CI workflows. Used on demand, not auto-deployed.

---

## Deployment Flow

```
claude-hangar repo                          ~/.claude/
================                            ========

core/hooks/*.sh         ──── setup.sh ────> hooks/*.sh
core/agents/*.md        ────────────────── > agents/*.md
core/skills/*/          ────────────────── > skills/*/
core/lib/common.sh      ────────────────── > lib/common.sh
core/statusline-*.sh    ────────────────── > statusline-command.sh
core/settings.json.tmpl ──(first run)────> settings.json

stacks/*/               ────────────────── > skills/*/
```

### setup.sh Modes

| Mode | Command | Behavior |
|------|---------|----------|
| Default | `bash setup.sh` | Validate, backup, deploy all |
| Check | `--check` | Dry-run: validate without deploying |
| Verify | `--verify` | Check all components are installed |
| Rollback | `--rollback` | Restore from automatic backup |
| Update | `--update` | `git pull --ff-only` + redeploy |

### First Run vs Subsequent

**First run:** backup existing `~/.claude/`, deploy everything, generate `settings.json` from template (replacing `{{LANGUAGE}}` with `English`).

**Subsequent runs:** overwrite hooks/agents/skills/lib/statusline. Skip `settings.json` (user may have customized it). No new backup (`.hangar-backup-done` marker exists).

---

## Backup / Rollback

On first deployment, setup creates a timestamped backup:

```
~/.claude/.backup-20260320-143052/
  hooks/
  agents/
  settings.json
  ...
```

`bash setup.sh --rollback` finds the most recent `.backup-*` directory and restores all components. The backup marker `.hangar-backup-done` prevents duplicate backups on re-runs.

---

## Hook Lifecycle

```
User prompt ──> UserPromptSubmit ──> skill-suggest.sh
     |
     v
Tool planned ──> PreToolUse ──> bash-guard.sh / secret-leak-check.sh / checkpoint.sh
     |                |
     | exit 0         | exit 2
     v                v
Tool executes    Action blocked
     |
     v
PostToolUse ──> token-warning.sh
     |
     v
Stop ──> session-stop.sh
```

Hooks communicate via stdin JSON and stdout JSON + exit code. Exit 0 with no stdout = allow. Exit 2 with JSON = block. Exit 0 with JSON = inject context.

---

## Settings Merge Strategy

`settings.json` is deployed **only on first install**. If the file already exists, setup skips it and prints:

```
[i] settings.json exists — skipping (manual merge recommended)
```

This protects user customizations. To adopt new settings from a Hangar update, manually merge from `core/settings.json.template`.

---

## State Management

| State Type | Location | Lifecycle |
|------------|----------|-----------|
| Skill state | `.{skill}-state.json` in project root | Cross-session |
| Hook temp | `${TEMP:-/tmp}/claude-*-{session}` | Session-scoped |
| Agent memory | `~/.claude/projects/.../memory/` | Persistent |
| Settings | `~/.claude/settings.json` | Deployed once, user-owned |

---

## Design Principles

1. **Convention over configuration** — sensible defaults, override when needed
2. **Cross-platform first** — every script works on Linux and Git Bash (Windows)
3. **Fail open** — if a hook crashes, the action proceeds
4. **Least privilege** — agents get minimum tools
5. **No vendor lock-in** — shell scripts + Node.js for JSON, no external dependencies
6. **One command** — `bash setup.sh` handles everything

---

## Next Steps

- [Configuration Reference](configuration.md) — settings details
- [Writing Hooks](writing-hooks.md) — hook development
- [Multi-Project Setup](multi-project.md) — registry system

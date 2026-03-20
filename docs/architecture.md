# Architecture

System architecture of Claude Hangar.

## Overview

Claude Hangar is a configuration management system for Claude Code. It packages hooks, agents, skills, and settings into a deployable structure, then syncs them to `~/.claude/` where Claude Code reads them at runtime.

The system follows a three-layer design where each layer adds specificity:

```
+---------------------------------------------------+
|                    Templates                       |
|    CI/CD workflows, project CLAUDE.md scaffolds    |
+---------------------------------------------------+
|                     Stacks                         |
|    Framework extensions (Astro, SvelteKit, ...)    |
+---------------------------------------------------+
|                      Core                          |
|    Hooks, Agents, Skills, Settings, Statusline     |
+---------------------------------------------------+
```

## Three-Layer Design

### Layer 1: Core

Universal configuration that applies to every project. Lives in `core/` and deploys to `~/.claude/`.

| Component | Source | Deployed To | Purpose |
|-----------|--------|-------------|---------|
| Hooks | `core/hooks/*.sh` | `~/.claude/hooks/` | Lifecycle guards (bash-guard, secret-leak, etc.) |
| Agents | `core/agents/*.md` | `~/.claude/agents/` | Specialized sub-agents (explorer, security-reviewer) |
| Skills | `core/skills/*/` | `~/.claude/skills/` | Reusable workflows (audit, deploy-check, etc.) |
| Lib | `core/lib/common.sh` | `~/.claude/lib/` | Shared shell functions |
| Settings | `core/settings.json.template` | `~/.claude/settings.json` | Hook registration, model config |
| Statusline | `core/statusline-command.sh` | `~/.claude/statusline-command.sh` | TUI status bar |

### Layer 2: Stacks

Framework-specific extensions that supplement core skills. Lives in `stacks/` and deploys into `~/.claude/skills/`.

```
stacks/
├── frontend/        # Astro, SvelteKit, Next.js, Hugo
├── backend/         # Fastify, SvelteKit server
├── css/             # Tailwind v4
├── deployment/      # Docker, Traefik, nginx
├── database/        # SQLite, PostgreSQL
└── testing/         # Playwright
```

Stack files are structured by sections (Security, Performance, SEO, etc.). Skills load only the relevant section per phase. Example: the audit skill running its security phase loads `stacks/deployment/docker.md` section "Security" but not section "Performance".

### Layer 3: Templates

Project scaffolding and CI/CD workflows. Lives in `templates/` and is used on demand (not auto-deployed).

```
templates/
├── ci/              # GitHub Actions workflows
└── claude-md/       # CLAUDE.md templates for new projects
```

Templates use `{{PLACEHOLDER}}` format for values that must be customized per project (e.g., `{{USER_EMAIL}}`, `{{PROJECT_NAME}}`).

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
| Default | `bash setup.sh` | Interactive wizard (first run) or sync |
| Check | `bash setup.sh --check` | Dry-run: validate without deploying |
| Verify | `bash setup.sh --verify` | Verify existing installation |
| Rollback | `bash setup.sh --rollback` | Restore from automatic backup |
| Update | `bash setup.sh --update` | `git pull` + sync |

First run: prerequisites check, structure validation, backup existing config, deploy all, generate `settings.json` from template. Subsequent runs: skip backup, overwrite hooks/agents/skills/lib/statusline, skip `settings.json` (user may have customized it).

## Hook Lifecycle

Hooks intercept Claude Code actions at specific events. The runtime flow:

```
User prompt ──> UserPromptSubmit ──> skill-suggest.sh (suggest /skill)
     |
     v
Tool planned ──> PreToolUse ──> bash-guard.sh (Bash) / secret-leak.sh (Write|Edit)
     |                |
     | exit 0         | exit 2
     v                v
Tool executes    Action blocked (reason shown)
     |
     v
PostToolUse ──> token-warning.sh (context check)
     |
     v
Response ──> Stop ──> session-stop.sh (cleanup)
```

### Hook Registration

Hooks are registered in `settings.json` under the `hooks` key. Each event type contains an array of matcher-hook pairs:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          { "type": "command", "command": "bash ~/.claude/hooks/bash-guard.sh" }
        ]
      },
      {
        "matcher": "Write|Edit",
        "hooks": [
          { "type": "command", "command": "bash ~/.claude/hooks/secret-leak-check.sh" },
          { "type": "command", "command": "bash ~/.claude/hooks/checkpoint.sh" }
        ]
      }
    ]
  }
}
```

The `matcher` field is a regex tested against the tool name. An empty string matches all tools.

### Hook Communication Protocol

Claude Code pipes JSON to stdin, reads stdout JSON + exit code. Results: exit 0 with no stdout = allow silently; exit 0 with JSON = inject `additionalContext`; exit 2 with JSON = block with `reason`; exit 1 / crash = hook error (logged, action proceeds).

## Skill Execution

Skills are invoked by `/skill-name` or suggested by the skill-suggest hook. Flow: user prompt triggers skill-suggest.sh, which matches against `skill-rules.json` and shows a non-blocking suggestion. User types `/deploy-check`, Claude Code loads `~/.claude/skills/deploy-check/SKILL.md` into context, follows its instructions, and produces structured output.

### Skill-Rules Matching

The `skill-suggest.sh` hook reads `skill-rules.json` and matches user prompts:

```json
{
  "skill": "/deploy-check",
  "triggers": ["deploy check", "deploy ready", "pre-deploy"],
  "exclude": []
}
```

- **Multi-word triggers**: substring match (`prompt.includes(trigger)`)
- **Single-word triggers**: word boundary match (prevents "review" matching "reviewed")
- **Excludes**: if any exclude phrase matches, the rule is skipped

### Skill State Flow

Complex skills persist state across sessions:

```
Session 1                    Session 2                    Session 3
=========                    =========                    =========

/audit start                 /audit continue              /audit report
    |                            |                            |
    v                            v                            v
Detect stack              Read .audit-state.json       Read .audit-state.json
Run Phase 1-2             Run Phase 3-4                Generate report
    |                            |                            |
    v                            v                            v
Write                     Update                        Final report
.audit-state.json         .audit-state.json             AUDIT-REPORT-*.md
```

## Agent Orchestration

Agents run as isolated sub-conversations. The main conversation invokes the Agent tool, which spawns a sub-conversation using the agent's frontmatter (model, tools, maxTurns, isolation). The sub-agent performs its task and returns the result to the main conversation. Example: "Check dependencies" invokes `dependency-checker.md` on Sonnet with read-only tools, runs `npm audit` + `npm outdated`, and returns a formatted report.

### Agent Isolation Levels

- **`none` (default):** Agent reads from the main project. Write tools are blocked via `disallowedTools`.
- **`worktree`:** Agent gets an isolated git worktree copy. Can read and write freely. Changes stay isolated until the user adopts them.

### Model-Task Matrix

| Agent | Model | Effort | Why |
|-------|-------|--------|-----|
| explorer | sonnet | low | Quick search -- speed matters |
| commit-reviewer | sonnet | low | Pre-commit check -- fast and cheap |
| dependency-checker | sonnet | low | npm audit + format -- mechanical task |
| explorer-deep | opus | high | Multi-file reasoning, architecture |
| security-reviewer | opus | high | OWASP checks, vulnerability assessment |

## State Management

| State Type | Location | Lifecycle | Example |
|------------|----------|-----------|---------|
| Skill state | Project root `.{skill}-state.json` | Cross-session, gitignored | `.audit-state.json` |
| Hook temp | `${TEMP:-/tmp}/claude-*-{session}` | Session-scoped, cleaned by session-stop | Token tracking |
| Agent memory | `.claude/projects/.../memory/` | Persistent across sessions | `MEMORY.md` |
| Settings | `~/.claude/settings.json` | Deployed once, user-owned | Hook registration |

## Multi-Project Support

The `registry/` directory contains the schema and examples for managing multiple projects. Each entry defines: repository URL, local path, which components to deploy, and project-specific CLAUDE.md overrides. The setup script iterates over entries and deploys per-project configurations.

## Complete System Flow

```
claude-hangar repo ── setup.sh ──> ~/.claude/ (hooks, agents, skills, settings)
                                        |
                                  Claude Code runtime
                                        |
                   +--------------------+--------------------+
                   |                    |                    |
             Hook Events           Agent Tool          /skill-name
                   |                    |                    |
                   v                    v                    v
            bash-guard.sh        explorer.md         deploy-check/
            secret-leak.sh       security-           SKILL.md
            skill-suggest.sh     reviewer.md              |
            token-warning.sh          |                   |
                   |                  v                    v
                   v           Sub-conversation     Instructions
            Allow / Block /    (own model, tools,   loaded into
            Context            scope, isolation)    main context
                   |                  |                    |
                   +--------+---------+---------+----------+
                            |                   |
                            v                   v
                      Structured output   State persistence
                      to user             (.state.json, MEMORY.md)
```

## Design Principles

1. **Convention over configuration** -- sensible defaults, override when needed
2. **Cross-platform first** -- every hook and script works on Linux and Git Bash (Windows)
3. **Fail open** -- if a hook crashes, the action proceeds (safety over blocking)
4. **Least privilege** -- agents get minimum tools, hooks check minimum patterns
5. **State isolation** -- skill state in project root, hook state in temp, agent memory in memory files
6. **No vendor lock-in** -- pure shell scripts + Node.js for JSON parsing, no external dependencies
7. **Deployable in one command** -- `bash setup.sh` handles everything

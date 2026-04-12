# Getting Started

Install and configure Claude Hangar — configuration management for [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

---

## What You Get

One repo, one script, a production-grade Claude Code environment:

- **27 hooks** — secret leak detection, bash command guard, token warnings, model routing, quality gates, and more
- **21 agents** — codebase explorer, explorer-deep, security reviewer, commit reviewer, plan reviewer, dependency checker, and more
- **31 skills** — audit, deploy-check, polish, scan, consult, handoff, and more
- **Statusline** — model, context bar, rate limits, cost, session duration
- **Multi-project registry** — manage configs across many repos from one place

Everything runs locally. No external services except Anthropic's API for your own rate limit data in the statusline.

---

## Prerequisites

| Tool | Required | Install |
|------|----------|---------|
| **Git** | Yes | Bundled with Git Bash / `apt install git` / `brew install git` |
| **Node.js** | Yes | [nodejs.org](https://nodejs.org/) (any LTS) — required for Hangar hooks, not Claude Code itself |
| **Bash 4.0+** | Yes | Linux: built-in. macOS: `brew install bash`. Windows: Git Bash. |
| **jq** | Optional | `winget install jqlang.jq` / `apt install jq` / `brew install jq` |

jq is only needed for the statusline. Everything else works without it.

---

## Install

### Option A: One-liner

```bash
curl -fsSL https://raw.githubusercontent.com/claude-hangar/claude-hangar/main/install.sh | bash
```

### Option B: Manual (recommended)

```bash
git clone https://github.com/claude-hangar/claude-hangar.git ~/.claude-hangar
cd ~/.claude-hangar
bash setup.sh
```

### Option C: Dry-run first

```bash
git clone https://github.com/claude-hangar/claude-hangar.git ~/.claude-hangar
cd ~/.claude-hangar
bash setup.sh --check    # validate without deploying
bash setup.sh            # deploy when ready
```

---

## What Gets Deployed

Setup copies files from the repo into `~/.claude/`:

```
~/.claude/
  hooks/                       # 27 hook scripts
    secret-leak-check.sh       #   PreToolUse — blocks secrets in file writes
    bash-guard.sh              #   PreToolUse — blocks destructive commands + enforces commits
    checkpoint.sh              #   PreToolUse — git stash checkpoint before writes
    config-protection.sh       #   PreToolUse — blocks weakening of linter/formatter configs
    db-query-guard.sh          #   PreToolUse — warns on direct database access
    mcp-health-check.sh        #   PreToolUse — checks MCP server health before tool calls
    permission-denied-retry.sh #   PreToolUse — retries with adjusted approach
    token-warning.sh           #   PostToolUse — warns at 70% and 80% context usage
    batch-format-collector.sh  #   PostToolUse — collects edited file paths for batch formatting
    continuous-learning.sh     #   PostToolUse — captures patterns from agent work
    cost-tracker.sh            #   PostToolUse — tracks token costs per session
    design-quality-check.sh    #   PostToolUse — detects generic AI UI drift patterns
    instinct-capture.sh        #   PostToolUse — captures instinct patterns
    skill-suggest.sh           #   UserPromptSubmit — suggests matching skills
    model-router.sh            #   UserPromptSubmit — suggests optimal model tier
    session-start.sh           #   SessionStart — loads STATUS.md, tasks, memory hygiene
    session-stop.sh            #   Stop — cleanup temp files, log session cost
    desktop-notify.sh          #   Stop — OS notification when session ends
    instinct-evolve.sh         #   Stop — evolves instinct data from session
    stop-batch-format.sh       #   Stop — runs formatters once at session end
    stop-failure.sh            #   StopFailure — logs errors on session failure
    post-compact.sh            #   PostCompact — resets tracking + context reload reminder
    config-change-guard.sh     #   ConfigChange — warns on critical settings changes
    task-completed-gate.sh     #   TaskCompleted — quality gate for task completion
    task-created-init.sh       #   TaskCreated — initializes new tasks
    subagent-tracker.sh        #   SubagentStart/Stop — subagent observability
    worktree-init.sh           #   WorktreeInit — initializes worktree environment
  agents/                          # 21 agent definitions
    explorer.md                    #   Quick codebase search (Sonnet, read-only)
    explorer-deep.md               #   Deep analysis (Opus, read-only)
    security-reviewer.md           #   Security review (Opus, OWASP Top 10)
    commit-reviewer.md             #   Pre-commit review (Sonnet, read-only)
    plan-reviewer.md               #   Spec/plan compliance (Sonnet, read-only)
    dependency-checker.md          #   npm audit + outdated (Sonnet, read-only)
    planner.md                     #   Implementation planning (Opus)
    architect.md                   #   System design decisions (Opus)
    tdd-guide.md                   #   TDD workflow guidance (Sonnet)
    doc-updater.md                 #   Documentation updates (Sonnet)
    refactor-agent.md              #   Code restructuring (Opus)
    test-writer.md                 #   Test generation (Sonnet)
    typescript-reviewer.md         #   TypeScript-specific review (Sonnet)
    python-reviewer.md             #   Python-specific review (Sonnet)
    go-reviewer.md                 #   Go-specific review (Sonnet)
    build-resolver-typescript.md   #   TypeScript build error resolution (Sonnet)
    build-resolver-python.md       #   Python build error resolution (Sonnet)
    build-resolver-go.md           #   Go build error resolution (Sonnet)
    harness-optimizer.md           #   Harness config optimization (Opus)
    performance-optimizer.md       #   Performance optimization (Opus)
    loop-operator.md               #   Autonomous workflow management (Sonnet)
  skills/                  # 31 skill definitions (audit, scan, consult, handoff, ...)
  lib/common.sh            # Shared shell functions (colors, logging, OS detection)
  statusline-command.sh    # Statusline script
  settings.json            # Hook registration, env vars, effort level
```

Stack extensions (Astro, SvelteKit, Next.js, Database, Auth) are deployed as additional skills.

---

## First Run

After `bash setup.sh`:

1. **Open Claude Code** in any project
2. **Check the statusline** — model, context bar, rate limits, cost, duration
3. **Write code** — the secret-leak-check hook silently guards file writes
4. **Try a skill** — type `/scan` to detect your tech stack, or `/audit` for a full audit
5. **Watch token warnings** — warnings appear at 70% and 80% context utilization

---

## Verify & Manage

```bash
bash setup.sh --verify     # check all components are installed
bash setup.sh --update     # git pull + redeploy
bash setup.sh --rollback   # restore from automatic backup
```

### Adding a Stack After Initial Setup

Setup is currently a one-time operation. To add a framework stack (Astro, SvelteKit, Next.js, Database, Auth) after the initial install:

1. **If supported:** `bash setup.sh --stack <name>` (re-runs setup for that stack only)
2. **Manual alternative:** Copy the stack files from `stacks/<name>/` into your project's `.claude/` directory, then restart Claude Code
3. **Future:** A dedicated `hangar integrate <stack>` command is planned for seamless post-init stack management

---

## Troubleshooting

**"Permission denied"** — Run with `bash setup.sh` explicitly. The script does not need to be executable.

**Hooks not firing** — Run `bash setup.sh --verify`. Restart Claude Code after installing hooks.

**Git Bash path issues (Windows)** — Run from Git Bash, not CMD or PowerShell. Hooks use `cygpath` automatically.

**"settings.json exists — skipping"** — Setup preserves your existing config. Merge settings from `core/settings.json.template` manually, or delete and re-run setup.

**macOS Bash too old** — `brew install bash` (macOS ships 3.2, Hangar needs 4.0+).

---

## Next Steps

- [Companion Tools](companion-tools.md) — extend Hangar with Superpowers, ccusage, and more
- [Configuration Reference](configuration.md) — every setting explained
- [Multi-Project Setup](multi-project.md) — manage multiple repos
- [Writing Skills](writing-skills.md) — create your own skills
- [FAQ](faq.md) — common questions

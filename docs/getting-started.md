# Getting Started

Install and configure Claude Hangar — configuration management for [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

---

## What You Get

One repo, one script, a production-grade Claude Code environment:

- **10 hooks** — secret leak detection, bash command guard, token warnings, checkpoints, and more
- **5 agents** — codebase explorer, security reviewer, commit reviewer, dependency checker
- **14+ skills** — audit, deploy-check, polish, scan, consult, and more
- **Statusline** — model, context bar, rate limits, cost, session duration
- **Multi-project registry** — manage configs across many repos from one place

Everything runs locally. No external services except Anthropic's API for your own rate limit data in the statusline.

---

## Prerequisites

| Tool | Required | Install |
|------|----------|---------|
| **Git** | Yes | Bundled with Git Bash / `apt install git` / `brew install git` |
| **Node.js** | Yes | [nodejs.org](https://nodejs.org/) (any LTS) |
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
  hooks/                   # 10 hook scripts
    secret-leak-check.sh   #   PreToolUse — blocks secrets in file writes
    bash-guard.sh          #   PreToolUse — blocks destructive commands + enforces commits
    checkpoint.sh          #   PreToolUse — git stash checkpoint before writes
    token-warning.sh       #   PostToolUse — warns at 70% and 80% context usage
    skill-suggest.sh       #   UserPromptSubmit — suggests matching skills
    session-start.sh       #   SessionStart — loads STATUS.md, tasks, memory hygiene
    session-stop.sh        #   Stop — cleanup temp files, log session cost
    post-compact.sh        #   PostCompact — resets token tracking after compaction
    config-change-guard.sh #   ConfigChange — warns on critical settings changes
    stop-failure.sh        #   StopFailure — logs errors on session failure
  agents/                  # 5 agent definitions
    explorer.md            #   Quick codebase search (Sonnet, read-only)
    explorer-deep.md       #   Deep analysis (Opus, worktree isolation)
    security-reviewer.md   #   Security review (Opus, OWASP Top 10)
    commit-reviewer.md     #   Pre-commit review (Sonnet, read-only)
    dependency-checker.md  #   npm audit + outdated (Sonnet, read-only)
  skills/                  # 14+ skill definitions (audit, scan, consult, ...)
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

---

## Troubleshooting

**"Permission denied"** — Run with `bash setup.sh` explicitly. The script does not need to be executable.

**Hooks not firing** — Run `bash setup.sh --verify`. Restart Claude Code after installing hooks.

**Git Bash path issues (Windows)** — Run from Git Bash, not CMD or PowerShell. Hooks use `cygpath` automatically.

**"settings.json exists — skipping"** — Setup preserves your existing config. Merge settings from `core/settings.json.template` manually, or delete and re-run setup.

**macOS Bash too old** — `brew install bash` (macOS ships 3.2, Hangar needs 4.0+).

---

## Next Steps

- [Configuration Reference](configuration.md) — every setting explained
- [Multi-Project Setup](multi-project.md) — manage multiple repos
- [Writing Skills](writing-skills.md) — create your own skills
- [FAQ](faq.md) — common questions

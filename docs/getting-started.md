# Getting Started

A step-by-step guide to installing and using Claude Hangar — the configuration management system for [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

---

## What Is Claude Hangar?

Claude Hangar is a centralized hub that deploys production-grade hooks, agents, skills, and settings to your Claude Code environment. Instead of manually configuring `~/.claude/` for every project, you clone one repo, run one script, and get a battle-tested setup that includes:

- **Secret leak detection** before every file write
- **Bash command guard** blocking destructive operations
- **Token usage warnings** to prevent context overflow
- **Three-layer audit system** for systematic code review
- **Statusline** showing model, context usage, rate limits, and session cost
- **Multi-project registry** to manage configs across many repos from one place

Everything is local. No data is sent to external services (the statusline queries Anthropic's API for your own usage metrics only).

---

## Prerequisites

| Requirement | Why | Install |
|-------------|-----|---------|
| **Claude Code** | The CLI this configures | [docs.anthropic.com](https://docs.anthropic.com/en/docs/claude-code) |
| **Git** | Clone the repo, version control | `apt install git` / `brew install git` / bundled with Git Bash |
| **Node.js** | JSON parsing in hooks and setup | [nodejs.org](https://nodejs.org/) (any LTS version) |
| **jq** | Statusline script | `apt install jq` / `brew install jq` / `winget install jqlang.jq` |
| **Bash 4.0+** | Shell scripts | Linux: built-in. macOS: `brew install bash`. Windows: Git Bash (bundled). |

> **Note:** `jq` is optional. Without it the statusline will show limited info, but everything else works fine.

---

## Quick Install

### Option A: One-liner

```bash
curl -fsSL https://raw.githubusercontent.com/claude-hangar/claude-hangar/main/install.sh | bash
```

This clones the repo to `~/.claude-hangar` and runs setup automatically.

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

The setup script copies files from the repo into `~/.claude/`:

```
~/.claude/
  hooks/                   # 10 hook scripts
    secret-leak-check.sh   #   PreToolUse — blocks secrets in file writes
    bash-guard.sh          #   PreToolUse — blocks destructive bash commands
    checkpoint.sh          #   PreToolUse — creates git checkpoint before writes
    token-warning.sh       #   PostToolUse — warns on high context usage
    session-start.sh       #   SessionStart — initializes session tracking
    session-stop.sh        #   Stop — cleanup on normal session end
    stop-failure.sh        #   StopFailure — cleanup on error session end
    post-compact.sh        #   PostCompact — handles context compaction events
    config-change-guard.sh #   ConfigChange — protects settings from unwanted changes
    skill-suggest.sh       #   UserPromptSubmit — suggests matching skills
  agents/                  # 5 agent definitions
    explorer.md            #   Quick codebase exploration (low effort)
    explorer-deep.md       #   Deep codebase analysis
    security-reviewer.md   #   Security-focused code review
    commit-reviewer.md     #   Commit message and diff review
    dependency-checker.md  #   Dependency audit
  skills/                  # 14+ skill definitions
    audit/                 #   Systematic website audit (9 phases)
    project-audit/         #   Repository audit for non-web projects
    adversarial-review/    #   Critical review (min. 5 findings)
    polish/                #   Code polish and cleanup
    deploy-check/          #   Pre-deployment verification
    git-hygiene/           #   Git workflow best practices
    freshness-check/       #   Dependency version freshness
    ...and more
  lib/                     # Shared shell functions
    common.sh              #   Colors, logging, OS detection
  statusline-command.sh    # Statusline script (model, tokens, rate limits)
  settings.json            # Claude Code settings (hooks, env vars, effort)
```

Stack extensions (Astro, SvelteKit, Next.js, Database, Auth) are deployed as additional skills.

---

## First Run Experience

After running `setup.sh`:

1. **Open Claude Code** in any project directory
2. **Check the statusline** at the bottom — you should see:
   - Model name (e.g., "Opus 4.6")
   - Current directory and git branch
   - Context usage bar with percentage
   - Effort level (hi/med/low)
   - 5-hour and 7-day rate limit usage
   - Session cost and duration
3. **Try a skill** — type `/audit auto` for a full website audit, or `/adversarial-review code` for a critical code review
4. **Write some code** — the secret-leak-check hook will silently guard your file writes. If you accidentally include an API key, it blocks the write and tells you why
5. **Watch token warnings** — as your session context fills up, you will see warnings at 70%, 85%, and 95% usage

---

## Profiles

Claude Hangar supports different profiles for different use cases. The profile determines which components are deployed:

### Solo Dev

The default profile. Deploys everything to `~/.claude/`:

- All 10 hooks
- All 5 agents
- All 14+ skills (including stack extensions)
- Full statusline with rate limits
- High effort level

Best for: Individual developers working on one or a few projects.

### Multi-Project

Everything from Solo Dev plus the multi-project registry:

- Centralized config in `registry.json`
- Per-project skill and hook selection
- Path management via `.local-config.json`

Best for: Developers managing multiple repositories. See [Multi-Project Setup](multi-project.md).

### Team

Shared configuration for team environments:

- Consistent hooks and settings across team members
- Shared CLAUDE.md template with team conventions
- Project registry as team agreement

Best for: Teams that want consistent Claude Code behavior.

### Minimal

Just the essentials:

- Secret leak detection hook
- Bash guard hook
- Statusline
- Basic settings

Best for: Users who want protection without the full skill/agent ecosystem.

### Custom

Pick and choose individual components:

- Select specific hooks, agents, and skills
- Custom settings.json
- Your own CLAUDE.md template

Best for: Users with an existing setup who want to add specific components.

---

## Troubleshooting

### "Permission denied" when running setup.sh

```bash
chmod +x setup.sh
bash setup.sh
```

Or run with `bash` explicitly — the script does not need to be executable.

### Hooks not firing

1. Verify installation: `bash setup.sh --verify`
2. Check that `~/.claude/settings.json` contains the hooks configuration
3. Restart Claude Code after installing hooks

### Git Bash path issues (Windows)

Git Bash uses Unix-style paths (`/c/Users/...`) but Node.js expects Windows paths. The hooks handle this automatically via `cygpath`. If you see path-related errors:

- Make sure you are running from Git Bash, not CMD or PowerShell
- Check that `cygpath` is available: `which cygpath`

### jq not found

The statusline requires `jq`. Install it:

- **Windows:** `winget install jqlang.jq` (restart Git Bash after install)
- **Linux:** `apt install jq` or `yum install jq`
- **macOS:** `brew install jq`

Without jq, Claude Hangar still works — only the statusline will be limited.

### Bash version too old (macOS)

macOS ships with Bash 3.2. Claude Hangar requires 4.0+:

```bash
brew install bash
# The setup script will use the brew-installed bash automatically
```

### "settings.json exists — skipping"

If you already have a `~/.claude/settings.json`, setup will not overwrite it. You can:

1. Manually merge the settings from `core/settings.json.template`
2. Back up your settings, delete the file, and re-run setup
3. Use `bash setup.sh --rollback` to restore your previous configuration

### Rolling back

If something goes wrong, restore your previous configuration:

```bash
cd ~/.claude-hangar
bash setup.sh --rollback
```

This restores from the automatic backup created during the first deployment.

---

## Next Steps

- [Configuration Reference](configuration.md) — understand every setting
- [Multi-Project Setup](multi-project.md) — manage multiple repos
- [FAQ](faq.md) — common questions answered
- [Patterns](patterns.md) — error handling and development patterns

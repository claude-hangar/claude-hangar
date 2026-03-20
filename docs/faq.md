# Frequently Asked Questions

Answers to common questions about Claude Hangar.

---

## Platform & Compatibility

### Does this work on Windows?

Yes. Claude Hangar is developed and tested on Windows 11 with Git Bash (MINGW64). All hooks use `node -e` for JSON parsing instead of platform-specific tools, and path conversion is handled via `cygpath`.

Requirements:
- Git Bash (included with [Git for Windows](https://git-scm.com/download/win))
- Node.js (any LTS version)
- jq (`winget install jqlang.jq`) — optional, for the statusline

> **Note:** Do not run setup.sh from CMD or PowerShell. Use Git Bash.

### Does this work on macOS?

Yes. The only caveat is that macOS ships with Bash 3.2, but Claude Hangar requires 4.0+. Install a newer version:

```bash
brew install bash
```

The setup script will work with the Homebrew-installed bash automatically. No other changes needed.

### Does this work on Linux?

Yes. Linux is the simplest platform — Bash 4.0+ is standard, and all dependencies are available via package managers:

```bash
sudo apt install git nodejs jq   # Debian/Ubuntu
sudo dnf install git nodejs jq   # Fedora
```

### What Claude Code version is required?

Claude Hangar works with any recent version of Claude Code. We recommend using the latest version to ensure all hook events (especially `StopFailure`, added in v2.1.78) are supported.

Check your version:

```bash
claude --version
```

If your version does not support a specific hook event, the hook simply will not fire — it will not cause errors.

---

## Installation & Setup

### Will this overwrite my existing ~/.claude/ config?

No. On the first run, setup.sh automatically creates a timestamped backup before deploying anything:

```
~/.claude/.backup-20260320-143052/
  hooks/
  agents/
  skills/
  settings.json
  ...
```

If you already have a `settings.json`, setup will skip it entirely and show a message:

```
[i] settings.json exists — skipping (manual merge recommended)
```

You can always restore your previous config with `bash setup.sh --rollback`.

### How do I update?

Pull the latest changes and re-deploy:

```bash
cd ~/.claude-hangar
bash setup.sh --update
```

This runs `git pull --ff-only` followed by a full re-deploy. Your `.local-config.json` and any local customizations are preserved.

### How do I rollback?

Restore from the automatic backup:

```bash
cd ~/.claude-hangar
bash setup.sh --rollback
```

This finds the most recent backup in `~/.claude/.backup-*` and restores all components.

### Can I install to a custom location?

Yes. Clone the repo wherever you want and run setup from there:

```bash
git clone https://github.com/claude-hangar/claude-hangar.git /my/custom/path
cd /my/custom/path
bash setup.sh
```

The deployment target is always `~/.claude/` regardless of where the repo lives.

---

## Features & Usage

### Can I use only hooks without skills?

Yes. The Minimal profile installs just the core hooks (secret-leak-check, bash-guard) and the statusline. You can also manually edit `settings.json` to enable only specific hooks.

If you want to remove skills after a full install:

```bash
rm -rf ~/.claude/skills/
rm -rf ~/.claude/agents/
```

The hooks will continue to work independently.

### How do I add my own skill?

Create a directory in `~/.claude/skills/` with a `SKILL.md` file:

```bash
mkdir -p ~/.claude/skills/my-skill
```

Write a `SKILL.md` with frontmatter and instructions:

```markdown
---
name: my-skill
description: >
  What this skill does and when to use it.
  Use when: "trigger phrase 1", "trigger phrase 2".
---

# /my-skill

Instructions for Claude Code when this skill is invoked.

## Steps

1. First, do this
2. Then, do that
3. Finally, verify the result
```

For contributing skills upstream, see [CONTRIBUTING.md](../CONTRIBUTING.md).

### What is the three-layer audit?

The three-layer audit system provides comprehensive code review through three independent perspectives:

1. **`/audit`** (or `/project-audit`) — Systematic audit with 9-10 phases covering security, performance, SEO, accessibility, code quality, and more. Uses structured check priorities (MUST / SHOULD / COULD) and generates findings with severity ratings.

2. **`/project-audit`** — Similar to `/audit` but focused on non-web projects: CLI tools, libraries, backend services, monorepos. Covers structure, dependencies, code quality, git hygiene, CI/CD, testing, and deployment.

3. **`/adversarial-review`** — Critical review that enforces honesty. Minimum 5 findings required — if fewer are found, the reviewer must look again. Uses three tracks: adversarial (try to break it), catalog (systematic checklist), and path tracer (follow data flows).

Using all three layers catches issues that any single review would miss.

### How does the statusline work?

The statusline is a bash script (`~/.claude/statusline-command.sh`) that Claude Code runs periodically. It receives JSON data about the current session via stdin and outputs a formatted single-line string.

The statusline shows:
- **Model name** — which model is active
- **Session and directory** — current project, git branch, dirty state
- **Context bar** — visual progress bar of context window usage
- **Effort level** — current reasoning effort (hi/med/low)
- **Rate limits** — 5-hour and 7-day utilization from the Anthropic API
- **Cost and rate** — session cost, token burn rate, estimated turns until compaction

The rate limit data is fetched from `https://api.anthropic.com/api/oauth/usage` using your OAuth token (auto-detected from `~/.claude/.credentials.json`). The response is cached for 60 seconds to minimize API calls.

### How does the skill-suggest hook work?

When you type a prompt, the `skill-suggest.sh` hook analyzes your text against a set of keyword rules defined in `skill-rules.json`. If your prompt matches a skill's trigger pattern, it shows a suggestion:

```
[i] Tip: Try /audit for a systematic code audit
```

This is non-blocking — it shows the suggestion and lets you proceed. If your prompt already starts with `/`, no suggestion is shown (you are already invoking a skill directly).

---

## Privacy & Security

### Is my data sent anywhere?

No. Everything runs locally:

- **Hooks** execute on your machine — no network calls
- **Skills** are markdown instructions processed by Claude Code locally
- **Agents** are local markdown definitions
- **Statusline** queries `api.anthropic.com/api/oauth/usage` for your own rate limit data only — it sends your OAuth token (which Claude Code already has) and receives usage percentages. No project data, code, or prompts are transmitted.

The setup script clones from GitHub once. After that, all operations are offline unless you explicitly run `--update`.

### What does the secret-leak-check hook detect?

The hook scans file content being written for patterns that look like:

- API keys (AWS, Google, Stripe, GitHub, etc.)
- Passwords and secrets in configuration files
- Private keys (SSH, PGP)
- Tokens (JWT, OAuth, bearer tokens)
- Database connection strings with credentials

If a match is found, the write is **blocked** (exit code 2) and a message explains what was detected. False positives can occur — the hook errs on the side of caution.

Certain files are excluded from scanning (e.g., lock files, test fixtures with dummy data).

---

## Teams & Collaboration

### Can I use this with a team?

Yes. The recommended approach:

1. Fork the Claude Hangar repo for your team
2. Customize the CLAUDE.md template with team conventions
3. Create a shared `registry.json` with all team projects
4. Each team member clones the fork and runs `bash setup.sh`
5. Machine-specific paths go in `.local-config.json` (gitignored)

This ensures everyone has the same hooks, skills, and conventions while allowing per-machine path differences.

### How do teams handle different settings?

The `settings.json` is only deployed on first install. After that, each team member can customize their own `~/.claude/settings.json` without it being overwritten. Team-wide changes should be communicated and manually merged.

For strict consistency, teams can include `.claude/settings.json` in the project's `configFiles` list in the registry — this deploys project-specific settings to each repo.

---

## Troubleshooting

### Hooks fire but show stderr warnings

On Windows Git Bash, stdout from hook scripts is redirected to stderr due to a known issue (Issue #20034). Claude Code interprets stderr output as a hook error.

All Claude Hangar hooks are designed for this — they produce **no output** on the allow path (exit 0) and only output when blocking (exit 2). If you write custom hooks, follow the same pattern.

### The statusline shows "Claude" with no data

This means the statusline script received empty input. Possible causes:

1. Claude Code is still initializing — wait a few seconds
2. `jq` is not installed — install it and restart Claude Code
3. The statusline script has a syntax error — run it manually:

```bash
echo '{}' | bash ~/.claude/statusline-command.sh
```

### Context fills up too fast

Adjust the auto-compaction threshold:

```json
{
  "env": {
    "CLAUDE_AUTOCOMPACT_PCT_OVERRIDE": "70"
  }
}
```

Lower values trigger compaction earlier, keeping more headroom. The default without override is 95%; Claude Hangar sets it to 80%.

### Setup says "structure validation failed"

Run the dry-run check for details:

```bash
bash setup.sh --check
```

Common causes:
- Missing directories (clone may have been incomplete — try re-cloning)
- Invalid JSON files (check for syntax errors)
- Too few hooks/agents (partial download)

---

## Next Steps

- [Getting Started](getting-started.md) — installation guide
- [Configuration Reference](configuration.md) — all settings explained
- [Multi-Project Setup](multi-project.md) — manage multiple repos
- [Patterns](patterns.md) — error handling and development patterns

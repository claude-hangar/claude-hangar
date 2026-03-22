# Frequently Asked Questions

---

## Platform & Compatibility

### Does this work on Windows?

Yes. Developed and tested on Windows 11 with Git Bash (MINGW64). All hooks use `node -e` for JSON parsing instead of platform-specific tools. Path conversion is handled via `cygpath`.

Requirements: Git Bash, Node.js, optionally jq for the statusline. Do not run from CMD or PowerShell — use Git Bash.

### Does this work on macOS?

Yes. macOS ships with Bash 3.2 but Hangar needs 4.0+. Install via `brew install bash`. No other changes needed.

### Does this work on Linux?

Yes. Linux is the simplest platform — Bash 4.0+ is standard:

```bash
sudo apt install git nodejs jq   # Debian/Ubuntu
```

### What Claude Code version is required?

Any recent version. If your version does not support a specific hook event (e.g., `StopFailure`), that hook simply will not fire — no errors.

---

## Installation

### Will this overwrite my existing ~/.claude/ config?

No. On first run, setup creates a timestamped backup:

```
~/.claude/.backup-20260320-143052/
```

If `settings.json` already exists, setup skips it entirely:

```
[i] settings.json exists — skipping (manual merge recommended)
```

Restore anytime with `bash setup.sh --rollback`.

### How do I update?

```bash
cd ~/.claude-hangar
bash setup.sh --update
```

This runs `git pull --ff-only` + full redeploy. Your `settings.json` and `.local-config.json` are preserved.

### How do I rollback?

```bash
cd ~/.claude-hangar
bash setup.sh --rollback
```

Restores from the most recent `~/.claude/.backup-*` directory.

### How do I uninstall?

Remove the deployed files and the repo:

```bash
rm -rf ~/.claude/hooks ~/.claude/agents ~/.claude/skills
rm -f ~/.claude/lib/common.sh ~/.claude/statusline-command.sh
rm -rf ~/.claude-hangar
```

Your `settings.json` is preserved. To fully reset, remove `~/.claude/settings.json` too (Claude Code will regenerate defaults).

### Can I install to a custom location?

Yes. Clone wherever you want. The deployment target is always `~/.claude/`:

```bash
git clone https://github.com/claude-hangar/claude-hangar.git /my/path
cd /my/path && bash setup.sh
```

---

## Usage

### Can I use only hooks without skills?

Yes. After a full install, remove what you do not need:

```bash
rm -rf ~/.claude/skills/
rm -rf ~/.claude/agents/
```

Hooks work independently. You can also edit `settings.json` to enable only specific hooks.

### How do I add my own skill?

Create a directory with a `SKILL.md`:

```bash
mkdir -p ~/.claude/skills/my-skill
```

Write frontmatter + instructions. See [Writing Skills](writing-skills.md) for the full format.

### How does the statusline work?

A bash script (`~/.claude/statusline-command.sh`) receives JSON from Claude Code via stdin and outputs a formatted line showing model, context bar, rate limits, cost, and duration. It queries `api.anthropic.com/api/oauth/usage` for your rate limit data (cached 60s). Requires `jq`.

### How does skill-suggest work?

The `skill-suggest.sh` hook matches your prompt against keyword rules in `skill-rules.json`. If a match is found, it shows a non-blocking suggestion. Prompts starting with `/` are skipped (you are already invoking a skill directly).

### Does this work with other AI coding tools?

Claude Hangar is built specifically for Claude Code. The hook events, settings format, and agent/skill system are Claude Code features. Other tools (Cursor, Copilot, etc.) have different configuration systems.

However, the CLAUDE.md templates and project conventions are useful reference material regardless of the tool.

---

## Privacy & Security

### Is my data sent anywhere?

No. Everything runs locally:

- **Hooks** — local shell scripts, no network calls
- **Skills / Agents** — local markdown files
- **Statusline** — queries Anthropic's API for your rate limit data only (your OAuth token, usage percentages back). No project data transmitted.

### What does secret-leak-check detect?

Patterns scanned in file writes:

- API keys (AWS, GitHub, Stripe, Anthropic, Google, etc.)
- Passwords and secrets in config files
- Private keys (SSH, PGP)
- Tokens (JWT, OAuth, bearer)
- Database connection strings with credentials

Writes are blocked (exit 2) with an explanation. Some files are excluded (`.env.example`, `*.template`, documentation paths).

---

## Teams

### Can I use this with a team?

Yes. Recommended approach:

1. Fork the Claude Hangar repo
2. Customize the CLAUDE.md template with team conventions
3. Create a shared `registry.json` with all team projects
4. Each member clones the fork and runs `bash setup.sh`
5. Machine-specific paths go in `.local-config.json` (gitignored)

### How do teams handle different settings?

`settings.json` is only deployed on first install. Each member can customize their own without it being overwritten. For strict consistency, include `.claude/settings.json` in the registry's `configFiles` per project.

---

## Troubleshooting

### Hooks show stderr warnings

On Git Bash, stdout is redirected to stderr (Issue #20034). All Hangar hooks handle this — no output on the allow path. Custom hooks must follow the same pattern.

### Statusline shows "Claude" with no data

`jq` is missing or the statusline received empty input. Install jq and restart Claude Code.

### Context fills up too fast

Lower the auto-compaction threshold in `settings.json`:

```json
{ "env": { "CLAUDE_AUTOCOMPACT_PCT_OVERRIDE": "70" } }
```

Hangar default is 80%. Without override, Claude Code uses 95%.

---

### Can I use Hangar with Superpowers or other plugins?

Yes. Hangar is the infrastructure layer — it handles safety hooks, config, and multi-project management. Companion tools like [Superpowers](https://github.com/obra/superpowers) (workflow methodology), [Trail of Bits Skills](https://github.com/trailofbits/skills) (security), [ccusage](https://github.com/ryoppippi/ccusage) (analytics), and [claude-squad](https://github.com/smtg-ai/claude-squad) (multi-session) are fully compatible. See the [Companion Tools Guide](companion-tools.md).

### What should I NOT combine with Hangar?

**GSD** (`gsd-build/gsd-2`) — GSD is its own CLI that replaces Claude Code. Hangar hooks won't fire inside GSD. Use one or the other.

---

## Next Steps

- [Companion Tools](companion-tools.md) — Superpowers, Trail of Bits, ccusage, claude-squad
- [Getting Started](getting-started.md) — installation guide
- [Configuration Reference](configuration.md) — all settings
- [Multi-Project Setup](multi-project.md) — manage multiple repos

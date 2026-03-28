# Awesome Claude Code — Submission Preparation

**Submit after:** 2026-03-27 (one week after first public commit on 2026-03-20)

**Submit via:** https://github.com/hesreallyhim/awesome-claude-code/issues/new?template=recommend-resource.yml

---

## Form Fields

### Title (auto-filled)

```
[Resource]: Claude Hangar
```

### Display Name

```
Claude Hangar
```

### Category

```
Tooling
```

### Sub-Category

```
Tooling: Config Managers
```

### Primary Link

```
https://github.com/claude-hangar/claude-hangar
```

### Author Name

```
Giorgo Lazaridis
```

### Author Link

```
https://github.com/GiorgoLazaridis
```

### License

```
MIT
```

### Other License

(leave blank — MIT is in the dropdown)

### Description

```
Production-grade configuration management for Claude Code. Ships 13 hooks (secret leak detection, bash command guard, git checkpoints, token warnings, model routing, task quality gates, subagent tracking, session lifecycle), 6 agents (codebase explorer, explorer-deep, security reviewer, commit reviewer, plan reviewer, dependency checker), and 18 skills (project scanning, three-layer audits, deployment checks, session handoff, and more). All hooks are cross-platform shell scripts that use Node.js for JSON parsing — no jq or platform-specific dependencies. Includes a multi-project registry for managing Claude Code configs across multiple repositories from one source, stack-specific extensions (Astro, SvelteKit, Next.js, Database, Auth), and a setup wizard that deploys everything to ~/.claude/ with automatic backup and rollback.
```

### Validate Claims

````markdown
**Quick verification (2 minutes):**

1. Clone and dry-run:
   ```bash
   git clone https://github.com/claude-hangar/claude-hangar.git /tmp/claude-hangar
   cd /tmp/claude-hangar
   bash setup.sh --check
   ```
   Expected output: "All checks passed — ready to deploy"

2. Count components:
   ```bash
   echo "Hooks: $(find core/hooks -name '*.sh' | wc -l)"
   echo "Agents: $(find core/agents -name '*.md' | wc -l)"
   echo "Skills: $(find core/skills -maxdepth 1 -mindepth 1 -type d | grep -v _shared | wc -l)"
   ```
   Expected: Hooks: 13, Agents: 6, Skills: 18

3. Verify hooks are functional (read any hook):
   ```bash
   head -30 core/hooks/secret-leak-check.sh
   ```
   Shows: stdin JSON parsing via `node -e`, regex patterns for API keys/tokens/credentials, exit 2 to block writes.

**Full verification (5 minutes):**

4. Run the test suite:
   ```bash
   bash tests/test-hooks.sh
   ```

5. Inspect the settings.json.template to see how hooks are registered:
   ```bash
   cat core/settings.json.template
   ```
   Shows: all 13 hooks mapped to Claude Code lifecycle events (PreToolUse, PostToolUse, UserPromptSubmit, TaskCompleted, SubagentStart/Stop, SessionStart, Stop, etc.)

**No network calls are made** by any hook. The statusline queries `api.anthropic.com` for rate limit data only (documented in docs/faq.md). No project data is transmitted.

**No `--dangerously-skip-permissions` required** for the core setup. The audit-runner skill (an optional batch automation tool) uses it and documents this prominently in its SKILL.md.

**Uninstall:** Delete `~/.claude/hooks/`, `~/.claude/agents/`, `~/.claude/skills/`, and the hook entries from `~/.claude/settings.json`. Or run `bash setup.sh --rollback` to restore from the automatic backup.
````

### Specific Task(s)

````markdown
**Task 1: Install and verify**
Clone the repo, run `bash setup.sh --check` to validate the structure, then `bash setup.sh` to deploy. Open Claude Code in any project — the statusline should show model, context bar, and rate limits.

**Task 2: Test the secret-leak hook**
In Claude Code, ask it to write a file containing a fake API key (e.g. a string matching the pattern `sk-` followed by 30+ alphanumeric characters). The secret-leak-check hook should block the write with an explanation.

**Task 3: Try the /scan skill**
Open Claude Code in any project and type `/scan`. It will auto-detect the tech stack, frameworks, file structure, and offer to generate a CLAUDE.md.
````

### Specific Prompt(s)

````markdown
**For Task 2:**
"Write a file called test-secret.txt containing a fake Anthropic API key"

(The hook should block this and explain why.)

**For Task 3:**
"/scan"

(Claude will scan the project and report what it finds.)
````

### Additional Comments

````markdown
Claude Hangar started as a personal config that grew across 11 projects over several months. The multi-project registry (manage configs for multiple repos from one registry.json) is, as far as I know, unique in this space — most Claude Code configs are single-project setups.

The hooks are designed to be cross-platform (Linux, macOS, Windows Git Bash) and fail-open — if a hook errors, it allows the operation to proceed rather than blocking the user. All hooks can be individually disabled by removing their entry from settings.json.

Every shell script passes ShellCheck (severity: warning), and the CI validates JSON, markdown, and runs a secret scan on every push.
````

### Checklist

- [x] I have checked that this resource hasn't already been submitted
- [x] It has been over one week since the first public commit to the repo I am recommending
- [x] All provided links are working and publicly accessible
- [x] I do NOT have any other open issues in this repository
- [x] I am primarily composed of human-y stuff and not electrical circuits

---

## Pre-Submission Checklist (Internal)

Before submitting, verify:

- [ ] Repo is at least 1 week old (first commit: 2026-03-20)
- [ ] CI is green
- [ ] `bash setup.sh --check` passes
- [ ] `bash tests/test-hooks.sh` passes
- [ ] No open issues in awesome-claude-code from this account
- [ ] Delete fork `GiorgoLazaridis/awesome-claude-code` (not needed, was created by mistake)
- [ ] All links in submission are working

## After Approval

Add badge to README.md:

```markdown
[![Mentioned in Awesome Claude Code](https://awesome.re/mentioned-badge.svg)](https://github.com/hesreallyhim/awesome-claude-code)
```

# Troubleshooting

Common issues and their solutions.

## Hooks

### Hook shows "hook error" in the terminal

**Cause:** On Windows Git Bash, `stdout` is redirected to `stderr` (GitHub Issue #20034). Claude Code interprets any stderr output as a hook error.

**Fix:** Ensure your hook produces **no stdout output on the allow path**. Only output on block (`exit 2`) or when providing context.

```bash
# WRONG — produces output on allow path
echo "Hook running..."
exit 0

# CORRECT — silent on allow path
# (do your logic)
exit 0
```

### Hook is not executing

**Checklist:**
1. Is the hook registered in `~/.claude/settings.json` under the correct event?
2. Is the hook file executable? (`chmod +x ~/.claude/hooks/my-hook.sh`)
3. Is the hook path correct? (use `~/.claude/hooks/`, not a relative path)
4. Does `bash ~/.claude/hooks/my-hook.sh <<< '{}'` work manually?
5. Check `matcher` — does it match the tool name? (`Write|Edit` not `write|edit`)

### Hook blocks everything / runs on wrong events

**Cause:** The `matcher` field is empty or too broad.

**Fix:** Set specific matchers:
```json
{"matcher": "Write|Edit", "hooks": [...]}  // Only Write and Edit
{"matcher": "Bash", "hooks": [...]}        // Only Bash
{"matcher": "", "hooks": [...]}            // ALL tool calls (usually wrong)
```

### "node: command not found" in hooks

**Cause:** Node.js is not in the PATH when hooks execute.

**Fix:**
- Ensure Node.js is installed globally (not just via nvm)
- On Windows: Check that Node.js is in the system PATH, not just user PATH
- In CI: Ensure the `actions/setup-node` step runs before hook tests

### Known Upstream Bugs (Claude Code)

These are known issues in Claude Code itself, not in Hangar hooks.

**stdin must be consumed:**
Hooks that receive JSON via stdin MUST consume it (e.g., `input=$(cat)`), even if unused. Failing to consume stdin can cause the hook to hang or produce misleading "hook error" labels.

**Hook edits require session restart:**
Changes to hook scripts or `settings.json` hook configuration do NOT hot-reload. You must restart the Claude Code session for changes to take effect.

**MCP auth breaks after compaction:**
After `/compact`, MCP server authentication can break silently. Fix: toggle the MCP connector off and on again, or restart the session.

**Early compaction can be counterproductive:**
Setting `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` too low (e.g., 50%) triggers compaction too early, losing valuable context. Default behavior is usually better.

**529 Overloaded errors:**
If Claude Code returns 529 errors frequently:
- Set `ENABLE_TOOL_SEARCH=auto:5` to reduce tool search overhead
- Reduce `MAX_THINKING_TOKENS` if set
- Disable unused MCP servers to reduce token load
- Reduce number of parallel operations

## Skills

### Skill not found / not suggested

**Checklist:**
1. Is the skill directory in `~/.claude/skills/`?
2. Does the directory contain a `SKILL.md` file?
3. Is the skill registered in `~/.claude/hooks/skill-rules.json`?
4. Does the trigger description match what the user typed?

### Skill triggers on wrong prompts

**Fix:** Refine the trigger patterns in `skill-rules.json`. Use specific keywords, not generic ones.

## Setup

### `bash setup.sh` fails on Windows

**Cause:** Git Bash may not support all bash features.

**Fix:**
- Use Git Bash, not PowerShell or cmd.exe
- Ensure `git` is in PATH
- Run `bash setup.sh` (not `./setup.sh`)

### Settings not applied after setup

**Checklist:**
1. Restart Claude Code after running setup
2. Check `~/.claude/settings.json` exists and is valid JSON
3. Run `bash setup.sh --verify` to check deployment

## MCP Servers

### MCP server stuck "connecting"

**Cause:** The MCP server process is slow to start, or dependencies are not installed.

**Fix:**
- Run the MCP command manually: `npx -y @upstash/context7-mcp`
- Check if `npx` works: `npx --version`
- Set `MCP_CONNECTION_NONBLOCKING=true` for headless sessions (Claude Code 2.1.89+)

### MCP tool results truncated

**Fix (Claude Code 2.1.91+):** MCP servers can set `_meta["anthropic/maxResultSizeChars"]` up to 500K in their response to prevent truncation of large results.

## CI/CD

### CI fails with "ShellCheck not found"

**Fix:** ShellCheck is pre-installed on `ubuntu-latest`. If using a custom runner, install it:
```bash
apt-get install -y shellcheck
```

### Markdown lint fails on documentation files

**Fix:** Check `.markdownlint.json` for configured rules. Common issues:
- Trailing spaces (MD009) — remove trailing whitespace
- Line length (MD013) — usually disabled for documentation
- Bare URLs (MD034) — wrap in angle brackets or markdown links

## Performance

### Claude Code is slow / uses too much context

**Possible causes:**
- Too many MCP servers connected (each adds startup time)
- Large CLAUDE.md files (keep under 5000 words)
- Many hooks firing on every tool call (use `if` conditions to filter)

**Fixes:**
- Set `MCP_CONNECTION_NONBLOCKING=true` for faster startup
- Use `if` conditions on hooks (Claude Code 2.1.85+) to reduce process spawns
- Run `/compact` when context utilization exceeds 70%

## Network / TLS

### Corporate TLS / MITM proxy blocks Claude Code

**Symptom:** API requests fail with TLS handshake errors, `unable to verify the first certificate`, or `self-signed certificate in certificate chain` — typical in enterprise networks with a TLS-terminating proxy (Zscaler, Netskope, Palo Alto, etc.) injecting its own root certificate.

**Fix (Claude Code 2.1.101+):** By default the CLI now trusts the OS certificate store, so enterprise root CAs added by your IT team are picked up automatically without extra configuration. No environment variable needed.

**Opt out** (rare — only if the OS store is broken or you want strict bundled CAs):

```bash
export CLAUDE_CODE_CERT_STORE=bundled
```

**Also useful:**
- `NODE_EXTRA_CA_CERTS=/path/to/corp-ca.pem` — still honored as a fallback
- `HTTPS_PROXY=http://proxy.corp:8080` — explicit proxy routing

### Slow or hanging API streams

**Fix (Claude Code 2.1.105+):** Stalled streams now abort after 5 minutes of no data and retry non-streaming automatically instead of hanging indefinitely. If you still see hangs, check corporate proxy idle-timeout settings — many are below 5 min and cut streams mid-response.
- Use `/codebase-map` after `/compact` to restore essential context

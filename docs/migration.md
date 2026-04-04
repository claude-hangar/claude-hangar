# Migration Guide

How to upgrade between Claude Hangar versions.

## General Upgrade Process

```bash
cd claude-hangar
git pull origin main
bash setup.sh --update
```

The `--update` flag preserves your custom settings while deploying new hooks, skills, and agents.

## Version-Specific Notes

### v1.3.0 (April 2026)

**New hooks require registration:**
If you have a custom `settings.json` (not using the template), add these events:

```json
"PermissionDenied": [{ "matcher": "", "hooks": [{ "type": "command", "command": "bash ~/.claude/hooks/permission-denied-retry.sh" }] }],
"TaskCreated": [{ "matcher": "", "hooks": [{ "type": "command", "command": "bash ~/.claude/hooks/task-created-init.sh" }] }],
"WorktreeCreate": [{ "matcher": "", "hooks": [{ "type": "command", "command": "bash ~/.claude/hooks/worktree-init.sh" }] }]
```

**New skills added:**
- `/error-analyzer` — Root-cause analysis (SYMPTOM → CAUSE → FIX → PREVENTION)
- `/inline-review` — Quick 8-point self-review checklist
- `/codebase-map` — Structural overview for context recovery
- `/doctor` — Project health meta-check

**New agents added:**
- `refactor-agent` — Opus, worktree isolation, systematic refactoring
- `test-writer` — Sonnet, worktree isolation, test generation

### v1.2.0 (March 2026)

**Superpowers and GSD patterns adopted:**
- Iron Laws, Anti-Rationalization Tables, 4-Level Task Verification
- `task-completed-gate.sh` added — rejects empty/vague task completions
- `post-compact.sh` added — resets token tracking after compaction

**If upgrading from v1.1.x:** Run `bash setup.sh --sync` to deploy new hooks.

### v1.1.0 (March 2026)

**MCP integration added:**
- `core/mcp/` directory with server configurations
- `sequential-thinking` and `context7` MCP servers in settings template

### v1.0.0 (March 2026)

Initial release. No migration needed.

## Custom Settings Preservation

The setup script uses a merge strategy:

1. **Hooks:** New hooks are added. Existing hooks are updated. Custom hooks are preserved.
2. **Skills:** New skills are added. Existing skills are overwritten (they're templates, not custom code).
3. **Settings:** `settings.json` is updated only if using the template. Custom settings are preserved.
4. **Agents:** New agents are added. Existing agents are overwritten.

**If you modified a core hook:** Your changes will be overwritten. Instead, create a new hook with a different name and register it in your project-level settings.

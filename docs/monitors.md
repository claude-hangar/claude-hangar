# Background Monitors

Monitors are background processes declared by a plugin manifest that auto-arm when the plugin is enabled at session start or when a skill in this plugin is invoked. They use the same `Monitor` tool that Claude Code exposes at runtime — a long-running command whose stdout lines are streamed back to the model as they arrive.

**Requires:** Claude Code v2.1.105+ (manifest key), Monitor tool v2.1.98+ (runtime).

## Why monitors vs. hooks?

| Concern | Hook | Monitor |
|---------|------|---------|
| Trigger | Discrete event (PostToolUse, Stop, etc.) | Continuous — every stdout line from the process |
| Cost model | One-shot per event | Long-lived; each line is a model interjection |
| Good for | Side-effects, validation, one-shot state capture | Tailing logs, polling CI/PR status, watch directories, streaming a `tsc --watch` feed |
| Lifecycle | Fires on event, exits | Armed at session start / skill invoke, killed at session end or by user |

## Manifest

Declare the path in `.claude-plugin/plugin.json`:

```json
{
  "name": "my-plugin",
  "monitors": "./monitors/monitors.json"
}
```

Or rely on the default location `monitors/monitors.json` (no manifest field needed).

**Important:** Monitor requires `Bash` permission and is unavailable on Amazon Bedrock, Google Vertex AI, Microsoft Foundry, or when `DISABLE_TELEMETRY` / `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` is set. A plugin that depends on monitors must degrade gracefully on these platforms.

## Candidates for migration in Hangar

The following Hangar scripts currently run as hooks. They are better modeled as monitors because they are continuous, not event-driven:

| Current script | Current event | Monitor fit |
|----------------|---------------|-------------|
| `core/hooks/cost-tracker.sh` | PostToolUse (polls cost JSON after every tool call) | Natural fit — could tail cost endpoint and stream threshold crossings |
| `core/hooks/subagent-tracker.sh` | SubagentStart/Stop | Partial fit — events are still discrete, keep as hook |
| `core/hooks/batch-format-collector.sh` | PostToolUse on Edit/Write | Partial fit — collector is event-driven, formatter runner could be a monitor watching the queue |
| `core/hooks/token-warning.sh` | PostToolUse (polls token usage) | Natural fit — could poll `/context` output and flag crossings |

## Migration status

The manifest key is declared in the official plugins-reference, but the precise schema of entries inside `monitors.json` has not yet been documented through stable community examples. Hangar will migrate scripts incrementally as examples solidify in the official plugin ecosystem.

**Current state (2026-04-14):** No `monitors.json` bundled. Hooks remain the canonical integration surface. See `TODO.md` for the migration tracking entry.

## References

- [Plugin manifest schema — `monitors` field](https://code.claude.com/docs/en/plugins-reference#component-path-fields)
- [Monitor tool reference](https://code.claude.com/docs/en/tools-reference#monitor-tool)

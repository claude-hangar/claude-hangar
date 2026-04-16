# Tutorial: Statusline Customization

The statusline is a single-line display at the bottom of the Claude Code TUI showing real-time session information.

## What the Statusline Shows

```
Opus 4.7 | my-session | project@main * | ████████░░ 450k/1.0m 45% | xhi | 5h 32% | 7d 15% | $0.42 | 12k/min ~8t | 25m
```

| Segment | Description |
|---------|-------------|
| Model | Active model name (e.g., `Opus 4.7`) |
| Session | Session name (if set via `/rename`) |
| Directory | Working dir, git branch, dirty indicator (`*`) |
| Context | Progress bar + used/total tokens + percentage |
| Effort | Reasoning effort level (low/med/hi/xhi/max) |
| 5h / 7d | Rate limit utilization + reset time |
| Extra | Extra usage credits (if enabled) |
| Cost | Session cost in USD |
| Burn rate | Token consumption per minute + compaction countdown (`~8t` = ~8 turns left) |
| Duration | Session duration |

## How It Works

The statusline script (`core/statusline-command.sh`) is registered in `settings.json`. Claude Code calls it periodically, passing session data as JSON via stdin. The script parses with `jq`, formats with ANSI colors, and prints one line.

Rate limit data (5h/7d) comes from the Anthropic OAuth API, resolved via `CLAUDE_CODE_OAUTH_TOKEN` or `~/.claude/.credentials.json`. API responses are cached for 60 seconds.

## Dynamic Usage Colors

| Utilization | Color | Meaning |
|-------------|-------|---------|
| < 50% | Green | Healthy |
| 50-69% | Yellow | Getting busy |
| 70-89% | Orange | High usage |
| 90%+ | Red | Critical |

## Modifying Colors

Edit the ANSI escape codes at the top of `statusline-command.sh`:

```bash
blue='\033[38;2;0;153;255m'     # Model name
orange='\033[38;2;255;176;85m'  # Token counts
green='\033[38;2;0;160;0m'      # Git branch, healthy usage
cyan='\033[38;2;46;149;153m'    # Directory, burn rate
red='\033[38;2;255;85;85m'      # Critical usage
yellow='\033[38;2;230;200;0m'   # Warning usage
```

Format: `\033[38;2;R;G;Bm` -- change R, G, B values to match your terminal theme.

## Adding a Segment

Append to the `out` variable before the duration line:

```bash
# Example: Git commit count
if [ -n "$cwd" ]; then
    commit_count=$(git -C "${cwd}" rev-list --count HEAD 2>/dev/null)
    [ -n "$commit_count" ] && out+="${sep}${dim}${commit_count} commits${rst}"
fi
```

## Removing a Segment

Comment out or delete the corresponding block. Each segment is self-contained. For example, to remove vim mode, comment out the `if [ "$vim_mode" = "true" ]` block.

## Compaction Countdown

When context usage is between 50% and the auto-compact threshold (default 95%), the statusline estimates remaining turns: `~8t` means approximately 8 turns left. Adjust the threshold via `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` in settings.json.

## Troubleshooting

**jq not found:** Install with `winget install jqlang.jq` (Windows), `apt install jq` (Linux), or `brew install jq` (macOS).

**No usage data (5h/7d empty):** Verify OAuth token exists in `~/.claude/.credentials.json` under `claudeAiOauth.accessToken`.

**Statusline not updating:** Check the script is executable (`chmod +x`), test with `echo '{}' | bash ~/.claude/statusline-command.sh`, and verify registration in `~/.claude/settings.json`.

**Garbled output:** Your terminal must support ANSI 24-bit color. Windows Terminal, iTerm2, Alacritty, and Kitty all work. Older terminals may show raw escape codes.

**Stale cache:** Delete `${LOCALAPPDATA}/claude-statusline/` (Windows) or `/tmp/claude-statusline/` (Linux) to force a refresh.

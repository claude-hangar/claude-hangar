# Tutorial: Statusline Customization

The statusline is a single-line display at the bottom of the Claude Code TUI that shows real-time session information. This tutorial explains what each segment shows, how it works, and how to customize it.

## What the Statusline Shows

A typical statusline looks like this:

```
Opus 4.6 | my-session | project@main * | ████████░░ 450k/1.0m 45% | hi | 5h 32% | 7d 15% | $0.42 | 12k/min | 25m
```

### Segments (left to right)

| Segment | Example | Description |
|---------|---------|-------------|
| Model | `Opus 4.6` | Active model name |
| Session | `my-session` | Session name (if set via `/rename`) |
| Directory | `project@main *` | Working directory, git branch, dirty indicator |
| Vim mode | `VIM` | Shown only when vim mode is active |
| Context | `████████░░ 450k/1.0m 45%` | Progress bar + used/total tokens + percentage |
| Effort | `hi` | Reasoning effort level (low/med/hi) |
| 5h usage | `5h 32%` | 5-hour rate limit utilization + reset time |
| 7d usage | `7d 15%` | 7-day rate limit utilization + reset time |
| Extra usage | `extra $2.40/$10.00` | Extra usage credits (if enabled) |
| Session cost | `$0.42` | Cost of current session |
| Burn rate | `12k/min` | Token consumption rate + compaction countdown |
| Duration | `25m` | Session duration |

## How It Works

The statusline is a Bash script (`core/statusline-command.sh`) registered in `settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/statusline-command.sh"
  }
}
```

Claude Code calls this script periodically, passing a JSON object via stdin with session data. The script parses this JSON with `jq`, formats the output with ANSI colors, and prints a single line.

### Data flow

```
Claude Code -> JSON via stdin -> statusline-command.sh -> formatted ANSI output
                                        |
                                        v
                                  OAuth API call (cached)
                                  for rate limit data
```

### OAuth token resolution

Rate limit data (5h/7d utilization) comes from the Anthropic OAuth API. The script resolves the OAuth token in this order:

1. `CLAUDE_CODE_OAUTH_TOKEN` environment variable
2. `~/.claude/.credentials.json` (claudeAiOauth.accessToken)

API responses are cached for 60 seconds to avoid excessive API calls.

## Color Scheme

The statusline uses ANSI 24-bit colors matched to a typical terminal theme:

| Element | Color | Hex | Usage |
|---------|-------|-----|-------|
| Model name | Blue | `#0099FF` | Always blue |
| Directory | Cyan | `#2E9599` | Working directory |
| Git branch | Green | `#00A000` | Branch name |
| Dirty indicator | Yellow | `#E6C800` | Uncommitted changes |
| Token count | Orange | `#FFB055` | Used/total tokens |
| Separators | Dim white | -- | Pipe characters between segments |

### Dynamic usage colors

The context percentage and rate limit segments use dynamic colors based on utilization:

| Utilization | Color | Meaning |
|-------------|-------|---------|
| < 50% | Green | Healthy |
| 50-69% | Yellow | Getting busy |
| 70-89% | Orange | High usage |
| 90%+ | Red | Critical |

## Modifying Colors

To change colors, edit the ANSI escape codes at the top of `statusline-command.sh`:

```bash
blue='\033[38;2;0;153;255m'     # Model name
orange='\033[38;2;255;176;85m'  # Token counts
green='\033[38;2;0;160;0m'      # Git branch, healthy usage
cyan='\033[38;2;46;149;153m'    # Directory, burn rate
red='\033[38;2;255;85;85m'      # Critical usage
yellow='\033[38;2;230;200;0m'   # Warning usage, dirty indicator
white='\033[38;2;220;220;220m'  # Labels
dim='\033[2m'                    # Separators, secondary info
rst='\033[0m'                    # Reset
```

These are RGB color codes in the format `\033[38;2;R;G;Bm`. Change the R, G, B values to match your terminal theme.

## Adding a Segment

To add a new segment, append to the `out` variable before the duration line.

**Example: Add a Git commit count segment:**

```bash
# After the cost section, before duration
if [ -n "$cwd" ]; then
    commit_count=$(git -C "${cwd}" rev-list --count HEAD 2>/dev/null)
    if [ -n "$commit_count" ]; then
        out+="${sep}${dim}${commit_count} commits${rst}"
    fi
fi
```

## Removing a Segment

To remove a segment, comment out or delete the corresponding block. Each segment is self-contained.

**Example: Remove the vim mode indicator:**

```bash
# Comment out these lines:
# if [ "$vim_mode" = "true" ]; then
#     out+="${sep}${yellow}VIM${rst}"
# fi
```

**Example: Remove rate limit data:**

Comment out the entire OAuth and usage section (the `if [ -n "$usage_data" ]` block and the preceding cache/fetch logic).

## Compaction Countdown

When context usage is between 50% and the auto-compact threshold (default 95%), the statusline estimates how many turns remain before auto-compaction:

```
12k/min ~8t
```

The `~8t` means approximately 8 turns until context is compacted. The estimate is based on the current burn rate and remaining context capacity.

To adjust the auto-compact threshold, set `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` in settings.json:

```json
{
  "env": {
    "CLAUDE_AUTOCOMPACT_PCT_OVERRIDE": "80"
  }
}
```

## Troubleshooting

### "jq not found"

The statusline requires `jq` for JSON parsing:

```bash
# Windows
winget install jqlang.jq

# Linux
sudo apt install jq

# macOS
brew install jq
```

### No usage data (5h/7d shows nothing)

- Check that you have an OAuth token: `cat ~/.claude/.credentials.json | jq .claudeAiOauth`
- Verify API access: `curl -s -H "Authorization: Bearer $(jq -r '.claudeAiOauth.accessToken' ~/.claude/.credentials.json)" https://api.anthropic.com/api/oauth/usage`
- The cache file is at `${LOCALAPPDATA}/claude-statusline/usage-cache.json` -- delete it to force a refresh

### Statusline not updating

- Check that the script is executable: `chmod +x ~/.claude/statusline-command.sh`
- Test manually: `echo '{}' | bash ~/.claude/statusline-command.sh`
- Verify registration in `~/.claude/settings.json`

### Garbled output or missing colors

- Your terminal must support ANSI 24-bit color (most modern terminals do)
- Windows Terminal, iTerm2, Alacritty, and Kitty all support 24-bit color
- Older terminals may show escape codes as literal text

### Cache stale / wrong data

Delete the cache directory to force a refresh:

```bash
# Windows
rm -rf "${LOCALAPPDATA}/claude-statusline/"

# Linux/macOS
rm -rf /tmp/claude-statusline/
```

## Performance Notes

The statusline is called frequently. Key optimizations in the script:

- **Single jq call:** All JSON fields are extracted in one `jq` invocation using `@tsv` output
- **Cached API responses:** OAuth usage data is cached for 60 seconds
- **No external dependencies beyond jq:** Pure Bash for formatting
- **3-second API timeout:** API calls use `--max-time 3` to prevent hangs
- **Fallback on failure:** If any data source fails, the segment is silently omitted

#!/usr/bin/env bash
# Single line: Model | session | dir@branch | vim | bar tokens% | effort | 5h | 7d | extra | $cost | rate/min | duration
# Optimized for Windows (Git Bash / MINGW) — GNU coreutils only

set -f  # disable globbing

input=$(cat)

if [ -z "$input" ]; then
    printf "Claude"
    exit 0
fi

# ANSI colors matching oh-my-posh theme
blue='\033[38;2;0;153;255m'
orange='\033[38;2;255;176;85m'
green='\033[38;2;0;160;0m'
cyan='\033[38;2;46;149;153m'
red='\033[38;2;255;85;85m'
yellow='\033[38;2;230;200;0m'
white='\033[38;2;220;220;220m'
dim='\033[2m'
rst='\033[0m'

sep=" ${dim}|${rst} "

# Format token counts (e.g., 50k / 200k)
format_tokens() {
    local num=$1
    if [ "$num" -ge 1000000 ]; then
        awk "BEGIN {printf \"%.1fm\", $num / 1000000}"
    elif [ "$num" -ge 1000 ]; then
        awk "BEGIN {printf \"%.0fk\", $num / 1000}"
    else
        printf "%d" "$num"
    fi
}

# Return color escape based on usage percentage
usage_color() {
    local pct=${1:-0}
    if [ "$pct" -ge 90 ]; then echo "$red"
    elif [ "$pct" -ge 70 ]; then echo "$orange"
    elif [ "$pct" -ge 50 ]; then echo "$yellow"
    else echo "$green"
    fi
}

# Round float to integer (pure bash, avoids awk subprocess)
round() {
    local val="${1:-0}"
    printf '%d' "${val%%.*}" 2>/dev/null || printf '0'
}

# ===== Extract ALL fields from input JSON in one jq call (no eval) =====
{
    IFS=$'\t' read -r model_name size total_in total_out pct_used_json cwd total_cost total_duration_ms vim_mode session_name
} < <(echo "$input" | jq -r '[
    (.model.display_name // "Claude"),
    (.context_window.context_window_size // 0 | tostring),
    (.context_window.total_input_tokens // 0 | tostring),
    (.context_window.total_output_tokens // 0 | tostring),
    (.context_window.used_percentage // -1 | tostring),
    (.cwd // ""),
    (.cost.total_cost_usd // 0 | tostring),
    (.cost.total_duration_ms // 0 | tostring),
    (.vim_mode // "" | tostring),
    (.session.name // "")
] | @tsv' 2>/dev/null) || true

[ "${size:-0}" -eq 0 ] 2>/dev/null && size=1000000
cumulative=$(( ${total_in:-0} + ${total_out:-0} ))

# Context window fill: used_percentage is ACTUAL window fill (after compression/dropping)
if [ "${pct_used_json:-0}" -ge 0 ] 2>/dev/null; then
    pct_used=$pct_used_json
    context_used=$(( pct_used * size / 100 ))
elif [ "$size" -gt 0 ]; then
    context_used=$cumulative
    pct_used=$(( cumulative * 100 / size ))
else
    context_used=0
    pct_used=0
fi
[ "$pct_used" -gt 100 ] && pct_used=100

used_tokens=$(format_tokens $context_used)
total_tokens=$(format_tokens $size)

# Reasoning effort (from env or settings)
settings_path="$HOME/.claude/settings.json"
effort_level="high"
if [ -n "$CLAUDE_CODE_EFFORT_LEVEL" ]; then
    effort_level="$CLAUDE_CODE_EFFORT_LEVEL"
elif [ -f "$settings_path" ]; then
    effort_val=$(jq -r '.effortLevel // empty' "$settings_path" 2>/dev/null)
    [ -n "$effort_val" ] && effort_level="$effort_val"
fi

# ===== Session duration =====
cache_dir="${LOCALAPPDATA:-${TEMP:-/tmp}}/claude-statusline"
[ -d "$cache_dir" ] || mkdir -p "$cache_dir" 2>/dev/null
now=$(date +%s)

# Primary: use total_duration_ms from StatusJSON (accurate, from Claude Code)
# Fallback: PPID-based file tracking (less reliable on Windows)
elapsed=0
if [ "${total_duration_ms:-0}" -gt 0 ] 2>/dev/null; then
    elapsed=$(( total_duration_ms / 1000 ))
else
    session_file="${cache_dir}/session-${PPID}"
    if [ ! -f "$session_file" ]; then
        rm -f "${cache_dir}"/session-* 2>/dev/null
        date +%s > "$session_file"
    fi
    session_start=$(cat "$session_file" 2>/dev/null)
    [ -n "$session_start" ] && elapsed=$(( now - session_start ))
fi

if [ "$elapsed" -ge 3600 ]; then
    duration="$(( elapsed / 3600 ))h$(( (elapsed % 3600) / 60 ))m"
elif [ "$elapsed" -ge 60 ]; then
    duration="$(( elapsed / 60 ))m"
elif [ "$elapsed" -gt 0 ]; then
    duration="${elapsed}s"
fi

# ===== Build single-line output =====
pct_color=$(usage_color "$pct_used")

# Inline progress bar
_filled=$(( pct_used * 10 / 100 ))
[ "$_filled" -gt 10 ] && _filled=10
_empty=$(( 10 - _filled ))
ctx_bar="${pct_color}"
for (( _i=0; _i<_filled; _i++ )); do ctx_bar+="█"; done
for (( _i=0; _i<_empty; _i++ )); do ctx_bar+="░"; done
ctx_bar+="${rst}"

out=""
out+="${blue}${model_name}${rst}"

# Session name (if set via /rename or auto-named from plan)
if [ -n "$session_name" ] && [ "$session_name" != "null" ]; then
    out+="${sep}${dim}${session_name}${rst}"
fi

# Current working directory + git info
if [ -n "$cwd" ]; then
    cwd="${cwd//\\//}"
    display_dir=$(printf '%s' "${cwd##*/}" | tr -d '\000-\037\177')
    out+=" ${dim}|${rst} "
    out+="${cyan}${display_dir}${rst}"
    git_branch=$(git -C "${cwd}" rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [ -n "$git_branch" ]; then
        out+="${dim}@${rst}${green}${git_branch}${rst}"
        if ! git -C "${cwd}" diff --quiet 2>/dev/null || ! git -C "${cwd}" diff --cached --quiet 2>/dev/null; then
            out+=" ${yellow}*${rst}"
        fi
    fi
fi

# Vim mode indicator
if [ "$vim_mode" = "true" ]; then
    out+="${sep}${yellow}VIM${rst}"
fi

# Context: bar + tokens + percentage
out+="${sep}${ctx_bar} ${orange}${used_tokens}/${total_tokens}${rst} ${pct_color}${pct_used}%${rst}"

# Effort (compact)
out+="${sep}"
case "$effort_level" in
    low)    out+="${dim}low${rst}" ;;
    medium) out+="${orange}med${rst}" ;;
    *)      out+="${green}hi${rst}" ;;
esac

# ===== OAuth token resolution =====
get_oauth_token() {
    if [ -n "$CLAUDE_CODE_OAUTH_TOKEN" ]; then
        echo "$CLAUDE_CODE_OAUTH_TOKEN"
        return 0
    fi
    local creds_file="${HOME}/.claude/.credentials.json"
    if [ -f "$creds_file" ]; then
        local token
        token=$(jq -r '.claudeAiOauth.accessToken // empty' "$creds_file" 2>/dev/null)
        if [ -n "$token" ] && [ "$token" != "null" ]; then
            echo "$token"
            return 0
        fi
    fi
    echo ""
}

# ===== Usage limits with caching =====
cache_file="${cache_dir}/usage-cache.json"
cache_max_age=60

needs_refresh=true
usage_data=""

if [ -f "$cache_file" ]; then
    cache_mtime=$(stat -c %Y "$cache_file" 2>/dev/null || stat -f %m "$cache_file" 2>/dev/null)
    if [ -n "$cache_mtime" ]; then
        cache_age=$(( now - cache_mtime ))
        if [ "$cache_age" -lt "$cache_max_age" ]; then
            needs_refresh=false
            usage_data=$(cat "$cache_file" 2>/dev/null)
        fi
    fi
fi

if $needs_refresh; then
    token=$(get_oauth_token)
    if [ -n "$token" ] && [ "$token" != "null" ]; then
        response=$(curl -s --max-time 3 \
            -H "Accept: application/json" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $token" \
            -H "anthropic-beta: oauth-2025-04-20" \
            -H "User-Agent: claude-code-statusline" \
            "https://api.anthropic.com/api/oauth/usage" 2>/dev/null)
        if [ -n "$response" ] && echo "$response" | jq -e '.five_hour' >/dev/null 2>&1; then
            usage_data="$response"
            echo "$response" > "${cache_file}.tmp" && mv "${cache_file}.tmp" "$cache_file"
        fi
    fi
    if [ -z "$usage_data" ] && [ -f "$cache_file" ]; then
        cached=$(cat "$cache_file" 2>/dev/null)
        if echo "$cached" | jq -e '.five_hour' >/dev/null 2>&1; then
            usage_data="$cached"
        fi
    fi
fi

if [ -n "$usage_data" ]; then
    {
        IFS=$'\t' read -r five_hour_pct five_hour_reset_iso seven_day_pct seven_day_reset_iso extra_enabled extra_pct extra_used_raw extra_limit_raw
    } < <(echo "$usage_data" | jq -r '[
        (.five_hour.utilization // 0 | tostring),
        (.five_hour.resets_at // ""),
        (.seven_day.utilization // 0 | tostring),
        (.seven_day.resets_at // ""),
        (.extra_usage.is_enabled // false | tostring),
        (.extra_usage.utilization // 0 | tostring),
        (.extra_usage.used_credits // 0 | tostring),
        (.extra_usage.monthly_limit // 0 | tostring)
    ] | @tsv' 2>/dev/null) || true

    normalize_pct() {
        local val="${1:-0}"
        local int_part="${val%%.*}"
        if [ "${int_part:-0}" -eq 0 ] 2>/dev/null && [ "$val" != "0" ] && [ "$val" != "0.0" ]; then
            awk "BEGIN {printf \"%.0f\", $val * 100}"
        else
            printf '%d' "$int_part" 2>/dev/null || printf '0'
        fi
    }
    five_hour_pct=$(normalize_pct "$five_hour_pct")
    seven_day_pct=$(normalize_pct "$seven_day_pct")

    five_hour_color=$(usage_color "$five_hour_pct")
    out+="${sep}${white}5h${rst} ${five_hour_color}${five_hour_pct}%${rst}"
    if [ -n "$five_hour_reset_iso" ]; then
        five_hr_epoch=$(date -d "${five_hour_reset_iso}" +%s 2>/dev/null)
        [ -n "$five_hr_epoch" ] && out+=" ${dim}@$(date -d "@$five_hr_epoch" +"%H:%M" 2>/dev/null)${rst}"
    fi

    seven_day_color=$(usage_color "$seven_day_pct")
    out+="${sep}${white}7d${rst} ${seven_day_color}${seven_day_pct}%${rst}"
    if [ -n "$seven_day_reset_iso" ]; then
        seven_d_epoch=$(date -d "${seven_day_reset_iso}" +%s 2>/dev/null)
        [ -n "$seven_d_epoch" ] && out+=" ${dim}@$(date -d "@$seven_d_epoch" +"%b %-d, %H:%M" 2>/dev/null)${rst}"
    fi

    if [ "${extra_enabled:-false}" = "true" ]; then
        extra_pct=$(normalize_pct "$extra_pct")
        extra_used=$(awk "BEGIN {printf \"%.2f\", ${extra_used_raw:-0}/100}")
        extra_limit=$(awk "BEGIN {printf \"%.2f\", ${extra_limit_raw:-0}/100}")
        extra_color=$(usage_color "$extra_pct")
        out+="${sep}${white}extra${rst} ${extra_color}\$${extra_used}/\$${extra_limit}${rst}"
    fi
fi

# Session cost
if [ -n "$total_cost" ] && [ "$total_cost" != "0" ]; then
    cost_display=$(awk "BEGIN {printf \"%.2f\", ${total_cost:-0}}")
    [ "$cost_display" != "0.00" ] && out+="${sep}${dim}\$${cost_display}${rst}"
fi

# Token burn rate
if [ "${elapsed:-0}" -gt 60 ] && [ "$cumulative" -gt 0 ]; then
    rate=$(( cumulative * 60 / elapsed ))
    rate_display=$(format_tokens $rate)
    out+="${sep}${cyan}${rate_display}/min${rst}"

    # Compaction countdown: estimate turns until auto-compact
    compact_pct=${CLAUDE_AUTOCOMPACT_PCT_OVERRIDE:-95}
    if [ "$pct_used" -ge 50 ] && [ "$pct_used" -lt "$compact_pct" ] && [ "$rate" -gt 0 ]; then
        remaining_tokens=$(( (compact_pct - pct_used) * size / 100 ))
        tokens_per_turn=$(( rate * 3 / 2 ))
        if [ "$tokens_per_turn" -gt 0 ]; then
            turns_left=$(( remaining_tokens / tokens_per_turn ))
            if [ "$turns_left" -le 20 ] && [ "$turns_left" -gt 0 ]; then
                out+=" ${dim}~${turns_left}t${rst}"
            fi
        fi
    fi
fi

# Session duration (last element)
[ -n "$duration" ] && out+="${sep}${dim}${duration}${rst}"

# NBSP prevents Claude Code from trimming spaces; ANSI reset overrides dim
out="${out// /$'\xC2\xA0'}"
printf "\033[0m%b" "$out"

exit 0

#!/usr/bin/env bash
# Hook: Desktop Notification (Stop)
# Sends a desktop notification when Claude Code completes a task.
# Trigger: Stop (async, 10s timeout)
#
# Supports: macOS (osascript), Linux (notify-send), Windows (PowerShell)

# No set -euo pipefail — hooks must be resilient on Windows

# Hook profile gate
export HOOK_NAME="desktop-notify"; export HOOK_MIN_PROFILE="strict"
source "${HOME}/.claude/lib/hook-gate.sh" 2>/dev/null || true

TITLE="Claude Code"

# Try to extract project name from cwd
PROJECT_NAME=$(basename "$(pwd)" 2>/dev/null || echo "project")

# Calculate session duration if marker exists
START_MARKER="$HOME/.claude/.session-start"
DURATION_MSG=""
if [ -f "$START_MARKER" ]; then
  START_EPOCH=$(cat "$START_MARKER" 2>/dev/null || echo "0")
  NOW_EPOCH=$(date +%s 2>/dev/null || echo "0")
  ELAPSED=$(( NOW_EPOCH - START_EPOCH ))
  if [ "$ELAPSED" -gt 3600 ]; then
    DURATION_MSG=" ($(( ELAPSED / 3600 ))h $(( (ELAPSED % 3600) / 60 ))m)"
  elif [ "$ELAPSED" -gt 60 ]; then
    DURATION_MSG=" ($(( ELAPSED / 60 ))m)"
  fi
fi

MSG="Session completed: ${PROJECT_NAME}${DURATION_MSG}"

# Detect OS and send notification
case "$(uname -s)" in
  Darwin*)
    osascript -e "display notification \"$MSG\" with title \"$TITLE\"" 2>/dev/null
    ;;
  Linux*)
    if command -v notify-send &>/dev/null; then
      notify-send "$TITLE" "$MSG" 2>/dev/null
    fi
    ;;
  MINGW*|MSYS*|CYGWIN*)
    powershell.exe -Command "
      [void][System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')
      \$notify = New-Object System.Windows.Forms.NotifyIcon
      \$notify.Icon = [System.Drawing.SystemIcons]::Information
      \$notify.Visible = \$true
      \$notify.ShowBalloonTip(5000, '$TITLE', '$MSG', 'Info')
      Start-Sleep -Seconds 6
      \$notify.Dispose()
    " 2>/dev/null &
    ;;
esac

exit 0

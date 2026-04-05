#!/usr/bin/env bash
# Hook: Desktop Notification (Stop)
# Sends a desktop notification when Claude Code completes a task.
# Trigger: Stop (async, 10s timeout)
#
# Supports: macOS (osascript), Linux (notify-send), Windows (PowerShell)

# No set -euo pipefail — hooks must be resilient on Windows

TITLE="Claude Code"
MSG="Task completed"

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

#!/usr/bin/env bash
# Toggle ListenClaude TTS on/off (no daemon restart needed).
# Usage:
#   bash scripts/toggle.sh         toggle current state
#   bash scripts/toggle.sh on      force on
#   bash scripts/toggle.sh off     force off
#   bash scripts/toggle.sh status  print state and exit

set -u

marker="${TMPDIR:-/tmp}/listen-claude.disabled"
action="${1:-toggle}"

exists=0
[[ -f "$marker" ]] && exists=1

case "$action" in
    on)
        [[ $exists -eq 1 ]] && rm -f "$marker"
        state="ON"
        ;;
    off)
        [[ $exists -eq 0 ]] && : > "$marker"
        state="OFF"
        ;;
    status)
        state=$([[ $exists -eq 1 ]] && echo "OFF" || echo "ON")
        ;;
    toggle|*)
        if [[ $exists -eq 1 ]]; then
            rm -f "$marker"; state="ON"
        else
            : > "$marker"; state="OFF"
        fi
        ;;
esac

echo "ListenClaude TTS: $state"

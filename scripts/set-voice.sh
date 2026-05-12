#!/usr/bin/env bash
# Set TTS_VOICE (and optionally TTS_ENGINE) in .env without restarting anything.
# Usage:
#   bash scripts/set-voice.sh <voice_id>             set TTS_VOICE only
#   bash scripts/set-voice.sh <voice_id> <engine>    also switch TTS_ENGINE
#
# Examples:
#   bash scripts/set-voice.sh 21m00Tcm4TlvDq8ikWAM elevenlabs
#   bash scripts/set-voice.sh Mei-Jia system

set -u

if [[ $# -lt 1 ]]; then
    echo "usage: $0 <voice_id> [engine]" >&2
    exit 2
fi

voice="$1"
engine="${2:-}"

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
env_file="$repo_dir/.env"

[[ -f "$env_file" ]] || cp "$repo_dir/.env.example" "$env_file"

tmp=$(mktemp)
# Drop existing TTS_VOICE; drop TTS_ENGINE only if user supplied a new engine.
if [[ -n "$engine" ]]; then
    grep -v -E '^[[:space:]]*(TTS_VOICE|TTS_ENGINE)[[:space:]]*=' "$env_file" > "$tmp"
    echo "TTS_ENGINE=$engine" >> "$tmp"
else
    grep -v -E '^[[:space:]]*TTS_VOICE[[:space:]]*=' "$env_file" > "$tmp"
fi
echo "TTS_VOICE=$voice" >> "$tmp"
mv "$tmp" "$env_file"

[[ -n "$engine" ]] && echo "TTS_ENGINE=$engine"
echo "TTS_VOICE=$voice"

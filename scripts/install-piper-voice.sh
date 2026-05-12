#!/usr/bin/env bash
# Download a Piper TTS voice from HuggingFace into PIPER_VOICES_DIR.
# Usage:
#   bash scripts/install-piper-voice.sh <voice_name>
#
# Example:
#   bash scripts/install-piper-voice.sh zh_CN-huayan-medium
#
# Voice names follow the pattern <lang_country>-<name>-<quality>.
# Browse the full catalog: https://huggingface.co/rhasspy/piper-voices

set -eu

if [[ $# -lt 1 ]]; then
    echo "usage: $0 <voice_name>" >&2
    echo "example: $0 zh_CN-huayan-medium" >&2
    exit 2
fi

voice="$1"
voices_dir="${PIPER_VOICES_DIR:-$HOME/.cache/piper-voices}"
mkdir -p "$voices_dir"

# Split <lang_country>-<name>-<quality>.
IFS='-' read -r lang_country name quality <<< "$voice"
if [[ -z "${quality:-}" ]]; then
    echo "Voice name must look like <lang_country>-<name>-<quality>, e.g. zh_CN-huayan-medium" >&2
    exit 1
fi
lang="${lang_country%_*}"

base="https://huggingface.co/rhasspy/piper-voices/resolve/main"
url_dir="$base/$lang/$lang_country/$name/$quality"
onnx_url="$url_dir/$voice.onnx"
json_url="$url_dir/$voice.onnx.json"

onnx_path="$voices_dir/$voice.onnx"
json_path="$voices_dir/$voice.onnx.json"

echo "Downloading $voice to $voices_dir ..."
if command -v curl >/dev/null 2>&1; then
    curl -L -f -o "$onnx_path" "$onnx_url"
    curl -L -f -o "$json_path" "$json_url"
elif command -v wget >/dev/null 2>&1; then
    wget -O "$onnx_path" "$onnx_url"
    wget -O "$json_path" "$json_url"
else
    echo "Neither curl nor wget found." >&2
    exit 1
fi

size_mb=$(du -m "$onnx_path" | awk '{print $1}')
echo "Done. $voice (${size_mb} MB)"
echo "To use:"
echo "  bash scripts/set-voice.sh $voice piper"

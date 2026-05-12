#!/usr/bin/env bash
# Install ListenClaude on macOS / Linux: create venv, install deps,
# register Claude Code Stop hook, install /listen + /choose-voice skills.
# Safe to re-run (idempotent).

set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
venv_dir="$repo_dir/.venv"
venv_python="$venv_dir/bin/python"
requirements="$repo_dir/requirements.txt"
settings_file="$HOME/.claude/settings.json"
patch_script="$repo_dir/scripts/patch_settings.py"
env_file="$repo_dir/.env"
uname_s="$(uname -s)"

echo
echo "=== ListenClaude install ==="
echo "Location: $repo_dir"
echo "Platform: $uname_s"

# 1. Find a usable system Python.
python_cmd=""
for c in python3 python; do
    if command -v "$c" >/dev/null 2>&1; then
        python_cmd="$c"; break
    fi
done
if [[ -z "$python_cmd" ]]; then
    echo "Python not found. Install Python 3.9+ first:" >&2
    echo "  macOS: brew install python@3.11" >&2
    echo "  Ubuntu/Debian: sudo apt install python3 python3-venv" >&2
    echo "  Fedora: sudo dnf install python3" >&2
    exit 1
fi
echo "Python: $python_cmd ($($python_cmd --version))"

# 2. Enforce >= 3.9.
py_ver=$($python_cmd -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
py_ver_num=$(echo "$py_ver" | awk -F. '{print $1*100+$2}')
if (( py_ver_num < 309 )); then
    echo "Python $py_ver is too old; need 3.9+" >&2
    exit 1
fi

# 3. venv + deps.
if [[ ! -x "$venv_python" ]]; then
    echo "Creating venv..."
    "$python_cmd" -m venv "$venv_dir"
fi
echo "Installing dependencies..."
"$venv_python" -m pip install --upgrade pip >/dev/null
"$venv_python" -m pip install -r "$requirements"

# 4. Linux audio playback prerequisites.
if [[ "$uname_s" == "Linux" ]]; then
    if ! command -v mpg123 >/dev/null 2>&1 && ! command -v ffplay >/dev/null 2>&1; then
        echo "Warning: neither mpg123 nor ffplay found — MP3 playback (edge / elevenlabs engines) will not work." >&2
        echo "  Ubuntu/Debian: sudo apt install mpg123" >&2
        echo "  Fedora:        sudo dnf install mpg123" >&2
    fi
fi

# 5. Default .env — only if missing.
if [[ ! -f "$env_file" ]]; then
    cp "$repo_dir/.env.example" "$env_file"
    echo ".env created (edit to choose voice / engine)"
fi

# 6. Make all bash scripts executable, then register the Stop hook.
chmod +x "$repo_dir"/scripts/*.sh 2>/dev/null || true
mkdir -p "$(dirname "$settings_file")"
"$venv_python" "$patch_script" "$settings_file" install unix "$repo_dir"

# 7. Install /listen and /choose-voice skills.
install_skill() {
    local template="$1"
    local name="$2"
    local dir="$HOME/.claude/skills/$name"
    [[ -f "$template" ]] || return 0
    mkdir -p "$dir"
    sed "s|__REPO_DIR__|$repo_dir|g" "$template" > "$dir/SKILL.md"
    echo "Skill /$name installed at: $dir"
}
install_skill "$repo_dir/skill/SKILL.md.template"        "listen"
install_skill "$repo_dir/skill/CHOOSE_VOICE.md.template" "choose-voice"

# 8. Optional: download a Piper voice if PIPER_VOICE env var is set.
# Example: PIPER_VOICE=zh_CN-huayan-medium ./install.sh
if [[ -n "${PIPER_VOICE:-}" ]]; then
    echo "Installing Piper TTS package and voice $PIPER_VOICE..."
    "$venv_python" -m pip install piper-tts >/dev/null 2>&1
    bash "$repo_dir/scripts/install-piper-voice.sh" "$PIPER_VOICE"
fi

echo
echo "=== Done ==="
echo "Open a new Claude Code session. Claude's next response will be read aloud."
echo
echo "Toggle on/off:  /listen   (or scripts/toggle.{sh,ps1})"
echo "Pick a voice:   /choose-voice"
echo "Uninstall:      ./uninstall.sh"

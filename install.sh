#!/usr/bin/env bash
# Install ListenClaude on macOS / Linux: create venv, install deps,
# register Stop hook. Safe to re-run.

set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
venv_dir="$repo_dir/.venv"
venv_python="$venv_dir/bin/python"
requirements="$repo_dir/requirements.txt"
settings_file="$HOME/.claude/settings.json"
patch_script="$repo_dir/scripts/patch_settings.py"
env_file="$repo_dir/.env"

echo
echo "=== ListenClaude install ==="
echo "Location: $repo_dir"

# 1. Find Python.
python_cmd=""
for c in python3 python; do
    if command -v "$c" >/dev/null 2>&1; then
        python_cmd="$c"; break
    fi
done
if [[ -z "$python_cmd" ]]; then
    echo "Python not found. Install Python 3.9+ first." >&2
    exit 1
fi
echo "Python: $python_cmd ($($python_cmd --version))"

# 2. venv + deps.
if [[ ! -x "$venv_python" ]]; then
    "$python_cmd" -m venv "$venv_dir"
fi
"$venv_python" -m pip install --upgrade pip >/dev/null
"$venv_python" -m pip install -r "$requirements"

# 3. Default .env.
if [[ ! -f "$env_file" ]]; then
    cp "$repo_dir/.env.example" "$env_file"
    echo ".env created (edit to choose voice / engine)"
fi

# 4. Register Stop hook.
chmod +x "$repo_dir/scripts/on_stop.sh" "$repo_dir/scripts/toggle.sh" 2>/dev/null || true
mkdir -p "$(dirname "$settings_file")"
"$venv_python" "$patch_script" "$settings_file" install unix "$repo_dir"

# 5. Install /listen and /choose-voice skills to ~/.claude/skills/.
chmod +x "$repo_dir/scripts/set-voice.sh" 2>/dev/null || true
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

echo
echo "=== Done ==="
echo "Open a new Claude Code session. After Claude responds you should hear it."
echo
echo "Pick a voice — see README \"Choosing a voice\"."
echo "Uninstall: ./uninstall.sh"

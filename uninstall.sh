#!/usr/bin/env bash
# Uninstall ListenClaude: remove the Stop hook entry. Repo files remain.

set -u

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
venv_python="$repo_dir/.venv/bin/python"
patch_script="$repo_dir/scripts/patch_settings.py"
settings_file="$HOME/.claude/settings.json"

echo
echo "=== ListenClaude uninstall ==="

if [[ -f "$patch_script" && -f "$settings_file" ]]; then
    python_cmd="$venv_python"
    if [[ ! -x "$python_cmd" ]]; then
        for c in python3 python; do
            if command -v "$c" >/dev/null 2>&1; then python_cmd="$c"; break; fi
        done
    fi
    if [[ -x "$python_cmd" ]] || command -v "$python_cmd" >/dev/null 2>&1; then
        "$python_cmd" "$patch_script" "$settings_file" uninstall
    else
        echo "Python not found; skipping hook removal"
    fi
else
    echo "patch_settings.py or settings.json not found; skipping"
fi

echo
echo "Done. Repo files kept; delete the directory manually for a clean wipe."

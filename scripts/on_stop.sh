#!/usr/bin/env bash
# Stop-hook entry: pipe Claude Code's JSON payload into listen_bridge.runner.
# Silent on failure so it never blocks Claude Code.

set -u

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_dir="$(cd "$script_dir/.." && pwd)"
python_bin="$repo_dir/.venv/bin/python"

[[ -x "$python_bin" ]] || exit 0

cat | "$python_bin" -m listen_bridge.runner >/dev/null 2>&1
exit 0

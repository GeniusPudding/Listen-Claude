"""Idempotently install/uninstall the ListenClaude Stop hook.

Usage:
    python patch_settings.py <settings_file> install <platform> <repo_dir>
    python patch_settings.py <settings_file> uninstall

Matches existing entries by the MARKER substring (the fixed sub-path
under scripts/) so the operation is idempotent and only touches our own
hook, leaving unrelated entries intact.
"""

import json
import os
import sys

MARKER = "scripts/on_stop"


def strip_ours(hook_groups):
    if not hook_groups:
        return []
    out = []
    for group in hook_groups:
        kept = [
            h for h in group.get("hooks", [])
            if MARKER not in (h.get("command") or "")
        ]
        if kept:
            out.append({**group, "hooks": kept})
    return out


def build_command(platform: str, repo_dir: str) -> str:
    repo_fwd = repo_dir.replace("\\", "/").rstrip("/")
    if platform == "win":
        path = f"{repo_fwd}/scripts/on_stop.ps1"
        return f'powershell -NoProfile -ExecutionPolicy Bypass -File "{path}"'
    if platform == "unix":
        path = f"{repo_fwd}/scripts/on_stop.sh"
        return f'bash "{path}"'
    raise SystemExit(f"unknown platform: {platform} (expected win|unix)")


def main() -> None:
    argv = sys.argv[1:]
    if len(argv) < 2:
        print("usage: patch_settings.py <settings_file> <install|uninstall> ...", file=sys.stderr)
        sys.exit(2)

    settings_path, mode = argv[0], argv[1]
    if mode not in ("install", "uninstall"):
        print(f"unknown mode: {mode}", file=sys.stderr)
        sys.exit(2)
    if mode == "install" and len(argv) != 4:
        print("install needs: <settings_file> install <platform> <repo_dir>", file=sys.stderr)
        sys.exit(2)

    settings = {}
    if os.path.exists(settings_path):
        with open(settings_path, "r", encoding="utf-8") as f:
            raw = f.read().strip()
            if raw:
                settings = json.loads(raw)

    hooks = settings.setdefault("hooks", {})
    hooks["Stop"] = strip_ours(hooks.get("Stop"))

    if mode == "install":
        platform, repo_dir = argv[2], argv[3]
        cmd = build_command(platform, repo_dir)
        hooks["Stop"].append({
            "hooks": [{"type": "command", "command": cmd, "timeout": 30}],
        })

    if not hooks["Stop"]:
        del hooks["Stop"]
    if not hooks:
        del settings["hooks"]

    os.makedirs(os.path.dirname(settings_path) or ".", exist_ok=True)
    with open(settings_path, "w", encoding="utf-8") as f:
        json.dump(settings, f, indent=2, ensure_ascii=False)
        f.write("\n")

    print(f"{mode}: {settings_path}")


if __name__ == "__main__":
    main()

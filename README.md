[English](README.md) · [繁體中文](README.zh-TW.md)

# ListenClaude（聽聲即克）

Hear Claude Code's responses as audio. Triggered automatically when Claude finishes responding — a parallel input channel that lets you *read and listen at the same time* to expand human-AI bandwidth.

Companion to [Kaikou-Claude](https://github.com/GeniusPudding/Kaikou-Claude) (voice → Claude). This project is Claude → voice.

## Features

- **Auto-triggered** by Claude Code's `Stop` hook — zero manual interaction.
- **Local first** — uses your OS built-in TTS by default (macOS `say`, Windows SAPI, Linux `spd-say`).
- **Pluggable engine** — drop in [Piper TTS](https://github.com/rhasspy/piper) for higher-quality offline voices.
- **Configurable reading mode** — full text, first paragraph only, or heuristic summary.
- **Skip-short threshold** — won't read trivial "ok" responses.

## Platform support

| Platform | Default engine | Status | Notes |
|----------|----------------|--------|-------|
| Windows  | Edge TTS | **Stable** | SAPI also available via `system` engine. |
| macOS    | Edge TTS | **Stable** | `say` voices available via `system`. |
| Linux    | Edge TTS | **Stable** | Install `mpg123` for MP3 playback (Edge / ElevenLabs). |

## Install

One command on every platform (clone + run install):

```bash
git clone https://github.com/GeniusPudding/ListenClaude.git
cd ListenClaude
.\install.ps1   # Windows
./install.sh    # macOS / Linux
```

The installer:

1. Creates a local `.venv` and installs Python deps (including `edge-tts`).
2. Writes a default `.env` (only if missing).
3. Registers a `Stop` hook in `~/.claude/settings.json` that invokes the venv Python directly (no shell wrapper, preserves stdin bytes).
4. Installs `/listen` and `/choose-voice` skills to `~/.claude/skills/`.
5. Optionally downloads a Piper voice if `PIPER_VOICE` env var is set during install.

Idempotent — re-run any time to upgrade or repair.

## Choosing a voice

The easiest way is the `/choose-voice` skill — just describe what you want in any Claude session:

```
/choose-voice                                 → list options
/choose-voice list edge Chinese voices
/choose-voice use zh-TW-HsiaoChenNeural
/choose-voice what voice am I using
```

### Engine 1: Edge TTS (default, free, high quality)

[Microsoft Edge's neural voices](https://learn.microsoft.com/azure/ai-services/speech-service/language-support), free, no API key. Auto-installed.

Popular Chinese voices:
- `zh-TW-HsiaoChenNeural` — TW female, warm (default)
- `zh-TW-YunJheNeural` — TW male
- `zh-CN-XiaoxiaoNeural` — CN female, very popular
- `zh-CN-YunyangNeural` — CN male, broadcaster
- `yue-HK-WanLungNeural` — Cantonese male

Full list: `.venv/bin/edge-tts --list-voices | grep zh`.

```
TTS_ENGINE=edge
TTS_VOICE=zh-TW-HsiaoChenNeural
```

### Engine 2: System TTS (free, no install)

OS built-in voices.

```bash
# macOS
say -v '?' | grep zh
# Windows
powershell "Add-Type -AssemblyName System.Speech; (New-Object System.Speech.Synthesis.SpeechSynthesizer).GetInstalledVoices().VoiceInfo | Select Name,Culture"
```

Common: `Mei-Jia` (mac TW), `Tingting` (mac CN), `Microsoft Yating Desktop` (Win TW).

```
TTS_ENGINE=system
TTS_VOICE=Mei-Jia
```

### Engine 3: Piper (free, local, neural quality)

Recommended for offline use with neural-quality voices.

**Option A — download during install** (one-shot):
```bash
# Windows
$env:PIPER_VOICE='zh_CN-huayan-medium'; .\install.ps1

# macOS / Linux
PIPER_VOICE=zh_CN-huayan-medium ./install.sh
```

**Option B — install voice after the fact:**
```bash
.\scripts\install-piper-voice.ps1 zh_CN-huayan-medium       # Windows
bash scripts/install-piper-voice.sh zh_CN-huayan-medium     # macOS / Linux
```

Then switch:
```bash
.\scripts\set-voice.ps1 zh_CN-huayan-medium piper     # Windows
bash scripts/set-voice.sh zh_CN-huayan-medium piper   # macOS / Linux
```

Audition voices: [Piper samples](https://rhasspy.github.io/piper-samples/). Full catalog: https://huggingface.co/rhasspy/piper-voices/tree/main.

### Engine 4: ElevenLabs (cloud, paid, premium quality)

1. Get a key from https://elevenlabs.io/app/settings/api-keys.
2. Browse https://elevenlabs.io/app/voice-library, copy a voice ID.
3. ```
   TTS_ENGINE=elevenlabs
   TTS_VOICE=<voice_id>
   ELEVENLABS_API_KEY=<your_key>
   ```

## Toggle (skill / script)

After install, the `/listen` skill is registered with Claude Code. Use it from any Claude session:

```
/listen          → toggle current state
/listen on       → enable
/listen off      → disable
/listen status   → report state
```

You can also run the script directly:

```bash
.\scripts\toggle.ps1 [on|off|status]   # Windows
bash scripts/toggle.sh [on|off|status] # macOS / Linux
```

The toggle uses a marker file (`$TMPDIR/listen-claude.disabled`), so changes take effect immediately on the next Claude response — no daemon restart, no Claude restart needed.

## Configuration

Edit `.env` in the repo root.

| Variable | Default | Notes |
|----------|---------|-------|
| `TTS_ENABLED` | `1` | `0` disables without uninstalling. |
| `TTS_ENGINE` | `system` | `system` or `piper`. |
| `TTS_VOICE` | (none) | Engine-specific voice ID. |
| `TTS_MODE` | `first` | `full`, `first`, or `summary`. |
| `TTS_MIN_WORDS` | `20` | Skip TTS if response shorter than this. |
| `TTS_MAX_CHARS` | `500` | Truncate longer responses. |
| `TTS_RATE` | `200` | Rough words-per-minute. |
| `PIPER_VOICES_DIR` | `~/.cache/piper-voices` | Piper voice files location. |

## How it works

```
Claude Code finishes responding
        ↓ Stop hook fires
scripts/on_stop.{ps1,sh} receives JSON on stdin
        ↓
listen_bridge.runner:
  1. Parse transcript_path from payload
  2. Tail transcript JSONL for the last assistant message
  3. Apply TTS_MODE (full / first paragraph / heuristic summary)
  4. Strip code blocks and markdown noise
  5. Truncate to TTS_MAX_CHARS
  6. Dispatch to TTS_ENGINE
        ↓
TTS engine plays audio in the background — never blocks Claude Code.
```

## Logs

`%TEMP%\listen-claude.log` (Windows) or `$TMPDIR/listen-claude.log` (Unix).

## Uninstall

```bash
.\uninstall.ps1      # Windows
./uninstall.sh       # macOS / Linux
```

Removes the Stop hook from `~/.claude/settings.json`. Repo files stay on disk.

## Coexistence with other Claude Code plugins

ListenClaude only adds a `Stop` hook. It plays nicely with any other plugin that uses `SessionStart` / `SessionEnd` / `PreToolUse` etc. — including [Kaikou-Claude](https://github.com/GeniusPudding/Kaikou-Claude) (Chinese voice input). The `patch_settings.py` script matches its own entries by the `scripts/on_stop` substring so re-install / uninstall never touches unrelated hooks.

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

## Install

```bash
git clone https://github.com/GeniusPudding/ListenClaude.git
cd ListenClaude

# Windows
.\install.ps1

# macOS / Linux
./install.sh
```

The installer creates a `.venv`, installs dependencies, copies `.env`, and registers a `Stop` hook in `~/.claude/settings.json`.

## Choosing a voice

### Built-in (free, no install)

```bash
# macOS — list Chinese voices
say -v '?' | grep zh
# Try them: say -v Mei-Jia "你好,我是測試"

# Windows — list SAPI voices
powershell "Add-Type -AssemblyName System.Speech; (New-Object System.Speech.Synthesis.SpeechSynthesizer).GetInstalledVoices().VoiceInfo | Where-Object {`$_.Culture.Name -like 'zh*'} | Select Name,Culture"
```

Common Chinese voices:
- macOS: `Mei-Jia` (TW female), `Tingting` (CN female), `Sin-ji` (HK Cantonese)
- Windows: `Microsoft Yating Desktop` (TW), `Microsoft Hanhan Desktop` (Cantonese)
- Linux: depends on `espeak`/`spd-say` installation

Set in `.env`:
```
TTS_ENGINE=system
TTS_VOICE=Mei-Jia
```

### Piper (free, high quality, requires download)

1. `pip install piper-tts` inside the venv.
2. Download a voice from [Piper samples](https://rhasspy.github.io/piper-samples/) — listen first, pick one you like. Recommended for Chinese: `zh_CN-huayan-medium`.
3. Place the `.onnx` and `.onnx.json` files in `~/.cache/piper-voices/`.
4. Set in `.env`:
   ```
   TTS_ENGINE=piper
   TTS_VOICE=zh_CN-huayan-medium
   ```

### ElevenLabs (cloud, highest quality, paid)

1. Get an API key from https://elevenlabs.io/app/settings/api-keys.
2. Browse https://elevenlabs.io/app/voice-library, audition with the built-in preview, copy a voice ID.
3. Set in `.env`:
   ```
   TTS_ENGINE=elevenlabs
   TTS_VOICE=<voice_id>
   ELEVENLABS_API_KEY=<your_key>
   ELEVENLABS_MODEL=eleven_multilingual_v2   # optional, default
   ```

Or use the `/choose-voice` skill in any Claude session — describe the voice ID and Claude will run the setter for you. Examples:

```
/choose-voice 21m00Tcm4TlvDq8ikWAM elevenlabs
/choose-voice list ElevenLabs voices
/choose-voice what voice am I using
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

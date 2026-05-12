"""Edge TTS — Microsoft Edge's free neural TTS service.

High-quality multilingual voices (Mandarin, Taiwanese-accented Mandarin,
Cantonese, English, Japanese, etc.) with no API key. Uses the unofficial
`edge-tts` Python package which talks to the same service Edge browser
uses for read-aloud.

Recommended Chinese voices:
    zh-TW-HsiaoChenNeural  Taiwanese-accented Mandarin, female, warm
    zh-TW-YunJheNeural     Taiwanese-accented Mandarin, male
    zh-CN-XiaoxiaoNeural   Mainland Mandarin, female, very popular
    zh-CN-YunyangNeural    Mainland Mandarin, male, broadcaster tone
    yue-HK-WanLungNeural   Cantonese (Hong Kong), male

Full list:
    edge-tts --list-voices | grep zh
"""

import os
import subprocess
import tempfile

from .. import config


def speak(text: str) -> None:
    voice = config.TTS_VOICE or "zh-TW-HsiaoChenNeural"
    try:
        import edge_tts
        import asyncio
    except ImportError:
        from . import system
        print("× Edge TTS engine selected but `edge-tts` not installed; fallback to system TTS", flush=True)
        system.speak(text)
        return

    with tempfile.NamedTemporaryFile(suffix=".mp3", delete=False) as f:
        mp3_path = f.name
    try:
        rate = _rate_string(config.TTS_RATE)
        communicate = edge_tts.Communicate(text, voice, rate=rate)
        asyncio.run(communicate.save(mp3_path))
        _play_mp3(mp3_path)
    except Exception as e:
        print(f"× Edge TTS failed: {e}", flush=True)
    finally:
        try:
            os.unlink(mp3_path)
        except OSError:
            pass


def _rate_string(wpm: int) -> str:
    # edge-tts uses SSML-style percentage offset from default. Default ~200wpm.
    # Map our wpm to "+X%" / "-X%".
    pct = int((wpm - 200) / 2)  # rough mapping
    return f"+{pct}%" if pct >= 0 else f"{pct}%"


def _play_mp3(path: str) -> None:
    if config.IS_MAC:
        subprocess.run(["afplay", path], check=False)
    elif config.IS_WIN:
        subprocess.run(
            ["powershell", "-NoProfile", "-Command",
             f"Add-Type -AssemblyName presentationCore; "
             f"$p = New-Object System.Windows.Media.MediaPlayer; "
             f"$p.Open('{path}'); $p.Play(); "
             f"Start-Sleep -Seconds 1; "
             f"while ($p.NaturalDuration.HasTimeSpan -and "
             f"$p.Position -lt $p.NaturalDuration.TimeSpan) {{ Start-Sleep -Milliseconds 100 }}"],
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
            creationflags=0x08000000,
            check=False,
        )
    else:
        for cmd in (["mpg123", "-q", path], ["ffplay", "-nodisp", "-autoexit", "-loglevel", "quiet", path]):
            try:
                subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=False)
                return
            except FileNotFoundError:
                continue

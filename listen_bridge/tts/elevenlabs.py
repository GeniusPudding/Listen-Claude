"""ElevenLabs cloud TTS — highest quality, multilingual, ~5000+ voices.

Requires:
- ELEVENLABS_API_KEY in .env
- TTS_VOICE set to an ElevenLabs voice_id
- `pip install requests` (optional dependency; only loaded if engine selected)

Voice picking:
- Browse https://elevenlabs.io/app/voice-library, audition, copy ID.
- Or use the `/voice` skill to set ID without leaving Claude.
"""

import os
import subprocess
import tempfile

from .. import config


def speak(text: str) -> None:
    api_key = os.getenv("ELEVENLABS_API_KEY", "")
    voice_id = config.TTS_VOICE
    if not api_key or not voice_id:
        # Missing config — fall back so the user still hears something.
        from . import system
        system.speak(text)
        return

    try:
        import requests
    except ImportError:
        from . import system
        print("× ElevenLabs engine selected but `requests` not installed; fallback to system TTS", flush=True)
        system.speak(text)
        return

    url = f"https://api.elevenlabs.io/v1/text-to-speech/{voice_id}"
    headers = {
        "xi-api-key": api_key,
        "Content-Type": "application/json",
        "Accept": "audio/mpeg",
    }
    payload = {
        "text": text,
        "model_id": os.getenv("ELEVENLABS_MODEL", "eleven_multilingual_v2"),
    }
    try:
        r = requests.post(url, headers=headers, json=payload, timeout=30, stream=True)
        if r.status_code != 200:
            print(f"× ElevenLabs HTTP {r.status_code}: {r.text[:200]}", flush=True)
            return
        with tempfile.NamedTemporaryFile(suffix=".mp3", delete=False) as f:
            for chunk in r.iter_content(8192):
                if chunk:
                    f.write(chunk)
            mp3_path = f.name
    except Exception as e:
        print(f"× ElevenLabs request failed: {e}", flush=True)
        return

    try:
        _play_mp3(mp3_path)
    finally:
        try:
            os.unlink(mp3_path)
        except OSError:
            pass


def _play_mp3(path: str) -> None:
    if config.IS_MAC:
        subprocess.run(["afplay", path], check=False)
    elif config.IS_WIN:
        # PowerShell can play MP3 via WMP COM object.
        subprocess.run(
            ["powershell", "-NoProfile", "-Command",
             f"$p = New-Object -ComObject WMPlayer.OCX; $p.URL = '{path}'; "
             "while ($p.playState -ne 1) {{ Start-Sleep -Milliseconds 100 }}"],
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
            creationflags=0x08000000,
            check=False,
        )
    else:
        for cmd in (["mpg123", "-q", path], ["ffplay", "-nodisp", "-autoexit", path]):
            try:
                subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=False)
                return
            except FileNotFoundError:
                continue

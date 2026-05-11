"""Piper TTS — local, high-quality voices.

Install:
    pip install piper-tts
    # Download a voice .onnx + .onnx.json from
    # https://github.com/rhasspy/piper/blob/master/VOICES.md
    # and put both files under $PIPER_VOICES_DIR (default ~/.cache/piper-voices).

Voice recommendations for Chinese:
    zh_CN-huayan-medium  — natural female, medium quality
    zh_CN-huayan-x_low   — same voice, smaller and faster
"""

import os
import subprocess
import tempfile

from .. import config


def _resolve_voice_path() -> str:
    voice = config.TTS_VOICE
    if not voice:
        return ""
    # Allow either an absolute .onnx path or a short name under PIPER_VOICES_DIR.
    if os.path.isabs(voice) and os.path.exists(voice):
        return voice
    candidate = os.path.join(config.PIPER_VOICES_DIR, voice)
    if not candidate.endswith(".onnx"):
        candidate += ".onnx"
    if os.path.exists(candidate):
        return candidate
    return ""


def speak(text: str) -> None:
    voice_path = _resolve_voice_path()
    if not voice_path:
        # Fall back to system TTS so the user still hears something.
        from . import system
        system.speak(text)
        return

    # Pipe text through piper, save to a temp wav, play it.
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as wav:
        wav_path = wav.name
    try:
        subprocess.run(
            ["piper", "--model", voice_path, "--output_file", wav_path],
            input=text.encode("utf-8"),
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=False,
        )
        _play_wav(wav_path)
    finally:
        try:
            os.unlink(wav_path)
        except OSError:
            pass


def _play_wav(path: str) -> None:
    if config.IS_MAC:
        subprocess.Popen(["afplay", path])
    elif config.IS_WIN:
        subprocess.Popen(
            ["powershell", "-NoProfile", "-Command",
             f"(New-Object Media.SoundPlayer '{path}').PlaySync()"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            creationflags=0x08000000,
        )
    else:
        for cmd in (["paplay", path], ["aplay", path]):
            try:
                subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                return
            except FileNotFoundError:
                continue

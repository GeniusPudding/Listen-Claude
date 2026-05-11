"""Built-in OS TTS: macOS `say`, Windows SAPI, Linux `spd-say` / `espeak`."""

import subprocess

from .. import config


def speak(text: str) -> None:
    if config.IS_MAC:
        _speak_mac(text)
    elif config.IS_WIN:
        _speak_win(text)
    else:
        _speak_linux(text)


def _speak_mac(text: str) -> None:
    args = ["say"]
    if config.TTS_VOICE:
        args += ["-v", config.TTS_VOICE]
    if config.TTS_RATE:
        args += ["-r", str(config.TTS_RATE)]
    args.append(text)
    subprocess.Popen(args, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def _speak_win(text: str) -> None:
    # SAPI via PowerShell; spoken async via Speak() returns immediately.
    voice_setter = ""
    if config.TTS_VOICE:
        # SelectVoice errors loudly if the name doesn't match — suppress.
        voice_setter = f"try {{ $s.SelectVoice('{config.TTS_VOICE}') }} catch {{}}"
    # Map a rough WPM rate (default 200) to SAPI's -10..10 scale.
    sapi_rate = max(-10, min(10, (config.TTS_RATE - 200) // 20))
    safe = text.replace("'", "''")
    script = (
        "Add-Type -AssemblyName System.Speech;"
        "$s = New-Object System.Speech.Synthesis.SpeechSynthesizer;"
        f"{voice_setter};"
        f"$s.Rate = {sapi_rate};"
        f"$s.Speak('{safe}');"
    )
    subprocess.Popen(
        ["powershell", "-NoProfile", "-Command", script],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        creationflags=0x08000000 if config.IS_WIN else 0,  # CREATE_NO_WINDOW
    )


def _speak_linux(text: str) -> None:
    # Try spd-say (speech-dispatcher) first, fall back to espeak.
    for cmd in (
        ["spd-say", "-r", str(config.TTS_RATE - 200), text],
        ["espeak", "-s", str(config.TTS_RATE), text],
    ):
        try:
            subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            return
        except FileNotFoundError:
            continue

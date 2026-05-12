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
    # Block until speech finishes so the caller's lock stays valid.
    subprocess.run(args, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=False)


def _speak_win(text: str) -> None:
    # SAPI via PowerShell — Speak() is synchronous inside the PS process,
    # and subprocess.run blocks until PS exits.
    voice_setter = ""
    if config.TTS_VOICE:
        voice_setter = f"try {{ $s.SelectVoice('{config.TTS_VOICE}') }} catch {{}}"
    sapi_rate = max(-10, min(10, (config.TTS_RATE - 200) // 20))
    safe = text.replace("'", "''")
    script = (
        "Add-Type -AssemblyName System.Speech;"
        "$s = New-Object System.Speech.Synthesis.SpeechSynthesizer;"
        f"{voice_setter};"
        f"$s.Rate = {sapi_rate};"
        f"$s.Speak('{safe}');"
    )
    subprocess.run(
        ["powershell", "-NoProfile", "-Command", script],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        creationflags=0x08000000 if config.IS_WIN else 0,
        check=False,
    )


def _speak_linux(text: str) -> None:
    for cmd in (
        ["spd-say", "-w", "-r", str(config.TTS_RATE - 200), text],  # -w blocks
        ["espeak", "-s", str(config.TTS_RATE), text],
    ):
        try:
            subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=False)
            return
        except FileNotFoundError:
            continue

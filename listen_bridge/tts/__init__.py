"""TTS engine dispatch."""

from .. import config


def speak(text: str) -> None:
    if not text:
        return
    if config.TTS_ENGINE == "piper":
        from . import piper
        piper.speak(text)
    else:
        from . import system
        system.speak(text)

"""TTS engine dispatch."""

from .. import config


def speak(text: str) -> None:
    if not text:
        return
    engine = config.TTS_ENGINE.lower()
    if engine == "piper":
        from . import piper
        piper.speak(text)
    elif engine == "elevenlabs":
        from . import elevenlabs
        elevenlabs.speak(text)
    else:
        from . import system
        system.speak(text)

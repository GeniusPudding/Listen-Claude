"""Entry point invoked by Claude Code's Stop hook.

Usage: stdin receives the hook JSON payload; this module reads it,
extracts the last assistant message, prepares text per TTS_MODE, and
hands it to the configured TTS engine.
"""

import json
import sys
import time

from . import config, summarize, transcript, tts


def _log(msg: str) -> None:
    try:
        with open(config.LOG_PATH, "a", encoding="utf-8") as f:
            f.write(f"[{time.strftime('%H:%M:%S')}] {msg}\n")
    except Exception:
        pass


def main() -> int:
    if not config.is_enabled():
        return 0

    try:
        payload = json.load(sys.stdin)
    except Exception as e:
        _log(f"failed to parse hook stdin: {e}")
        return 0

    text = transcript.extract_last_assistant(payload)
    if not text:
        _log("no assistant message found")
        return 0

    if len(text.split()) < config.TTS_MIN_WORDS and len(text) < config.TTS_MIN_WORDS * 2:
        _log(f"skip (too short): {text[:40]}")
        return 0

    spoken = summarize.prepare_text(text, config.TTS_MODE, config.TTS_MAX_CHARS)
    _log(f"speak ({config.TTS_ENGINE} / {config.TTS_VOICE or 'default'}): {spoken[:80]}")
    tts.speak(spoken)
    return 0


if __name__ == "__main__":
    sys.exit(main())

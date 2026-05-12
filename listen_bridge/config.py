"""Runtime configuration loaded from .env."""

import os
import tempfile

from dotenv import load_dotenv

load_dotenv()

import sys
IS_WIN = sys.platform == "win32"
IS_MAC = sys.platform == "darwin"
IS_LINUX = sys.platform.startswith("linux")

# TTS engine: "system" (built-in: macOS say / Win SAPI), "piper" (local
# Piper TTS, requires the piper-tts pip package and a downloaded voice).
TTS_ENGINE = os.getenv("TTS_ENGINE", "system").lower()

# Voice identifier — interpretation depends on the engine:
#   system + macOS: voice name (e.g. "Mei-Jia", "Tingting"); `say -v '?'`
#   system + Windows: voice name (e.g. "Microsoft Yating Desktop")
#   piper: path to .onnx file, or short name resolved under PIPER_VOICES_DIR
TTS_VOICE = os.getenv("TTS_VOICE", "")

# Reading mode:
#   "full"  — read the entire last assistant message
#   "first" — read only the first paragraph
#   "summary" — heuristic summary (headers + first sentence of each paragraph)
TTS_MODE = os.getenv("TTS_MODE", "first")

# Skip TTS if message has fewer words than this (avoid reading "ok").
TTS_MIN_WORDS = int(os.getenv("TTS_MIN_WORDS", "20"))

# Maximum characters to send to TTS (truncate longer messages).
TTS_MAX_CHARS = int(os.getenv("TTS_MAX_CHARS", "500"))

# Words per minute roughly; engine-specific mapping in tts/<engine>.py.
TTS_RATE = int(os.getenv("TTS_RATE", "200"))

# Master switch — set to "0" to disable TTS without uninstalling.
TTS_ENABLED = os.getenv("TTS_ENABLED", "1") == "1"

# Runtime toggle marker — if this file exists, TTS is disabled regardless
# of TTS_ENABLED. Created/removed by scripts/toggle.{ps1,sh} for fast on/off
# without editing .env.
TOGGLE_MARKER = os.path.join(tempfile.gettempdir(), "listen-claude.disabled")


def is_enabled() -> bool:
    if not TTS_ENABLED:
        return False
    if os.path.exists(TOGGLE_MARKER):
        return False
    return True

# Piper-specific: directory holding .onnx and .onnx.json voice files.
PIPER_VOICES_DIR = os.getenv(
    "PIPER_VOICES_DIR",
    os.path.expanduser("~/.cache/piper-voices"),
)

LOG_PATH = os.path.join(tempfile.gettempdir(), "listen-claude.log")

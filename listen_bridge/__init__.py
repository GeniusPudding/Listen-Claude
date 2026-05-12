"""Listen-Claude — text-to-speech for Claude Code responses.

Triggered by Claude Code's Stop hook. Reads the last assistant message,
optionally summarizes, and plays it through TTS (system or Piper).
"""

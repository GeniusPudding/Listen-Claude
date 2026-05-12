"""Direct Python entry for Claude Code's Stop hook.

Invoked by Claude Code without a shell wrapper so stdin reaches Python
with its original byte encoding from Claude Code (a PowerShell or bash
middleman re-encodes the bytes and corrupts the JSON payload).
"""

import os
import sys

# Make the listen_bridge package importable regardless of cwd.
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from listen_bridge.runner import main

sys.exit(main())

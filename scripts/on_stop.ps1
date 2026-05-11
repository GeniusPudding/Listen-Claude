# Stop-hook entry. Receives Claude Code's JSON payload on stdin, pipes it
# into listen_bridge.runner. Stays silent so a TTS failure never blocks
# Claude Code from continuing.

$repoDir   = Split-Path -Parent $PSScriptRoot
$venvPython = Join-Path $repoDir '.venv\Scripts\python.exe'

if (-not (Test-Path $venvPython)) {
    exit 0
}

$stdin = [Console]::In.ReadToEnd()
$stdin | & $venvPython -m listen_bridge.runner 2>$null | Out-Null
exit 0

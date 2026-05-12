# Set TTS_VOICE (and optionally TTS_ENGINE) in .env without restarting anything.
# Usage:
#   .\scripts\set-voice.ps1 <voice_id>                  set TTS_VOICE only
#   .\scripts\set-voice.ps1 <voice_id> <engine>         also switch TTS_ENGINE
#
# Examples:
#   .\scripts\set-voice.ps1 21m00Tcm4TlvDq8ikWAM elevenlabs
#   .\scripts\set-voice.ps1 Mei-Jia system

param(
    [Parameter(Mandatory=$true)][string]$VoiceId,
    [string]$Engine
)

$repoDir = Split-Path -Parent $PSScriptRoot
$envFile = Join-Path $repoDir '.env'

if (-not (Test-Path $envFile)) {
    Copy-Item (Join-Path $repoDir '.env.example') $envFile
}

$lines = @(Get-Content $envFile)
$kept = $lines | Where-Object {
    -not ($_ -match '^\s*TTS_VOICE\s*=') -and
    -not ($Engine -and ($_ -match '^\s*TTS_ENGINE\s*='))
}
$new = $kept + "TTS_VOICE=$VoiceId"
if ($Engine) { $new += "TTS_ENGINE=$Engine" }
Set-Content -Path $envFile -Value $new -Encoding UTF8

if ($Engine) {
    Write-Host "TTS_ENGINE=$Engine"
}
Write-Host "TTS_VOICE=$VoiceId"

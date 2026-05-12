# Toggle ListenClaude TTS on/off (no daemon restart needed).
# Usage:
#   .\scripts\toggle.ps1        toggle current state
#   .\scripts\toggle.ps1 on     force on
#   .\scripts\toggle.ps1 off    force off
#   .\scripts\toggle.ps1 status print state and exit

param([string]$Action = 'toggle')

$marker = Join-Path $env:TEMP 'listen-claude.disabled'
$exists = Test-Path $marker

switch ($Action.ToLower()) {
    'on'     { if ($exists) { Remove-Item $marker -Force }; $state = 'ON' }
    'off'    { if (-not $exists) { New-Item -ItemType File -Path $marker -Force | Out-Null }; $state = 'OFF' }
    'status' { $state = if ($exists) { 'OFF' } else { 'ON' } }
    default  {
        if ($exists) { Remove-Item $marker -Force; $state = 'ON' }
        else         { New-Item -ItemType File -Path $marker -Force | Out-Null; $state = 'OFF' }
    }
}

Write-Host "ListenClaude TTS: $state"

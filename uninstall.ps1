# Uninstall ListenClaude: remove the Stop hook entry. Repo files remain.

$ErrorActionPreference = 'Continue'
$repoDir      = $PSScriptRoot
$venvPython   = Join-Path $repoDir '.venv\Scripts\python.exe'
$patchScript  = Join-Path $repoDir 'scripts\patch_settings.py'
$settingsFile = Join-Path $HOME '.claude\settings.json'

Write-Host ''
Write-Host '=== ListenClaude uninstall ==='

if ((Test-Path $patchScript) -and (Test-Path $settingsFile)) {
    $pythonCmd = $null
    if (Test-Path $venvPython) {
        $pythonCmd = $venvPython
    } else {
        foreach ($c in @('py', 'python', 'python3')) {
            try {
                $out = & $c --version 2>&1
                if ($LASTEXITCODE -eq 0) { $pythonCmd = $c; break }
            } catch {}
        }
    }
    if ($pythonCmd) {
        & $pythonCmd $patchScript $settingsFile uninstall
    } else {
        Write-Host 'Python not found; skipping hook removal'
    }
} else {
    Write-Host 'patch_settings.py or settings.json not found; skipping'
}

# Remove our skills if present.
foreach ($name in @('listen', 'choose-voice')) {
    $dir = Join-Path $HOME ".claude\skills\$name"
    if (Test-Path $dir) {
        Remove-Item -Recurse -Force $dir
        Write-Host "Removed /$name skill"
    }
}

Write-Host ''
Write-Host 'Done. Repo files kept; delete the directory manually for a clean wipe.'

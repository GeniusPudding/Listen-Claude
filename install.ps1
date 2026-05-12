# Install ListenClaude: create venv, install deps, register Stop hook.
# Safe to re-run.

$ErrorActionPreference = 'Stop'
$repoDir       = $PSScriptRoot
$venvDir       = Join-Path $repoDir '.venv'
$venvPython    = Join-Path $venvDir 'Scripts\python.exe'
$requirements  = Join-Path $repoDir 'requirements.txt'
$settingsDir   = Join-Path $HOME '.claude'
$settingsFile  = Join-Path $settingsDir 'settings.json'
$patchScript   = Join-Path $repoDir 'scripts\patch_settings.py'
$envFile       = Join-Path $repoDir '.env'

Write-Host ''
Write-Host '=== ListenClaude install ==='
Write-Host "Location: $repoDir"

# 1. Find a usable system Python.
$pythonCmd = $null
foreach ($c in @('py', 'python', 'python3')) {
    try {
        $out = & $c --version 2>&1
        if ($LASTEXITCODE -eq 0) { $pythonCmd = $c; Write-Host "Python: $c ($out)"; break }
    } catch {}
}
if (-not $pythonCmd) {
    Write-Host 'Python not found. Install Python 3.9+ first.' -ForegroundColor Red
    exit 1
}

# 2. venv + deps.
if (-not (Test-Path $venvPython)) {
    Write-Host 'Creating venv...'
    & $pythonCmd -m venv $venvDir
}
& $venvPython -m pip install --upgrade pip 2>&1 | Out-Null
& $venvPython -m pip install -r $requirements

# 3. Default .env.
if (-not (Test-Path $envFile)) {
    Copy-Item (Join-Path $repoDir '.env.example') $envFile
    Write-Host '.env created (edit to choose voice / engine)'
}

# 4. Register Stop hook.
if (-not (Test-Path $settingsDir)) { New-Item -ItemType Directory -Path $settingsDir | Out-Null }
& $venvPython $patchScript $settingsFile install win $repoDir

# 5. Install /listen skill to ~/.claude/skills/listen/SKILL.md.
$skillDir   = Join-Path $HOME '.claude\skills\listen'
$templateFp = Join-Path $repoDir 'skill\SKILL.md.template'
if (Test-Path $templateFp) {
    if (-not (Test-Path $skillDir)) { New-Item -ItemType Directory -Path $skillDir | Out-Null }
    $template = Get-Content $templateFp -Raw
    $repoFwd = $repoDir -replace '\\','/'
    $skillContent = $template.Replace('__REPO_DIR__', $repoFwd)
    Set-Content -Path (Join-Path $skillDir 'SKILL.md') -Value $skillContent -Encoding UTF8
    Write-Host "Skill /listen installed at: $skillDir"
}

Write-Host ''
Write-Host '=== Done ==='
Write-Host 'Open a new Claude Code session. After Claude responds you should hear it.'
Write-Host ''
Write-Host 'Pick a voice — see README "Choosing a voice".'
Write-Host 'Uninstall: .\uninstall.ps1'

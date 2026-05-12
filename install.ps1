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

# 5. Install /listen and /choose-voice skills to ~/.claude/skills/.
$repoFwd = $repoDir -replace '\\','/'
$skillsRoot = Join-Path $HOME '.claude\skills'

function Install-Skill($templateRel, $skillName) {
    $templateFp = Join-Path $repoDir $templateRel
    if (-not (Test-Path $templateFp)) { return }
    $dir = Join-Path $skillsRoot $skillName
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $content = (Get-Content $templateFp -Raw).Replace('__REPO_DIR__', $repoFwd)
    # Write UTF-8 WITHOUT BOM — Claude Code's YAML frontmatter parser rejects
    # files that start with a BOM (treats the BOM bytes as part of the first
    # line, so the `---` delimiter no longer matches).
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText((Join-Path $dir 'SKILL.md'), $content, $utf8NoBom)
    Write-Host "Skill /$skillName installed at: $dir"
}

Install-Skill 'skill\SKILL.md.template'         'listen'
Install-Skill 'skill\CHOOSE_VOICE.md.template'  'choose-voice'

# 6. Optional: download a Piper voice if PIPER_VOICE env var is set.
#    Example: $env:PIPER_VOICE='zh_CN-huayan-medium'; .\install.ps1
if ($env:PIPER_VOICE) {
    Write-Host "Installing Piper TTS package and voice $env:PIPER_VOICE..."
    & $venvPython -m pip install piper-tts 2>&1 | Out-Null
    & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $repoDir 'scripts\install-piper-voice.ps1') $env:PIPER_VOICE
}

Write-Host ''
Write-Host '=== Done ==='
Write-Host 'Open a new Claude Code session. After Claude responds you should hear it.'
Write-Host ''
Write-Host 'Pick a voice — see README "Choosing a voice".'
Write-Host 'Uninstall: .\uninstall.ps1'

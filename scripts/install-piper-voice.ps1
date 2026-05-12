# Download a Piper TTS voice from HuggingFace into PIPER_VOICES_DIR.
# Usage:
#   .\scripts\install-piper-voice.ps1 <voice_name>
#
# Example:
#   .\scripts\install-piper-voice.ps1 zh_CN-huayan-medium
#
# Voice names follow the pattern <lang_country>-<name>-<quality>.
# Browse the full catalog: https://huggingface.co/rhasspy/piper-voices

param([Parameter(Mandatory=$true)][string]$VoiceName)

$voicesDir = $env:PIPER_VOICES_DIR
if (-not $voicesDir) {
    $voicesDir = Join-Path $env:USERPROFILE '.cache\piper-voices'
}

if (-not (Test-Path $voicesDir)) {
    New-Item -ItemType Directory -Path $voicesDir -Force | Out-Null
}

$parts = $VoiceName.Split('-')
if ($parts.Count -lt 3) {
    Write-Host "Voice name must look like <lang_country>-<name>-<quality>, e.g. zh_CN-huayan-medium" -ForegroundColor Red
    exit 1
}
$langCountry = $parts[0]
$lang        = $langCountry.Split('_')[0]
$name        = $parts[1]
$quality     = $parts[2]

$base = "https://huggingface.co/rhasspy/piper-voices/resolve/main"
$urlDir   = "$base/$lang/$langCountry/$name/$quality"
$onnxUrl  = "$urlDir/$VoiceName.onnx"
$jsonUrl  = "$urlDir/$VoiceName.onnx.json"

$onnxPath = Join-Path $voicesDir "$VoiceName.onnx"
$jsonPath = Join-Path $voicesDir "$VoiceName.onnx.json"

Write-Host "Downloading $VoiceName to $voicesDir ..."
try {
    Invoke-WebRequest -Uri $onnxUrl -OutFile $onnxPath -UseBasicParsing
    Invoke-WebRequest -Uri $jsonUrl -OutFile $jsonPath -UseBasicParsing
} catch {
    Write-Host "Download failed: $_" -ForegroundColor Red
    Write-Host "Check the voice name at https://huggingface.co/rhasspy/piper-voices/tree/main" -ForegroundColor Yellow
    exit 1
}

$sizeMB = [Math]::Round((Get-Item $onnxPath).Length / 1MB, 1)
Write-Host "Done. $VoiceName ($sizeMB MB)"
Write-Host "To use:"
Write-Host "  .\scripts\set-voice.ps1 $VoiceName piper"

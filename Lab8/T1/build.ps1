# Lab 8 T1 - Build script
# Run from repo root: .\Lab8\T1\build.ps1

$TaskDir  = $PSScriptRoot
$RepoRoot = Split-Path (Split-Path $PSScriptRoot)
$TaskRel  = "Lab8\T1"
$Kcpsm    = "$RepoRoot\Lab8\kcpsm6_files"

Write-Host "=== Lab 8 T1: Square problem with pushbuttons and 7-seg ==="

Copy-Item "$Kcpsm\ROM_form.v" "$TaskDir\ROM_form.v"

Push-Location $TaskDir
& "$Kcpsm\kcpsm6.exe" btn_rom.psm
Pop-Location

Remove-Item "$TaskDir\ROM_form.v"

if (-not (Test-Path "$TaskDir\btn_rom.v")) {
    Write-Host "ERROR: btn_rom.v was not generated."
    exit 1
}

python "$RepoRoot\run_hardware.py" $TaskRel

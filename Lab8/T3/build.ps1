# Lab 8 T3 - Build script (7-seg, 16-bit LEDs, LCD Pmod)
# Run from repo root: .\Lab8\T3\build.ps1

$TaskDir  = $PSScriptRoot
$RepoRoot = Split-Path (Split-Path $PSScriptRoot)
$TaskRel  = "Lab8\T3"
$Kcpsm    = "$RepoRoot\Lab8\kcpsm6_files"

Write-Host "=== Lab 8 T3: Square problem with LCD Pmod output ==="

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

# HW7 T2 - Build script (Smart Light Controller)
# Run from repo root: .\HW7\T2\build.ps1

$TaskDir  = $PSScriptRoot
$RepoRoot = Split-Path (Split-Path $PSScriptRoot)
$TaskRel  = "HW7\T2"
$Kcpsm    = "$RepoRoot\Lab8\kcpsm6_files"

Write-Host "=== HW7 T2: Smart Light Controller ==="

# Remove stale output so we know for sure if assembly succeeded
if (Test-Path "$TaskDir\als_rom.v") {
    Remove-Item "$TaskDir\als_rom.v"
}

Copy-Item "$Kcpsm\ROM_form.v" "$TaskDir\ROM_form.v"

Push-Location $TaskDir
& "$Kcpsm\kcpsm6.exe" als_rom.psm
Pop-Location

Remove-Item "$TaskDir\ROM_form.v"

if (-not (Test-Path "$TaskDir\als_rom.v")) {
    Write-Host "ERROR: als_rom.v was not generated. Check that kcpsm6.exe ran correctly."
    exit 1
}

Write-Host "Assembly succeeded. Starting Vivado..."
python "$RepoRoot\run_hardware.py" $TaskRel

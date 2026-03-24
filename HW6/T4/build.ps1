# HW6 T4 - Build script (Square Problem)
# Run from repo root: .\HW6\T4\build.ps1
# REQUIRES: list_ch16_02_sio_rom.psm from Pong Chu textbook Ch.16 resources
#           Place it in HW6\T4\ before running.

$RepoRoot  = (Resolve-Path "$PSScriptRoot\..\..")
$TaskDir   = $PSScriptRoot
$TaskRel   = "HW6\T4"
$Kcpsm     = "$RepoRoot\KCPSM6_Release9_30Sept14"
$Psm       = "list_ch16_02_sio_rom.psm"

Write-Host "=== HW6 T4: Square Problem ==="

if (-not (Test-Path "$TaskDir\$Psm")) {
    Write-Host "ERROR: $Psm not found in $TaskRel\"
    Write-Host "  Get it from Pong Chu textbook Ch.16 resources and place it here."
    exit 1
}

Copy-Item "$Kcpsm\Verilog\ROM_form_JTAGLoader_Vivado_2June14.v" "$TaskDir\ROM_form.v"
Copy-Item "$Kcpsm\Verilog\kcpsm6.v" "$TaskDir\kcpsm6.v"

Push-Location $TaskDir
& "$Kcpsm\kcpsm6.exe" $Psm
Pop-Location

Remove-Item "$TaskDir\ROM_form.v"

python run_hardware.py $TaskRel

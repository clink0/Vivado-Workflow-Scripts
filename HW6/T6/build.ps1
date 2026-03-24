# HW6 T6 - Build script
# Run from repo root: .\HW6\T6\build.ps1

$RepoRoot  = (Resolve-Path "$PSScriptRoot\..\..")
$TaskDir   = $PSScriptRoot
$TaskRel   = "HW6\T6"
$Kcpsm     = "$RepoRoot\KCPSM6_Release9_30Sept14"

Write-Host "=== HW6 T6: Mask lower 2 bits ==="

Copy-Item "$Kcpsm\Verilog\ROM_form_JTAGLoader_Vivado_2June14.v" "$TaskDir\ROM_form.v"
Copy-Item "$Kcpsm\Verilog\kcpsm6.v" "$TaskDir\kcpsm6.v"

Push-Location $TaskDir
& "$Kcpsm\kcpsm6.exe" prog.psm
Pop-Location

Remove-Item "$TaskDir\ROM_form.v"

python run_hardware.py $TaskRel

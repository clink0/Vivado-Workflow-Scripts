# HW6 T8 - Build script (call version)
# Run from repo root: .\HW6\T8\build_call.ps1
#
# Temporarily swaps main_top.v to instantiate prog_call instead of prog,
# builds, then restores. With CALL, return goes back to output s2 so
# both s3 (0x06) and s2 (0x05) get written when sw[0]=1.

$RepoRoot  = (Resolve-Path "$PSScriptRoot\..\..")
$TaskDir   = $PSScriptRoot
$TaskRel   = "HW6\T8"
$Kcpsm     = "$RepoRoot\KCPSM6_Release9_30Sept14"

Write-Host "=== HW6 T8: Jump/return/load (call version) ==="

Copy-Item "$Kcpsm\Verilog\ROM_form_JTAGLoader_Vivado_2June14.v" "$TaskDir\ROM_form.v"
Copy-Item "$Kcpsm\Verilog\kcpsm6.v" "$TaskDir\kcpsm6.v"

Push-Location $TaskDir
& "$Kcpsm\kcpsm6.exe" prog_call.psm
Pop-Location

Remove-Item "$TaskDir\ROM_form.v"

# Swap instantiation in main_top.v: prog -> prog_call
$TopFile = "$TaskDir\main_top.v"
(Get-Content $TopFile) -replace 'prog #\(', 'prog_call #(' | Set-Content $TopFile

python run_hardware.py $TaskRel

# Restore main_top.v
(Get-Content $TopFile) -replace 'prog_call #\(', 'prog #(' | Set-Content $TopFile

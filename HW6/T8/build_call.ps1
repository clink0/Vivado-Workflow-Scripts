# HW6 T8 - Build script (call version)
# Run from repo root: .\HW6\T8\build_call.ps1

$RepoRoot  = (Resolve-Path "$PSScriptRoot\..\..")  .Path
$TaskDir   = (Resolve-Path $PSScriptRoot).Path
$TaskRel   = "HW6\T8"
$Kcpsm     = "$RepoRoot\KCPSM6_Release9_30Sept14"
$TopFile   = "$TaskDir\main_top.v"

Write-Host "=== HW6 T8: Jump/return/load (call version) ==="

Copy-Item "$Kcpsm\Verilog\ROM_form_JTAGLoader_Vivado_2June14.v" "$TaskDir\ROM_form.v"
Copy-Item "$Kcpsm\Verilog\kcpsm6.v" "$TaskDir\kcpsm6.v"

Push-Location $TaskDir
& "$Kcpsm\kcpsm6.exe" prog_call.psm
Pop-Location

Remove-Item "$TaskDir\ROM_form.v"

if (-not (Test-Path "$TaskDir\prog_call.v")) {
    Write-Host "ERROR: prog_call.v was not generated. Check that ROM_form.v was found by the assembler."
    exit 1
}

(Get-Content $TopFile) -replace 'prog #\(', 'prog_call #(' | Set-Content $TopFile

python "$RepoRoot\run_hardware.py" $TaskRel

(Get-Content $TopFile) -replace 'prog_call #\(', 'prog #(' | Set-Content $TopFile

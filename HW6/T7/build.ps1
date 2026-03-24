# HW6 T7 - Build script
# Run from repo root: .\HW6\T7\build.ps1

$RepoRoot  = (Resolve-Path "$PSScriptRoot\..\..")  .Path
$TaskDir   = (Resolve-Path $PSScriptRoot).Path
$TaskRel   = "HW6\T7"
$Kcpsm     = "$RepoRoot\KCPSM6_Release9_30Sept14"

Write-Host "=== HW6 T7: Right shift switches by 1 ==="

Copy-Item "$Kcpsm\Verilog\ROM_form_JTAGLoader_Vivado_2June14.v" "$TaskDir\ROM_form.v"
Copy-Item "$Kcpsm\Verilog\kcpsm6.v" "$TaskDir\kcpsm6.v"

Push-Location $TaskDir
& "$Kcpsm\kcpsm6.exe" prog.psm
Pop-Location

Remove-Item "$TaskDir\ROM_form.v"

if (-not (Test-Path "$TaskDir\prog.v")) {
    Write-Host "ERROR: prog.v was not generated. Check that ROM_form.v was found by the assembler."
    exit 1
}

python "$RepoRoot\run_hardware.py" $TaskRel

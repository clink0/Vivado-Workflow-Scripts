# HW6 T8_2 - Build script (call version)
# Run from repo root: .\HW6\T8_2\build.ps1

$TaskDir  = $PSScriptRoot
$RepoRoot = Split-Path (Split-Path $PSScriptRoot)
$TaskRel  = "HW6\T8_2"
$Kcpsm    = "$RepoRoot\KCPSM6_Release9_30Sept14"

Write-Host "=== HW6 T8_2: Jump/call (call version) ==="

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

python "$RepoRoot\run_hardware.py" $TaskRel

# HW9 T1 - Build script
# SPI leader outputs constant 8'b00001111 (no IP cores, uses run_hardware.py)
# Run from repo root: .\HW9\T1\build.ps1

$TaskDir = $PSScriptRoot
$RepoRoot = Split-Path (Split-Path $TaskDir -Parent) -Parent

Write-Host "=== HW9 T1: SPI Leader Constant Output ==="
Write-Host "Running Vivado via run_hardware.py..."

python "$RepoRoot\run_hardware.py" "HW9\T1"

if ($LASTEXITCODE -eq 0) {
    Write-Host "SUCCESS: Build complete."
    Write-Host "Open Vivado Hardware Manager and program the device."
    Write-Host ""
    Write-Host "Hardware setup:"
    Write-Host "  Oscilloscope Ch1 -> JB1 (SCK)"
    Write-Host "  Oscilloscope Ch2 -> JB3 (MOSI)"
    Write-Host "  GND              -> JB5 (GND)"
    Write-Host "  Expected: 2MHz SCK, MOSI pattern 00001111"
} else {
    Write-Host "ERROR: Build failed. Check Vivado log."
}

# CourseProject T3 — Heart Rate Monitor: XADC + Picoblaze + OLED
# Run from repo root: .\CourseProject\T3\build.ps1

$TaskDir  = $PSScriptRoot
$RepoRoot = Split-Path (Split-Path $PSScriptRoot)
$Kcpsm    = "$RepoRoot\Lab8\kcpsm6_files"
$Vivado   = "C:\Xilinx\Vivado\2018.3\bin\vivado.bat"

Write-Host "=== CourseProject T3: Heart Rate Monitor ==="

# ── Step 1: Assemble PSM -> prog.v ───────────────────────────────────────
Copy-Item "$Kcpsm\kcpsm6.v"   "$TaskDir\kcpsm6.v"   -Force
Copy-Item "$Kcpsm\ROM_form.v" "$TaskDir\ROM_form.v"  -Force

if (Test-Path "$TaskDir\prog.v") { Remove-Item "$TaskDir\prog.v" }

Push-Location $TaskDir
& "$Kcpsm\kcpsm6.exe" prog.psm
Pop-Location

$timeout = 30; $elapsed = 0
Write-Host "Waiting for prog.v..."
while (-not (Test-Path "$TaskDir\prog.v") -and $elapsed -lt $timeout) {
    Start-Sleep -Seconds 1; $elapsed++
}
Remove-Item "$TaskDir\ROM_form.v" -ErrorAction SilentlyContinue

if (-not (Test-Path "$TaskDir\prog.v")) {
    Write-Host "ERROR: prog.v not generated. Check kcpsm6.exe output."
    exit 1
}
Write-Host "Assembly succeeded."

# ── Step 2: Build Vivado project ─────────────────────────────────────────
$vFiles = @(
    "$TaskDir\cp_t3_top.v",
    "$TaskDir\OledSPI.v",
    "$TaskDir\OledInit.v",
    "$TaskDir\OledEX_t3.v",
    "$TaskDir\charLib.v",
    "$TaskDir\kcpsm6.v",
    "$TaskDir\prog.v"
)
$xdcFile = "$TaskDir\constraints.xdc"
$projDir = "$TaskDir\vivado_project"

$addFiles = ($vFiles | ForEach-Object { "add_files -norecurse {$_}" }) -join "`n"

$tcl = @"
create_project CP_T3 {$projDir} -part xc7a35tcpg236-1 -force
if {[catch {set_property board_part digilentinc.com:basys3:part0:1.2 [current_project]}]} {
    puts "Note: board part not available"
}
set_property target_language Verilog [current_project]

$addFiles

create_ip -name xadc_wiz -vendor xilinx.com -library ip -version 3.3 -module_name xadc_wiz_0
set_property -dict [list \
    CONFIG.INTERFACE_SELECTION          {Enable_DRP} \
    CONFIG.SINGLE_CHANNEL_SELECTION     {VAUXP6_VAUXN6} \
    CONFIG.DCLK_FREQUENCY               {100} \
    CONFIG.ADC_CONVERSION_RATE          {1000} \
    CONFIG.CHANNEL_ENABLE_VAUXP6_VAUXN6 {true} \
] [get_ips xadc_wiz_0]
generate_target {all} [get_ips xadc_wiz_0]

set_property top cp_t3_top [current_fileset]
update_compile_order -fileset sources_1

add_files -fileset constrs_1 -norecurse {$xdcFile}

reset_run synth_1
launch_runs synth_1
wait_on_run synth_1
set s [get_property STATUS [get_runs synth_1]]
if {[string first "Complete" `$s] < 0} { puts "ERROR: Synthesis failed: `$s"; exit 1 }

reset_run impl_1
launch_runs impl_1
wait_on_run impl_1
set s [get_property STATUS [get_runs impl_1]]
if {[string first "Complete" `$s] < 0} { puts "ERROR: Implementation failed: `$s"; exit 1 }

launch_runs impl_1 -to_step write_bitstream
wait_on_run impl_1
set s [get_property STATUS [get_runs impl_1]]
if {[string first "Complete" `$s] < 0} { puts "ERROR: Bitstream failed: `$s"; exit 1 }

puts "SUCCESS: Bitstream ready."
close_project
"@

$tclFile = "$TaskDir\build.tcl"
$tcl | Out-File -FilePath $tclFile -Encoding ASCII

& $Vivado -mode batch -source $tclFile -log "$TaskDir\vivado.log" -journal "$TaskDir\vivado.jou"

$bit = "$projDir\CP_T3.runs\impl_1\cp_t3_top.bit"
if (Test-Path $bit) {
    Write-Host "Bitstream: $bit"
} else {
    Write-Host "ERROR: Bitstream not found. Check vivado.log."
}

# CourseProject T1 — Pmod OLED static text display (no Picoblaze)
# Run from repo root: .\CourseProject\T1\build.ps1

$TaskDir = $PSScriptRoot
$Vivado  = "C:\Xilinx\Vivado\2018.3\bin\vivado.bat"

Write-Host "=== CourseProject T1: Pmod OLED Character Display ==="

$vFiles = @(
    "$TaskDir\cp_t1_top.v",
    "$TaskDir\OledSPI.v",
    "$TaskDir\OledInit.v",
    "$TaskDir\OledEX.v",
    "$TaskDir\charLib.v"
)
$xdcFile = "$TaskDir\constraints.xdc"
$projDir = "$TaskDir\vivado_project"

$addFiles = ($vFiles | ForEach-Object { "add_files -norecurse {$_}" }) -join "`n"

$tcl = @"
create_project CP_T1 {$projDir} -part xc7a35tcpg236-1 -force
if {[catch {set_property board_part digilentinc.com:basys3:part0:1.2 [current_project]}]} {
    puts "Note: board part not available"
}
set_property target_language Verilog [current_project]

$addFiles

set_property top cp_t1_top [current_fileset]
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

$bit = "$projDir\CP_T1.runs\impl_1\cp_t1_top.bit"
if (Test-Path $bit) {
    Write-Host "Bitstream: $bit"
} else {
    Write-Host "ERROR: Bitstream not found. Check vivado.log."
}

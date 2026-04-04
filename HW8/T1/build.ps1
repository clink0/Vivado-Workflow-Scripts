# HW8 T1 - Build script
# Uses the provided xadc_wiz_0 IP (.xci) from the official demo
# Run from repo root: .\HW8\T1\build.ps1

$TaskDir  = $PSScriptRoot
$Vivado   = "C:\Xilinx\Vivado\2018.3\bin\vivado.bat"

Write-Host "=== HW8 T1: XADC Demo (provided IP) ==="

# Build file list
$vFiles = @(
    "$TaskDir\XADCdemo.v",
    "$TaskDir\bin2dec.v",
    "$TaskDir\DigitToSeg.v",
    "$TaskDir\mux4_4bus.v",
    "$TaskDir\sevensegdecoder.v",
    "$TaskDir\counter3bit.v",
    "$TaskDir\segClkDevider.v",
    "$TaskDir\decoder3_8.v"
)
$xciFile = "$TaskDir\xadc_wiz_0.xci"
$xdcFile = "$TaskDir\xadc.xdc"
$projDir = "$TaskDir\vivado_project"

# Generate TCL script
$addFiles = ($vFiles | ForEach-Object { "add_files -norecurse {$_}" }) -join "`n"

$tcl = @"
create_project T1 {$projDir} -part xc7a35tcpg236-1 -force
if {[catch {set_property board_part digilentinc.com:basys3:part0:1.2 [current_project]}]} {
    puts "Note: board part not available"
}
set_property target_language Verilog [current_project]

$addFiles

# Add and synthesize the provided xadc_wiz_0 IP
add_files -norecurse {$xciFile}
set_property generate_synth_checkpoint true [get_files xadc_wiz_0.xci]
generate_target {all} [get_files xadc_wiz_0.xci]
synth_ip [get_ips xadc_wiz_0]

set_property top XADCdemo [current_fileset]
update_compile_order -fileset sources_1

add_files -fileset constrs_1 -norecurse {$xdcFile}

# Synthesis
reset_run synth_1
launch_runs synth_1
wait_on_run synth_1
set s [get_property STATUS [get_runs synth_1]]
if {[string first "Complete" `$s] < 0} { puts "ERROR: Synthesis failed: `$s"; exit 1 }

# Implementation
reset_run impl_1
launch_runs impl_1
wait_on_run impl_1
set s [get_property STATUS [get_runs impl_1]]
if {[string first "Complete" `$s] < 0} { puts "ERROR: Implementation failed: `$s"; exit 1 }

# Bitstream
launch_runs impl_1 -to_step write_bitstream
wait_on_run impl_1
set s [get_property STATUS [get_runs impl_1]]
if {[string first "Complete" `$s] < 0} { puts "ERROR: Bitstream failed: `$s"; exit 1 }

puts "SUCCESS: Bitstream written."
close_project
"@

$tclFile = "$TaskDir\build.tcl"
$tcl | Out-File -FilePath $tclFile -Encoding ASCII

Write-Host "Running Vivado..."
& $Vivado -mode batch -source $tclFile -log "$TaskDir\vivado.log" -journal "$TaskDir\vivado.jou"

if (Test-Path "$projDir\T1.runs\impl_1\XADCdemo.bit") {
    Write-Host "Bitstream ready: $projDir\T1.runs\impl_1\XADCdemo.bit"
    Write-Host "Open Vivado Hardware Manager and program the device."
} else {
    Write-Host "ERROR: Bitstream not found. Check vivado.log."
}

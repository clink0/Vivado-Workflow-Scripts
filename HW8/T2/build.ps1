# HW8 T2 - Build script
# Creates a new xadc_wiz_0 IP from scratch via Vivado IP Catalog (create_ip)
# Run from repo root: .\HW8\T2\build.ps1

$TaskDir  = $PSScriptRoot
$Vivado   = "C:\Xilinx\Vivado\2018.3\bin\vivado.bat"

Write-Host "=== HW8 T2: XADC Demo (student-created IP) ==="

$vFiles = @(
    "$TaskDir\xadc_top.v",
    "$TaskDir\bin2dec.v",
    "$TaskDir\DigitToSeg.v",
    "$TaskDir\mux4_4bus.v",
    "$TaskDir\sevensegdecoder.v",
    "$TaskDir\counter3bit.v",
    "$TaskDir\segClkDevider.v",
    "$TaskDir\decoder3_8.v"
)
$xdcFile = "$TaskDir\xadc.xdc"
$projDir = "$TaskDir\vivado_project"

$addFiles = ($vFiles | ForEach-Object { "add_files -norecurse {$_}" }) -join "`n"

$tcl = @"
create_project T2 {$projDir} -part xc7a35tcpg236-1 -force
if {[catch {set_property board_part digilentinc.com:basys3:part0:1.2 [current_project]}]} {
    puts "Note: board part not available"
}
set_property target_language Verilog [current_project]

$addFiles

# Create XADC IP from scratch (this is the "IP you created" for Task 2)
create_ip -name xadc_wiz -vendor xilinx.com -library ip -version 3.3 -module_name xadc_wiz_0
set_property -dict [list \
    CONFIG.INTERFACE_SELECTION      {Enable_DRP} \
    CONFIG.SEQUENCER_MODE           {Continuous} \
    CONFIG.DCLK_FREQUENCY           {100} \
    CONFIG.ADC_CONVERSION_RATE      {1000} \
    CONFIG.CHANNEL_ENABLE_VAUXP6_VAUXN6   {true} \
    CONFIG.CHANNEL_ENABLE_VAUXP7_VAUXN7   {true} \
    CONFIG.CHANNEL_ENABLE_VAUXP14_VAUXN14 {true} \
    CONFIG.CHANNEL_ENABLE_VAUXP15_VAUXN15 {true} \
] [get_ips xadc_wiz_0]
generate_target {all} [get_ips xadc_wiz_0]
synth_ip [get_ips xadc_wiz_0]

set_property top xadc_top [current_fileset]
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

if (Test-Path "$projDir\T2.runs\impl_1\xadc_top.bit") {
    Write-Host "Bitstream ready: $projDir\T2.runs\impl_1\xadc_top.bit"
    Write-Host "Open Vivado Hardware Manager and program the device."
} else {
    Write-Host "ERROR: Bitstream not found. Check vivado.log."
}

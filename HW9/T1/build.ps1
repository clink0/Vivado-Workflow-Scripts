$TaskDir  = $PSScriptRoot
$Vivado   = "C:\Xilinx\Vivado\2018.3\bin\vivado.bat"

$vFiles = @(
    "$TaskDir\XADCdemo.v",
    "$TaskDir\SPI_leader_transmitter.v"
)
$xdcFile = "$TaskDir\constraints.xdc"
$projDir = "$TaskDir\vivado_project"

$addFiles = ($vFiles | ForEach-Object { "add_files -norecurse {$_}" }) -join "`n"

$tcl = @"
create_project T1 {$projDir} -part xc7a35tcpg236-1 -force
if {[catch {set_property board_part digilentinc.com:basys3:part0:1.2 [current_project]}]} {
    puts "Note: board part not available"
}
set_property target_language Verilog [current_project]

$addFiles

create_ip -name xadc_wiz -vendor xilinx.com -library ip -version 3.3 -module_name xadc_wiz_0
set_property -dict [list \
    CONFIG.INTERFACE_SELECTION            {ENABLE_DRP} \
    CONFIG.SEQUENCER_MODE                 {Continuous} \
    CONFIG.DCLK_FREQUENCY                 {100} \
    CONFIG.ADC_CONVERSION_RATE            {1000} \
    CONFIG.CHANNEL_ENABLE_VAUXP6_VAUXN6   {true} \
] [get_ips xadc_wiz_0]
generate_target {all} [get_ips xadc_wiz_0]

set_property top XADCdemo [current_fileset]
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

puts "SUCCESS: Bitstream written."
close_project
"@

$tclFile = "$TaskDir\build.tcl"
$tcl | Out-File -FilePath $tclFile -Encoding ASCII

& $Vivado -mode batch -source $tclFile -log "$TaskDir\vivado.log" -journal "$TaskDir\vivado.jou"

if (Test-Path "$projDir\T1.runs\impl_1\XADCdemo.bit") {
    Write-Host "Bitstream ready: $projDir\T1.runs\impl_1\XADCdemo.bit"
} else {
    Write-Host "ERROR: Bitstream not found. Check vivado.log."
}

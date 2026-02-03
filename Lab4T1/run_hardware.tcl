
# Create project
create_project Lab4T1 {C:\Users\lebray\Vivado-Workflow-Scripts\Lab4T1\vivado_project} -part xc7a35tcpg236-1 -force

# Try to set board_part, but continue if it fails (for older Vivado versions)
if {[catch {set_property board_part digilentinc.com:basys3:part0:1.2 [current_project]}]} {
    puts "Note: Board part not available, using part only"
}

set_property target_language Verilog [current_project]

puts "Adding design files..."
add_files -norecurse {C:\Users\lebray\Vivado-Workflow-Scripts\Lab4T1\trafficLight.v}
add_files -norecurse {C:\Users\lebray\Vivado-Workflow-Scripts\Lab4T1\trafficLight_top.v}
add_files -fileset constrs_1 -norecurse {C:\Users\lebray\Vivado-Workflow-Scripts\Basys3_Master.xdc}
set_property top trafficLight_top [current_fileset]

update_compile_order -fileset sources_1

puts "========================================="
puts "Running Synthesis..."
puts "========================================="

reset_run synth_1
launch_runs synth_1
wait_on_run synth_1

set synth_status [get_property STATUS [get_runs synth_1]]
if {$synth_status != "synth_design Complete!"} {
    puts "ERROR: Synthesis failed: $synth_status"
    exit 1
}
puts "Synthesis completed successfully"

puts "========================================="
puts "Running Implementation..."
puts "========================================="

reset_run impl_1
launch_runs impl_1
wait_on_run impl_1

set impl_status [get_property STATUS [get_runs impl_1]]
if {$impl_status != "route_design Complete!"} {
    puts "ERROR: Implementation failed: $impl_status"
    exit 1
}
puts "Implementation completed successfully"

puts "========================================="
puts "Generating Bitstream..."
puts "========================================="

launch_runs impl_1 -to_step write_bitstream
wait_on_run impl_1

set bit_status [get_property STATUS [get_runs impl_1]]
if {$bit_status != "write_bitstream Complete!"} {
    puts "ERROR: Bitstream generation failed: $bit_status"
    exit 1
}
puts "Bitstream generated successfully"


puts "========================================="
puts "Bitstream Location"
puts "========================================="

set bit_file [get_property DIRECTORY [current_run]]/[get_property top [current_fileset]].bit
puts "Bitstream file: $bit_file"

# Hardware manager programming only works in GUI mode for Vivado 2018.x
# User should program manually using the Hardware Manager GUI
puts ""
puts "========================================="
puts "PROGRAMMING INSTRUCTIONS"
puts "========================================="
puts "Vivado 2018.3 requires GUI for programming."
puts "To program your device:"
puts "  1. Open Vivado GUI"
puts "  2. Flow -> Open Hardware Manager"
puts "  3. Open Target -> Auto Connect"
puts "  4. Program Device -> Select the .bit file above"
puts "========================================="

close_project

puts "========================================="
puts "Hardware flow completed successfully!"
puts "========================================="

exit 0

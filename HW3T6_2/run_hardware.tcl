
create_project HW3T6_2 {C:\Users\lebray\Vivado-Workflow-Scripts\HW3T6_2\vivado_project} -part xc7a35tcpg236-1 -force

if {[catch {set_property board_part digilentinc.com:basys3:part0:1.2 [current_project]}]} {
    puts "Note: Board part not available, using part only"
}

set_property target_language Verilog [current_project]
add_files -norecurse {C:\Users\lebray\Vivado-Workflow-Scripts\HW3T6_2\7seg.v}
add_files -norecurse {C:\Users\lebray\Vivado-Workflow-Scripts\HW3T6_2\carpark.v}
add_files -norecurse {C:\Users\lebray\Vivado-Workflow-Scripts\HW3T6_2\carpark_top.v}
add_files -fileset constrs_1 -norecurse {C:\Users\lebray\Vivado-Workflow-Scripts\Basys3_Master.xdc}
set_property top carpark_top [current_fileset]

update_compile_order -fileset sources_1

reset_run synth_1
launch_runs synth_1
wait_on_run synth_1
set synth_status [get_property STATUS [get_runs synth_1]]
if {$synth_status != "synth_design Complete!"} {
    puts "ERROR: Synthesis failed: $synth_status"
    exit 1
}

reset_run impl_1
launch_runs impl_1
wait_on_run impl_1
set impl_status [get_property STATUS [get_runs impl_1]]
if {$impl_status != "route_design Complete!"} {
    puts "ERROR: Implementation failed: $impl_status"
    exit 1
}

launch_runs impl_1 -to_step write_bitstream
wait_on_run impl_1
set bit_status [get_property STATUS [get_runs impl_1]]
if {$bit_status != "write_bitstream Complete!"} {
    puts "ERROR: Bitstream generation failed: $bit_status"
    exit 1
}

close_project

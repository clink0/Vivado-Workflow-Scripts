
create_project HW3T5_2 {C:\Users\lebray\Vivado-Workflow-Scripts\HW3T5_2\vivado_project} -part xc7a35tcpg236-1 -force

if {[catch {set_property board_part digilentinc.com:basys3:part0:1.2 [current_project]}]} {
    puts "Note: Board part not available, using part only"
}

set_property target_language Verilog [current_project]
add_files -norecurse {C:\Users\lebray\Vivado-Workflow-Scripts\HW3T5_2\even_parity_checker_top.v}
add_files -norecurse {C:\Users\lebray\Vivado-Workflow-Scripts\HW3T5_2\four_bit_even_parity_checker.v}
add_files -fileset sim_1 -norecurse {C:\Users\lebray\Vivado-Workflow-Scripts\HW3T5_2\four_bit_even_parity_checker_tb.v}
add_files -fileset constrs_1 -norecurse {C:\Users\lebray\Vivado-Workflow-Scripts\Basys3_Master.xdc}
set_property top even_parity_checker_top [current_fileset]
set_property top four_bit_even_parity_checker_tb [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

launch_simulation -mode behavioral

run 1000ns

catch {
    add_wave {/*}
}

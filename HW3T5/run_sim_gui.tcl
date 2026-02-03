
# Create project
create_project HW3T5 {C:\Users\lebray\Vivado-Workflow-Scripts\HW3T5\vivado_project} -part xc7a35tcpg236-1 -force

# Try to set board_part, but continue if it fails (for older Vivado versions)
if {[catch {set_property board_part digilentinc.com:basys3:part0:1.2 [current_project]}]} {
    puts "Note: Board part not available, using part only"
}

set_property target_language Verilog [current_project]

puts "Adding design files..."
add_files -norecurse {C:\Users\lebray\Vivado-Workflow-Scripts\HW3T5\three_bit_even_parity_generator.v}

puts "Adding testbench files..."
add_files -fileset sim_1 -norecurse {C:\Users\lebray\Vivado-Workflow-Scripts\HW3T5\three_bit_even_parity_generator_tb.v}
add_files -fileset constrs_1 -norecurse {C:\Users\lebray\Vivado-Workflow-Scripts\Basys3_Master.xdc}
set_property top three_bit_even_parity_generator [current_fileset]
set_property top three_bit_even_parity_generator_tb [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "========================================="
puts "Launching simulation in GUI mode..."
puts "========================================="

# Launch simulation in GUI mode
launch_simulation -mode behavioral


# Run simulation
run 1000ns

# Add all signals to waveform (if not already added)
catch {
    add_wave {/*}
}

puts "========================================="
puts "Simulation completed!"
puts "Waveform viewer is now open."
puts "Close the waveform window when done viewing."
puts "========================================="

# Don't close automatically - let user view waveforms
# User will close Vivado when done

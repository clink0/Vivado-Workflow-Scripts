# HW9 T1 Constraints - SPI Leader constant output

# Clock
set_property PACKAGE_PIN W5 [get_ports CLK100MHZ]
set_property IOSTANDARD LVCMOS33 [get_ports CLK100MHZ]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports CLK100MHZ]

# JB PMOD - SPI outputs
# JB1 = SCK
set_property PACKAGE_PIN H4 [get_ports {JB[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {JB[0]}]
# JB2 = SS (active low)
set_property PACKAGE_PIN H1 [get_ports {JB[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {JB[1]}]
# JB3 = MOSI
set_property PACKAGE_PIN G1 [get_ports {JB[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {JB[2]}]

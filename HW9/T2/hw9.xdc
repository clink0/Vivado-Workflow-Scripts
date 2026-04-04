# HW9 T2 Constraints - XADC + SPI Leader to Arduino

# Clock
set_property PACKAGE_PIN W5 [get_ports CLK100MHZ]
set_property IOSTANDARD LVCMOS33 [get_ports CLK100MHZ]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports CLK100MHZ]

# JB PMOD - SPI outputs to Arduino
# JB1 = SCK  -> Arduino Pin 2
set_property PACKAGE_PIN H4 [get_ports {JB[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {JB[0]}]
# JB2 = SS (active low) -> Arduino Pin 12
set_property PACKAGE_PIN H1 [get_ports {JB[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {JB[1]}]
# JB3 = MOSI -> Arduino Pin 13
set_property PACKAGE_PIN G1 [get_ports {JB[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {JB[2]}]

# JXADC - Analog input (Easy Pulse Sensor / potentiometer on channel 6)
# vauxp6 = JXADC pin 1 (J3), vauxn6 = JXADC pin 5 (K3, tie to GND)
set_property PACKAGE_PIN J3 [get_ports vauxp6]
set_property IOSTANDARD LVCMOS33 [get_ports vauxp6]
set_property PACKAGE_PIN K3 [get_ports vauxn6]
set_property IOSTANDARD LVCMOS33 [get_ports vauxn6]

# vp_in / vn_in are dedicated XADC pins - no XDC constraint needed

# CourseProject T1 — Pmod OLED on JB connector

# Clock
set_property PACKAGE_PIN W5  [get_ports CLK100MHZ]
set_property IOSTANDARD LVCMOS33 [get_ports CLK100MHZ]
create_clock -period 10.000 -name sys_clk -add [get_ports CLK100MHZ]

# Button C — reset
set_property PACKAGE_PIN U18 [get_ports btnC]
set_property IOSTANDARD LVCMOS33 [get_ports btnC]

# Pmod JB — OLED signals
# JB1 (A14) = CS
set_property PACKAGE_PIN A14 [get_ports CS]
set_property IOSTANDARD LVCMOS33 [get_ports CS]

# JB2 (A16) = SDIN (MOSI)
set_property PACKAGE_PIN A16 [get_ports SDIN]
set_property IOSTANDARD LVCMOS33 [get_ports SDIN]

# JB4 (B16) = SCLK
set_property PACKAGE_PIN B16 [get_ports SCLK]
set_property IOSTANDARD LVCMOS33 [get_ports SCLK]

# JB7 (A15) = DC (Data/Command)
set_property PACKAGE_PIN A15 [get_ports DC]
set_property IOSTANDARD LVCMOS33 [get_ports DC]

# JB8 (A17) = RES (Reset, active low)
set_property PACKAGE_PIN A17 [get_ports RES]
set_property IOSTANDARD LVCMOS33 [get_ports RES]

# JB9 (C15) = VBAT (power FET, active low)
set_property PACKAGE_PIN C15 [get_ports VBAT]
set_property IOSTANDARD LVCMOS33 [get_ports VBAT]

# JB10 (C16) = VDD (power FET, active low)
set_property PACKAGE_PIN C16 [get_ports VDD]
set_property IOSTANDARD LVCMOS33 [get_ports VDD]

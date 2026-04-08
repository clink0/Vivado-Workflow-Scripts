# HW11 T3 — Full Heart Rate Monitor (XADC + Picoblaze + OLED + UART)

# Clock
set_property PACKAGE_PIN W5  [get_ports CLK100MHZ]
set_property IOSTANDARD LVCMOS33 [get_ports CLK100MHZ]
create_clock -period 10.000 -name sys_clk -add [get_ports CLK100MHZ]

# Button C — reset
set_property PACKAGE_PIN U18 [get_ports btnC]
set_property IOSTANDARD LVCMOS33 [get_ports btnC]

# LEDs (lower 8 show raw XADC value)
set_property PACKAGE_PIN U16 [get_ports {led[0]}]
set_property PACKAGE_PIN E19 [get_ports {led[1]}]
set_property PACKAGE_PIN U19 [get_ports {led[2]}]
set_property PACKAGE_PIN V19 [get_ports {led[3]}]
set_property PACKAGE_PIN W18 [get_ports {led[4]}]
set_property PACKAGE_PIN U15 [get_ports {led[5]}]
set_property PACKAGE_PIN U14 [get_ports {led[6]}]
set_property PACKAGE_PIN V14 [get_ports {led[7]}]
set_property PACKAGE_PIN V13 [get_ports {led[8]}]
set_property PACKAGE_PIN V3  [get_ports {led[9]}]
set_property PACKAGE_PIN W3  [get_ports {led[10]}]
set_property PACKAGE_PIN U3  [get_ports {led[11]}]
set_property PACKAGE_PIN P3  [get_ports {led[12]}]
set_property PACKAGE_PIN N3  [get_ports {led[13]}]
set_property PACKAGE_PIN P1  [get_ports {led[14]}]
set_property PACKAGE_PIN L1  [get_ports {led[15]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[*]}]

# XADC — JXADC VAUXP6/VAUXN6 (pulse sensor input)
set_property PACKAGE_PIN J3 [get_ports vauxp6]
set_property IOSTANDARD LVCMOS33 [get_ports vauxp6]
set_property PACKAGE_PIN K3 [get_ports vauxn6]
set_property IOSTANDARD LVCMOS33 [get_ports vauxn6]

# Pmod JB — OLED
set_property PACKAGE_PIN A14 [get_ports CS]
set_property IOSTANDARD LVCMOS33 [get_ports CS]
set_property PACKAGE_PIN A16 [get_ports SDIN]
set_property IOSTANDARD LVCMOS33 [get_ports SDIN]
set_property PACKAGE_PIN B16 [get_ports SCLK]
set_property IOSTANDARD LVCMOS33 [get_ports SCLK]
set_property PACKAGE_PIN A15 [get_ports DC]
set_property IOSTANDARD LVCMOS33 [get_ports DC]
set_property PACKAGE_PIN A17 [get_ports RES]
set_property IOSTANDARD LVCMOS33 [get_ports RES]
set_property PACKAGE_PIN C15 [get_ports VBAT]
set_property IOSTANDARD LVCMOS33 [get_ports VBAT]
set_property PACKAGE_PIN C16 [get_ports VDD]
set_property IOSTANDARD LVCMOS33 [get_ports VDD]

# UART TX — Basys3 USB-UART bridge (pin A18 = UART_TX_OUT on Basys3)
set_property PACKAGE_PIN A18 [get_ports uart_tx]
set_property IOSTANDARD LVCMOS33 [get_ports uart_tx]

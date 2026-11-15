# RISC-V Processor Minimal Constraints File
# For Xilinx 7-series FPGA (Basys3 board)
#
# Clocking: W5 is the 100 MHz board oscillator. The wrapper divides it by 2
# (toggle flop + BUFG) to produce the 50 MHz core clock. Timing is constrained
# on the generated core clock, matching the actual hardware.

# Board clock: 100 MHz oscillator
set_property PACKAGE_PIN W5 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -period 10.000 -name sys_clk_pin [get_ports clk]

# Generated 50 MHz core clock from the toggle-flop + BUFG divider in the wrapper
create_generated_clock -name clk_core -source [get_ports clk] -divide_by 2 [get_pins u_clkbuf/O]

# Reset button (asynchronous, active high) - synchronized in the wrapper
set_property PACKAGE_PIN U18 [get_ports reset]
set_property IOSTANDARD LVCMOS33 [get_ports reset]
set_false_path -from [get_ports reset]

# Debug output LEDs (PC debug - lower 16 bits only)
set_property PACKAGE_PIN U16 [get_ports {pc_debug[0]}]
set_property PACKAGE_PIN E19 [get_ports {pc_debug[1]}]
set_property PACKAGE_PIN U19 [get_ports {pc_debug[2]}]
set_property PACKAGE_PIN V19 [get_ports {pc_debug[3]}]
set_property PACKAGE_PIN W18 [get_ports {pc_debug[4]}]
set_property PACKAGE_PIN U15 [get_ports {pc_debug[5]}]
set_property PACKAGE_PIN U14 [get_ports {pc_debug[6]}]
set_property PACKAGE_PIN V14 [get_ports {pc_debug[7]}]
set_property PACKAGE_PIN V13 [get_ports {pc_debug[8]}]
set_property PACKAGE_PIN V3 [get_ports {pc_debug[9]}]
set_property PACKAGE_PIN W3 [get_ports {pc_debug[10]}]
set_property PACKAGE_PIN U3 [get_ports {pc_debug[11]}]
set_property PACKAGE_PIN P3 [get_ports {pc_debug[12]}]
set_property PACKAGE_PIN N3 [get_ports {pc_debug[13]}]
set_property PACKAGE_PIN P1 [get_ports {pc_debug[14]}]
set_property PACKAGE_PIN L1 [get_ports {pc_debug[15]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pc_debug[*]}]

# LEDs are asynchronous status outputs - no timing requirement
set_false_path -to [get_ports {pc_debug[*]}]

# Clock uncertainty on the core clock
set_clock_uncertainty -setup 0.100 [get_clocks clk_core]
set_clock_uncertainty -hold 0.050 [get_clocks clk_core]

# I/O voltage configuration for bitstream generation
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
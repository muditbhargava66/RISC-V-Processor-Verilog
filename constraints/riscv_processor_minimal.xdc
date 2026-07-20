# RISC-V Processor Minimal Constraints File
# For Xilinx 7-series FPGA (Basys3 board)
# Reduced I/O for successful implementation

# Clock constraint - 50MHz for reliable timing
set_property PACKAGE_PIN W5 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -period 20.000 -name sys_clk_pin -waveform {0.000 10.000} [get_ports clk]

# Reset button
set_property PACKAGE_PIN U18 [get_ports reset]
set_property IOSTANDARD LVCMOS33 [get_ports reset]

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

# Timing constraints
set_input_delay -clock sys_clk_pin -min 0.500 [get_ports reset]
set_input_delay -clock sys_clk_pin -max 2.000 [get_ports reset]

# Output delay constraints for debug signals
set_output_delay -clock sys_clk_pin -min 0.500 [get_ports {pc_debug[*]}]
set_output_delay -clock sys_clk_pin -max 3.000 [get_ports {pc_debug[*]}]

# Set false paths for debug outputs to relax timing
set_false_path -to [get_ports {pc_debug[*]}]

# Clock uncertainty
set_clock_uncertainty -setup 0.100 [get_clocks sys_clk_pin]
set_clock_uncertainty -hold 0.050 [get_clocks sys_clk_pin]

# Set maximum delay for internal paths
set_max_delay -from [get_clocks sys_clk_pin] -to [get_clocks sys_clk_pin] 19.500